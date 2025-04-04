class ChatMessage {
  final bool isUser;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.isUser,
    required this.content,
    required this.timestamp,
  });
}
