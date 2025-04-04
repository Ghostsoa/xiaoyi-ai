import 'package:flutter/material.dart';
import '../../model/online_role_card.dart';
import '../../components/cached_network_image.dart';
import '../../components/custom_snack_bar.dart';
import '../../net/role_card/online_role_card_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dao/character_card_dao.dart';
import 'author_role_cards_page.dart';
import '../../components/loading_overlay.dart';

class OnlineRoleCardDetailPage extends StatefulWidget {
  final OnlineRoleCard card;

  const OnlineRoleCardDetailPage({
    super.key,
    required this.card,
  });

  @override
  State<OnlineRoleCardDetailPage> createState() =>
      _OnlineRoleCardDetailPageState();
}

class _OnlineRoleCardDetailPageState extends State<OnlineRoleCardDetailPage> {
  final _onlineRoleCardService = OnlineRoleCardService();

  Future<void> _importCard(BuildContext context) async {
    try {
      final characterCard = await LoadingOverlay.show(
        context,
        text: '导入中',
        future: () => _onlineRoleCardService.downloadCard(widget.card.code),
      );

      // 保存到本地
      final prefs = await SharedPreferences.getInstance();
      final characterCardDao = CharacterCardDao(prefs);
      await characterCardDao.saveCard(characterCard);

      if (mounted) {
        CustomSnackBar.show(context, message: '导入成功');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '导入失败: $e');
      }
    }
  }

  Future<void> _showRewardDialog() async {
    final amounts = [10, 50, 100];
    final selectedAmount = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          '激励作者',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择激励金额',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ...amounts.map((amount) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(amount),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.monetization_on_outlined,
                          size: 18,
                          color: Color(0xFFFFD700),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$amount 小懿币',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '取消',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );

    if (selectedAmount != null) {
      try {
        await _onlineRoleCardService.rewardCard(
            widget.card.code, selectedAmount);
        if (mounted) {
          CustomSnackBar.show(context, message: '激励成功');
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(context, message: '激励失败: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          child: CachedNetworkImage(
                            imageUrl: widget.card.coverUrl,
                            fit: BoxFit.cover,
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
                                    widget.card.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.card.category == 'single'
                                        ? const Color(0xFF1E90FF)
                                        : const Color(0xFFFFD700),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (widget.card.category == 'single'
                                                ? const Color(0xFF1E90FF)
                                                : const Color(0xFFFFD700))
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.card.category == 'single'
                                            ? Icons.person_outline
                                            : Icons.people_outline,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.card.category == 'single'
                                            ? '单人'
                                            : '多人',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '作者：${widget.card.authorName}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.download_outlined,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.card.downloads}次下载',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 作者其他作品按钮
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuthorRoleCardsPage(
                            authorId: widget.card.userId.toString(),
                            authorName: widget.card.authorName,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      '查看作者其他作品',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 标签
                  if (widget.card.tags.isNotEmpty) ...[
                    const Text(
                      '标签',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.card.tags
                          .where((tag) => tag.isNotEmpty)
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // 简介
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '角色简介',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _showRewardDialog,
                        icon: const Icon(
                          Icons.monetization_on_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          '激励作者',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFFFD700).withOpacity(0.2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          side: BorderSide(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.card.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 提示信息
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '导入后可查看',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem('• 完整的角色设定'),
                        _buildInfoItem('• 模型配置参数'),
                        _buildInfoItem('• 状态栏设置'),
                        _buildInfoItem('• 聊天界面样式'),
                        if (widget.card.category == 'multi')
                          _buildInfoItem('• 群聊角色配置'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 底部按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _importCard(context),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('导入角色卡'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 40,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }
}
