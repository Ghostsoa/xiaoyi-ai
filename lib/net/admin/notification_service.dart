import 'package:dio/dio.dart';
import '../http_client.dart';

class NotificationType {
  static const int system = 1;
  static const int announcement = 2;
  static const int personal = 3;
  static const int promotion = 4;
  static const int maintenance = 5;
}

class AdminNotificationService {
  static final _httpClient = HttpClient();

  /// 获取错误信息
  static String _getErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final responseData = e.response!.data;
      return responseData['message'] ?? responseData['error'] ?? '请求失败';
    }
    return e.toString();
  }

  /// 创建通知
  static Future<({bool success, String message, Map<String, dynamic>? data})>
      createNotification({
    required String title,
    required String content,
    required int type,
    bool isGlobal = false,
    String? expiredAt,
    List<int>? userIds,
  }) async {
    try {
      final data = {
        'title': title,
        'content': content,
        'type': type,
        'is_global': isGlobal,
        if (expiredAt != null) 'expired_at': expiredAt,
        if (!isGlobal && userIds != null && userIds.isNotEmpty)
          'user_ids': userIds,
      };

      final response =
          await _httpClient.post('/admin/notifications', data: data);

      return (
        success: true,
        message: (response.data['message'] as String?) ?? '创建通知成功',
        data: response.data['data'] as Map<String, dynamic>?
      );
    } catch (e) {
      return (success: false, message: _getErrorMessage(e), data: null);
    }
  }

  /// 更新通知
  static Future<({bool success, String message})> updateNotification({
    required int id,
    required String title,
    required String content,
    required int type,
    bool? isGlobal,
    String? expiredAt,
  }) async {
    try {
      final data = {
        'title': title,
        'content': content,
        'type': type,
        if (isGlobal != null) 'is_global': isGlobal,
        if (expiredAt != null) 'expired_at': expiredAt,
      };

      final response =
          await _httpClient.put('/admin/notifications/$id', data: data);

      return (
        success: true,
        message: (response.data['message'] as String?) ?? '更新通知成功',
      );
    } catch (e) {
      return (success: false, message: _getErrorMessage(e));
    }
  }

  /// 删除通知
  static Future<({bool success, String message})> deleteNotification(
      int id) async {
    try {
      final response = await _httpClient.delete('/admin/notifications/$id');

      return (
        success: true,
        message: (response.data['message'] as String?) ?? '删除通知成功',
      );
    } catch (e) {
      return (success: false, message: _getErrorMessage(e));
    }
  }

  /// 获取通知列表
  static Future<
      ({
        bool success,
        String message,
        List<Map<String, dynamic>>? notifications,
        int? total
      })> getNotifications({
    int page = 1,
    int pageSize = 20,
    String? query,
    int? type,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'page_size': pageSize,
        if (query != null && query.isNotEmpty) 'query': query,
        if (type != null) 'type': type.toString(),
      };

      final response = await _httpClient.get(
        '/admin/notifications',
        queryParameters: queryParams,
      );

      final data = response.data['data'] as Map<String, dynamic>;

      return (
        success: true,
        message: (response.data['message'] as String?) ?? '获取通知列表成功',
        notifications: List<Map<String, dynamic>>.from(data['list'] as List),
        total: data['total'] as int?
      );
    } catch (e) {
      return (
        success: false,
        message: _getErrorMessage(e),
        notifications: null,
        total: null
      );
    }
  }

  /// 获取通知详情
  static Future<
          ({bool success, String message, Map<String, dynamic>? notification})>
      getNotificationDetail(int id) async {
    try {
      final response = await _httpClient.get('/admin/notifications/$id');

      return (
        success: true,
        message: (response.data['message'] as String?) ?? '获取通知详情成功',
        notification: response.data['data'] as Map<String, dynamic>?
      );
    } catch (e) {
      return (success: false, message: _getErrorMessage(e), notification: null);
    }
  }
}
