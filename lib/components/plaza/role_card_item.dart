import 'package:flutter/material.dart';
import '../../model/online_role_card.dart';
import '../../components/cached_network_image.dart';
import '../plaza/shimmer_effect.dart';

class RoleCardItem extends StatelessWidget {
  final OnlineRoleCard card;
  final Function(OnlineRoleCard) onTap;

  const RoleCardItem({
    super.key,
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(card),
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
              child: Hero(
                tag: 'card_cover_${card.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: card.coverUrl,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ShimmerEffect(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 24,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
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
                          card.title,
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
                          color: card.category == 'single'
                              ? const Color(0xFF1E90FF)
                              : const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (card.category == 'single'
                                      ? const Color(0xFF1E90FF)
                                      : const Color(0xFFFFD700))
                                  .withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              card.category == 'single'
                                  ? Icons.person_outline
                                  : Icons.people_outline,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              card.category == 'single' ? '单人' : '多人',
                              style: const TextStyle(
                                color: Colors.white,
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
                    card.description,
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
                    child: card.tags.isNotEmpty && card.tags.first.isNotEmpty
                        ? Wrap(
                            spacing: 8,
                            children: card.tags
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
                          '@${card.authorName.length > 6 ? '${card.authorName.substring(0, 6)}...' : card.authorName}',
                        ),
                        const SizedBox(width: 12),
                        // 时间
                        Text(_formatTime(card.createdAt)),
                        const SizedBox(width: 12),
                        // 下载量
                        Row(
                          children: [
                            Icon(
                              Icons.download_outlined,
                              size: 12,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(card.downloads.toString()),
                          ],
                        ),
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else if (time.year == now.year) {
      return '${time.month}月${time.day}日';
    } else {
      return '${time.year}年${time.month}月${time.day}日';
    }
  }
}
