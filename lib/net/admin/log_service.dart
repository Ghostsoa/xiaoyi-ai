import 'package:dio/dio.dart';
import '../http_client.dart';

class AdminLogService {
  final HttpClient _client = HttpClient();

  /// 获取日志清理配置
  Future<(Map<String, dynamic>?, String?)> getLogConfig() async {
    try {
      final response = await _client.get('/admin/logs/config');

      if (response.statusCode == 200) {
        return (response.data['data'] as Map<String, dynamic>, null);
      }
      return (null, response.data['message'] as String);
    } on DioException catch (e) {
      print('Get log config error: ${e.message}');
      final message = e.response?.data['message'] as String? ?? '获取日志清理配置失败';
      return (null, message);
    }
  }

  /// 手动触发日志清理
  Future<String?> triggerCleanup() async {
    try {
      final response = await _client.post('/admin/logs/cleanup');
      return response.data['message'] as String;
    } on DioException catch (e) {
      print('Trigger cleanup error: ${e.message}');
      return e.response?.data['message'] as String? ?? '触发日志清理失败';
    }
  }

  /// 获取日志统计信息
  Future<(Map<String, dynamic>?, String?)> getLogStats() async {
    try {
      final response = await _client.get('/admin/logs/stats');

      if (response.statusCode == 200) {
        return (response.data['data'] as Map<String, dynamic>, null);
      }
      return (null, response.data['message'] as String);
    } on DioException catch (e) {
      print('Get log stats error: ${e.message}');
      final message = e.response?.data['message'] as String? ?? '获取日志统计失败';
      return (null, message);
    }
  }

  /// 获取错误日志列表
  Future<(Map<String, dynamic>?, String?)> getErrorLogs({
    int page = 1,
    int pageSize = 20,
    int? severity,
    String? module,
    String? function,
    String? startTime,
    String? endTime,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'page_size': pageSize,
        if (severity != null) 'severity': severity,
        if (module != null) 'module': module,
        if (function != null) 'function': function,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
      };

      final response = await _client.get(
        '/admin/error-logs',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return (response.data['data'] as Map<String, dynamic>, null);
      }
      return (null, response.data['message'] as String);
    } on DioException catch (e) {
      print('Get error logs error: ${e.message}');
      final message = e.response?.data['message'] as String? ?? '获取错误日志列表失败';
      return (null, message);
    }
  }

  /// 获取模块列表
  Future<(List<String>?, String?)> getModules({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.get(
        '/admin/error-logs/modules',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return ((data['list'] as List).cast<String>(), null);
      }
      return (null, response.data['message'] as String);
    } on DioException catch (e) {
      print('Get modules error: ${e.message}');
      final message = e.response?.data['message'] as String? ?? '获取模块列表失败';
      return (null, message);
    }
  }

  /// 获取函数列表
  Future<(List<String>?, String?)> getFunctions({
    int page = 1,
    int pageSize = 20,
    String? module,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'page_size': pageSize,
        if (module != null) 'module': module,
      };

      final response = await _client.get(
        '/admin/error-logs/functions',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return ((data['list'] as List).cast<String>(), null);
      }
      return (null, response.data['message'] as String);
    } on DioException catch (e) {
      print('Get functions error: ${e.message}');
      final message = e.response?.data['message'] as String? ?? '获取函数列表失败';
      return (null, message);
    }
  }
}
