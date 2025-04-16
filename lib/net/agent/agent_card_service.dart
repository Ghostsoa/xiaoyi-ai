import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../http_client.dart';

class AgentCardService {
  final HttpClient _client = HttpClient();

  /// 获取我的智能体卡列表
  Future<({List<Map<String, dynamic>> list, int total})> getMyCards() async {
    try {
      final response = await _client.get('/user/agent-cards/my');

      if (response.statusCode == 200) {
        final data = response.data['data'];

        // 处理list为null的情况
        final rawList = data['list'];
        final List<Map<String, dynamic>> list =
            rawList != null ? List<Map<String, dynamic>>.from(rawList) : [];

        return (list: list, total: data['total'] as int);
      }

      throw '获取列表失败';
    } catch (e) {
      String errorMessage = '获取列表失败：网络错误';
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'] as String? ?? errorMessage;
        }
      }
      throw errorMessage;
    }
  }

  /// 创建智能体卡
  ///
  /// 返回值为 (成功状态，消息，数据)
  Future<(bool, String, Map<String, dynamic>?)> createAgentCard({
    required String name,
    String? description,
    String? tags,
    String? setting,
    String? instruction,
    required String modelName,
    String? temperature = '0.7',
    String? topP = '0.9',
    String? topK = '40',
    String? maxTokens = '2000',
    String? frequencyPenalty = '0',
    Map<String, dynamic>? customFields,
    required int status,
    List<int>? worldbookEntryIds,
    File? coverImage,
    File? backgroundImage,
    String? userPrefix,
    String? userSuffix,
    String? customRules,
    bool? enableFunctionCall,
    int? keywordMatchDepth,
  }) async {
    try {
      // 准备表单数据
      final formData = FormData();

      // 添加必填字段
      formData.fields.add(MapEntry('name', name));
      formData.fields.add(MapEntry('model_name', modelName));
      formData.fields.add(MapEntry('status', status.toString()));

      // 添加可选字段
      if (description != null) {
        formData.fields.add(MapEntry('description', description));
      }

      if (tags != null) {
        formData.fields.add(MapEntry('tags', tags));
      }

      if (setting != null) {
        formData.fields.add(MapEntry('setting', setting));
      }

      if (instruction != null) {
        formData.fields.add(MapEntry('instruction', instruction));
      }

      if (temperature != null) {
        formData.fields.add(MapEntry('temperature', temperature));
      }

      if (topP != null) {
        formData.fields.add(MapEntry('top_p', topP));
      }

      if (topK != null) {
        formData.fields.add(MapEntry('top_k', topK));
      }

      if (maxTokens != null) {
        formData.fields.add(MapEntry('max_tokens', maxTokens));
      }

      if (frequencyPenalty != null) {
        formData.fields.add(MapEntry('frequency_penalty', frequencyPenalty));
      }

      if (customFields != null) {
        formData.fields
            .add(MapEntry('custom_fields', json.encode(customFields)));
      }

      // 添加新的可选字段
      if (userPrefix != null) {
        formData.fields.add(MapEntry('user_prefix', userPrefix));
      }

      if (userSuffix != null) {
        formData.fields.add(MapEntry('user_suffix', userSuffix));
      }

      if (customRules != null) {
        formData.fields.add(MapEntry('custom_rules', customRules));
      }

      if (enableFunctionCall != null) {
        formData.fields.add(
            MapEntry('enable_function_call', enableFunctionCall.toString()));
      }

      if (keywordMatchDepth != null) {
        formData.fields
            .add(MapEntry('keyword_match_depth', keywordMatchDepth.toString()));
      }

      // 添加世界书条目ID数组（如果有）
      if (worldbookEntryIds != null && worldbookEntryIds.isNotEmpty) {
        formData.fields.add(
            MapEntry('worldbook_entry_ids', json.encode(worldbookEntryIds)));
      }

      // 添加封面图片文件
      if (coverImage != null) {
        final fileName = coverImage.path.split('/').last;
        formData.files.add(MapEntry(
          'cover',
          await MultipartFile.fromFile(
            coverImage.path,
            filename: fileName,
          ),
        ));
      }

      // 添加背景图片文件
      if (backgroundImage != null) {
        final fileName = backgroundImage.path.split('/').last;
        formData.files.add(MapEntry(
          'background',
          await MultipartFile.fromFile(
            backgroundImage.path,
            filename: fileName,
          ),
        ));
      }

      // 发送请求
      final response = await _client.post(
        '/user/agent-cards',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        // 解析返回的数据
        final responseData = response.data;
        return (
          true,
          responseData['message'] as String? ?? '创建成功',
          responseData['data'] as Map<String, dynamic>?
        );
      } else {
        // 处理其他状态码
        return (false, response.data['message'] as String? ?? '创建失败', null);
      }
    } catch (e) {
      // 处理网络请求异常
      String errorMessage = '创建失败：网络错误';
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'] as String? ?? errorMessage;
        }
      }
      return (false, errorMessage, null);
    }
  }

  Future<Map<String, dynamic>> getCardDetail(int id) async {
    try {
      final response = await _client.get('/user/agent-cards/$id');
      return response.data['data'];
    } catch (e) {
      throw '获取详情失败：${e.toString()}';
    }
  }

  Future<(bool, String, Map<String, dynamic>?)> updateAgentCard({
    required int id,
    String? name,
    String? description,
    String? tags,
    String? setting,
    String? instruction,
    String? modelName,
    String? temperature,
    String? topP,
    String? topK,
    String? maxTokens,
    String? frequencyPenalty,
    Map<String, dynamic>? customFields,
    List<int>? worldbookEntryIds,
    int? status,
    File? coverImage,
    File? backgroundImage,
    String? userPrefix,
    String? userSuffix,
    String? customRules,
    bool? enableFunctionCall,
    int? keywordMatchDepth,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      // 只添加已修改的字段
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (tags != null) data['tags'] = tags;
      if (setting != null) data['setting'] = setting;
      if (instruction != null) data['instruction'] = instruction;
      if (modelName != null) data['model_name'] = modelName;
      if (temperature != null) data['temperature'] = double.parse(temperature);
      if (topP != null) data['top_p'] = double.parse(topP);
      if (topK != null) data['top_k'] = int.parse(topK);
      if (maxTokens != null) data['max_tokens'] = int.parse(maxTokens);
      if (frequencyPenalty != null)
        data['frequency_penalty'] = double.parse(frequencyPenalty);
      if (customFields != null) data['custom_fields'] = customFields;
      if (worldbookEntryIds != null)
        data['worldbook_entry_ids'] = worldbookEntryIds;
      if (status != null) data['status'] = status;

      // 添加新的可选字段
      if (userPrefix != null) data['user_prefix'] = userPrefix;
      if (userSuffix != null) data['user_suffix'] = userSuffix;
      if (customRules != null) data['custom_rules'] = customRules;
      if (enableFunctionCall != null)
        data['enable_function_call'] = enableFunctionCall;

      if (keywordMatchDepth != null) {
        data['keyword_match_depth'] = keywordMatchDepth;
      }

      // 只有在选择了新图片时才处理图片
      if (coverImage != null) {
        final bytes = await coverImage.readAsBytes();
        data['cover_base64'] = 'data:image/png;base64,${base64Encode(bytes)}';
      }
      if (backgroundImage != null) {
        final bytes = await backgroundImage.readAsBytes();
        data['background_base64'] =
            'data:image/png;base64,${base64Encode(bytes)}';
      }

      final response = await _client.put('/user/agent-cards/$id', data: data);
      final responseData = response.data;
      return (
        responseData['code'] == 0,
        responseData['message'] as String? ?? '更新成功',
        responseData['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      return (false, '更新失败：$e', null);
    }
  }

  Future<(bool, String)> deleteAgentCard(int id) async {
    try {
      final response = await _client.delete('/user/agent-cards/$id');
      return (true, response.data['message'] as String);
    } catch (e) {
      return (false, '删除失败：${e.toString()}');
    }
  }

  /// 获取在线智能体卡列表
  Future<({List<Map<String, dynamic>> list, int total})> getOnlineCards({
    int page = 1,
    int pageSize = 10,
    String? keyword,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'page': page,
        'page_size': pageSize,
      };

      if (keyword != null && keyword.isNotEmpty) {
        params['keyword'] = keyword;
      }

      final response = await _client.get(
        '/user/agent-cards',
        queryParameters: params,
      );

      final data = response.data['data'];
      return (
        list: List<Map<String, dynamic>>.from(data['list']),
        total: data['total'] as int,
      );
    } catch (e) {
      throw '获取列表失败：${e.toString()}';
    }
  }

  /// 检查用户创作资格
  Future<({bool hasPermission, String? message})>
      checkCreationQualification() async {
    try {
      final response = await _client.get('/user/agent-cards/qualification');
      if (response.statusCode == 200) {
        final data = response.data;
        return (
          hasPermission: data['data']['has_permission'] as bool? ?? false,
          message: data['message'] as String?,
        );
      }
      return (
        hasPermission: false,
        message: response.data['message'] as String? ?? '检查创作资格失败',
      );
    } catch (e) {
      throw '检查创作资格失败：${e.toString()}';
    }
  }

  /// 申请创作资格
  Future<String> applyForCreationQualification() async {
    try {
      final response =
          await _client.post('/user/agent-cards/qualification/apply');
      if (response.statusCode == 200) {
        return response.data['message'] ?? '申请提交成功';
      }
      // 处理错误状态码，如400等
      final message = response.data['message'] ?? '申请提交失败';
      final error = response.data['error'];
      return error != null ? '$message：$error' : message;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map) {
          final message = responseData['message'] ?? '申请失败';
          final error = responseData['error'];
          return error != null ? '$message：$error' : message;
        }
      }
      return '申请创作资格失败：${e.toString().replaceFirst('Exception: ', '')}';
    }
  }
}
