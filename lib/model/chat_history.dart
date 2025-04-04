class ChatHistory {
  final String code;
  final List<Map<String, String>> messages;
  final int slot; // 存档槽位

  ChatHistory({
    required this.code,
    List<Map<String, String>>? messages,
    this.slot = 1, // 默认使用第一个存档槽
  }) : messages = messages ?? [];

  // 添加新消息，并根据上下文限制进行处理
  void addMessage(bool isUser, String content,
      {bool enableContextLimit = false, int contextTurns = 10}) {
    messages.add({
      'role': isUser ? 'user' : 'assistant',
      'content': content,
    });

    // 如果启用了上下文限制，保持对话轮数在限制范围内
    if (enableContextLimit && messages.length > contextTurns * 2) {
      // 每轮对话包含用户和AI各一条消息，所以乘以2
      // 从开头移除超出限制的消息
      messages.removeRange(0, 2);
    }
  }

  // 转换为JSON
  Map<String, dynamic> toJson() => {
        'code': code,
        'messages': messages,
        'slot': slot,
      };

  // 从JSON创建实例
  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    return ChatHistory(
      code: json['code'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => Map<String, String>.from(e as Map))
          .toList(),
      slot: json['slot'] as int? ?? 1,
    );
  }

  // 清空对话历史
  void clear() {
    messages.clear();
  }

  // 创建新存档
  ChatHistory copyWithSlot(int newSlot) {
    return ChatHistory(
      code: code,
      messages: List.from(messages),
      slot: newSlot,
    );
  }
}
