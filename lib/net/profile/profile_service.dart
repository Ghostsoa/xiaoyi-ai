import 'dart:io';
import 'package:dio/dio.dart';
import '../http_client.dart';
import '../../dao/storage_dao.dart';

class ProfileService {
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

  Future<(Map<String, dynamic>?, String?)> getAssetInfo() async {
    try {
      final response = await _client.get('/asset');

      if (response.statusCode == 200) {
        return (response.data['data'] as Map<String, dynamic>, null);
      }
      return (null, response.data['message'] as String);
    } catch (e) {
      return (null, _getErrorMessage(e));
    }
  }

  /// 上传头像
  Future<(String?, String?)> uploadAvatar(File imageFile) async {
    try {
      // 创建 FormData
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'avatar.jpg',
        ),
      });

      final response = await _client.post(
        '/user/avatar',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return (data['avatar'] as String, '头像更新成功');
      }
      return (null, response.data['message'] as String? ?? '上传头像失败');
    } catch (e) {
      return (null, _getErrorMessage(e));
    }
  }

  /// 获取头像图片
  Future<Response> getAvatarImage(String avatarUrl) async {
    try {
      final response = await _client.get(
        avatarUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );
      return response;
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  Future<(Map<String, dynamic>?, String?)> getAssetLogs({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.get(
        '/asset/logs',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response.statusCode == 200) {
        return (response.data['data'] as Map<String, dynamic>, null);
      }
      return (null, response.data['message'] as String);
    } catch (e) {
      return (null, _getErrorMessage(e));
    }
  }

  /// 修改用户名
  Future<String?> updateUsername(String username) async {
    try {
      final response = await _client.post(
        '/user/update-username',
        data: {'username': username},
      );

      if (response.statusCode == 200 && response.data['code'] == 200) {
        return null;
      }
      return response.data['message'] as String? ?? '修改用户名失败';
    } catch (e) {
      return _getErrorMessage(e);
    }
  }

  /// 修改密码
  Future<String?> updatePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _client.post(
        '/user/update-password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200 && response.data['code'] == 200) {
        return null;
      }
      return response.data['message'] as String? ?? '修改密码失败';
    } catch (e) {
      return _getErrorMessage(e);
    }
  }
}
