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
  List<CharacterCard> _filteredCards = [];
  bool _isLoading = true;

  // 分类相关
  String _currentCategory = '全部';
  final List<String> _categories = ['全部', '男性', '女性', '其他'];

  // 男性相关标签
  final List<String> _maleTags = [
    '男性',
    '男',
    '男性向',
    '男生',
    '帅哥',
    '少年',
    '男孩',
    '男主'
  ];

  // 女性相关标签
  final List<String> _femaleTags = [
    '女性',
    '女',
    '女性向',
    '女生',
    '美女',
    '少女',
    '女孩',
    '女主'
  ];

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
          _filterCards();
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

  // 根据当前分类筛选角色卡
  void _filterCards() {
    if (_cards == null) return;

    setState(() {
      if (_currentCategory == '全部') {
        _filteredCards = List.from(_cards!);
      } else if (_currentCategory == '男性') {
        _filteredCards = _cards!.where((card) {
          return card.tags.any((tag) => _maleTags.contains(tag));
        }).toList();
      } else if (_currentCategory == '女性') {
        _filteredCards = _cards!.where((card) {
          return card.tags.any((tag) => _femaleTags.contains(tag));
        }).toList();
      } else {
        // 其他
        _filteredCards = _cards!.where((card) {
          return !card.tags.any(
              (tag) => _maleTags.contains(tag) || _femaleTags.contains(tag));
        }).toList();
      }
    });
  }

  // 更改当前分类
  void _changeCategory(String category) {
    setState(() {
      _currentCategory = category;
      _filterCards();
    });
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

    return Column(
      children: [
        // 分类选项卡
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _buildCategoryTabs(),
        ),
        // 角色卡列表
        Expanded(
          child: _cards == null || _cards!.isEmpty
              ? _buildEmptyView()
              : _filteredCards.isEmpty
                  ? _buildNoCategoryMatchView()
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _filteredCards.length,
                      itemBuilder: (context, index) {
                        final card = _filteredCards[index];
                        return _buildCharacterCard(card);
                      },
                    ),
        ),
      ],
    );
  }

  // 构建分类选项卡
  Widget _buildCategoryTabs() {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: _categories.map((category) {
          final isSelected = category == _currentCategory;
          // 根据分类设置颜色
          Color activeColor;

          switch (category) {
            case '男性':
              activeColor = const Color(0xFF5C9CE6); // 蓝色
              break;
            case '女性':
              activeColor = const Color(0xFFE667AF); // 粉色
              break;
            case '其他':
              activeColor = const Color(0xFFAA88FF); // 紫色
              break;
            default:
              activeColor = const Color(0xFF4CAF50); // 绿色
          }

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () => _changeCategory(category),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? activeColor
                            : Colors.white.withOpacity(0.6),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // 下划线指示器
                  Container(
                    height: 2,
                    width: category.length * 14.0, // 根据文字长度自适应宽度
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 构建没有匹配分类的视图
  Widget _buildNoCategoryMatchView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _currentCategory == '男性'
                ? Icons.male
                : _currentCategory == '女性'
                    ? Icons.female
                    : Icons.help_outline,
            size: 64,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            '没有$_currentCategory角色',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '尝试添加不同的角色或更改筛选条件',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
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
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 3,
                                runSpacing: 3,
                                children: card.tags.take(3).map((tag) {
                                  // 根据标签类型设置不同的颜色
                                  Color tagColor = Colors.blueGrey;

                                  if (_maleTags.contains(tag)) {
                                    tagColor = const Color(0xFF5C9CE6); // 蓝色系
                                  } else if (_femaleTags.contains(tag)) {
                                    tagColor = const Color(0xFFE667AF); // 粉色系
                                  } else if (tag.contains('温柔') ||
                                      tag.contains('可爱') ||
                                      tag.contains('治愈')) {
                                    tagColor = const Color(0xFF68D391); // 绿色系
                                  } else if (tag.contains('暗黑') ||
                                      tag.contains('恐怖') ||
                                      tag.contains('血腥')) {
                                    tagColor = const Color(0xFFE53E3E); // 红色系
                                  }

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tagColor.withOpacity(0.15),
                                      border: Border.all(
                                        color: tagColor.withOpacity(0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_maleTags.contains(tag))
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(right: 2),
                                            child: Icon(
                                              Icons.male,
                                              color: tagColor.withOpacity(0.9),
                                              size: 8,
                                            ),
                                          )
                                        else if (_femaleTags.contains(tag))
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(right: 2),
                                            child: Icon(
                                              Icons.female,
                                              color: tagColor.withOpacity(0.9),
                                              size: 8,
                                            ),
                                          ),
                                        Text(
                                          tag,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              // 如果标签超过3个，显示+X
                              if (card.tags.length > 3)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '+${card.tags.length - 3}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
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
