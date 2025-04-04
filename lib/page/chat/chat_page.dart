import 'package:flutter/material.dart';
import '../../model/character_card.dart';
import '../../model/chat_message.dart';
import '../../model/chat_history.dart';
import '../../service/chat_history_service.dart';
import '../../service/image_service.dart';
import '../../components/custom_snack_bar.dart';
import 'widgets/chat_input.dart';
import 'widgets/chat_message_list.dart';
import '../../service/chat_list_service.dart';
import '../../net/chat/chat_service.dart';
import 'dart:convert';

class ChatPage extends StatefulWidget {
  final CharacterCard character;
  final ChatHistoryService chatHistoryService;
  final ChatListService chatListService;

  const ChatPage({
    super.key,
    required this.character,
    required this.chatHistoryService,
    required this.chatListService,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
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
        // 将历史消息转换为UI显示的消息列表
        _messages.addAll(
          history.messages.map(
            (msg) => ChatMessage(
              isUser: msg['role'] == 'user',
              content: msg['content'] ?? '',
              timestamp: DateTime.now(), // 历史消息暂时使用当前时间
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
      // 调用AI接口获取回复
      final response = await _chatService.sendMessage(
        input: text,
        messages: _chatHistory.messages,
        card: widget.character,
      );

      if (mounted && response != null) {
        // 解析响应JSON
        Map<String, dynamic>? responseData;
        String displayContent;

        if (widget.character.statusBarType != StatusBarType.none) {
          // 只在启用状态栏时进行 JSON 处理
          try {
            responseData = json.decode(response) as Map<String, dynamic>;
            displayContent = responseData['content'] as String? ?? response;
            // 移除显示内容中的标签
            displayContent = _removeContentTags(displayContent);
          } catch (e) {
            displayContent = _removeContentTags(response);
            responseData = {'content': response};
          }
        } else {
          // 不启用状态栏时直接使用原始响应
          displayContent = _removeContentTags(response);
        }

        final aiMessage = ChatMessage(
          isUser: false,
          // 根据是否启用状态栏决定消息内容格式
          content:
              responseData != null ? json.encode(responseData) : displayContent,
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
          _isLoading = false;
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
      } else {
        throw Exception('响应为空');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // 发送失败时，将用户消息从历史记录中移除
          _messages.removeLast();
          _chatHistory.messages.removeLast();
          _isLoading = false;
          // 将发送的内容恢复到输入框
          _inputController.text = text;
        });
        CustomSnackBar.show(context, message: '发送失败: $e');
      }
    }
  }

  void _handleActionSelected(String action) {
    _inputController.text = action;
    _sendMessage();
  }

  Future<void> _handleMessageEdit(ChatMessage editedMessage) async {
    // 如果是撤销操作（content为空）
    if (editedMessage.content.isEmpty) {
      String? lastUserMessage;
      setState(() {
        if (_messages.length >= 2) {
          // 保存用户的最后一条消息
          final userMessage = _messages[_messages.length - 2];
          if (userMessage.isUser) {
            lastUserMessage = userMessage.content;
          }
          _messages.removeRange(_messages.length - 2, _messages.length);
          _chatHistory.messages.removeRange(
              _chatHistory.messages.length - 2, _chatHistory.messages.length);
        } else if (_messages.length == 1) {
          final message = _messages.last;
          if (message.isUser) {
            lastUserMessage = message.content;
          }
          _messages.removeLast();
          _chatHistory.messages.removeLast();
        }
      });

      // 恢复用户输入
      if (lastUserMessage?.isNotEmpty ?? false) {
        _inputController.text = lastUserMessage!;
      }

      // 保存更新后的历史记录
      await widget.chatHistoryService.saveHistory(_chatHistory);
      // 更新消息列表显示
      if (_messages.isNotEmpty) {
        final lastMessage = _messages.last;
        await widget.chatListService.updateItem(
          widget.character,
          lastMessage,
        );
      }
      return;
    }

    // 正常的编辑操作
    final index = _messages.indexWhere((msg) =>
        msg.timestamp == editedMessage.timestamp &&
        msg.isUser == editedMessage.isUser);

    if (index != -1) {
      setState(() {
        _messages[index] = editedMessage;
      });

      // 更新历史记录
      final historyIndex =
          _chatHistory.messages.length - _messages.length + index;
      if (historyIndex >= 0 && historyIndex < _chatHistory.messages.length) {
        _chatHistory.messages[historyIndex] = {
          'role': editedMessage.isUser ? 'user' : 'assistant',
          'content': editedMessage.content,
        };

        // 保存更新后的历史记录
        await widget.chatHistoryService.saveHistory(_chatHistory);

        // 更新消息列表
        await widget.chatListService.updateItem(
          widget.character,
          editedMessage,
        );
      }
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
          // 背景图
          if (widget.character.backgroundImageBase64 != null)
            Positioned.fill(
              child: ImageService.imageFromBase64String(
                widget.character.backgroundImageBase64!,
                fit: BoxFit.cover,
              ),
            ),
          // 背景遮罩
          Positioned.fill(
            child: Container(
              color:
                  Colors.black.withOpacity(widget.character.backgroundOpacity),
            ),
          ),
          // 主体内容
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  widget.character.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  // 存档切换按钮
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () => _showSlotSelectionDialog(),
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
                child: ChatMessageList(
                  messages: _messages,
                  scrollController: _scrollController,
                  aiBubbleColor: widget.character.aiBubbleColor,
                  aiTextColor: widget.character.aiTextColor,
                  userBubbleColor: widget.character.userBubbleColor,
                  userTextColor: widget.character.userTextColor,
                  statusBarType: widget.character.statusBarType,
                  onActionSelected: _handleActionSelected,
                  onMessageEdited: _handleMessageEdit,
                ),
              ),
            ],
          ),
          // 底部输入框
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
