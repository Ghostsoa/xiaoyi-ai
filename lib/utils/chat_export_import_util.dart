import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../model/character_card.dart';
import '../model/chat_history.dart';
import '../service/chat_history_service.dart';
import '../service/character_card_service.dart';
import 'package:archive/archive.dart';

/// 聊天数据导出导入工具类
class ChatExportImportUtil {
  /// 导出并分享角色卡和聊天记录
  static Future<void> exportAndShare(
    BuildContext context,
    String characterCode,
    CharacterCardService characterCardService,
    ChatHistoryService chatHistoryService,
  ) async {
    try {
      // 1. 获取角色卡
      final characterCard =
          await characterCardService.getCardByCode(characterCode);
      if (characterCard == null) {
        throw Exception('未找到角色卡');
      }

      // 2. 获取所有存档的聊天记录
      final chatHistories = <ChatHistory>[];
      for (int slot = 1; slot <= ChatHistoryService.maxSlots; slot++) {
        final history =
            await chatHistoryService.getHistory(characterCode, slot: slot);
        if (history.messages.isNotEmpty) {
          chatHistories.add(history);
        }
      }

      // 3. 准备数据
      final exportData = {
        'characterCard': characterCard.toJson(),
        'chatHistories':
            chatHistories.map((history) => history.toJson()).toList(),
        'exportTime': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      // 4. 压缩数据
      final jsonString = jsonEncode(exportData);
      final jsonBytes = utf8.encode(jsonString);
      final gzipData = GZipEncoder().encode(jsonBytes);

      // 5. 保存为临时文件
      final tempDir = await getTemporaryDirectory();
      final fileName =
          '${characterCard.title}_备份_${DateTime.now().millisecondsSinceEpoch}.json';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(gzipData!);

      // 6. 分享文件
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: '${characterCard.title} 备份数据',
        text: '这是 ${characterCard.title} 的角色卡和聊天记录备份，可以导入到小懿AI中恢复数据。',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  /// 导出所有角色卡和聊天记录
  static Future<void> exportAllData(
    BuildContext context,
    CharacterCardService characterCardService,
    ChatHistoryService chatHistoryService,
  ) async {
    try {
      // 1. 获取所有角色卡
      final characterCards = await characterCardService.getAllCards();
      if (characterCards.isEmpty) {
        throw Exception('没有找到任何角色卡');
      }

      // 2. 准备导出数据
      final Map<String, dynamic> exportData = {
        'characterCards': <Map<String, dynamic>>[],
        'chatHistories': <Map<String, dynamic>>[],
        'exportTime': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      // 3. 获取每个角色卡的聊天记录
      for (final card in characterCards) {
        exportData['characterCards'].add(card.toJson());

        // 获取该角色卡的所有聊天存档
        for (int slot = 1; slot <= ChatHistoryService.maxSlots; slot++) {
          final history =
              await chatHistoryService.getHistory(card.code, slot: slot);
          if (history.messages.isNotEmpty) {
            exportData['chatHistories'].add(history.toJson());
          }
        }
      }

      // 4. 压缩数据
      final jsonString = jsonEncode(exportData);
      final jsonBytes = utf8.encode(jsonString);
      final gzipData = GZipEncoder().encode(jsonBytes);

      // 5. 保存为临时文件
      final tempDir = await getTemporaryDirectory();
      final fileName =
          '小懿AI_全部数据备份_${DateTime.now().millisecondsSinceEpoch}.json';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(gzipData!);

      // 6. 分享文件
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: '小懿AI 全部数据备份',
        text:
            '这是您的小懿AI全部角色卡和聊天记录备份，共包含 ${characterCards.length} 个角色卡和 ${exportData['chatHistories'].length} 个聊天记录。',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  /// 从JSON字符串导入
  static Future<String> importFromJson(
    String jsonString,
    CharacterCardService characterCardService,
    ChatHistoryService chatHistoryService,
  ) async {
    try {
      // 1. 解压数据
      final jsonBytes = utf8.encode(jsonString);
      GZipDecoder decoder = GZipDecoder();
      List<int> decompressedBytes;

      try {
        // 尝试解压数据
        decompressedBytes = decoder.decodeBytes(jsonBytes);
      } catch (e) {
        // 如果解压失败，可能是未压缩的JSON，直接使用
        decompressedBytes = jsonBytes;
      }

      final decompressedJson = utf8.decode(decompressedBytes);

      // 2. 解析JSON
      final Map<String, dynamic> importData = jsonDecode(decompressedJson);

      // 3. 导入角色卡
      int cardCount = 0;
      if (importData.containsKey('characterCard')) {
        final cardJson = importData['characterCard'] as Map<String, dynamic>;
        final characterCard = CharacterCard.fromJson(cardJson);
        await characterCardService.updateCard(characterCard);
        cardCount++;
      } else if (importData.containsKey('characterCards')) {
        final List<dynamic> cardsList = importData['characterCards'];
        for (final cardJson in cardsList) {
          final characterCard = CharacterCard.fromJson(cardJson);
          await characterCardService.updateCard(characterCard);
          cardCount++;
        }
      }

      // 4. 导入聊天记录
      int historyCount = 0;
      if (importData.containsKey('chatHistories')) {
        final List<dynamic> historyList = importData['chatHistories'];
        for (final historyJson in historyList) {
          final history = ChatHistory.fromJson(historyJson);
          await chatHistoryService.saveHistory(history);
          historyCount++;
        }
      }

      return '导入完成: $cardCount 个角色卡, $historyCount 个聊天记录';
    } catch (e) {
      throw Exception('导入失败: $e');
    }
  }

  /// 从文件导入
  static Future<String> importFromFile(
    File file,
    CharacterCardService characterCardService,
    ChatHistoryService chatHistoryService,
  ) async {
    try {
      // 1. 读取文件内容
      final bytes = await file.readAsBytes();

      // 2. 尝试解压数据
      final String jsonString = _tryDecompress(bytes);

      // 3. 调用导入方法
      return await importFromJson(
          jsonString, characterCardService, chatHistoryService);
    } catch (e) {
      throw Exception('从文件导入失败: $e');
    }
  }

  /// 尝试解压数据，如果解压失败则直接返回UTF8解码的字符串
  static String _tryDecompress(List<int> bytes) {
    try {
      // 尝试解压数据
      final decompressed = GZipDecoder().decodeBytes(bytes);
      return utf8.decode(decompressed);
    } catch (e) {
      // 如果解压失败，可能是未压缩的JSON
      return utf8.decode(bytes);
    }
  }
}
