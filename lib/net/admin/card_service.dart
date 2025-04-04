import '../http_client.dart';

class CardService {
  static final _httpClient = HttpClient();

  /// 生成卡密
  static Future<void> generateCards({
    required int cardType,
    double? amount,
    int? duration,
    required int count,
  }) async {
    try {
      await _httpClient.post('/admin/cards/generate', data: {
        'card_type': cardType,
        if (amount != null) 'amount': amount,
        if (duration != null) 'duration': duration,
        'count': count,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 获取卡密列表
  static Future<Map<String, dynamic>> getCardList({
    required String batchNo,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _httpClient.get(
        '/admin/cards/list',
        queryParameters: {
          'batch_no': batchNo,
          'page': page,
          'page_size': pageSize,
        },
      );
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  /// 获取卡密批次列表
  static Future<Map<String, dynamic>> getCardBatches({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _httpClient.get(
        '/admin/cards/batches',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  /// 批量删除卡密批次
  static Future<void> deleteCardBatches(List<String> batchNos) async {
    try {
      await _httpClient.delete('/admin/cards/batches', data: {
        'batch_nos': batchNos,
      });
    } catch (e) {
      rethrow;
    }
  }
}
