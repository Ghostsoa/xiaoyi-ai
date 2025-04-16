import '../http_client.dart';

class WorldSessionService {
  final _client = HttpClient();

  Future<Map<String, dynamic>> getSessions({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _client.get(
        '/session',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('获取会话列表失败: $e');
    }
  }

  Future<Map<String, dynamic>> deleteSession(String sessionId) async {
    final response = await _client.delete('/session/$sessionId');
    return response.data;
  }
}
