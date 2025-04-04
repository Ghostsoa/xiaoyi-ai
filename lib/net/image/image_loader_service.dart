import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../http_client.dart';

class ImageLoaderService {
  static final ImageLoaderService _instance = ImageLoaderService._internal();
  static const String _cacheKeyPrefix = 'image_cache_';
  static const String _cacheTimeKeyPrefix = 'image_cache_time_';
  static const String _cacheUrlListKey = 'image_cache_url_list';
  static const int _maxCacheSize = 150;

  // 添加内存缓存
  final Map<String, Image> _memoryCache = {};
  static const int _maxMemoryCacheSize = 100;

  late SharedPreferences _prefs;
  final _httpClient = HttpClient();
  bool _initialized = false;

  factory ImageLoaderService() {
    return _instance;
  }

  ImageLoaderService._internal();

  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // 从内存缓存中获取图片
  Image? _getFromMemoryCache(String url) {
    return _memoryCache[url];
  }

  // 将图片保存到内存缓存
  void _saveToMemoryCache(String url, Image image) {
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      // 移除最早添加的图片
      _memoryCache.remove(_memoryCache.keys.first);
    }
    _memoryCache[url] = image;
  }

  // 获取缓存的图片列表
  List<String> _getCachedUrls() {
    return _prefs.getStringList(_cacheUrlListKey) ?? [];
  }

  // 更新缓存的图片列表
  Future<void> _updateCachedUrls(List<String> urls) async {
    await _prefs.setStringList(_cacheUrlListKey, urls);
  }

  // 清理过期缓存
  Future<void> _cleanOldCache() async {
    final urls = _getCachedUrls();
    if (urls.length > _maxCacheSize) {
      // 按访问时间排序
      urls.sort((a, b) {
        final timeA = _prefs.getInt(_cacheTimeKeyPrefix + a) ?? 0;
        final timeB = _prefs.getInt(_cacheTimeKeyPrefix + b) ?? 0;
        return timeA.compareTo(timeB);
      });

      // 删除最旧的缓存，直到数量符合限制
      final urlsToRemove = urls.sublist(0, urls.length - _maxCacheSize);
      for (final url in urlsToRemove) {
        await _prefs.remove(_cacheKeyPrefix + url);
        await _prefs.remove(_cacheTimeKeyPrefix + url);
      }

      // 更新URL列表
      urls.removeRange(0, urls.length - _maxCacheSize);
      await _updateCachedUrls(urls);
    }
  }

  // 更新缓存访问时间
  Future<void> _updateCacheAccessTime(String url) async {
    await _prefs.setInt(
        _cacheTimeKeyPrefix + url, DateTime.now().millisecondsSinceEpoch);
  }

  // 从缓存中获取图片
  String? _getFromCache(String url) {
    return _prefs.getString(_cacheKeyPrefix + url);
  }

  // 将图片保存到缓存
  Future<void> _saveToCache(String url, String base64Image) async {
    final urls = _getCachedUrls();
    if (!urls.contains(url)) {
      urls.add(url);
      await _updateCachedUrls(urls);
    }
    await _prefs.setString(_cacheKeyPrefix + url, base64Image);
    await _updateCacheAccessTime(url);
    await _cleanOldCache();
  }

  String _getErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final responseData = e.response!.data;
      return responseData['error'] ?? '请求失败';
    }
    return e.toString();
  }

  // 加载图片
  Future<Image> loadImage(String url) async {
    if (!_initialized) {
      await init();
    }

    try {
      // 先检查内存缓存
      final memoryCachedImage = _getFromMemoryCache(url);
      if (memoryCachedImage != null) {
        return memoryCachedImage;
      }

      // 再检查持久化缓存
      final cachedImage = _getFromCache(url);
      if (cachedImage != null) {
        // 更新访问时间
        await _updateCacheAccessTime(url);
        final image = Image.memory(
          base64Decode(cachedImage),
          fit: BoxFit.cover,
        );
        // 保存到内存缓存
        _saveToMemoryCache(url, image);
        return image;
      }

      // 如果没有缓存，从网络加载
      final response = await _httpClient.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      final imageBytes = Uint8List.fromList(response.data as List<int>);
      // 将图片数据转换为base64
      final base64Image = base64Encode(imageBytes);

      // 保存到缓存
      await _saveToCache(url, base64Image);

      final image = Image.memory(
        imageBytes,
        fit: BoxFit.cover,
      );
      // 保存到内存缓存
      _saveToMemoryCache(url, image);
      return image;
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // 清除所有缓存
  Future<void> clearCache() async {
    if (!_initialized) {
      await init();
    }

    // 清除内存缓存
    _memoryCache.clear();

    // 清除持久化缓存
    final urls = _getCachedUrls();
    for (final url in urls) {
      await _prefs.remove(_cacheKeyPrefix + url);
      await _prefs.remove(_cacheTimeKeyPrefix + url);
    }
    await _prefs.remove(_cacheUrlListKey);
  }
}
