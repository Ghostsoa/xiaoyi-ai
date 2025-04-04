import 'package:dio/dio.dart';
import '../../net/http_client.dart';

class NotificationService {
  final HttpClient _httpClient = HttpClient();

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int pageSize = 10,
    String? sortBy,
    String? order,
    int? type,
    int? status,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'page_size': pageSize,
      };

      if (sortBy != null) queryParameters['sort_by'] = sortBy;
      if (order != null) queryParameters['order'] = order;
      if (type != null) queryParameters['type'] = type;
      if (status != null) queryParameters['status'] = status;

      final response = await _httpClient.get(
        '/notifications',
        queryParameters: queryParameters,
      );

      return response.data;
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      throw errorMessage;
    }
  }

  Future<Map<String, dynamic>> getNotificationDetail(
      String notificationId) async {
    try {
      final response = await _httpClient.get(
        '/notifications/$notificationId',
      );

      return response.data;
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      throw errorMessage;
    }
  }

  Future<void> markAsRead(List<String> notificationIds) async {
    try {
      final List<int> ids = notificationIds.map((id) => int.parse(id)).toList();

      await _httpClient.post(
        '/notifications/read',
        data: {
          'notification_ids': ids,
        },
      );
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      throw errorMessage;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _httpClient.post(
        '/notifications/read-all',
      );
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      throw errorMessage;
    }
  }

  Future<Map<String, dynamic>> getNotificationStatus() async {
    try {
      final response = await _httpClient.get(
        '/notifications/status',
      );

      return response.data;
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      throw errorMessage;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final data = error.response?.data;
        if (data != null && data['message'] != null) {
          return data['message'].toString();
        }
      }
      return error.message ?? '请求失败';
    }
    return error.toString();
  }
}
