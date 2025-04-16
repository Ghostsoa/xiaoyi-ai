import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SettingsDao {
  static const String _userBubbleColorKey = 'user_bubble_color';
  static const String _aiBubbleColorKey = 'ai_bubble_color';
  static const String _userTextColorKey = 'user_text_color';
  static const String _aiTextColorKey = 'ai_text_color';
  static const String _regexStylesKey = 'regex_styles';

  // 默认的正则表达式样式配置
  static const List<Map<String, dynamic>> defaultRegexStyles = [
    {
      'name': '中文引号',
      'regex': '[“”]([^“”]+)[“”]|[‘’]([^‘’]+)[‘’]',
      'color': 0xFFFFB74D, // 橙色
      'isBold': true,
      'isItalic': false,
    },
    {
      'name': '重点标记',
      'regex': '「([^」]+)」',
      'color': 0xFF4CAF50, // 绿色
      'isBold': true,
      'isItalic': false,
    },
  ];

  final SharedPreferences _prefs;

  SettingsDao._(this._prefs);

  static Future<SettingsDao> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsDao._(prefs);
  }

  // 保存颜色
  Future<void> saveColor(String key, Color color) async {
    await _prefs.setInt(key, color.value);
  }

  // 获取颜色
  Color getColor(String key, Color defaultColor) {
    final value = _prefs.getInt(key);
    return value != null ? Color(value) : defaultColor;
  }

  // 保存用户气泡颜色
  Future<void> saveUserBubbleColor(Color color) async {
    await saveColor(_userBubbleColorKey, color);
  }

  // 保存AI气泡颜色
  Future<void> saveAiBubbleColor(Color color) async {
    await saveColor(_aiBubbleColorKey, color);
  }

  // 保存用户文字颜色
  Future<void> saveUserTextColor(Color color) async {
    await saveColor(_userTextColorKey, color);
  }

  // 保存AI文字颜色
  Future<void> saveAiTextColor(Color color) async {
    await saveColor(_aiTextColorKey, color);
  }

  // 获取用户气泡颜色
  Color getUserBubbleColor() {
    return getColor(_userBubbleColorKey, Colors.blue.shade600);
  }

  // 获取AI气泡颜色
  Color getAiBubbleColor() {
    return getColor(_aiBubbleColorKey, Colors.black87);
  }

  // 获取用户文字颜色
  Color getUserTextColor() {
    return getColor(_userTextColorKey, Colors.white);
  }

  // 获取AI文字颜色
  Color getAiTextColor() {
    return getColor(_aiTextColorKey, Colors.white);
  }

  // 保存所有颜色设置
  Future<void> saveColorSettings({
    required Color userBubbleColor,
    required Color aiBubbleColor,
    required Color userTextColor,
    required Color aiTextColor,
  }) async {
    await Future.wait([
      saveUserBubbleColor(userBubbleColor),
      saveAiBubbleColor(aiBubbleColor),
      saveUserTextColor(userTextColor),
      saveAiTextColor(aiTextColor),
    ]);
  }

  // 保存正则表达式样式配置
  Future<void> saveRegexStyles(List<Map<String, dynamic>> styles) async {
    final jsonStr = jsonEncode(styles);
    await _prefs.setString(_regexStylesKey, jsonStr);
  }

  // 获取正则表达式样式配置
  List<Map<String, dynamic>> getRegexStyles() {
    final jsonStr = _prefs.getString(_regexStylesKey);
    if (jsonStr == null) {
      return List.from(defaultRegexStyles);
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return List.from(defaultRegexStyles);
    }
  }
}
