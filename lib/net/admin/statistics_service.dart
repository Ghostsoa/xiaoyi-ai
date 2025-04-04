import 'package:dio/dio.dart';
import '../http_client.dart';

class AdminStatisticsService {
  final HttpClient _client = HttpClient();

  /// 获取每日统计数据
  Future<(List<Map<String, dynamic>>?, String?)> getDailyStats() async {
    try {
      final response = await _client.get('/admin/statistics/daily');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data == null) {
          return (<Map<String, dynamic>>[], null);
        }
        return (
          (data as List).map((e) => Map<String, dynamic>.from(e)).toList(),
          null
        );
      }
      return (null, response.data['message'] as String);
    } on DioException catch (e) {
      print('Get daily stats error: ${e.message}');
      final message = e.response?.data['message'] as String? ?? '获取每日统计数据失败';
      return (null, message);
    }
  }

  /// 获取月度统计数据
  Future<(Map<String, dynamic>?, String?)> getMonthlyStats() async {
    try {
      final response = await _client.get('/admin/statistics/monthly');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data == null) {
          return (<String, dynamic>{}, null);
        }
        return (Map<String, dynamic>.from(data), null);
      }
      return (null, response.data['message'] as String);
    } on DioException catch (e) {
      print('Get monthly stats error: ${e.message}');
      final message = e.response?.data['message'] as String? ?? '获取月度统计数据失败';
      return (null, message);
    }
  }

  /// 获取系统监控数据
  Future<(Map<String, dynamic>?, String?)> getMonitorStats() async {
    try {
      final response = await _client.get('/admin/monitor/stats');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data == null) {
          return (<String, dynamic>{}, null);
        }
        return (Map<String, dynamic>.from(data), null);
      }
      return (null, response.data['message'] as String);
    } on DioException catch (e) {
      print('Get monitor stats error: ${e.message}');
      final message = e.response?.data['message'] as String? ?? '获取系统监控数据失败';
      return (null, message);
    }
  }
}
