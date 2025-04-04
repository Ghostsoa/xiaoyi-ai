import 'package:dio/dio.dart';
import '../http_client.dart';

class ModelSeries {
  final String name;
  final List<String> models;
  final String comment;

  ModelSeries({
    required this.name,
    required this.models,
    required this.comment,
  });

  factory ModelSeries.fromJson(Map<String, dynamic> json) {
    return ModelSeries(
      name: json['name'] as String,
      models: List<String>.from(json['models'] as List),
      comment: json['comment'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'models': models,
      'comment': comment,
    };
  }
}

class ModelKey {
  final String key;
  final String comment;

  ModelKey({
    required this.key,
    required this.comment,
  });

  factory ModelKey.fromJson(Map<String, dynamic> json) {
    return ModelKey(
      key: json['key'] as String,
      comment: json['comment'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'comment': comment,
    };
  }
}

class KeyManagerService {
  final _httpClient = HttpClient();

  String _getErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final responseData = e.response!.data;
      return responseData['error'] ??
          responseData['message'] ??
          responseData['msg'] ??
          '请求失败';
    }
    return e.toString();
  }

  // 添加模型系列
  Future<void> addModelSeries(ModelSeries series) async {
    try {
      final response = await _httpClient.post(
        '/admin/key-manager/series',
        data: series.toJson(),
      );

      if (response.statusCode != 200 || response.data['code'] != 200) {
        throw response.data['msg'] ?? response.data['message'] ?? '添加模型系列失败';
      }
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // 获取所有模型系列
  Future<List<ModelSeries>> getAllModelSeries() async {
    try {
      final response = await _httpClient.get('/admin/key-manager/series');

      if (response.statusCode == 200 && response.data['code'] == 200) {
        final dynamic data = response.data['data'];
        if (data == null || (data is List && data.isEmpty)) {
          return []; // 返回空列表而不是抛出异常
        }
        return (data as List)
            .map((json) => ModelSeries.fromJson(json))
            .toList();
      } else {
        throw response.data['msg'] ?? response.data['message'] ?? '获取模型系列列表失败';
      }
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // 获取指定模型系列
  Future<ModelSeries> getModelSeries(String name) async {
    try {
      final response = await _httpClient.get('/admin/key-manager/series/$name');

      if (response.statusCode == 200 && response.data['code'] == 200) {
        return ModelSeries.fromJson(response.data['data']);
      } else {
        throw response.data['msg'] ?? response.data['message'] ?? '获取模型系列失败';
      }
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // 删除模型系列
  Future<void> deleteModelSeries(String name) async {
    try {
      final response =
          await _httpClient.delete('/admin/key-manager/series/$name');

      if (response.statusCode != 200 || response.data['code'] != 200) {
        throw response.data['msg'] ?? response.data['message'] ?? '删除模型系列失败';
      }
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // 添加密钥
  Future<void> addKeys(String seriesName, List<ModelKey> keys) async {
    try {
      final response = await _httpClient.post(
        '/admin/key-manager/series/$seriesName/keys',
        data: keys.map((key) => key.toJson()).toList(),
      );

      if (response.statusCode != 200 || response.data['code'] != 200) {
        throw response.data['msg'] ?? response.data['message'] ?? '添加密钥失败';
      }
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // 获取密钥列表
  Future<List<ModelKey>> getKeys(String seriesName) async {
    try {
      final response =
          await _httpClient.get('/admin/key-manager/series/$seriesName/keys');

      if (response.statusCode == 200 && response.data['code'] == 200) {
        final dynamic data = response.data['data'];
        if (data == null || (data is List && data.isEmpty)) {
          return []; // 返回空列表而不是抛出异常
        }
        return (data as List).map((json) => ModelKey.fromJson(json)).toList();
      } else {
        throw response.data['msg'] ?? response.data['message'] ?? '获取密钥列表失败';
      }
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // 删除密钥
  Future<void> deleteKey(String seriesName, String key) async {
    try {
      // 在URL中添加key作为查询参数
      final String url = '/admin/key-manager/series/$seriesName/keys?key=$key';
      final response = await _httpClient.delete(url);

      if (response.statusCode != 200 || response.data['code'] != 200) {
        throw response.data['msg'] ?? response.data['message'] ?? '删除密钥失败';
      }
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // 批量删除密钥
  Future<void> batchDeleteKeys(String seriesName, List<String> keys) async {
    try {
      final response = await _httpClient.post(
        '/admin/key-manager/series/$seriesName/keys/batch-delete',
        data: {'keys': keys},
      );

      if (response.statusCode != 200 || response.data['code'] != 200) {
        throw response.data['msg'] ?? response.data['message'] ?? '批量删除密钥失败';
      }
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }
}
