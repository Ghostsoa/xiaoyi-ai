import 'package:flutter/material.dart';
import 'dart:convert';
import '../chat_v2/agent_chat_page.dart';
import '../chat_v2/session_init_page.dart';
import '../../net/session/session_service.dart';
import '../../components/loading_overlay.dart';
import '../../components/custom_snack_bar.dart';

class WorldCardDetailPage extends StatelessWidget {
  final Map<String, dynamic> cardData;

  const WorldCardDetailPage({
    super.key,
    required this.cardData,
  });

  List<String> _parseTags(dynamic tags) {
    if (tags == null) return [];
    if (tags is List) return tags.map((e) => e.toString()).toList();
    if (tags is String) {
      if (tags.isEmpty) return [];
      return tags
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final card = cardData;
    final tags = _parseTags(card['tags']);
    final String instruction = card['instruction']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.8),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                ],
              ),
            ),
          ),
          // 内容区域
          Positioned.fill(
            bottom: 90, // 为底部按钮留出空间
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 头像和基本信息
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 封面图
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: Builder(
                            builder: (context) {
                              if (card['cover_base64'] != null &&
                                  card['cover_base64'].toString().isNotEmpty) {
                                try {
                                  final bytes = base64.decode(
                                      card['cover_base64']
                                          .toString()
                                          .split(',')
                                          .last);
                                  return Image.memory(
                                    bytes,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildErrorContainer();
                                    },
                                  );
                                } catch (e) {
                                  return _buildErrorContainer();
                                }
                              }
                              return _buildErrorContainer();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // 基本信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    card['name'] ?? '未命名',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: card['status'] == 1
                                        ? Colors.orange.withOpacity(0.2)
                                        : Colors.green.withOpacity(0.2),
                                  ),
                                  child: Text(
                                    card['status'] == 1 ? '预览' : '正式',
                                    style: TextStyle(
                                      color: card['status'] == 1
                                          ? Colors.orange
                                          : Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '@${card['author_name'] ?? '未知作者'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (card['model_name'] != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.psychology_outlined,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    card['model_name'],
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            if (card['chat_count'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${card['chat_count']} 次对话',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 标签
                  if (tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 简介和激励按钮
                  if (card['description'] != null &&
                      card['description'].toString().isNotEmpty) ...[
                    Row(
                      children: [
                        const Text(
                          '简介',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            // TODO: 处理激励作者
                          },
                          icon: const Icon(
                            Icons.monetization_on_outlined,
                            size: 16,
                            color: Color(0xFFFFD700),
                          ),
                          label: const Text(
                            '激励作者',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 14,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        card['description'].toString(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 使用说明部分
                  if (instruction.isNotEmpty) ...[
                    const Text(
                      '使用说明',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      instruction,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // 返回按钮
          Positioned(
            left: 16,
            top: 40,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // 固定在底部的开始探索按钮
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final sessionService = SessionService();
                    try {
                      final response = await LoadingOverlay.show(
                        context,
                        future: () => sessionService.createSession(
                          card['id'],
                          title: card['name'],
                        ),
                      );

                      if (response['code'] == 200) {
                        final sessionData = response['data'];
                        print('初始化字段: ${sessionData['init_fields']}');
                        print('会话状态: ${sessionData['status']}');

                        // 预加载背景图片
                        if (sessionData['background_base64'] != null) {
                          final imageData = base64Decode(
                              sessionData['background_base64']
                                  .toString()
                                  .replaceFirst(
                                      RegExp(r'data:image/[^;]+;base64,'), ''));
                          await precacheImage(
                            MemoryImage(imageData),
                            context,
                          );
                        }

                        if (context.mounted) {
                          if (sessionData['status'].toString() == '0') {
                            // 未初始化，跳转到初始化页面
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SessionInitPage(
                                  sessionId: sessionData['id'],
                                  sessionName: card['name'] ?? '会话初始化',
                                  initFields: List<String>.from(
                                      sessionData['init_fields']),
                                  coverBase64: sessionData['cover_base64'],
                                  backgroundBase64:
                                      sessionData['background_base64'],
                                ),
                              ),
                            );
                          } else {
                            // 不需要初始化，直接跳转到聊天页面
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AgentChatPage(
                                  sessionId: sessionData['id'],
                                  sessionName: card['name'] ?? '未命名',
                                  backgroundBase64:
                                      sessionData['background_base64'],
                                ),
                              ),
                            );
                          }
                        }
                      } else {
                        final errorMessage = response['message'] ?? '创建会话失败';
                        final errorDetail = response['error'];
                        final fullError = errorDetail != null
                            ? '$errorMessage：$errorDetail'
                            : errorMessage;
                        throw fullError;
                      }
                    } catch (e) {
                      if (context.mounted) {
                        CustomSnackBar.show(
                          context,
                          message: e.toString().replaceFirst('Exception: ', ''),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 8,
                    shadowColor:
                        Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '开始探索',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContainer() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: Colors.white54,
        ),
      ),
    );
  }
}
