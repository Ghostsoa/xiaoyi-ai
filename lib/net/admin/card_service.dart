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
    String? batchNo,
    String? cardNo,
    dynamic used,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (batchNo != null) {
        queryParams['batch_no'] = batchNo;
      }

      if (cardNo != null) {
        queryParams['card_no'] = cardNo;
      }

      if (used != null) {
        queryParams['used'] = used;
      }

      final response = await _httpClient.get(
        '/admin/cards/list',
        queryParameters: queryParams,
      );
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  /// 获取卡密批次列表
  static Future<Map<String, dynamic>> getCardBatches({
    String? batchNo,
    int? cardType,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (batchNo != null) {
        queryParams['batch_no'] = batchNo;
      }

      if (cardType != null) {
        queryParams['card_type'] = cardType;
      }

      final response = await _httpClient.get(
        '/admin/cards/batches',
        queryParameters: queryParams,
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
