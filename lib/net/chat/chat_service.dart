import '../../model/character_card.dart';
import '../http_client.dart';
import 'package:dio/dio.dart';

class ChatService {
  static const String _chatEndpoint = '/chat';
  static const String _decideEndpoint = '/chat/decide';
  static const String _statusEndpoint = '/chat/status';
  final _httpClient = HttpClient();

  String _getErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final responseData = e.response!.data;
      return responseData['error'] ?? '请求失败';
    }
    return e.toString();
  }

  /// 获取应该发言的角色列表
  Future<List<String>> decideNextSpeakers({
    required String input,
    required List<Map<String, String>> messages,
    required String systemPrompt,
    required List<GroupCharacter> roles,
  }) async {
    try {
      final requestBody = {
        'input': input,
        'messages': messages,
        'system': systemPrompt,
        'roles': roles
            .map((r) => {'name': r.name, 'description': r.setting})
            .toList(),
      };

      final response = await _httpClient.post(
        _decideEndpoint,
        data: requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['code'] == 200 && responseData['data'] != null) {
          return List<String>.from(responseData['data']['speakers'] as List);
        } else {
          throw responseData['error'] ?? responseData['message'] ?? '决策失败';
        }
      } else {
        throw '决策请求失败: ${response.statusCode}';
      }
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  /// 发送对话请求
  ///
  /// [input] 用户输入的文本，在群聊的后续对话中可以为空
  /// [messages] 历史消息记录
  /// [card] 角色卡信息，用于获取系统设定和配置
  /// [role] 当前发言角色信息，如果提供则表示是群聊模式
  Future<String?> sendMessage({
    String? input,
    required List<Map<String, String>> messages,
    required CharacterCard card,
    GroupCharacter? role,
  }) async {
    try {
      // 构建系统指令
      final systemPrompt = role != null
          ? '[设定]${role.setting}' // 群聊模式，使用当前角色的设定
          : '[设定]${card.setting} [用户设定]${card.userSetting}'; // 单聊模式

      // 获取状态栏内容
      final String status = card.statusBarType == StatusBarType.none
          ? ''
          : (card.statusBar ?? '');

      // 构建请求体
      final requestBody = {
        'model': card.modelName,
        'input': input ?? '请以角色身份继续对话',
        'messages': messages,
        'system': systemPrompt,
        'status': status,
      };

      // 如果是群聊模式，添加角色信息
      if (role != null) {
        requestBody['role'] = {
          'name': role.name,
          'description': role.setting,
        };
      }

      // 添加模型参数
      requestBody['config'] = {
        'temperature': card.modelParams.temperature,
        'top_p': card.modelParams.topP,
        'max_tokens': card.modelParams.maxTokens,
        'presence_penalty': card.modelParams.presencePenalty,
        'frequency_penalty': card.modelParams.frequencyPenalty,
      };

      // 发送请求
      final response = await _httpClient.post(
        _chatEndpoint,
        data: requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['code'] == 200 && responseData['data'] != null) {
          return responseData['data']['response'] as String?;
        } else {
          throw responseData['error'] ?? responseData['message'] ?? '请求失败';
        }
      } else {
        throw '请求失败: ${response.statusCode}';
      }
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  /// 生成状态栏JSON
  Future<String?> generateStatusBar(String prompt) async {
    try {
      final requestBody = {
        'prompt': prompt,
      };

      final response = await _httpClient.post(
        _statusEndpoint,
        data: requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['code'] == 200 && responseData['data'] != null) {
          return responseData['data'] as String;
        } else {
          throw responseData['error'] ?? responseData['message'] ?? '生成失败';
        }
      } else {
        throw '请求失败: ${response.statusCode}';
      }
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }
}
