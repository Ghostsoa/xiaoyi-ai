import 'package:flutter/material.dart';
import '../../model/character_card.dart';
import '../../model/chat_message.dart';
import '../../model/chat_history.dart';
import '../../service/chat_history_service.dart';
import '../../service/image_service.dart';
import '../../components/custom_snack_bar.dart';
import 'widgets/chat_input.dart';
import 'widgets/group_message_list.dart';
import '../../service/chat_list_service.dart';
import '../../net/chat/chat_service.dart';
import 'dart:convert';

class GroupChatPage extends StatefulWidget {
  final CharacterCard character;
  final ChatHistoryService chatHistoryService;
  final ChatListService chatListService;

  const GroupChatPage({
    super.key,
    required this.character,
    required this.chatHistoryService,
    required this.chatListService,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  late ChatHistory _chatHistory;
  bool _isLoading = false;
  bool _isInitialized = false;
  final _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final history =
          await widget.chatHistoryService.getHistory(widget.character.code);
      setState(() {
        _chatHistory = history;
        _messages.addAll(
          history.messages.map(
            (msg) => ChatMessage(
              isUser: msg['role'] == 'user',
              content: msg['content'] ?? '',
              timestamp: DateTime.now(),
            ),
          ),
        );
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '加载历史记录失败');
      }
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 移除内容中的标签
  String _removeContentTags(String content) {
    return content.replaceAllMapped(
      RegExp(r'<(scene|action|thought|s)>(.*?)</\1>'),
      (Match m) => m.group(2) ?? '',
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading || !_isInitialized) return;

    // 添加用户消息
    final userMessage = ChatMessage(
      isUser: true,
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      // 将用户消息添加到历史记录
      _chatHistory.addMessage(
        true,
        text,
        enableContextLimit: widget.character.modelParams.enableContextLimit,
        contextTurns: widget.character.modelParams.contextTurns,
      );
      _inputController.clear();
      _isLoading = true;
    });

    try {
      // 获取应该发言的角色列表
      final speakers = await _chatService.decideNextSpeakers(
        input: text,
        messages: _chatHistory.messages,
        systemPrompt: widget.character.setting,
        roles: widget.character.groupCharacters,
      );

      if (mounted && speakers.isNotEmpty) {
        // 遍历每个应该发言的角色
        for (final speakerName in speakers) {
          final speaker = widget.character.groupCharacters
              .firstWhere((role) => role.name == speakerName);

          // 获取角色回复
          final response = await _chatService.sendMessage(
            input: text,
            messages: _chatHistory.messages,
            card: widget.character,
            role: speaker,
          );

          if (mounted && response != null) {
            Map<String, dynamic>? responseData;
            String displayContent;

            try {
              responseData = json.decode(response) as Map<String, dynamic>;
              displayContent = responseData['content'] as String? ?? response;
              displayContent = _removeContentTags(displayContent);
            } catch (e) {
              displayContent = _removeContentTags(response);
              responseData = {'content': response};
            }

            responseData['name'] = speakerName;

            final aiMessage = ChatMessage(
              isUser: false,
              content: json.encode(responseData),
              timestamp: DateTime.now(),
            );

            setState(() {
              _messages.add(aiMessage);
              _chatHistory.addMessage(
                false,
                response,
                enableContextLimit:
                    widget.character.modelParams.enableContextLimit,
                contextTurns: widget.character.modelParams.contextTurns,
              );
            });

            // 保存对话历史
            await widget.chatHistoryService.saveHistory(_chatHistory);
            // 更新消息列表，使用实际显示的内容（已去除标签）
            await widget.chatListService.updateItem(
              widget.character,
              ChatMessage(
                isUser: false,
                content: displayContent,
                timestamp: DateTime.now(),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeLast();
          _chatHistory.messages.removeLast();
          _isLoading = false;
          // 将发送的内容恢复到输入框
          _inputController.text = text;
        });
        CustomSnackBar.show(context, message: '发送失败: $e');
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleActionSelected(String action) {
    _inputController.text = action;
    _sendMessage();
  }

  void _handleMessageEdit(ChatMessage updatedMessage) {
    // 如果是撤销操作（content为空）
    if (updatedMessage.content.isEmpty) {
      // 找到最后一条用户消息的位置
      int lastUserMessageIndex = _messages.length - 1;
      String? lastUserMessage;

      while (lastUserMessageIndex >= 0 &&
          !_messages[lastUserMessageIndex].isUser) {
        lastUserMessageIndex--;
      }

      if (lastUserMessageIndex >= 0) {
        // 保存用户的最后一条消息
        lastUserMessage = _messages[lastUserMessageIndex].content;

        setState(() {
          // 移除从用户消息到最后的所有消息（包括所有AI回复）
          _messages.removeRange(lastUserMessageIndex, _messages.length);
          _chatHistory.messages
              .removeRange(lastUserMessageIndex, _chatHistory.messages.length);
        });

        // 恢复用户输入
        _inputController.text = lastUserMessage;

        // 保存更新后的历史记录
        widget.chatHistoryService.saveHistory(_chatHistory);

        // 更新消息列表显示
        if (_messages.isNotEmpty) {
          final lastMessage = _messages.last;
          String displayContent;
          try {
            final jsonData = json.decode(lastMessage.content);
            displayContent =
                _removeContentTags(jsonData['content'] as String? ?? '');
          } catch (e) {
            displayContent = _removeContentTags(lastMessage.content);
          }

          widget.chatListService.updateItem(
            widget.character,
            ChatMessage(
              isUser: lastMessage.isUser,
              content: displayContent,
              timestamp: lastMessage.timestamp,
            ),
          );
        }
      }
      return;
    }

    // 使用时间戳和用户标识来匹配消息
    final index = _messages.indexWhere((msg) =>
        msg.timestamp == updatedMessage.timestamp &&
        msg.isUser == updatedMessage.isUser);

    if (index != -1) {
      setState(() {
        _messages[index] = updatedMessage;

        // 更新历史记录
        final historyIndex =
            _chatHistory.messages.length - _messages.length + index;
        if (historyIndex >= 0 && historyIndex < _chatHistory.messages.length) {
          try {
            // 解析更新后的消息内容
            final jsonData = json.decode(updatedMessage.content);
            _chatHistory.messages[historyIndex] = {
              'role': updatedMessage.isUser ? 'user' : 'assistant',
              'content': json.encode(jsonData), // 保持 JSON 格式
              'name': jsonData['name'], // 保留角色名称
            };
          } catch (e) {
            // 如果解析失败，直接使用原始内容
            _chatHistory.messages[historyIndex] = {
              'role': updatedMessage.isUser ? 'user' : 'assistant',
              'content': updatedMessage.content,
            };
          }
        }
      });

      // 保存更新后的历史记录
      widget.chatHistoryService.saveHistory(_chatHistory);

      // 更新消息列表显示
      String displayContent;
      try {
        final jsonData = json.decode(updatedMessage.content);
        displayContent =
            _removeContentTags(jsonData['content'] as String? ?? '');
      } catch (e) {
        displayContent = _removeContentTags(updatedMessage.content);
      }

      widget.chatListService.updateItem(
        widget.character,
        ChatMessage(
          isUser: updatedMessage.isUser,
          content: displayContent,
          timestamp: updatedMessage.timestamp,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (widget.character.backgroundImageBase64 != null)
            Positioned.fill(
              child: ImageService.imageFromBase64String(
                widget.character.backgroundImageBase64!,
                fit: BoxFit.cover,
              ),
            ),
          Positioned.fill(
            child: Container(
              color:
                  Colors.black.withOpacity(widget.character.backgroundOpacity),
            ),
          ),
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                title: Column(
                  children: [
                    Text(
                      widget.character.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${widget.character.groupCharacters.length}人群聊',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                actions: [
                  // 存档切换按钮
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () => _showSlotSelectionDialog(),
                  ),
                  // 群聊成员按钮
                  IconButton(
                    icon: const Icon(Icons.group),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.black87,
                        builder: (context) => _buildMembersList(),
                      );
                    },
                  ),
                  // 清除历史按钮
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.black87,
                          title: const Text(
                            '清除对话历史',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            '确定要清除当前存档的所有对话历史吗？此操作不可恢复。',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text(
                                '取消',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                '清除',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await widget.chatHistoryService
                              .clearHistory(widget.character.code);
                          await widget.chatListService
                              .deleteItem(widget.character.code);

                          if (mounted) {
                            setState(() {
                              _messages.clear();
                              _chatHistory.clear();
                            });
                            CustomSnackBar.show(context, message: '对话历史已清除');
                          }
                        } catch (e) {
                          if (mounted) {
                            CustomSnackBar.show(context, message: '清除失败: $e');
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
              Expanded(
                child: GroupMessageList(
                  messages: _messages,
                  scrollController: _scrollController,
                  aiBubbleColor: widget.character.aiBubbleColor,
                  aiTextColor: widget.character.aiTextColor,
                  userBubbleColor: widget.character.userBubbleColor,
                  userTextColor: widget.character.userTextColor,
                  statusBarType: widget.character.statusBarType,
                  onActionSelected: _handleActionSelected,
                  onMessageEdited: _handleMessageEdit,
                  characters: widget.character.groupCharacters,
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ChatInput(
              controller: _inputController,
              isLoading: _isLoading,
              onSend: _sendMessage,
              onUndo: () {
                _handleMessageEdit(
                  ChatMessage(
                    isUser: true,
                    content: '',
                    timestamp: DateTime.now(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: const Row(
            children: [
              Icon(Icons.group, color: Colors.white),
              SizedBox(width: 8),
              Text(
                '群聊成员',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white24),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: widget.character.groupCharacters.length,
            itemBuilder: (context, index) {
              final character = widget.character.groupCharacters[index];
              return ListTile(
                leading: character.avatarBase64 != null
                    ? ClipOval(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: ImageService.imageFromBase64String(
                            character.avatarBase64!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white24,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                title: Text(
                  character.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  character.setting,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: Colors.white70),
                  onPressed: () {
                    Navigator.pop(context);
                    _requestCharacterSpeak(character);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 请求指定角色发言
  Future<void> _requestCharacterSpeak(GroupCharacter character) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 调用AI接口获取角色回复
      final response = await _chatService.sendMessage(
        input: '请以此角色继续发言',
        messages: _chatHistory.messages,
        card: widget.character,
        role: character,
      );

      if (mounted && response != null) {
        Map<String, dynamic>? responseData;
        String displayContent;

        try {
          responseData = json.decode(response) as Map<String, dynamic>;
          displayContent = responseData['content'] as String? ?? response;
        } catch (e) {
          displayContent = response;
          responseData = {'content': response};
        }

        responseData['name'] = character.name;

        final aiMessage = ChatMessage(
          isUser: false,
          content: json.encode(responseData),
          timestamp: DateTime.now(),
        );

        setState(() {
          _messages.add(aiMessage);
          _chatHistory.addMessage(
            false,
            response,
            enableContextLimit: widget.character.modelParams.enableContextLimit,
            contextTurns: widget.character.modelParams.contextTurns,
          );
        });

        // 保存对话历史
        await widget.chatHistoryService.saveHistory(_chatHistory);
        // 更新消息列表
        await widget.chatListService.updateItem(
          widget.character,
          ChatMessage(
            isUser: false,
            content: displayContent,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '发送失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showSlotSelectionDialog() async {
    await showDialog<int>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择存档',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: widget.chatHistoryService
                    .getSlotPreviews(widget.character.code),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return Column(
                    children: snapshot.data!.map((preview) {
                      final slot = preview['slot'] as int;
                      final messageCount = preview['messageCount'] as int;

                      return ListTile(
                        title: Row(
                          children: [
                            Text(
                              '存档 $slot',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            if (slot == _chatHistory.slot)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '当前',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          messageCount > 0 ? '$messageCount条消息' : '空存档',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        onTap: () async {
                          if (slot != _chatHistory.slot) {
                            // 保存当前存档
                            await widget.chatHistoryService
                                .saveHistory(_chatHistory);
                            // 加载新存档
                            final newHistory =
                                await widget.chatHistoryService.getHistory(
                              widget.character.code,
                              slot: slot,
                            );
                            // 设置当前存档槽位
                            await widget.chatHistoryService.setCurrentSlot(
                              widget.character.code,
                              slot,
                            );
                            if (mounted) {
                              setState(() {
                                _chatHistory = newHistory;
                                _messages.clear();
                                _messages.addAll(
                                  newHistory.messages.map(
                                    (msg) => ChatMessage(
                                      isUser: msg['role'] == 'user',
                                      content: msg['content'] ?? '',
                                      timestamp: DateTime.now(),
                                    ),
                                  ),
                                );
                              });
                              Navigator.of(context).pop();
                            }
                          }
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
