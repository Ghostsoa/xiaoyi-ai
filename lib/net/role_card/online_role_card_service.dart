import '../http_client.dart';
import '../../model/online_role_card.dart';
import '../../model/character_card.dart';
import 'package:dio/dio.dart';
import '../../utils/character_card_packer.dart';
import 'dart:typed_data';

class OnlineRoleCardService {
  final _httpClient = HttpClient();

  String _getErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final responseData = e.response!.data;
      return responseData['error'] ?? '请求失败';
    }
    return e.toString();
  }

  Future<({List<OnlineRoleCard> list, int total})> getList({
    int page = 1,
    int pageSize = 5,
    String? category,
    String? tag,
    String? query,
    String? sortBy,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (category != null) 'category': category,
        if (tag != null) 'tag': tag,
        if (query != null && query.isNotEmpty) 'q': query,
        if (sortBy != null) 'sort_by': sortBy,
      };

      final response = await _httpClient.get(
        query != null && query.isNotEmpty
            ? '/role-cards/search'
            : '/role-cards/list',
        queryParameters: queryParams,
      );

      final data = response.data['data'];
      final rawList = data['list'] as List?;
      final list =
          rawList?.map((item) => OnlineRoleCard.fromJson(item)).toList() ?? [];
      final total = data['total'] as int? ?? 0;

      return (list: list, total: total);
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  /// 下载角色卡原始数据
  Future<CharacterCard> downloadCard(String code) async {
    try {
      final response = await _httpClient.get(
        '/role-cards/$code/download',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      if (response.data == null) {
        throw '下载角色卡失败：数据为空';
      }

      final bytes = Uint8List.fromList(response.data as List<int>);
      return CharacterCardPacker.unpackCard(bytes);
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  /// 获取用户发布的角色卡列表
  Future<({List<OnlineRoleCard> list, int total})> getUserRoleCards({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _httpClient.get(
        '/role-cards/user/list',
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

      final data = response.data['data'];
      final rawList = data['list'] as List?;
      final list =
          rawList?.map((item) => OnlineRoleCard.fromJson(item)).toList() ?? [];
      final total = data['total'] as int? ?? 0;

      return (list: list, total: total);
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  /// 删除角色卡
  Future<void> deleteCard(String code) async {
    try {
      await _httpClient.delete('/role-cards/$code');
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  /// 激励角色卡作者
  Future<void> rewardCard(String code, int amount) async {
    try {
      final formData = FormData.fromMap({
        'amount': amount.toString(),
      });

      await _httpClient.post(
        '/role-cards/$code/reward',
        data: formData,
      );
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  /// 获取作者的作品列表
  Future<({List<OnlineRoleCard> list, int total})> getAuthorRoleCards(
    String authorId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _httpClient.get(
        '/role-cards/author/$authorId',
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

      final data = response.data['data'];
      final rawList = data['list'] as List?;
      final list =
          rawList?.map((item) => OnlineRoleCard.fromJson(item)).toList() ?? [];
      final total = data['total'] as int? ?? 0;

      return (list: list, total: total);
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }
}
