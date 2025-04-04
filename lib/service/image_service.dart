import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageService {
  // 缓存已解码的图片
  static final Map<String, Image> _imageCache = {};
  static const int _maxCacheSize = 20; // 最大缓存数量

  // 处理头像图片 - 裁切为正方形
  static Future<String> processAvatarImage(String imagePath) async {
    final File imageFile = File(imagePath);
    final img.Image? image = img.decodeImage(await imageFile.readAsBytes());

    if (image == null) return '';

    // 裁切为正方形
    final int size = image.width < image.height ? image.width : image.height;
    final int x = (image.width - size) ~/ 2;
    final int y = (image.height - size) ~/ 2;
    final img.Image croppedImage =
        img.copyCrop(image, x: x, y: y, width: size, height: size);

    // 调整大小为120x120，使用高质量调整算法
    final img.Image resizedImage = img.copyResize(
      croppedImage,
      width: 120,
      height: 120,
      interpolation: img.Interpolation.cubic,
    );

    // 转换为base64，不压缩质量
    final List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 100);
    return base64Encode(compressedBytes);
  }

  // 处理封面图片 - 裁切为正方形
  static Future<String> processCoverImage(String imagePath) async {
    final File imageFile = File(imagePath);
    final img.Image? image = img.decodeImage(await imageFile.readAsBytes());

    if (image == null) return '';

    // 裁切为正方形
    final int size = image.width < image.height ? image.width : image.height;
    final int x = (image.width - size) ~/ 2;
    final int y = (image.height - size) ~/ 2;
    final img.Image croppedImage =
        img.copyCrop(image, x: x, y: y, width: size, height: size);

    // 调整大小为200x200
    final img.Image resizedImage =
        img.copyResize(croppedImage, width: 200, height: 200);

    // 转换为base64，不压缩质量
    final List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 100);
    return base64Encode(compressedBytes);
  }

  // 处理背景图片 - 只做尺寸压缩，不压缩质量
  static Future<String> processBackgroundImage(String imagePath) async {
    final File imageFile = File(imagePath);
    final img.Image? image = img.decodeImage(await imageFile.readAsBytes());

    if (image == null) return '';

    // 计算压缩后的尺寸，保持宽高比
    double ratio = image.width / image.height;
    int targetWidth = image.width;
    int targetHeight = image.height;

    // 如果图片太大，按比例缩小
    if (image.width > 1920 || image.height > 1080) {
      if (ratio > 16 / 9) {
        targetWidth = 1920;
        targetHeight = (1920 / ratio).round();
      } else {
        targetHeight = 1080;
        targetWidth = (1080 * ratio).round();
      }
    }

    // 调整大小，保持宽高比
    final img.Image resizedImage = img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );

    // 转换为base64，使用100%质量以不影响图片质量
    final List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 100);
    return base64Encode(compressedBytes);
  }

  // 从base64加载图片Widget，带缓存
  static Widget imageFromBase64String(
    String base64String, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    try {
      // 检查缓存
      if (_imageCache.containsKey(base64String)) {
        return SizedBox(
          width: width,
          height: height,
          child: _imageCache[base64String]!,
        );
      }

      // 解码图片
      final image = Image.memory(
        base64Decode(base64String),
        width: width,
        height: height,
        fit: fit,
        cacheWidth: width?.toInt(),
        cacheHeight: height?.toInt(),
        filterQuality: FilterQuality.high,
      );

      // 添加到缓存
      if (_imageCache.length >= _maxCacheSize) {
        _imageCache.remove(_imageCache.keys.first);
      }
      _imageCache[base64String] = image;

      return image;
    } catch (e) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Icon(Icons.broken_image, color: Colors.grey[600]),
      );
    }
  }
}
