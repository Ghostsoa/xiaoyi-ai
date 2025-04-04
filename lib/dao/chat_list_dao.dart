import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/chat_list_item.dart';

class ChatListDao {
  static const String _storageKey = 'chat_list';
  final SharedPreferences _prefs;

  ChatListDao(this._prefs);

  // 获取所有消息列表项
  Future<List<ChatListItem>> getAllItems() async {
    final String? jsonString = _prefs.getString(_storageKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => ChatListItem.fromJson(json)).toList();
  }

  // 更新消息列表项
  Future<bool> updateItem(ChatListItem item) async {
    final items = await getAllItems();
    final index =
        items.indexWhere((i) => i.characterCode == item.characterCode);

    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }

    // 按最后消息时间排序
    items.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    final jsonString = json.encode(items.map((i) => i.toJson()).toList());
    return await _prefs.setString(_storageKey, jsonString);
  }

  // 删除消息列表项
  Future<bool> deleteItem(String characterCode) async {
    final items = await getAllItems();
    items.removeWhere((item) => item.characterCode == characterCode);

    final jsonString = json.encode(items.map((i) => i.toJson()).toList());
    return await _prefs.setString(_storageKey, jsonString);
  }

  // 清空消息列表
  Future<bool> clear() async {
    return await _prefs.remove(_storageKey);
  }
}
