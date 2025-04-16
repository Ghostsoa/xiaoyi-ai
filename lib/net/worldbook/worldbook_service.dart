import '../http_client.dart';

class WorldbookService {
  final _client = HttpClient();

  /// 获取世界书条目列表
  Future<({List<Map<String, dynamic>> list, int total})> getWorldbookEntries({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _client.get(
        '/worldbook',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return (
          list: List<Map<String, dynamic>>.from(data['list']),
          total: data['total'] as int,
        );
      }

      throw '获取列表失败';
    } catch (e) {
      String errorMessage = '获取列表失败：网络错误';
      if (e is String) {
        errorMessage = e;
      }
      throw errorMessage;
    }
  }

  Future<(bool, String)> createWorldbookEntry(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        '/worldbook',
        data: data,
      );

      if (response.data['code'] == 200) {
        return (true, '创建成功');
      } else {
        final message = (response.data['message'] ?? '创建失败').toString();
        return (false, message);
      }
    } catch (e) {
      return (false, e.toString());
    }
  }

  Future<(bool, String)> updateWorldbookEntry(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await _client.put(
        '/worldbook/$id',
        data: data,
      );

      if (response.data['code'] == 200) {
        return (true, '更新成功');
      } else {
        final message = (response.data['message'] ?? '更新失败').toString();
        return (false, message);
      }
    } catch (e) {
      return (false, e.toString());
    }
  }

  Future<(bool, String)> deleteWorldbookEntry(int id) async {
    try {
      final response = await _client.delete('/worldbook/$id');

      if (response.data['code'] == 200) {
        return (true, '删除成功');
      } else {
        final message = (response.data['message'] ?? '删除失败').toString();
        return (false, message);
      }
    } catch (e) {
      return (false, e.toString());
    }
  }
}
