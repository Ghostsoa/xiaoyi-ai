import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ImageGenerationService {
  /// 生成图片
  /// [prompt] - 提示词
  /// [model] - 模型名称 (flux 或 turbo)
  /// [width] - 图片宽度
  /// [height] - 图片高度
  /// [seed] - 随机种子 (为null时随机生成)
  /// [enhance] - 是否增强
  /// [nologo] - 是否去除水印
  Future<String?> generateImage({
    required String prompt,
    String model = 'flux',
    int width = 768,
    int height = 1024,
    int? seed,
    bool enhance = true,
    bool nologo = true,
  }) async {
    try {
      // 如果没有提供seed，随机生成一个
      seed ??= Random().nextInt(9999999) + 1;

      // 构建基础 URL
      const baseUrl = "https://image.pollinations.ai/prompt/";

      // 构建完整提示词
      String fullPrompt =
          "$prompt?model=$model&width=$width&height=$height&seed=$seed";
      if (nologo) {
        fullPrompt += "&nologo=true";
      }
      if (enhance) {
        fullPrompt += "&enhance=true";
      }

      // 构建URL
      final url = Uri.parse("$baseUrl$fullPrompt");

      // 发送请求
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // 获取应用文档目录
        final directory = await getApplicationDocumentsDirectory();

        // 生成文件名（使用时间戳避免重复）
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final filename =
            "${directory.path}/${nologo ? 'nologo_' : ''}${model}_$timestamp.png";

        // 保存图片
        final file = File(filename);
        await file.writeAsBytes(response.bodyBytes);

        return filename;
      } else {
        print('请求失败，状态码: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('生成图片时发生错误: $e');
      return null;
    }
  }
}
