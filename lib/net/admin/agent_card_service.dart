import 'package:dio/dio.dart';
import '../http_client.dart';

class AdminAgentCardService {
  final HttpClient _client = HttpClient();

  /// 获取申请列表
  Future<(List<int>?, String?)> getApplications() async {
    try {
      final response =
          await _client.get('/admin/agent-cards/qualification/applications');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return (List<int>.from(data['applicants']), null);
      }
      return (null, response.data['message'] as String);
    } catch (e) {
      String errorMessage = '获取申请列表失败：网络错误';
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'] as String? ?? errorMessage;
        }
      }
      return (null, errorMessage);
    }
  }

  /// 获取有资格用户列表
  Future<(List<int>?, String?)> getQualifiedUsers() async {
    try {
      final response =
          await _client.get('/admin/agent-cards/qualification/users');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return (List<int>.from(data['users']), null);
      }
      return (null, response.data['message'] as String);
    } catch (e) {
      String errorMessage = '获取资格用户列表失败：网络错误';
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'] as String? ?? errorMessage;
        }
      }
      return (null, errorMessage);
    }
  }

  /// 批准申请
  Future<String?> approveApplication(int userId) async {
    try {
      final response = await _client
          .post('/admin/agent-cards/qualification/approve/$userId');

      if (response.statusCode == 200) {
        return response.data['message'] as String;
      }
      return response.data['message'] as String;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData.containsKey('message')) {
          return responseData['message'] as String;
        }
      }
      return '批准申请失败：${e.toString()}';
    }
  }

  /// 撤销资格
  Future<String?> revokeQualification(int userId) async {
    try {
      final response =
          await _client.post('/admin/agent-cards/qualification/revoke/$userId');

      if (response.statusCode == 200) {
        return response.data['message'] as String;
      }
      return response.data['message'] as String;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData.containsKey('message')) {
          return responseData['message'] as String;
        }
      }
      return '撤销资格失败：${e.toString()}';
    }
  }
}
