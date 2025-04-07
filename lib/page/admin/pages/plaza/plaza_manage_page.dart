import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../../../components/custom_snack_bar.dart';
import '../../../../model/online_role_card.dart';
import '../../../../net/role_card/online_role_card_service.dart';
import '../../../../components/cached_network_image.dart';

class PlazaManagePage extends StatefulWidget {
  const PlazaManagePage({super.key});

  @override
  State<PlazaManagePage> createState() => _PlazaManagePageState();
}

class _PlazaManagePageState extends State<PlazaManagePage> {
  final _roleCardService = OnlineRoleCardService();
  final RefreshController _refreshController = RefreshController();
  final _searchController = TextEditingController();

  List<OnlineRoleCard> _cards = [];
  int _total = 0;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _isLoading = false;
  bool _isError = false;
  final Set<int> _selectedCardIds = {};

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      _currentPage = 1;
      final result = await _roleCardService.getList(
        page: _currentPage,
        pageSize: _pageSize,
        query: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _cards = result.list;
          _total = result.total;
          _isLoading = false;
        });
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _isLoading = false;
        });
        _refreshController.refreshFailed();
        CustomSnackBar.show(context, message: '加载角色卡失败: $e');
      }
    }
  }

  Future<void> _onLoading() async {
    if (_isLoading || _cards.length >= _total) {
      _refreshController.loadComplete();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _roleCardService.getList(
        page: _currentPage + 1,
        pageSize: _pageSize,
        query: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _cards.addAll(result.list);
          _total = result.total;
          _currentPage++;
          _isLoading = false;
        });

        if (_cards.length >= _total) {
          _refreshController.loadNoData();
        } else {
          _refreshController.loadComplete();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _refreshController.loadFailed();
        CustomSnackBar.show(context, message: '加载更多角色卡失败: $e');
      }
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedCardIds.isEmpty) {
      CustomSnackBar.show(context, message: '请选择要删除的角色卡');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的${_selectedCardIds.length}个角色卡吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        // 逐个删除选中的角色卡
        for (final card
            in _cards.where((c) => _selectedCardIds.contains(c.id))) {
          await _roleCardService.deleteCard(card.code);
        }

        if (mounted) {
          _selectedCardIds.clear();
          CustomSnackBar.show(context, message: '角色卡删除成功');
          _loadCards(); // 重新加载列表
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          CustomSnackBar.show(context, message: '删除失败: $e');
        }
      }
    }
  }

  void _performSearch() {
    _loadCards();
  }

  Widget _buildCardItem(OnlineRoleCard card) {
    final isSelected = _selectedCardIds.contains(card.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blue.withOpacity(0.15)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? Colors.blue.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedCardIds.remove(card.id);
            } else {
              _selectedCardIds.add(card.id);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 复选框
              SizedBox(
                width: 24,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedCardIds.add(card.id);
                      } else {
                        _selectedCardIds.remove(card.id);
                      }
                    });
                  },
                  activeColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              // 封面图片
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: card.coverUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.5)),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white70,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 卡片信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题行
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            card.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
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
                            horizontal: 8,
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 描述
                    Text(
                      card.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // 作者信息和下载量
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          card.authorName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.download_outlined,
                          size: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${card.downloads}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const Spacer(),
                        // 删除按钮
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: '删除角色卡',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('确认删除'),
                                content:
                                    Text('确定要删除角色卡"${card.title}"吗？此操作不可恢复。'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('删除',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              try {
                                await _roleCardService.deleteCard(card.code);
                                if (mounted) {
                                  CustomSnackBar.show(context,
                                      message: '角色卡删除成功');
                                  _loadCards(); // 重新加载列表
                                }
                              } catch (e) {
                                if (mounted) {
                                  CustomSnackBar.show(context,
                                      message: '删除失败: $e');
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无角色卡',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _loadCards,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('刷新'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 工具栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '搜索角色卡',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.6)),
                          prefixIcon: Icon(Icons.search,
                              size: 20, color: Colors.white.withOpacity(0.7)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onSubmitted: (_) => _performSearch(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: _isLoading || _selectedCardIds.isEmpty
                          ? null
                          : _deleteSelected,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(
                        _selectedCardIds.isEmpty
                            ? '删除'
                            : '删除(${_selectedCardIds.length})',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        disabledBackgroundColor: Colors.white.withOpacity(0.05),
                        disabledForegroundColor: Colors.red.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 列表内容
          Expanded(
            child: _isLoading && _cards.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : _isError
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '加载失败',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _loadCards,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('重试'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _cards.isEmpty
                        ? _buildEmptyState()
                        : SmartRefresher(
                            controller: _refreshController,
                            enablePullDown: true,
                            enablePullUp: true,
                            onRefresh: _loadCards,
                            onLoading: _onLoading,
                            header: const WaterDropHeader(
                              waterDropColor: Colors.white,
                              complete: Text('刷新完成',
                                  style: TextStyle(color: Colors.white)),
                              failed: Text('刷新失败',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            footer: ClassicFooter(
                              loadingText: '加载中...',
                              canLoadingText: '加载更多',
                              noDataText: '没有更多数据',
                              failedText: '加载失败',
                              idleText: '上拉加载',
                              textStyle: const TextStyle(color: Colors.white),
                            ),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _cards.length,
                              itemBuilder: (context, index) {
                                return _buildCardItem(_cards[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
