import 'package:dio/dio.dart';
import '../http_client.dart';

class CardUseService {
  static final _httpClient = HttpClient();

  /// 获取错误信息
  static String _getErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final responseData = e.response!.data;
      // 首先尝试读取错误信息，然后是消息字段，最后是msg字段（服务器有时返回这个字段）
      return responseData['error'] ??
          responseData['message'] ??
          responseData['msg'] ??
          '请求失败';
    }
    return e.toString();
  }

  /// 使用卡密
  static Future<({bool success, String message, Map<String, dynamic>? data})>
      useCard(String cardNo) async {
    try {
      final response = await _httpClient.post('/cards/use', data: {
        'card_no': cardNo,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final message = response.data['message'] as String? ?? '兑换成功';
        return (success: true, message: message, data: data);
      }

      return (
        success: false,
        message: response.data['message'] as String? ?? '兑换失败',
        data: null
      );
    } catch (e) {
      return (success: false, message: _getErrorMessage(e), data: null);
    }
  }
}
