import 'package:flutter/material.dart';
import '../../model/character_card.dart';
import '../../service/character_card_service.dart';
import '../../service/image_service.dart';
import 'character_edit_page.dart';
import 'character_detail_page.dart';
import '../../service/chat_history_service.dart';
import '../../service/chat_list_service.dart';
import '../../components/custom_snack_bar.dart';
import '../../net/role_card/role_card_service.dart';
import '../../components/loading_overlay.dart';

class LocalPlazaPage extends StatefulWidget {
  final CharacterCardService characterCardService;
  final ChatHistoryService chatHistoryService;
  final ChatListService chatListService;

  const LocalPlazaPage({
    super.key,
    required this.characterCardService,
    required this.chatHistoryService,
    required this.chatListService,
  });

  @override
  State<LocalPlazaPage> createState() => LocalPlazaPageState();
}

class LocalPlazaPageState extends State<LocalPlazaPage> {
  List<CharacterCard>? _cards;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> refreshCards() async {
    await _loadCards();
  }

  Future<void> _loadCards() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cards = await widget.characterCardService.getAllCards();
      if (mounted) {
        setState(() {
          _cards = cards;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              '正在加载角色卡...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return _cards == null || _cards!.isEmpty
        ? _buildEmptyView()
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _cards!.length,
            itemBuilder: (context, index) {
              final card = _cards![index];
              return _buildCharacterCard(card);
            },
          );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无本地角色',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击顶部按钮创建新角色',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard(CharacterCard card) {
    return Stack(
      children: [
        Card(
          color: Colors.white.withOpacity(0.1),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CharacterDetailPage(
                        card: card,
                        chatHistoryService: widget.chatHistoryService,
                        chatListService: widget.chatListService,
                      ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    if (card.coverImageBase64 != null)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: ImageService.imageFromBase64String(
                            card.coverImageBase64!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              card.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (card.tags.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: card.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 右上角更多按钮
              Positioned(
                right: 4,
                top: 4,
                child: Material(
                  color: Colors.transparent,
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    color: Colors.black87,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, color: Colors.white70),
                            SizedBox(width: 8),
                            Text(
                              '编辑',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'upload',
                        child: Row(
                          children: [
                            Icon(Icons.cloud_upload_outlined,
                                color: Colors.white70),
                            SizedBox(width: 8),
                            Text(
                              '上传到大厅',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              '删除',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CharacterEditPage(
                              characterCardService: widget.characterCardService,
                              card: card,
                            ),
                          ),
                        );
                        if (result == true) {
                          _loadCards();
                        }
                      } else if (value == 'upload') {
                        try {
                          final roleCardService = RoleCardService();
                          // 根据角色卡类型判断分类
                          final category = card.chatType == ChatType.single
                              ? 'single'
                              : 'multi';

                          final result = await LoadingOverlay.show(
                            context,
                            text: '上传中',
                            future: () =>
                                roleCardService.uploadCard(card, category),
                          );

                          if (result['code'] == 200) {
                            CustomSnackBar.show(context, message: '上传成功');
                          } else {
                            CustomSnackBar.show(context,
                                message: result['msg'] ?? '上传失败');
                          }
                        } catch (e) {
                          CustomSnackBar.show(context, message: '上传失败: $e');
                        }
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.black87,
                            title: const Text(
                              '确认删除',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              '确定要删除这个角色卡吗？此操作将同时删除该角色的所有消息和对话记录，且不可恢复。',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text(
                                  '取消',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text(
                                  '删除',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            // 删除角色卡
                            await widget.characterCardService
                                .deleteCard(card.code);
                            // 删除消息列表项
                            await widget.chatListService.deleteItem(card.code);
                            // 删除对话历史
                            await widget.chatHistoryService
                                .clearHistory(card.code);

                            _loadCards();
                            if (mounted) {
                              CustomSnackBar.show(context, message: '删除成功');
                            }
                          } catch (e) {
                            if (mounted) {
                              CustomSnackBar.show(context, message: '删除失败: $e');
                            }
                          }
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // 左侧突出的单人/多人标记
        Positioned(
          left: -2,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: card.chatType == ChatType.single
                  ? const Color(0xFF1E90FF)
                  : const Color(0xFFFFD700),
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: (card.chatType == ChatType.single
                          ? const Color(0xFF1E90FF)
                          : const Color(0xFFFFD700))
                      .withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              card.chatType == ChatType.single ? '单人' : '多人',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
