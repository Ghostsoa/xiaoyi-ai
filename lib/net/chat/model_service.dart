import '../http_client.dart';
import 'package:dio/dio.dart';

class ModelService {
  final _httpClient = HttpClient();

  String _getErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final responseData = e.response!.data;
      return responseData['error'] ?? responseData['message'] ?? '请求失败';
    }
    return e.toString();
  }

  /// 获取所有可用的模型列表
  Future<List<ModelGroup>> getAvailableModels() async {
    try {
      final response = await _httpClient.get('/chat/models');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['code'] == 200 && responseData['data'] != null) {
          final List<dynamic> modelGroups = responseData['data'];
          return modelGroups
              .map((group) => ModelGroup.fromJson(group))
              .toList();
        } else {
          throw responseData['error'] ?? responseData['message'] ?? '获取模型列表失败';
        }
      } else {
        throw '请求失败: ${response.statusCode}';
      }
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }
}

/// 模型组类，包含模型组名和模型列表
class ModelGroup {
  final String name;
  final List<String> models;
  final String comment;

  ModelGroup({
    required this.name,
    required this.models,
    required this.comment,
  });

  factory ModelGroup.fromJson(Map<String, dynamic> json) {
    return ModelGroup(
      name: json['name'] as String,
      models: List<String>.from(json['models'] as List),
      comment: json['comment'] as String,
    );
  }
}
