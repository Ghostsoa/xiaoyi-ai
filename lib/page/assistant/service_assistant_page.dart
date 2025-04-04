import 'package:flutter/material.dart';
import '../../components/custom_snack_bar.dart';
import '../../net/http_client.dart';

class ServiceAssistantPage extends StatefulWidget {
  const ServiceAssistantPage({super.key});

  @override
  State<ServiceAssistantPage> createState() => _ServiceAssistantPageState();
}

class _ServiceAssistantPageState extends State<ServiceAssistantPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final _httpClient = HttpClient();

  @override
  void initState() {
    super.initState();
    // 添加欢迎消息
    _addSystemMessage(
      '你好！我是小懿智能客服助手，很高兴为你提供帮助。你可以向我咨询有关小懿的使用方法、功能介绍、账号问题等。请问有什么可以帮到你的吗？',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _handleSubmit() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();

    // 添加用户消息到UI中，但并不清除之前的消息
    setState(() {
      // 添加用户消息
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isLoading = true;
    });

    // 滚动到底部
    _scrollToBottom();

    try {
      // 调用客服API - 每次都作为单独对话处理，不传递历史消息
      final response = await _httpClient
          .post('/chat/customer', data: {"input": userMessage});

      if (response.data['code'] == 200) {
        setState(() {
          _messages.add(ChatMessage(
            text: response.data['data']['response'],
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      } else {
        // 显示错误消息
        setState(() {
          _messages.add(ChatMessage(
            text: "抱歉，我遇到了一些问题，无法回答您的问题。错误信息：${response.data['message']}",
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });

        if (mounted) {
          CustomSnackBar.show(context,
              message: "客服对话失败: ${response.data['message']}");
        }
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "抱歉，我遇到了一些网络问题，请稍后再试。",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });

      if (mounted) {
        CustomSnackBar.show(context, message: "请求失败: $e");
      }
    }

    // 滚动到底部
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Row(
          children: [
            Icon(Icons.support_agent, size: 24),
            SizedBox(width: 8),
            Text('智能客服', style: TextStyle(fontSize: 18)),
          ],
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            // 消息列表
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    return _buildMessage(_messages[index]);
                  } else {
                    // 显示加载指示器
                    return _buildLoadingIndicator();
                  }
                },
              ),
            ),

            // 底部输入框
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // 输入框
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: '请输入问题...',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _handleSubmit(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 发送按钮
                  Material(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _handleSubmit,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).primaryColor.withOpacity(0.8)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '正在回复...',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
