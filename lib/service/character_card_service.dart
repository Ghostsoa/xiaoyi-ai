import 'package:flutter/material.dart';
import '../dao/character_card_dao.dart';
import '../model/character_card.dart';
import '../dao/storage_dao.dart';

class CharacterCardService {
  final CharacterCardDao _dao;
  final String _userId; // 用户ID，用于生成角色卡编码

  CharacterCardService(this._dao, this._userId);

  // 创建新角色卡
  Future<CharacterCard> createCard({
    required String title,
    required String description,
    required List<String> tags,
    required String setting,
    required String userSetting,
    required ChatType chatType,
    StatusBarType statusBarType = StatusBarType.none,
    String? statusBar,
    String? coverImageBase64,
    String? backgroundImageBase64,
    required String modelName,
    required ModelParameters modelParams,
    required List<GroupCharacter> groupCharacters,
    String? openingMessage,
    Color aiBubbleColor = const Color(0xFFFFFFFF),
    Color aiTextColor = const Color(0xFF000000),
    Color userBubbleColor = const Color(0xFF000000),
    Color userTextColor = const Color(0xFFFFFFFF),
    double backgroundOpacity = 0.0,
    bool hideSettings = false,
  }) async {
    // 获取当前登录用户的ID
    final storageDao = StorageDao();
    final currentUserId = storageDao.getUserId();

    // 如果获取不到用户ID，则抛出异常
    if (currentUserId == null) {
      throw Exception('创建角色卡失败：用户未登录或无法获取用户ID');
    }

    final code =
        CharacterCard.generateCode(title, currentUserId, DateTime.now());

    final card = CharacterCard(
      code: code,
      title: title,
      description: description,
      tags: tags,
      setting: setting,
      userSetting: userSetting,
      chatType: chatType,
      statusBarType: statusBarType,
      statusBar: statusBar,
      coverImageBase64: coverImageBase64,
      backgroundImageBase64: backgroundImageBase64,
      modelName: modelName,
      modelParams: modelParams,
      groupCharacters: groupCharacters,
      aiBubbleColor: aiBubbleColor,
      aiTextColor: aiTextColor,
      userBubbleColor: userBubbleColor,
      userTextColor: userTextColor,
      backgroundOpacity: backgroundOpacity,
      openingMessage: chatType != ChatType.group ? openingMessage : null,
      authorId: currentUserId,
      hideSettings: hideSettings,
    );

    await _dao.saveCard(card);
    return card;
  }

  // 更新角色卡
  Future<bool> updateCard(CharacterCard card) {
    return _dao.saveCard(card);
  }

  // 删除角色卡
  Future<bool> deleteCard(String code) {
    return _dao.deleteCard(code);
  }

  // 获取所有角色卡
  Future<List<CharacterCard>> getAllCards() {
    return _dao.getAllCards();
  }

  // 根据编码获取角色卡
  Future<CharacterCard?> getCardByCode(String code) {
    return _dao.getCardByCode(code);
  }

  // 获取所有本地角色卡的编码列表
  Future<List<String>> getAllCardCodes() {
    return _dao.getAllCardCodes();
  }
}
