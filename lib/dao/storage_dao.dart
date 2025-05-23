import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class StorageDao {
  static const String _keyToken = 'token';
  static const String _keyUser = 'user';
  static const String _keyEmail = 'email';
  static const String _keyPassword = 'password';
  static const String _keyCredentials = 'credentials';
  static const String _primaryColorKey = 'primary_color';
  static const String _secondaryColorKey = 'secondary_color';
  static const String _apiNodeKey = 'api_node';
  static const String _defaultNode = 'hk.xiaoyi.ink';
  static const String _cdnNode = 'hk.xiaoyi.live';

  static final StorageDao _instance = StorageDao._internal();
  late SharedPreferences _prefs;

  factory StorageDao() {
    return _instance;
  }

  StorageDao._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token相关
  Future<void> saveToken(String token) async {
    await _prefs.setString(_keyToken, token);
  }

  String? getToken() {
    return _prefs.getString(_keyToken);
  }

  // 用户信息相关
  Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs.setString(_keyUser, jsonEncode(user));
  }

  Map<String, dynamic>? getUser() {
    final userStr = _prefs.getString(_keyUser);
    if (userStr != null) {
      return jsonDecode(userStr) as Map<String, dynamic>;
    }
    return null;
  }

  // 登录凭证相关
  Future<void> saveCredentials(String email, String password) async {
    await _prefs.setString(_keyEmail, email);
    await _prefs.setString(_keyPassword, password);
  }

  Map<String, String?> getCredentials() {
    return {
      'email': _prefs.getString(_keyEmail),
      'password': _prefs.getString(_keyPassword),
    };
  }

  // 清除登录凭证（只清除密码，保留账号）
  Future<void> clearCredentials() async {
    await _prefs.remove(_keyPassword);
  }

  // 清除所有数据
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  // 只清除用户数据和Token，保留登录凭证
  Future<void> clearUserData() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUser);
  }

  Future<void> saveThemeColors(Color primary, Color secondary) async {
    await _prefs.setInt(_primaryColorKey, primary.value);
    await _prefs.setInt(_secondaryColorKey, secondary.value);
  }

  Future<(Color, Color)> getThemeColors() async {
    if (!_prefs.containsKey(_primaryColorKey) ||
        !_prefs.containsKey(_secondaryColorKey)) {
      // 如果没有保存过主题色，返回默认颜色
      return (
        const Color(0xFF6C72CB), // 优雅的紫蓝色
        const Color(0xFF88A0BF), // 柔和的灰蓝色
      );
    }
    final primaryValue = _prefs.getInt(_primaryColorKey)!;
    final secondaryValue = _prefs.getInt(_secondaryColorKey)!;
    return (Color(primaryValue), Color(secondaryValue));
  }

  // 保存布尔值
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  // 获取布尔值
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // API节点相关
  Future<void> saveApiNode(String node) async {
    await _prefs.setString(_apiNodeKey, node);
  }

  String getApiNode() {
    return _prefs.getString(_apiNodeKey) ?? _defaultNode;
  }

  // 获取默认节点
  String getDefaultNode() {
    return _defaultNode;
  }

  // 获取CDN节点
  String getCdnNode() {
    return _cdnNode;
  }

  // 获取当前用户ID
  String? getUserId() {
    final userData = getUser();
    if (userData == null) {
      print('StorageDao.getUserId: 用户数据为空');
      return null;
    }

    final user = userData['user'] as Map<String, dynamic>?;
    if (user == null) {
      print('StorageDao.getUserId: user字段为空, userData = $userData');
      return null;
    }

    final id = user['id']?.toString();
    if (id == null) {
      print('StorageDao.getUserId: id字段为空, user = $user');
      return null;
    }

    print('StorageDao.getUserId: 成功获取用户ID = $id');
    return id;
  }
}
