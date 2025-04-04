import 'package:dio/dio.dart';
import '../http_client.dart';

class AdminAssetService {
  final HttpClient _client = HttpClient();

  /// 更新用户余额
  Future<String?> updateBalance(
    int userId, {
    required double amount,
    required String remark,
  }) async {
    try {
      final response = await _client.post(
        '/admin/asset/balance',
        data: {
          'user_id': userId,
          'amount': amount,
          'remark': remark,
        },
      );

      return response.data['message'] as String;
    } on DioException catch (e) {
      print('Update balance error: ${e.message}');
      return e.response?.data['message'] as String? ?? '更新余额失败';
    }
  }

  /// 增加经验值
  Future<String?> addExp(
    int userId, {
    required int exp,
    required String remark,
  }) async {
    try {
      final response = await _client.post(
        '/admin/asset/exp',
        data: {
          'user_id': userId,
          'exp': exp,
          'remark': remark,
        },
      );

      return response.data['message'] as String;
    } on DioException catch (e) {
      print('Add exp error: ${e.message}');
      return e.response?.data['message'] as String? ?? '增加经验值失败';
    }
  }

  /// 重置用户资产
  Future<String?> resetAsset(int userId) async {
    try {
      final response = await _client.post(
        '/admin/asset/reset',
        data: userId,
      );

      return response.data['message'] as String;
    } on DioException catch (e) {
      print('Reset asset error: ${e.message}');
      return e.response?.data['message'] as String? ?? '重置资产失败';
    }
  }
}
