import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/character_card.dart';

class CharacterCardDao {
  static const String _storageKey = 'character_cards';
  final SharedPreferences _prefs;

  CharacterCardDao(this._prefs);

  // 获取所有角色卡
  Future<List<CharacterCard>> getAllCards() async {
    final String? jsonString = _prefs.getString(_storageKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => CharacterCard.fromJson(json)).toList();
  }

  // 保存角色卡
  Future<bool> saveCard(CharacterCard card) async {
    final cards = await getAllCards();
    final index = cards.indexWhere((c) => c.code == card.code);

    if (index >= 0) {
      cards[index] = card; // 更新现有卡片
    } else {
      cards.add(card); // 添加新卡片
    }

    final jsonString = json.encode(cards.map((c) => c.toJson()).toList());
    return await _prefs.setString(_storageKey, jsonString);
  }

  // 删除角色卡
  Future<bool> deleteCard(String code) async {
    final cards = await getAllCards();
    cards.removeWhere((card) => card.code == code);

    final jsonString = json.encode(cards.map((c) => c.toJson()).toList());
    return await _prefs.setString(_storageKey, jsonString);
  }

  // 根据编码获取角色卡
  Future<CharacterCard?> getCardByCode(String code) async {
    final cards = await getAllCards();
    try {
      return cards.firstWhere((card) => card.code == code);
    } catch (e) {
      return null;
    }
  }

  // 获取所有本地角色卡的编码列表
  Future<List<String>> getAllCardCodes() async {
    final cards = await getAllCards();
    return cards.map((card) => card.code).toList();
  }
}
