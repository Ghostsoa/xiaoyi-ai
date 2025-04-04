import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'secure_storage.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  static const String _deviceIdKey = 'device_unique_id';
  static const String _signatureKeyId = 'signature_key';

  String? _deviceCode;
  String? _signatureKey;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final SecureStorage _secureStorage = SecureStorage();

  factory DeviceService() {
    return _instance;
  }

  DeviceService._internal() {
    _initializeSecureStorage();
  }

  // 初始化安全存储
  Future<void> _initializeSecureStorage() async {
    await _secureStorage.initializeDefaultKeys();
  }

  // 获取签名密钥
  Future<String> _getSignatureKey() async {
    if (_signatureKey != null) {
      return _signatureKey!;
    }

    final key = await _secureStorage.secureRetrieve(_signatureKeyId);
    if (key == null) {
      throw Exception('签名密钥获取失败，请重新初始化应用');
    }

    _signatureKey = key;
    return key;
  }

  // 获取或生成设备唯一标识符
  Future<String> getDeviceCode() async {
    if (_deviceCode != null) {
      return _deviceCode!;
    }

    // 先尝试从本地存储获取
    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString(_deviceIdKey);

    if (storedId != null && storedId.isNotEmpty) {
      _deviceCode = storedId;
      return storedId;
    }

    // 如果本地没有，则生成新的设备标识符
    String deviceId = await _generateDeviceId();

    // 存储到本地
    await prefs.setString(_deviceIdKey, deviceId);
    _deviceCode = deviceId;

    return deviceId;
  }

  // 生成设备唯一标识符
  Future<String> _generateDeviceId() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? _generateUUID();
      }
    } catch (e) {
      print('获取设备信息失败: $e');
    }

    // 如果无法获取系统级别的标识符，则生成一个UUID
    return _generateUUID();
  }

  // 生成一个UUID
  String _generateUUID() {
    Random random = Random.secure();
    var values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // version 4
    values[8] = (values[8] & 0x3f) | 0x80; // variant is 10

    var hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  // 生成随机Nonce
  String generateNonce(int length) {
    const charset =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  // 生成HMAC-SHA256签名
  Future<String> generateSignature(String deviceCode, String nonce) async {
    final key = utf8.encode(await _getSignatureKey());
    final message = utf8.encode('$deviceCode:$nonce');
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(message);
    return digest.toString();
  }

  // 获取所有请求头所需的设备信息
  Future<Map<String, String>> getDeviceHeaders() async {
    String deviceCode = await getDeviceCode();
    String nonce = generateNonce(16);
    String signature = await generateSignature(deviceCode, nonce);

    return {
      'X-Device-Code': deviceCode,
      'X-Nonce': nonce,
      'X-Signature': signature,
    };
  }
}
