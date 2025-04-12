import 'package:dio/dio.dart';
import '../../model/user_model.dart';
import '../http_client.dart';
import '../../service/device_service.dart';

class ApiService {
  final HttpClient _client = HttpClient();
  final DeviceService _deviceService = DeviceService();

  String _getErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final responseData = e.response!.data;
      print('Login error response: $responseData');
      print('Status code: ${e.response?.statusCode}');

      if (responseData['error'] != null) {
        return responseData['error'].toString();
      }

      if (responseData['message'] != null) {
        if (e.response?.statusCode == 403 &&
            responseData['message'].toString().contains('设备已被封禁')) {
          return '此设备已被封禁，无法登录。请联系管理员解除限制。';
        }
        return responseData['message'].toString();
      }

      return '请求失败';
    }
    return e.toString();
  }

  Future<(UserModel?, String?)> login(String email, String password) async {
    try {
      final deviceHeaders = await _deviceService.getDeviceHeaders();

      final response = await _client.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(headers: deviceHeaders),
      );

      if (response.statusCode == 200) {
        return (UserModel.fromJson(response.data['data']), null);
      }
      return (null, response.data['message'] as String);
    } catch (e) {
      return (null, _getErrorMessage(e));
    }
  }

  Future<(bool, String)> register(
      String email, String password, String username, String code,
      {int gender = 1, int? inviterId}) async {
    try {
      final deviceHeaders = await _deviceService.getDeviceHeaders();

      final data = {
        'email': email,
        'password': password,
        'username': username,
        'code': code,
        'gender': gender,
      };

      // 如果有邀请人ID，则添加到请求中
      if (inviterId != null) {
        data['inviter_id'] = inviterId;
      }

      final response = await _client.post(
        '/auth/register',
        data: data,
        options: Options(headers: deviceHeaders),
      );

      return (response.statusCode == 200, response.data['message'] as String);
    } catch (e) {
      return (false, _getErrorMessage(e));
    }
  }

  Future<(bool, String)> sendCode(String email) async {
    try {
      final deviceHeaders = await _deviceService.getDeviceHeaders();

      final response = await _client.post(
        '/auth/send-code',
        data: {
          'email': email,
        },
        options: Options(headers: deviceHeaders),
      );

      return (response.statusCode == 200, response.data['message'] as String);
    } catch (e) {
      return (false, _getErrorMessage(e));
    }
  }

  /// 发送忘记密码验证码
  Future<(bool, String)> sendForgotPasswordCode(String email) async {
    try {
      final deviceHeaders = await _deviceService.getDeviceHeaders();

      final response = await _client.post(
        '/auth/forgot-password',
        data: {
          'email': email,
        },
        options: Options(headers: deviceHeaders),
      );

      return (response.statusCode == 200, response.data['message'] as String);
    } catch (e) {
      return (false, _getErrorMessage(e));
    }
  }

  /// 重置密码
  Future<(bool, String)> resetPassword(
      String email, String code, String password) async {
    try {
      // 打印完整请求数据用于调试
      final requestData = {
        'email': email,
        'code': code,
        'new_password': password, // 尝试小写开头
      };
      print('重置密码请求数据: $requestData');

      final response = await _client.post(
        '/auth/reset-password',
        data: requestData,
      );

      if (response.statusCode == 200) {
        return (true, response.data['message'] as String);
      } else {
        print('重置密码响应状态码: ${response.statusCode}');
        print('重置密码响应数据: ${response.data}');
        return (false, response.data['message'] as String);
      }
    } catch (e) {
      print('重置密码请求异常: $e');
      return (false, _getErrorMessage(e));
    }
  }
}
