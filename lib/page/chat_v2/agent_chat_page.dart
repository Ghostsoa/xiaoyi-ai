import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../net/session/session_service.dart';
import '../../components/chat_v2/chat_input_field.dart';
import '../../components/chat_v2/custom_fields_panel.dart';
import '../../components/custom_snack_bar.dart';
import '../../components/custom_markdown.dart';
import '../../dao/settings_dao.dart';

class Message {
  final String id;
  final String sessionId;
  final String role;
  final String content;
  final int? tokenCount;
  final String? modelName;
  final String? createdAt;
  final bool isComplete;
  final List<String>? keywords;

  Message({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.tokenCount,
    this.modelName,
    this.createdAt,
    this.isComplete = true,
    this.keywords,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    List<String>? keywords;
    if (json['keywords'] != null) {
      keywords = List<String>.from(json['keywords']);
    }

    return Message(
      id: json['id'].toString(),
      sessionId: json['session_id'],
      role: json['role'],
      content: json['content'],
      tokenCount: json['token_count'],
      modelName: json['model_name'],
      createdAt: json['created_at'],
      keywords: keywords,
    );
  }

  factory Message.pending({required String content}) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: '',
      role: 'model',
      content: content,
      isComplete: false,
    );
  }

  factory Message.user({required String content}) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: '',
      role: 'user',
      content: content,
    );
  }

  bool get isUser => role == 'user';
}

class AgentChatPage extends StatefulWidget {
  final String sessionId;
  final String sessionName;
  final String? backgroundBase64;

  const AgentChatPage({
    super.key,
    required this.sessionId,
    required this.sessionName,
    this.backgroundBase64,
  });

  @override
  State<AgentChatPage> createState() => _AgentChatPageState();
}

