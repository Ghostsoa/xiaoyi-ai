import 'package:dio/dio.dart';
import '../../model/character_card.dart';
import '../../utils/character_card_packer.dart';
import '../http_client.dart';

class RoleCardService {
  final _httpClient = HttpClient();

  String _getErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final responseData = e.response!.data;
      return responseData['error'] ?? '请求失败';
    }
    return e.toString();
  }

  Future<Map<String, dynamic>> uploadCard(
      CharacterCard card, String category) async {
    try {
      // 1. 准备角色卡数据文件
      final cardData = CharacterCardPacker.packCard(card);

      // 2. 准备封面图片
      final coverImageData =
          CharacterCardPacker.base64ToImageBytes(card.coverImageBase64);

      // 3. 构建表单数据
      final formData = FormData.fromMap({
        'title': card.title,
        'description': card.description,
        'category': category,
        'code': card.code,
        'tags': card.tags,
        'raw_data': MultipartFile.fromBytes(
          cardData,
          filename: '${card.code}.xycard',
        ),
        'cover': MultipartFile.fromBytes(
          coverImageData,
          filename: '${card.code}_cover.jpg',
        ),
      });

      // 4. 发送请求
      final response =
          await _httpClient.post('/role-cards/upload', data: formData);
      return response.data;
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }
}
