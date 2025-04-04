import 'package:dio/dio.dart';
import '../http_client.dart';

class LotteryService {
  final _client = HttpClient();

  /// 进行抽奖
  Future<Map<String, dynamic>> draw() async {
    try {
      final response = await _client.post('/lottery/draw');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'],
          'prize': response.data['data']['prize'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'],
        'error': response.data['error'] ?? '抽奖失败',
      };
    } on DioException catch (e) {
      print('抽奖失败: $e');
      final data = e.response?.data;
      return {
        'success': false,
        'message': data?['message'] ?? '抽奖失败',
        'error': data?['error'] ?? '网络错误，请稍后再试',
      };
    } catch (e) {
      print('抽奖异常: $e');
      return {
        'success': false,
        'message': '抽奖失败',
        'error': '发生未知错误，请稍后再试',
      };
    }
  }
}
