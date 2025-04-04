class ChatListItem {
  final String characterCode; // 角色卡编码
  final String title; // 角色名称
  final String? avatarBase64; // 头像
  final String lastMessage; // 最后一条消息
  final DateTime lastMessageTime; // 最后消息时间
  final bool isGroup; // 是否群聊

  ChatListItem({
    required this.characterCode,
    required this.title,
    this.avatarBase64,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.isGroup,
  });

  Map<String, dynamic> toJson() => {
        'characterCode': characterCode,
        'title': title,
        'avatarBase64': avatarBase64,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime.toIso8601String(),
        'isGroup': isGroup,
      };

  factory ChatListItem.fromJson(Map<String, dynamic> json) => ChatListItem(
        characterCode: json['characterCode'] as String,
        title: json['title'] as String,
        avatarBase64: json['avatarBase64'] as String?,
        lastMessage: json['lastMessage'] as String,
        lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
        isGroup: json['isGroup'] as bool,
      );
}
