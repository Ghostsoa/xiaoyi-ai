import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../model/character_card.dart';

/// 角色卡打包工具
/// 用于将角色卡打包成二进制数据或从二进制数据解包成角色卡
/// 主要用于角色卡的导入导出、上传下载等操作
class CharacterCardPacker {
  /// 将角色卡打包成二进制数据
  /// 返回压缩后的二进制数据
  static Uint8List packCard(CharacterCard card) {
    try {
      // 1. 将角色卡转换为 JSON
      final jsonData = card.toJson();
      final jsonString = json.encode(jsonData);
      final jsonBytes = utf8.encode(jsonString);

      // 2. 压缩数据
      final gzipData = GZipEncoder().encode(jsonBytes);
      return Uint8List.fromList(gzipData);
    } catch (e) {
      throw Exception('打包角色卡失败: $e');
    }
  }

  /// 从二进制数据解包成角色卡
  /// [data] 压缩的二进制数据
  /// 返回解析后的角色卡对象
  static CharacterCard unpackCard(Uint8List data) {
    try {
      // 1. 解压数据
      final decompressed = GZipDecoder().decodeBytes(data);

      // 2. 解析 JSON
      final jsonString = utf8.decode(decompressed);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // 3. 转换为角色卡对象
      return CharacterCard.fromJson(jsonData);
    } catch (e) {
      throw Exception('解包角色卡失败: $e');
    }
  }

  /// 将角色卡打包成 Base64 字符串
  /// 用于在不支持二进制传输的场景
  static String packToBase64(CharacterCard card) {
    final binaryData = packCard(card);
    return base64Encode(binaryData);
  }

  /// 从 Base64 字符串解包成角色卡
  /// [base64String] Base64 编码的字符串
  static CharacterCard unpackFromBase64(String base64String) {
    final binaryData = base64Decode(base64String);
    return unpackCard(binaryData);
  }

  /// 将 Base64 图片转换为二进制数据
  /// [base64Image] Base64 编码的图片数据（包含 data:image/jpeg;base64, 前缀）
  /// 返回图片的二进制数据
  static Uint8List base64ToImageBytes(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) {
      throw Exception('图片数据为空');
    }

    try {
      // 移除 Base64 图片数据的前缀（如果有）
      String pureBase64 = base64Image;
      if (base64Image.contains(',')) {
        pureBase64 = base64Image.split(',')[1];
      }

      return base64Decode(pureBase64);
    } catch (e) {
      throw Exception('转换图片失败: $e');
    }
  }
}
