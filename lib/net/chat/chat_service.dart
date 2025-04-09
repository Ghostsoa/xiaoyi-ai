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
      // 优先使用error字段，然后是message字段
      if (responseData['error'] != null) {
        return responseData['error'].toString();
      }

      if (responseData['message'] != null) {
        return responseData['message'].toString();
      }

      return '请求失败';
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

      final response = await _httpClient.postForChat(
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

      // 使用长超时发送请求 (180秒)
      final response = await _httpClient.postForChat(
        _chatEndpoint,
        data: requestBody,
      );

      final responseData = response.data;

      // 检查API返回的状态码，若不为200则抛出错误
      if (responseData['code'] != 200) {
        if (responseData['error'] != null) {
          throw responseData['error'].toString();
        } else if (responseData['message'] != null) {
          throw responseData['message'].toString();
        } else {
          throw '请求错误：${responseData['code']}';
        }
      }

      // 正常情况下返回响应
      if (responseData['data'] != null) {
        return responseData['data']['response'] as String?;
      } else {
        throw '响应数据为空';
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

      final response = await _httpClient.postForChat(
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
