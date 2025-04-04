import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/chat_history.dart';

class ChatHistoryDao {
  static const String _storagePrefix = 'chat_history_';
  final SharedPreferences _prefs;

  ChatHistoryDao(this._prefs);

  // 获取指定角色卡的对话历史
  Future<ChatHistory?> getHistory(String characterCode) async {
    final String? jsonString =
        _prefs.getString('$_storagePrefix$characterCode');
    if (jsonString == null) return null;

    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return ChatHistory.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  // 保存对话历史
  Future<bool> saveHistory(ChatHistory history) async {
    final String jsonString = jsonEncode(history.toJson());
    return await _prefs.setString(
      '$_storagePrefix${history.code}',
      jsonString,
    );
  }

  // 删除指定角色卡的对话历史
  Future<bool> deleteHistory(String characterCode) async {
    return await _prefs.remove('$_storagePrefix$characterCode');
  }

  // 获取所有对话历史的角色卡编码
  Future<List<String>> getAllHistoryCodes() async {
    final keys = _prefs.getKeys();
    return keys
        .where((key) => key.startsWith(_storagePrefix))
        .map((key) => key.substring(_storagePrefix.length))
        .toList();
  }

  // 删除所有对话历史
  Future<bool> deleteAllHistories() async {
    final keys = _prefs.getKeys();
    final historyKeys =
        keys.where((key) => key.startsWith(_storagePrefix)).toList();

    for (final key in historyKeys) {
      await _prefs.remove(key);
    }

    return true;
  }
}
