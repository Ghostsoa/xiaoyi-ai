import 'package:dio/dio.dart';
import '../http_client.dart';

class DeviceManagementService {
  final HttpClient _client = HttpClient();

  /// 获取设备黑名单列表
  Future<Map<String, dynamic>> getBlacklist({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _client.get(
        '/admin/devices/blacklist',
        queryParameters: queryParams,
      );

      print('GET请求成功: ${response.data}');

      if (response.data['code'] == 200) {
        final responseData = response.data['data'] as Map<String, dynamic>;
        return {
          'success': true,
          'data': {
            'devices': responseData['list'] ?? [],
            'total_pages': (responseData['total'] as int? ?? 0) > 0
                ? ((responseData['total'] as int) + limit - 1) ~/ limit
                : 1
          },
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? '获取黑名单失败',
      };
    } catch (e) {
      print('获取黑名单错误: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  /// 解封设备及关联账户
  Future<Map<String, dynamic>> unbanDevice(String deviceCode) async {
    try {
      final response = await _client.post(
        '/admin/devices/unban',
        data: {
          'device_code': deviceCode,
        },
      );

      print('解除禁用响应: ${response.data}');

      if (response.data['code'] == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? '设备已解封',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? '解封设备失败',
      };
    } catch (e) {
      print('解除禁用错误: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  /// 获取设备关联的所有用户
  Future<Map<String, dynamic>> getDeviceUsers(String deviceCode) async {
    try {
      final response = await _client.get(
        '/admin/devices/users',
        queryParameters: {
          'device_code': deviceCode,
        },
      );

      print('获取设备用户响应: ${response.data}');

      if (response.data['code'] == 200) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? '获取设备关联用户失败',
      };
    } catch (e) {
      print('获取设备用户错误: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  /// 获取用户关联的所有设备
  Future<Map<String, dynamic>> getUserDevices(int userId) async {
    try {
      final response = await _client.get('/admin/devices/user/$userId');

      print('获取用户设备响应: ${response.data}');

      if (response.data['code'] == 200) {
        // 推测API返回的数据结构可能不符合页面期望，添加数据结构转换逻辑
        final responseData = response.data['data'];

        // 检查返回的是什么格式，并进行转换
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('devices') &&
            responseData.containsKey('user_info')) {
          // 已经是正确的格式，直接返回
          return {
            'success': true,
            'data': responseData,
          };
        } else if (responseData is Map<String, dynamic>) {
          // 只返回了用户信息，没有设备列表
          return {
            'success': true,
            'data': {
              'devices': [], // 空设备列表
              'user_info': responseData,
            },
          };
        } else if (responseData is List) {
          // 只返回了设备列表，没有用户信息
          // 需要再请求用户详情
          try {
            final userResponse = await _client.get('/admin/user/$userId');
            if (userResponse.data['code'] == 200) {
              return {
                'success': true,
                'data': {
                  'devices': responseData,
                  'user_info': userResponse.data['data'],
                },
              };
            }
          } catch (e) {
            print('获取用户信息错误: $e');
          }

          // 如果获取用户信息失败，至少返回设备列表
          return {
            'success': true,
            'data': {
              'devices': responseData,
              'user_info': {'id': userId},
            },
          };
        } else {
          // 未知格式，尽量适配
          return {
            'success': true,
            'data': {
              'devices': responseData is List ? responseData : [],
              'user_info': {'id': userId},
            },
          };
        }
      }
      return {
        'success': false,
        'message': response.data['message'] ?? '获取用户关联设备失败',
      };
    } catch (e) {
      print('获取用户设备错误: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  String _getErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final responseData = e.response!.data;
      return responseData['message'] ?? responseData['error'] ?? '请求失败';
    }
    return e.toString();
  }
}
