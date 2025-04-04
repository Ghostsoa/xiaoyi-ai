import '../dao/chat_list_dao.dart';
import '../model/chat_list_item.dart';
import '../model/character_card.dart';
import '../model/chat_message.dart';
import 'dart:convert';

class ChatListService {
  final ChatListDao _dao;

  ChatListService(this._dao);

  // 获取所有消息列表项
  Future<List<ChatListItem>> getAllItems() {
    return _dao.getAllItems();
  }

  // 移除内容中的标签
  String _removeContentTags(String content) {
    return content.replaceAllMapped(
      RegExp(r'<(scene|action|thought|s)>(.*?)</\1>'),
      (Match m) => m.group(2) ?? '',
    );
  }

  // 处理消息内容，提取纯文本
  String _processMessageContent(String content) {
    try {
      // 尝试解析为JSON
      final jsonData = json.decode(content) as Map<String, dynamic>;
      if (jsonData['content'] != null) {
        String displayContent = jsonData['content'] as String;
        // 移除标签
        return _removeContentTags(displayContent);
      }
      // 如果没有content字段，返回原始内容
      return _removeContentTags(content);
    } catch (e) {
      // 如果不是JSON格式，直接移除标签
      return _removeContentTags(content);
    }
  }

  // 更新消息列表项
  Future<bool> updateItem(
    CharacterCard character,
    ChatMessage message,
  ) async {
    final processedContent = _processMessageContent(message.content);

    final item = ChatListItem(
      characterCode: character.code,
      title: character.title,
      avatarBase64: character.coverImageBase64,
      lastMessage: processedContent,
      lastMessageTime: message.timestamp,
      isGroup: character.chatType == ChatType.group,
    );
    return await _dao.updateItem(item);
  }

  // 删除消息列表项
  Future<bool> deleteItem(String characterCode) {
    return _dao.deleteItem(characterCode);
  }

  // 清空消息列表
  Future<bool> clear() {
    return _dao.clear();
  }
}