class _AgentChatPageState extends State<AgentChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _refreshController = RefreshController();
  final _sessionService = SessionService();
  final List<Message> _messages = [];
  bool _isSending = false;
  bool _isLoading = false;
  late final ImageProvider? _backgroundImage;
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _showPanel = false;
  bool _isLoadingCustomFields = false;
  Map<String, dynamic>? _customFields;
  late List<Map<String, dynamic>> _regexStyles;
  bool _showScrollToBottom = false;

  // 颜色设置
  late SettingsDao _settingsDao;
  Color _userBubbleColor = Colors.blue.shade600;
  Color _aiBubbleColor = Colors.black87;
  Color _userTextColor = Colors.white;
  Color _aiTextColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _initializeSettings();
    _initializeScrollController();
  }

  void _initializeScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        // 当距离底部超过200像素时显示按钮
        setState(() {
          _showScrollToBottom = maxScroll - currentScroll > 200;
        });
      }
    });
  }

  void _initializeChat() {
    // 处理背景图片
    _backgroundImage = _getBackgroundImage();
    // 在构建完成后加载消息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  Future<void> _initializeSettings() async {
    _settingsDao = await SettingsDao.create();
    await _loadColorSettings();
    _regexStyles = _settingsDao.getRegexStyles();
  }

  ImageProvider? _getBackgroundImage() {
    if (widget.backgroundBase64 == null || widget.backgroundBase64!.isEmpty) {
      return null;
    }

    try {
      final cleanBase64 = widget.backgroundBase64!
          .replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
      return MemoryImage(base64Decode(cleanBase64));
    } catch (e) {
      debugPrint('加载背景图片失败: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // 确保在下一帧绘制完成后滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _loadMessages({bool initial = true}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final page = initial ? 1 : _currentPage + 1;
      final result =
          await _sessionService.getMessages(widget.sessionId, page: page);

      final messages = result['messages'] as List<dynamic>;
      final total = result['total'] as int;

      if (mounted) {
        setState(() {
          if (initial) {
            _messages.clear();
            _currentPage = 1;
          } else {
            _currentPage++;
          }

          if (messages.isNotEmpty) {
            final newMessages =
                messages.map((m) => Message.fromJson(m)).toList();

            // 按照时间顺序排序
            if (initial) {
              _messages.addAll(newMessages);
              // 初始加载时立即滚动到底部
              _scrollToBottom();
            } else {
              // 加载更多历史消息，添加到列表前面
              _messages.insertAll(0, newMessages);
            }

            // 根据总消息数判断是否还有更多数据
            _hasMoreData = _messages.length < total;
          } else {
            _hasMoreData = false;
          }

          _isLoading = false;
        });
      }

      _refreshController.refreshCompleted();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _refreshController.refreshFailed();
        CustomSnackBar.show(context, message: '加载消息失败: $e');
      }
    }
  }

  void _onLoadMore() async {
    if (!_hasMoreData) {
      _refreshController.refreshCompleted();
      return;
    }

    await _loadMessages(initial: false);
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    final userMessage = Message.user(content: content);
    final pendingMessage = Message.pending(content: '正在思考...');

    setState(() {
      _messages.add(userMessage);
      _messages.add(pendingMessage);
      _isSending = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _sessionService.chat(widget.sessionId, content);

      if (mounted) {
        setState(() {
          final index = _messages.indexOf(pendingMessage);
          if (index != -1) {
            _messages[index] = Message(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              sessionId: widget.sessionId,
              role: 'model',
              content: response['content'] ?? '',
              isComplete: true,
              keywords: response['keywords'] != null
                  ? List<String>.from(response['keywords'])
                  : null,
            );
          }
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '发送消息失败: $e');
        setState(() {
          _messages.remove(pendingMessage);
          _isSending = false;
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _sessionService.clearHistory(widget.sessionId);

      if (mounted) {
        setState(() {
          _messages.clear();
          _isLoading = false;
        });
        CustomSnackBar.show(context, message: '历史记录已清除');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        CustomSnackBar.show(context, message: '清除失败: $e');
      }
    }
  }

  Future<void> _showClearHistoryDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '确认清除',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '确定要清除所有聊天记录吗？这个操作不可恢复。',
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

    if (confirmed == true) {
      await _clearHistory();
    }
  }

  Future<void> _undoLastRound() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _sessionService.undoLastRound(widget.sessionId);
      await _loadMessages();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomSnackBar.show(context, message: '已撤销最后一轮对话');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        CustomSnackBar.show(context, message: '撤销失败: $e');
      }
    }
  }

  Future<void> _showUndoRoundsDialog() async {
    int rounds = 1;
    final selectedRounds = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            '撤销多轮对话',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '请选择要撤销的对话轮数',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white),
                    onPressed:
                        rounds > 1 ? () => setState(() => rounds--) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$rounds',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () => setState(() => rounds++),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text(
                '取消',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(rounds),
              child: const Text(
                '确定',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedRounds != null) {
      await _undoRounds(selectedRounds);
    }
  }

  Future<void> _undoRounds(int rounds) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _sessionService.undoRounds(widget.sessionId, rounds);
      await _loadMessages();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomSnackBar.show(context, message: '已撤销 $rounds 轮对话');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        CustomSnackBar.show(context, message: '撤销失败: $e');
      }
    }
  }

  void _togglePanel() async {
    if (!mounted) return;

    if (!_showPanel) {
      setState(() {
        _showPanel = true;
        _isLoadingCustomFields = true;
      });

      try {
        final result = await _sessionService.getCustomFields(widget.sessionId);

        if (mounted) {
          setState(() {
            _customFields = result;
            _isLoadingCustomFields = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingCustomFields = false;
          });
          CustomSnackBar.show(context, message: '获取自定义字段失败: $e');
        }
      }
    } else {
      setState(() {
        _showPanel = false;
      });
    }
  }

  void _handleCustomFieldsUpdated(Map<String, dynamic> updatedFields) {
    setState(() {
      _customFields = updatedFields;
    });
  }

  void _handleRegexStylesChanged(List<Map<String, dynamic>> newStyles) {
    setState(() {
      _regexStyles = newStyles;
    });
    _settingsDao.saveRegexStyles(newStyles);
  }

  // 加载颜色设置
  Future<void> _loadColorSettings() async {
    setState(() {
      _userBubbleColor = _settingsDao.getUserBubbleColor();
      _aiBubbleColor = _settingsDao.getAiBubbleColor();
      _userTextColor = _settingsDao.getUserTextColor();
      _aiTextColor = _settingsDao.getAiTextColor();
    });
  }

  // 保存颜色设置
  Future<void> _saveColorSettings() async {
    await _settingsDao.saveColorSettings(
      userBubbleColor: _userBubbleColor,
      aiBubbleColor: _aiBubbleColor,
      userTextColor: _userTextColor,
      aiTextColor: _aiTextColor,
    );
  }

  // 更新用户气泡颜色
  void _updateUserBubbleColor(Color color) {
    setState(() {
      _userBubbleColor = color;
    });
    _saveColorSettings();
  }

  // 更新AI气泡颜色
  void _updateAiBubbleColor(Color color) {
    setState(() {
      _aiBubbleColor = color;
    });
    _saveColorSettings();
  }

  // 更新用户文字颜色
  void _updateUserTextColor(Color color) {
    setState(() {
      _userTextColor = color;
    });
    _saveColorSettings();
  }

  // 更新AI文字颜色
  void _updateAiTextColor(Color color) {
    setState(() {
      _aiTextColor = color;
    });
    _saveColorSettings();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 点击空白处关闭键盘
      onTap: () {
        // 取消当前文本输入框的焦点
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // 添加悬浮按钮
        floatingActionButton: _showScrollToBottom
            ? Padding(
                padding: const EdgeInsets.only(bottom: 65.0),
                child: Container(
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _scrollToBottom,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                '回到底部',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
        // 调整悬浮按钮位置
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: Stack(
          children: [
            // 背景图层
            if (_backgroundImage != null)
              Positioned.fill(
                child: Image(
                  image: _backgroundImage!,
                  fit: BoxFit.cover,
                ),
              ),

            // 主聊天内容
            Column(
              children: [
                AppBar(
                  title: Text(widget.sessionName),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _loadMessages(),
                    ),
                  ],
                ),
                Expanded(
                  child: SmartRefresher(
                    controller: _refreshController,
                    enablePullDown: true,
                    enablePullUp: false,
                    onRefresh: _onLoadMore,
                    header: const ClassicHeader(
                      idleText: '下拉加载更多',
                      refreshingText: '加载中...',
                      completeText: '加载完成',
                      failedText: '加载失败',
                      releaseText: '松开加载更多',
                      textStyle: TextStyle(color: Colors.white70),
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildMessageBubble(message),
                        );
                      },
                    ),
                  ),
                ),
                ChatInputField(
                  controller: _messageController,
                  isLoading: _isSending,
                  onSend: _sendMessage,
                  backgroundColor: Colors.black54,
                  textColor: Colors.white,
                  iconColor: Colors.white,
                  onPanelToggle: _togglePanel,
                  hintText: '发送一条消息...',
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ],
            ),

            // 自定义字段侧边栏（覆盖在主内容上）
            if (_showPanel)
              Positioned.fill(
                child: CustomFieldsPanel(
                  isLoading: _isLoadingCustomFields,
                  customFields: _customFields,
                  onClose: _togglePanel,
                  sessionId: widget.sessionId,
                  onFieldsUpdated: _handleCustomFieldsUpdated,
                  onUndoLastRound: _undoLastRound,
                  onUndoMultipleRounds: _showUndoRoundsDialog,
                  onClearHistory: _showClearHistoryDialog,
                  userBubbleColor: _userBubbleColor,
                  aiBubbleColor: _aiBubbleColor,
                  userTextColor: _userTextColor,
                  aiTextColor: _aiTextColor,
                  onUserBubbleColorChanged: _updateUserBubbleColor,
                  onAiBubbleColorChanged: _updateAiBubbleColor,
                  onUserTextColorChanged: _updateUserTextColor,
                  onAiTextColorChanged: _updateAiTextColor,
                  regexStyles: _regexStyles,
                  onRegexStylesChanged: _handleRegexStylesChanged,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Row(
      mainAxisAlignment:
          message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: message.isUser ? _userBubbleColor : _aiBubbleColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: message.content.isEmpty
                          ? const Text(
                              '正在思考...',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            )
                          : CustomMarkdown(
                              data: message.content,
                              baseStyle: TextStyle(
                                color: message.isUser
                                    ? _userTextColor
                                    : _aiTextColor,
                                fontSize: 16,
                              ),
                              codeBackgroundColor: message.isUser
                                  ? Colors.blue.shade800
                                  : Colors.grey.shade800,
                              blockquoteColor: message.isUser
                                  ? Colors.blue.shade300
                                  : Colors.grey.shade600,
                              regexStyles: _regexStyles,
                            ),
                    ),
                    if (!message.isComplete) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            message.isUser
                                ? Colors.white70
                                : Colors.blue.shade200,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // 显示关键词信息（仅对AI消息且有关键词时显示）
                if (!message.isUser &&
                    message.keywords != null &&
                    message.keywords!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showKeywordsDialog(message.keywords!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tag,
                            size: 12,
                            color: Colors.blue.shade200,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${message.keywords!.length}个关键词',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showKeywordsDialog(List<String> keywords) {
    // 先取消焦点，防止弹出输入法
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        // 确保点击对话框不会引起输入法弹出
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            '匹配的关键词',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: keywords
                    .map((keyword) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '#',
                                style: TextStyle(
                                    color: Colors.blue.shade300,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                keyword,
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      ),
    );
  }

  // 构建底部输入区域
  Widget _buildBottomInput() {
    return Container(
      child: Row(
        children: [
          // 面板按钮
          IconButton(
            icon: Icon(
              Icons.menu,
              color: _showPanel ? Colors.blue : Colors.grey,
            ),
            onPressed: _togglePanel,
            tooltip: '查看自定义字段',
          ),

          // 输入框
          ChatInputField(
            controller: _messageController,
            isLoading: _isSending,
            onSend: _sendMessage,
            backgroundColor: Colors.black54,
            textColor: Colors.white,
            iconColor: Colors.white,
            onPanelToggle: _togglePanel,
            hintText: '发送一条消息...',
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ],
      ),
    );
  }
}
