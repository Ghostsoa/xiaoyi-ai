import 'package:flutter/material.dart';
import 'publish_card_page.dart';
import '../../net/agent/agent_card_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../components/loading_overlay.dart';
import '../../components/custom_snack_bar.dart';
import '../worldbook/worldbook_list_page.dart';
import 'instruction_page.dart';

class CreationCenterPage extends StatefulWidget {
  const CreationCenterPage({super.key});

  @override
  State<CreationCenterPage> createState() => _CreationCenterPageState();
}

class _CreationCenterPageState extends State<CreationCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _agentCardService = AgentCardService();

  List<Map<String, dynamic>> _creationItems = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadCreationItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCreationItems() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _agentCardService.getMyCards();
      setState(() {
        _creationItems = result.list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 创作按钮行
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.add_circle_outline,
                  label: '发布卡',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PublishCardPage(),
                      ),
                    ).then((_) {
                      // 当用户从发布页面返回时刷新列表
                      _loadCreationItems();
                    });
                  },
                ),
                _buildActionButton(
                  icon: Icons.book_outlined,
                  label: '编辑世界书',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const WorldbookListPage(isEditMode: true),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.menu_book_outlined,
                  label: '必读说明',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InstructionPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 我的创作标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '我的创作',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadCreationItems,
                ),
            ],
          ),

          const SizedBox(height: 12),

          // 创作列表
          Expanded(
            child: _isLoading && _creationItems.isEmpty
                ? ListView.builder(
                    itemCount: 3,
                    itemBuilder: (context, index) => _buildSkeletonItem(),
                  )
                : _error != null && _creationItems.isEmpty
                    ? _buildErrorState()
                    : _creationItems.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _creationItems.length,
                            itemBuilder: (context, index) {
                              final item = _creationItems[index];
                              return _buildCreationItem(item);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '未知错误',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _loadCreationItems,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCreationItem(Map<String, dynamic> item) {
    final status = item['status'] as int;
    final DateTime updatedAt = DateTime.parse(item['updated_at']);
    final String? coverBase64 = item['cover_base64'] as String?;
    final String name = item['name'] as String;
    final String description = item['description'] as String? ?? '';
    final dynamic tagsData = item['tags'];
    final int id = item['id'] as int;

    // 处理base64图片数据
    Uint8List? imageBytes;
    if (coverBase64 != null && coverBase64.isNotEmpty) {
      try {
        final startIndex = coverBase64.indexOf(',');
        if (startIndex != -1) {
          final actualBase64 = coverBase64.substring(startIndex + 1);
          imageBytes = base64Decode(actualBase64);
        } else {
          imageBytes = base64Decode(coverBase64);
        }
      } catch (e) {
        print('解码base64图片失败: $e');
      }
    }

    return InkWell(
      onTap: () async {
        try {
          final detail = await LoadingOverlay.show(
            context,
            future: () => _agentCardService.getCardDetail(id),
          );

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PublishCardPage(
                  isEdit: true,
                  cardDetail: detail,
                ),
              ),
            ).then((_) {
              // 编辑完成后刷新列表
              _loadCreationItems();
            });
          }
        } catch (e) {
          if (mounted) {
            CustomSnackBar.show(
              context,
              message: e.toString(),
            );
          }
        }
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 封面图片
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 96,
                    height: 96,
                    color: Colors.white.withOpacity(0.05),
                    child: imageBytes != null
                        ? Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.image_outlined,
                            size: 32,
                            color: Colors.white.withOpacity(0.3),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // 内容区域
                Expanded(
                  child: SizedBox(
                    height: 96,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // 名称和状态 - 占1行
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              status == 1 ? '预览' : '正式',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    status == 1 ? Colors.orange : Colors.green,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // 简介 - 占2行
                        Text(
                          description.isNotEmpty ? description : '暂无描述',
                          style: TextStyle(
                            fontSize: 13,
                            color: description.isNotEmpty
                                ? Colors.white.withOpacity(0.7)
                                : Colors.white.withOpacity(0.3),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // 标签和时间行
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // 标签
                              Expanded(
                                child: _buildTags(tagsData),
                              ),
                              // 聊天数量
                              if (item['chat_count'] != null) ...[
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${item['chat_count']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              // 时间和删除按钮
                              Text(
                                _formatDate(updatedAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon:
                                    const Icon(Icons.delete_outline, size: 16),
                                color: Colors.white.withOpacity(0.5),
                                onPressed: () async {
                                  // 显示确认对话框
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: Colors.grey[900],
                                      title: const Text(
                                        '确认删除',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: Text(
                                        '确定要删除"$name"吗？此操作不可恢复。',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            '删除',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true && mounted) {
                                    try {
                                      final (success, message) =
                                          await LoadingOverlay.show(
                                        context,
                                        future: () => _agentCardService
                                            .deleteAgentCard(id),
                                      );

                                      if (mounted) {
                                        CustomSnackBar.show(
                                          context,
                                          message: message,
                                        );
                                        if (success) {
                                          _loadCreationItems();
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        CustomSnackBar.show(
                                          context,
                                          message: e.toString(),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonItem() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 骨架图片
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 96,
                  height: 96,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
              const SizedBox(width: 12),

              // 骨架内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题骨架
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 描述骨架
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 16,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 标签骨架
                    Container(
                      height: 14,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // 时间骨架
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 14,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          height: 14,
                          width: 14,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: Colors.white.withOpacity(0.1),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.6),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.6),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.create_new_folder_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无创作内容',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击上方按钮开始创作',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags(dynamic tagsData) {
    // 处理标签数据，确保转换为List
    List<String> tags = [];
    if (tagsData is String) {
      if (tagsData.isNotEmpty) {
        tags = tagsData.split(',');
      }
    } else if (tagsData is List) {
      tags = tagsData.map((tag) => tag.toString()).toList();
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    final displayTags = tags.take(3).toList();
    final remainingCount = tags.length - displayTags.length;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ...displayTags.map((tag) {
          return Text(
            '#$tag',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          );
        }).toList(),
        if (remainingCount > 0)
          Text(
            '+$remainingCount',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '今天';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.month}-${date.day}';
    }
  }
}
