import '../dao/chat_history_dao.dart';
import '../model/chat_history.dart';
import 'package:get_storage/get_storage.dart';

class ChatHistoryService {
  final ChatHistoryDao _dao;
  final _storage = GetStorage();
  static const _historyKey = 'chat_history';
  static const _currentSlotKey = 'current_slot';
  static const maxSlots = 5; // 最大存档数

  ChatHistoryService(this._dao);

  // 获取当前存档槽位
  Future<int> getCurrentSlot(String code) async {
    final key = '${_currentSlotKey}_$code';
    return _storage.read(key) ?? 1;
  }

  // 设置当前存档槽位
  Future<void> setCurrentSlot(String code, int slot) async {
    final key = '${_currentSlotKey}_$code';
    await _storage.write(key, slot);
  }

  // 获取指定存档的历史记录
  Future<ChatHistory> getHistory(String code, {int? slot}) async {
    slot ??= await getCurrentSlot(code);
    final key = '${_historyKey}_${code}_$slot';
    final data = _storage.read(key);
    if (data != null) {
      return ChatHistory.fromJson(data);
    }
    return ChatHistory(code: code, slot: slot);
  }

  // 保存历史记录到指定存档
  Future<void> saveHistory(ChatHistory history) async {
    final key = '${_historyKey}_${history.code}_${history.slot}';
    await _storage.write(key, history.toJson());
  }

  // 清除指定存档的历史记录
  Future<void> clearHistory(String code, {int? slot}) async {
    slot ??= await getCurrentSlot(code);
    final key = '${_historyKey}_${code}_$slot';
    await _storage.remove(key);
  }

  // 获取所有存档的最后一条消息
  Future<List<Map<String, dynamic>>> getSlotPreviews(String code) async {
    final previews = <Map<String, dynamic>>[];
    for (int i = 1; i <= maxSlots; i++) {
      final history = await getHistory(code, slot: i);
      final lastMessage =
          history.messages.isNotEmpty ? history.messages.last : null;
      previews.add({
        'slot': i,
        'lastMessage': lastMessage,
        'messageCount': history.messages.length,
      });
    }
    return previews;
  }

  // 复制存档
  Future<void> copySlot(String code, int fromSlot, int toSlot) async {
    final history = await getHistory(code, slot: fromSlot);
    final newHistory = history.copyWithSlot(toSlot);
    await saveHistory(newHistory);
  }

  // 删除存档
  Future<void> deleteSlot(String code, int slot) async {
    await clearHistory(code, slot: slot);
  }

  // 获取所有对话历史的角色卡编码
  Future<List<String>> getAllHistoryCharacterCodes() {
    return _dao.getAllHistoryCodes();
  }

  // 清除所有对话历史
  Future<bool> clearAllHistories() {
    return _dao.deleteAllHistories();
  }
}
