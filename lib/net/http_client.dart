import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../dao/storage_dao.dart';
import '../components/custom_snack_bar.dart';

class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  late Dio _dio;
  final _storageDao = StorageDao();
  static BuildContext? _context;
  String _appVersion = '1.0.0'; // 默认版本号
  bool _isInitialized = false;

  // 设置全局 context
  static void setContext(BuildContext context) {
    _context = context;
  }

  factory HttpClient() {
    return _instance;
  }

  // 初始化版本信息
  Future<void> _initVersion() async {
    if (_isInitialized) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      _isInitialized = true;
    } catch (e) {
      print('获取应用版本失败: $e');
      _isInitialized = true; // 即使失败也标记为已初始化，使用默认版本号
    }
  }

  HttpClient._internal() {
    _setupDio();
  }

  void _setupDio() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://xy.xiaoyi.live/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      validateStatus: (status) {
        return status != null && status < 500;
      },
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 配置自定义的HttpClientAdapter
    (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };

    // 添加拦截器
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));

    // 添加Token和版本拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 确保版本信息已初始化
        await _initVersion();

        // 获取本地存储的token
        final token = _storageDao.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // 添加版本号到请求头
        options.headers['X-App-Version'] = _appVersion;
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // 检查响应中是否包含token失效的错误
        if (response.data is Map && response.data['error'] == 'token已失效') {
          _storageDao.clearUserData();
          if (_context != null && _context!.mounted) {
            CustomSnackBar.show(
              _context!,
              message: 'Token已失效，请重新登录',
            );
            Navigator.of(_context!, rootNavigator: true)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          }
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              error: 'Token已失效',
            ),
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        // 如果是401错误，可以在这里处理token过期的情况
        if (error.response?.statusCode == 401) {
          _storageDao.clearUserData();
          _storageDao.clearCredentials(); // 添加清除登录凭证
          if (_context != null && _context!.mounted) {
            CustomSnackBar.show(
              _context!,
              message: 'Token已过期，请重新登录',
            );
            Navigator.of(_context!, rootNavigator: true)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      print('发起GET请求: $path');
      final response = await _dio.get(path,
          queryParameters: queryParameters, options: options);
      print('GET请求成功: ${response.data}');
      return response;
    } catch (e) {
      print('GET请求失败: $e');
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data, Options? options}) async {
    try {
      print('发起POST请求: $path');
      print('POST请求数据: $data');
      final response = await _dio.post(path, data: data, options: options);
      print('POST请求成功: ${response.data}');
      return response;
    } catch (e) {
      print('POST请求失败: $e');
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      print('发起PUT请求: $path');
      final response = await _dio.put(path, data: data);
      print('PUT请求成功: ${response.data}');
      return response;
    } catch (e) {
      print('PUT请求失败: $e');
      rethrow;
    }
  }

  Future<Response> delete(String path, {dynamic data}) async {
    try {
      print('发起DELETE请求: $path');
      final response = await _dio.delete(path, data: data);
      print('DELETE请求成功: ${response.data}');
      return response;
    } catch (e) {
      print('DELETE请求失败: $e');
      rethrow;
    }
  }
}
