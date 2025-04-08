import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/painting.dart';

enum ChatType {
  single, // 单人聊天
  group // 群聊
}

enum StatusBarType {
  none, // 不启用
  immersive, // 沉浸式
  custom // 自定义
}

class ModelParameters {
  final double temperature; // 温度
  final double topP; // 采样范围
  final double presencePenalty; // 存在惩罚
  final double frequencyPenalty; // 频率惩罚
  final int maxTokens; // 最大令牌数
  final bool enableContextLimit; // 是否启用上下文限制
  final int contextTurns; // 记忆轮数

  ModelParameters({
    this.temperature = 0.8,
    this.topP = 0.8,
    this.presencePenalty = 0.0,
    this.frequencyPenalty = 0.0,
    this.maxTokens = 4096,
    this.enableContextLimit = false,
    this.contextTurns = 50,
  });

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'topP': topP,
        'presencePenalty': presencePenalty,
        'frequencyPenalty': frequencyPenalty,
        'maxTokens': maxTokens,
        'enableContextLimit': enableContextLimit,
        'contextTurns': contextTurns,
      };

  factory ModelParameters.fromJson(Map<String, dynamic> json) =>
      ModelParameters(
        temperature: json['temperature'] ?? 0.8,
        topP: json['topP'] ?? 0.8,
        presencePenalty: json['presencePenalty'] ?? 0.0,
        frequencyPenalty: json['frequencyPenalty'] ?? 0.0,
        maxTokens: json['maxTokens'] ?? 4096,
        enableContextLimit: json['enableContextLimit'] ?? false,
        contextTurns: json['contextTurns'] ?? 50,
      );
}

class GroupCharacter {
  final String? avatarBase64; // 修改为base64
  final String name; // 角色名称
  final String setting; // 角色设定

  GroupCharacter({
    this.avatarBase64, // 修改为base64
    required this.name,
    required this.setting,
  });

  Map<String, dynamic> toJson() => {
        'avatarBase64': avatarBase64, // 修改为base64
        'name': name,
        'setting': setting,
      };

  factory GroupCharacter.fromJson(Map<String, dynamic> json) => GroupCharacter(
        avatarBase64: json['avatarBase64'] as String?, // 修改为base64
        name: json['name'] as String,
        setting: json['setting'] as String,
      );
}

class CharacterCard {
  final String code; // 专属编码
  final String title; // 作品名称
  final String description; // 简介
  final List<String> tags; // 标签
  final String setting; // 设定
  final String userSetting; // 用户设定
  final ChatType chatType; // 类型(单人/群聊)
  final StatusBarType statusBarType; // 状态栏类型
  final String? statusBar; // 状态栏内容
  final String? coverImageBase64; // 修改为base64
  final String? backgroundImageBase64; // 修改为base64
  final String? avatarBase64; // 添加头像属性
  final String modelName; // 模型选择
  final ModelParameters modelParams; // 模型参数
  final List<GroupCharacter> groupCharacters; // 群聊角色列表
  // 聊天界面样式
  final Color aiBubbleColor; // AI气泡颜色
  final Color aiTextColor; // AI文字颜色
  final Color userBubbleColor; // 用户气泡颜色
  final Color userTextColor; // 用户文字颜色
  final double backgroundOpacity; // 背景透明度
  final String? openingMessage; // 开场白
  final String? authorId; // 作者ID
  final bool hideSettings; // 是否隐藏设定

  bool get isGroup => chatType == ChatType.group; // 添加 isGroup getter

  CharacterCard({
    required this.code,
    required this.title,
    required this.description,
    required this.tags,
    required this.setting,
    required this.userSetting,
    required this.chatType,
    this.statusBarType = StatusBarType.none,
    this.statusBar,
    this.coverImageBase64,
    this.backgroundImageBase64,
    this.avatarBase64,
    required this.modelName,
    required this.modelParams,
    required this.groupCharacters,
    this.aiBubbleColor = const Color(0xFFFFFFFF), // 纯白色
    this.aiTextColor = const Color(0xFF000000), // 纯黑色
    this.userBubbleColor = const Color(0xFF000000), // 纯黑色
    this.userTextColor = const Color(0xFFFFFFFF), // 纯白色
    this.backgroundOpacity = 0.0,
    this.openingMessage, // 开场白
    this.authorId, // 作者ID
    this.hideSettings = false, // 是否隐藏设定，默认为false
  });

  // 生成专属编码
  static String generateCode(String title, String userId, DateTime timestamp) {
    final input = '$title$userId${timestamp.millisecondsSinceEpoch}';
    final bytes = utf8.encode(input);
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 16); // 取前16位作为编码
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'title': title,
        'description': description,
        'tags': tags,
        'setting': setting,
        'userSetting': userSetting,
        'chatType': chatType.toString(),
        'statusBarType': statusBarType.toString(),
        'statusBar': statusBar,
        'coverImageBase64': coverImageBase64,
        'backgroundImageBase64': backgroundImageBase64,
        'avatarBase64': avatarBase64,
        'modelName': modelName,
        'modelParams': modelParams.toJson(),
        'groupCharacters': groupCharacters.map((c) => c.toJson()).toList(),
        'aiBubbleColor': aiBubbleColor.value,
        'aiTextColor': aiTextColor.value,
        'userBubbleColor': userBubbleColor.value,
        'userTextColor': userTextColor.value,
        'backgroundOpacity': backgroundOpacity,
        'openingMessage': openingMessage, // 开场白
        'authorId': authorId, // 作者ID
        'hideSettings': hideSettings, // 是否隐藏设定
      };

  factory CharacterCard.fromJson(Map<String, dynamic> json) => CharacterCard(
        code: json['code'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        tags: List<String>.from(json['tags'] as List),
        setting: json['setting'] as String,
        userSetting: json['userSetting'] as String,
        chatType: ChatType.values.firstWhere(
          (e) => e.toString() == json['chatType'],
          orElse: () => ChatType.single,
        ),
        statusBarType: StatusBarType.values.firstWhere(
          (e) => e.toString() == json['statusBarType'],
          orElse: () => StatusBarType.none,
        ),
        statusBar: json['statusBar'] as String?,
        coverImageBase64: json['coverImageBase64'] as String?,
        backgroundImageBase64: json['backgroundImageBase64'] as String?,
        avatarBase64: json['avatarBase64'] as String?,
        modelName: json['modelName'] as String,
        modelParams: ModelParameters.fromJson(
            json['modelParams'] as Map<String, dynamic>),
        groupCharacters: (json['groupCharacters'] as List)
            .map((e) => GroupCharacter.fromJson(e as Map<String, dynamic>))
            .toList(),
        aiBubbleColor: Color(json['aiBubbleColor'] as int? ?? 0xFFFFFFFF),
        aiTextColor: Color(json['aiTextColor'] as int? ?? 0xFF000000),
        userBubbleColor: Color(json['userBubbleColor'] as int? ?? 0xFF000000),
        userTextColor: Color(json['userTextColor'] as int? ?? 0xFFFFFFFF),
        backgroundOpacity:
            (json['backgroundOpacity'] as num?)?.toDouble() ?? 0.0,
        openingMessage: json['openingMessage'] as String?, // 开场白
        authorId: json['authorId'] as String?, // 作者ID
        hideSettings: json['hideSettings'] as bool? ?? false, // 是否隐藏设定
      );
}
