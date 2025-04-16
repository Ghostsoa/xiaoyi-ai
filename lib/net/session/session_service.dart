import '../http_client.dart';
import 'package:dio/dio.dart';

class SessionService {
  final _client = HttpClient();

  Future<Map<String, dynamic>> createSession(int cardId,
      {String? title}) async {
    try {
      final Map<String, dynamic> data = {'agent_card_id': cardId};

      // 如果提供了title，则添加到请求数据中
      if (title != null && title.isNotEmpty) {
        data['title'] = title;
      }

      final response = await _client.post(
        '/session',
        data: data,
      );

      return response.data;
    } catch (e) {
      if (e.toString().contains('DioException')) {
        // 尝试从DioException中提取详细错误信息
        if (e is DioException &&
            e.response != null &&
            e.response!.data is Map) {
          final responseData = e.response!.data as Map;
          final message = responseData['message'] as String? ?? '创建会话失败';
          final error = responseData['error'];
          if (error != null) {
            throw Exception('$message：$error');
          }
          throw Exception(message);
        }
      }
      throw Exception('创建会话失败: $e');
    }
  }

  Future<Map<String, dynamic>> initializeSession(
    String sessionId,
    Map<String, String> initFields,
  ) async {
    try {
      final response = await _client.post(
        '/session/$sessionId/init',
        data: {'init_fields': initFields},
      );

      return response.data;
    } catch (e) {
      throw Exception('初始化会话失败: $e');
    }
  }

  Future<Map<String, dynamic>> loadSession(String sessionId) async {
    try {
      final response = await _client.get('/session/$sessionId/load');
      return response.data;
    } catch (e) {
      throw Exception('加载会话失败: $e');
    }
  }

  Future<Map<String, dynamic>> chat(String sessionId, String content) async {
    try {
      final response = await _client
          .post('/session/$sessionId/chat', data: {'content': content});

      if (response.data['code'] == 200) {
        return response.data['data'];
      } else {
        throw Exception(response.data['msg'] ?? '发送消息失败');
      }
    } catch (e) {
      throw Exception('发送消息失败: $e');
    }
  }

  Future<Map<String, dynamic>> getMessages(String sessionId,
      {int page = 1}) async {
    try {
      final response = await _client
          .get('/session/$sessionId/messages?page=$page&order=asc');

      if (response.data['code'] == 200) {
        final data = response.data['data'];
        return {
          'messages': data['messages'] as List<dynamic>,
          'total': data['total'] as int,
        };
      } else {
        throw Exception(response.data['message'] ?? '获取消息失败');
      }
    } catch (e) {
      throw Exception('获取消息失败: $e');
    }
  }

  Future<void> clearHistory(String sessionId) async {
    try {
      final response = await _client.post('/session/$sessionId/clear');

      if (response.data['code'] != 200) {
        throw Exception(response.data['message'] ?? '清除历史记录失败');
      }
    } catch (e) {
      throw Exception('清除历史记录失败: $e');
    }
  }

  Future<void> undoLastRound(String sessionId) async {
    try {
      final response = await _client.post('/session/$sessionId/undo');

      if (response.data['code'] != 200) {
        throw Exception(response.data['message'] ?? '撤销对话失败');
      }
    } catch (e) {
      throw Exception('撤销对话失败: $e');
    }
  }

  Future<void> undoRounds(String sessionId, int rounds) async {
    try {
      final response = await _client.post(
        '/session/$sessionId/undo-rounds',
        data: {'rounds': rounds},
      );

      if (response.data['code'] != 200) {
        throw Exception(response.data['message'] ?? '撤销对话失败');
      }
    } catch (e) {
      throw Exception('撤销对话失败: $e');
    }
  }

  /// 获取会话的自定义字段
  Future<Map<String, dynamic>> getCustomFields(String sessionId) async {
    try {
      final response = await _client.get('/session/$sessionId/custom-fields');

      if (response.data['code'] == 200) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? '获取自定义字段失败');
      }
    } catch (e) {
      throw Exception('获取自定义字段失败: $e');
    }
  }

  /// 更新会话的自定义字段
  Future<void> updateCustomFields(
      String sessionId, Map<String, dynamic> customFields) async {
    try {
      final response = await _client.put(
        '/session/$sessionId/custom-fields',
        data: {'custom_fields': customFields},
      );

      if (response.data['code'] != 200) {
        throw Exception(response.data['message'] ?? '更新自定义字段失败');
      }
    } catch (e) {
      throw Exception('更新自定义字段失败: $e');
    }
  }
}
