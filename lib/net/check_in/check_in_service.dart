import 'package:dio/dio.dart';
import '../http_client.dart';
import '../../dao/storage_dao.dart';

class CheckInService {
  final HttpClient _client = HttpClient();
  final _storageDao = StorageDao();

  String _getErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final responseData = e.response!.data;
      return responseData['error'] ?? '请求失败';
    }
    return e.toString();
  }

  /// 获取请求头
  Map<String, String> getHeaders() {
    final token = _storageDao.getToken() ?? '';
    return {
      'Authorization': 'Bearer $token',
    };
  }

  /// 执行签到
  Future<(Map<String, dynamic>?, String?)> checkIn() async {
    try {
      final response = await _client.post('/check-in');
      print('签到原始响应: ${response.data}');

      if (response.statusCode == 200) {
        return (response.data['data'] as Map<String, dynamic>, null);
      }
      return (
        null,
        response.data['msg'] as String? ?? response.data['message'] as String?
      );
    } catch (e) {
      return (null, _getErrorMessage(e));
    }
  }

  /// 获取签到状态
  Future<(Map<String, dynamic>?, String?)> getCheckInStatus() async {
    try {
      final response = await _client.get('/check-in/status');
      print('获取签到状态原始响应: ${response.data}');

      if (response.statusCode == 200) {
        return (response.data['data'] as Map<String, dynamic>, null);
      }
      return (
        null,
        response.data['msg'] as String? ?? response.data['message'] as String?
      );
    } catch (e) {
      return (null, _getErrorMessage(e));
    }
  }

  /// 获取本周签到情况
  Future<(Map<String, dynamic>?, String?)> getWeeklyCheckIn() async {
    try {
      final response = await _client.get('/check-in/weekly');
      print('获取周签到原始响应: ${response.data}');

      if (response.statusCode == 200) {
        return (response.data['data'] as Map<String, dynamic>, null);
      }
      return (
        null,
        response.data['msg'] as String? ?? response.data['message'] as String?
      );
    } catch (e) {
      return (null, _getErrorMessage(e));
    }
  }
}
