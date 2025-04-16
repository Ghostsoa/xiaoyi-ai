import 'package:flutter/material.dart';
import 'dart:convert';

class WorldCardItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function() onTap;

  const WorldCardItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String name = item['name'] as String? ?? '';
    final String description = item['description'] as String? ?? '';
    final String tags = item['tags'] as String? ?? '';
    final String? coverBase64 = item['cover_base64'] as String?;
    final int status = item['status'] as int? ?? 1;
    final String authorName = item['author_name'] as String? ?? '';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧小图
            SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  color: Colors.white.withOpacity(0.1),
                  child: coverBase64 != null && coverBase64.isNotEmpty
                      ? Image.memory(
                          base64Decode(coverBase64.split(',').last),
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.image_not_supported_outlined,
                          size: 24,
                          color: Colors.white.withOpacity(0.3),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 右侧内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题行
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 标题
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 类型标签
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: status == 1
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              status == 1
                                  ? Icons.preview_outlined
                                  : Icons.check_circle_outline,
                              color: status == 1 ? Colors.orange : Colors.green,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              status == 1 ? '预览' : '正式',
                              style: TextStyle(
                                color:
                                    status == 1 ? Colors.orange : Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 简介
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 标签区域（固定高度）
                  SizedBox(
                    height: 16,
                    child: tags.isNotEmpty
                        ? Wrap(
                            spacing: 8,
                            children: tags
                                .split(',')
                                .where((tag) => tag.isNotEmpty)
                                .take(2)
                                .map((tag) => Text(
                                      '#$tag',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 9,
                                      ),
                                    ))
                                .toList(),
                          )
                        : null,
                  ),
                  const SizedBox(height: 4),
                  // 底部信息
                  DefaultTextStyle(
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                    child: Row(
                      children: [
                        // 作者（最多显示6个字符）
                        Text(
                          '@${authorName.length > 6 ? '${authorName.substring(0, 6)}...' : authorName}',
                        ),
                        // 如果有聊天数量，显示分隔点和聊天数量
                        if (item['chat_count'] != null) ...[
                          Text(' · '),
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 10,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(width: 3),
                          Text('${item['chat_count']}'),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
