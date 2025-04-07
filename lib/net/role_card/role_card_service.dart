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

  Future<Map<String, dynamic>> uploadCard(CharacterCard card, String category,
      {int status = 1}) async {
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
        'tags': card.tags.join(','),
        'status': status.toString(),
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
      final response = await _httpClient.post(
        '/role-cards/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        // 处理可能返回字符串或其他类型的情况
        return {'code': 400, 'msg': '上传失败：服务器返回了非预期的数据格式'};
      }
    } catch (e) {
      final errorMsg = _getErrorMessage(e);
      // 错误时，返回统一的错误格式Map，而不是抛出字符串异常
      return {'code': 500, 'msg': errorMsg};
    }
  }
}
