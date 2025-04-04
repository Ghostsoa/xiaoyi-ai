import '../http_client.dart';

class VersionService {
  static final _httpClient = HttpClient();

  /// 获取版本信息
  static Future<Map<String, String>> getVersionInfo() async {
    try {
      final response = await _httpClient.get('/user/version');
      final data = response.data['data'] as Map<String, dynamic>;
      return {
        'current_version': data['current_version'],
        'min_version': data['min_version'],
      };
    } catch (e) {
      rethrow;
    }
  }

  /// 更新版本信息
  static Future<void> updateVersion({
    required String currentVersion,
    required String minVersion,
  }) async {
    try {
      await _httpClient.put('/admin/version', data: {
        'current_version': currentVersion,
        'min_version': minVersion,
      });
    } catch (e) {
      rethrow;
    }
  }
}
