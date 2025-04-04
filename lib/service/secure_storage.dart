import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 安全存储服务
/// 使用混淆和分散存储的方式提高密钥安全性
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  static const String _keyStoragePrefix = 'secure_storage_';

  // 这些值用于混淆真实密钥
  static const List<String> _obfuscationKeys = [
    'XrT9kL2p',
    'Bw5EzMq7',
    'H8aJvQ4s',
    'P3nSdF6g',
    'Y7cWu1xZ',
    'G0mC5vA9',
    'Rj2lKb4N',
    'D6fOi3tU'
  ];

  factory SecureStorage() {
    return _instance;
  }

  SecureStorage._internal();

  /// 存储加密后的敏感信息
  Future<void> secureStore(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();

    // 将密钥分散存储，混淆处理
    List<String> parts = _splitAndObfuscate(value);

    // 存储每个部分，使用不同的键
    for (int i = 0; i < parts.length; i++) {
      await prefs.setString('${_keyStoragePrefix}${key}_part_$i', parts[i]);
    }

    // 存储部分数量
    await prefs.setInt('${_keyStoragePrefix}${key}_parts_count', parts.length);
  }

  /// 获取并重构敏感信息
  Future<String?> secureRetrieve(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 获取部分数量
      final count = prefs.getInt('${_keyStoragePrefix}${key}_parts_count');
      if (count == null) return null;

      // 重新组装各个部分
      List<String> parts = [];
      for (int i = 0; i < count; i++) {
        final part = prefs.getString('${_keyStoragePrefix}${key}_part_$i');
        if (part == null) return null;
        parts.add(part);
      }

      // 解除混淆，重组密钥
      return _deobfuscateAndJoin(parts);
    } catch (e) {
      print('安全存储检索失败: $e');
      return null;
    }
  }

  /// 初始化默认密钥（仅首次运行时）
  Future<void> initializeDefaultKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final isInitialized = prefs.getBool('secure_storage_initialized') ?? false;

    if (!isInitialized) {
      // 使用平台通道获取原生代码中的密钥（更安全）
      // 这里为了示例，我们仍然使用硬编码的值，但在实际开发中，
      // 可以考虑使用Flutter的MethodChannel从原生代码获取密钥
      const signatureKey = 'X0eeMF2T6YcKgP7ZqwB9SdL1jRn3VkHa5J8oUWxD4E';
      await secureStore('signature_key', signatureKey);

      // 标记为已初始化
      await prefs.setBool('secure_storage_initialized', true);
    }
  }

  /// 分割字符串并添加混淆
  List<String> _splitAndObfuscate(String value) {
    // 将字符串分成3-5个部分
    final random = DateTime.now().millisecondsSinceEpoch % 3;
    final parts = 3 + random; // 3到5个部分
    final partSize = (value.length / parts).ceil();

    List<String> obfuscatedParts = [];
    for (int i = 0; i < parts; i++) {
      final start = i * partSize;
      final end = (i + 1) * partSize;
      final actualEnd = end > value.length ? value.length : end;

      if (start < value.length) {
        String part = value.substring(start, actualEnd);

        // 添加混淆
        final obfuscationKey = _obfuscationKeys[i % _obfuscationKeys.length];
        final combined = '$part:$obfuscationKey';
        final obfuscated = base64Encode(utf8.encode(combined));

        obfuscatedParts.add(obfuscated);
      }
    }

    return obfuscatedParts;
  }

  /// 解除混淆并重组字符串
  String _deobfuscateAndJoin(List<String> obfuscatedParts) {
    List<String> parts = [];

    for (int i = 0; i < obfuscatedParts.length; i++) {
      final decoded = utf8.decode(base64Decode(obfuscatedParts[i]));
      final splitIndex = decoded.lastIndexOf(':');

      if (splitIndex != -1) {
        final part = decoded.substring(0, splitIndex);
        // 验证混淆键是否匹配
        final obfuscationKey = decoded.substring(splitIndex + 1);
        final expectedKey = _obfuscationKeys[i % _obfuscationKeys.length];

        if (obfuscationKey == expectedKey) {
          parts.add(part);
        } else {
          throw Exception('安全性校验失败');
        }
      }
    }

    return parts.join('');
  }
}
