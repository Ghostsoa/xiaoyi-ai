import 'package:flutter/material.dart';
import '../../model/online_role_card.dart';
import '../../components/cached_network_image.dart';
import '../plaza/shimmer_effect.dart';

class UserRoleCardItem extends StatelessWidget {
  final OnlineRoleCard card;
  final Function(OnlineRoleCard) onTap;
  final Function(OnlineRoleCard) onDelete;
  final Function(OnlineRoleCard, int)? onToggleStatus;

  const UserRoleCardItem({
    super.key,
    required this.card,
    required this.onTap,
    required this.onDelete,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isPublic = card.status == 1;

    return InkWell(
      onTap: () => onTap(card),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧小图
            SizedBox(
              width: 70,
              height: 70,
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
            const SizedBox(width: 8),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 删除按钮
                      InkWell(
                        onTap: () => onDelete(card),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red.withOpacity(0.9),
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '删除',
                                style: TextStyle(
                                  color: Colors.red.withOpacity(0.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // 简介
                  Text(
                    card.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 标签显示 - 如果有标签的话
                  if (card.tags.isNotEmpty && card.tags.first.isNotEmpty)
                    SizedBox(
                      height: 14,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: card.tags
                            .where((tag) => tag.isNotEmpty)
                            .take(3) // 显示前三个标签
                            .map((tag) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    '#$tag',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 10,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 4),
                  // 底部信息
                  DefaultTextStyle(
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                    child: Row(
                      children: [
                        // 切换可见性按钮
                        if (onToggleStatus != null)
                          InkWell(
                            onTap: () =>
                                onToggleStatus!(card, isPublic ? 0 : 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isPublic
                                    ? Colors.green.withOpacity(0.8)
                                    : Colors.orange.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPublic
                                        ? Icons.public
                                        : Icons.lock_outline,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    isPublic ? '公开' : '非公开',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.swap_horiz,
                                    color: Colors.white,
                                    size: 9,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isPublic
                                  ? Colors.green.withOpacity(0.8)
                                  : Colors.orange.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPublic ? Icons.public : Icons.lock_outline,
                                  color: Colors.white,
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  isPublic ? '公开' : '非公开',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 8),
                        // 类型
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: card.category == 'single'
                                ? const Color(0xFF1E90FF) // 单人用蓝色
                                : const Color(0xFFFFD700), // 多人用黄色
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: (card.category == 'single'
                                        ? const Color(0xFF1E90FF)
                                        : const Color(0xFFFFD700))
                                    .withOpacity(0.3),
                                blurRadius: 3,
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
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                card.category == 'single' ? '单人' : '多人',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 下载量
                        Row(
                          children: [
                            Icon(
                              Icons.download_outlined,
                              size: 10,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(width: 2),
                            Text(card.downloads.toString()),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // 时间
                        Expanded(
                          child: Text(
                            _formatTime(card.createdAt),
                            overflow: TextOverflow.ellipsis,
                          ),
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

  // 复用大厅中的时间格式化函数
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
