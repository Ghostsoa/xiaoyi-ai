import 'package:dio/dio.dart';
import '../http_client.dart';

class AdminUserService {
  final HttpClient _client = HttpClient();

  Future<(Map<String, dynamic>?, String?)> getUserList({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.get(
        '/admin/users',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response.statusCode == 200) {
        return (response.data['data'] as Map<String, dynamic>, null);
      }
      return (null, response.data['message'] as String);
    } on DioException catch (e) {
      print('Get user list error: ${e.message}');
      final message = e.response?.data['message'] as String? ?? '获取用户列表失败';
      return (null, message);
    }
  }

  Future<(Map<String, dynamic>?, String?)> getUserDetail(int userId) async {
    try {
      // 并行请求用户详情和资产信息
      final responses = await Future.wait([
        _client.get('/admin/user/$userId'),
        _client.get('/admin/asset/$userId'),
      ]);

      final userResponse = responses[0];
      final assetResponse = responses[1];

      if (userResponse.statusCode == 200 && assetResponse.statusCode == 200) {
        final userData = userResponse.data['data'] as Map<String, dynamic>;
        final assetData = assetResponse.data['data'] as Map<String, dynamic>;

        // 合并用户详情和资产信息
        userData['asset'] = assetData;
        return (userData, null);
      }

      return (null, userResponse.data['message'] as String);
    } on DioException catch (e) {
      print('Get user detail error: ${e.message}');
      final message = e.response?.data['message'] as String? ?? '获取用户详情失败';
      return (null, message);
    }
  }

  Future<String?> updateUserStatus(
    int userId, {
    required int status,
    required String reason,
  }) async {
    try {
      final data = {
        'status': status,
        'reason': reason,
      };
      print('Updating user status with data: $data');

      final response = await _client.put(
        '/admin/user/$userId',
        data: data,
      );

      print('Update user status response: ${response.data}');
      return response.data['message'] as String;
    } on DioException catch (e) {
      print('Update user status error: ${e.message}');
      print('Error response: ${e.response?.data}');
      print('Error request: ${e.requestOptions.data}');
      print('Error URL: ${e.requestOptions.path}');
      return e.response?.data['message'] as String? ?? '更新用户状态失败';
    }
  }

  Future<String?> updateUserRole(
    int userId, {
    required int role,
  }) async {
    try {
      final response = await _client.put(
        '/admin/user/$userId/role',
        data: {
          'role': role,
        },
      );

      return response.data['message'] as String;
    } on DioException catch (e) {
      print('Update user role error: ${e.message}');
      return e.response?.data['message'] as String? ?? '更新用户角色失败';
    }
  }

  Future<String?> kickUser(
    int userId, {
    required String reason,
  }) async {
    try {
      final response = await _client.post(
        '/admin/kick-user',
        data: {
          'user_id': userId,
          'reason': reason,
        },
      );

      return response.data['message'] as String;
    } on DioException catch (e) {
      print('Kick user error: ${e.message}');
      return e.response?.data['message'] as String? ?? '踢出用户失败';
    }
  }

  /// 删除用户
  Future<String?> deleteUser(
    int userId, {
    required String reason,
  }) async {
    try {
      final response = await _client.delete(
        '/admin/user/$userId',
        data: {
          'reason': reason,
        },
      );

      return response.data['message'] as String;
    } on DioException catch (e) {
      print('Delete user error: ${e.message}');
      return e.response?.data['message'] as String? ?? '删除用户失败';
    }
  }

  Future<(Map<String, dynamic>?, String?)> getUserAsset(int userId) async {
    try {
      final response = await _client.get('/admin/asset/$userId');

      if (response.statusCode == 200) {
        return (response.data['data'] as Map<String, dynamic>, null);
      }
      return (null, response.data['message'] as String);
    } on DioException catch (e) {
      print('Get user asset error: ${e.message}');
      final message = e.response?.data['message'] as String? ?? '获取用户资产详情失败';
      return (null, message);
    }
  }

  /// 获取用户资产变动记录
  Future<(Map<String, dynamic>?, String?)> getUserAssetLogs(
    int userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.get(
        '/admin/asset/$userId/logs',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response.statusCode == 200) {
        return (response.data['data'] as Map<String, dynamic>, null);
      }
      return (null, response.data['message'] as String);
    } on DioException catch (e) {
      print('Get user asset logs error: ${e.message}');
      final message = e.response?.data['message'] as String? ?? '获取用户资产变动记录失败';
      return (null, message);
    }
  }
}
