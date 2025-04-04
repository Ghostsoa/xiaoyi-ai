import 'package:flutter/material.dart';
import '../../model/online_role_card.dart';
import '../../net/role_card/online_role_card_service.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../components/cached_network_image.dart';
import 'online_role_card_detail_page.dart';

class OnlinePlazaPage extends StatefulWidget {
  const OnlinePlazaPage({super.key});

  @override
  State<OnlinePlazaPage> createState() => _OnlinePlazaPageState();
}

class _OnlinePlazaPageState extends State<OnlinePlazaPage> {
  final _onlineRoleCardService = OnlineRoleCardService();
  final _searchController = TextEditingController();
  final RefreshController _refreshController = RefreshController();

  List<OnlineRoleCard> _cards = [];
  int _total = 0;
  int _currentPage = 1;
  String? _currentCategory;
  String? _currentTag;
  String _sortBy = 'time';
  bool _isLoading = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _onRefresh();
  }

  Future<void> _onRefresh() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      _currentPage = 1;
      final result = await _onlineRoleCardService.getList(
        page: _currentPage,
        category: _currentCategory,
        tag: _currentTag,
        query: _searchController.text.trim(),
        sortBy: _sortBy,
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
      final result = await _onlineRoleCardService.getList(
        page: _currentPage + 1,
        category: _currentCategory,
        tag: _currentTag,
        query: _searchController.text.trim(),
        sortBy: _sortBy,
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
      }
    }
  }

  Widget _buildSkeletonItem() {
    return Container(
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
          // 左侧图片骨架
          Container(
            width: 80,
            height: 80,
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
          const SizedBox(width: 12),
          // 右侧内容骨架
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题骨架
                Row(
                  children: [
                    Expanded(
                      child: ShimmerEffect(
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 类型标签骨架
                    ShimmerEffect(
                      child: Container(
                        width: 40,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 简介骨架
                ShimmerEffect(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 标签骨架
                Row(
                  children: [
                    ShimmerEffect(
                      child: Container(
                        width: 40,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ShimmerEffect(
                      child: Container(
                        width: 40,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 底部信息骨架
                Row(
                  children: [
                    ShimmerEffect(
                      child: Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: true,
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final searchBarHeight = 36.0;
              final categoryBarHeight = 32.0;
              final paddingHeight = 24.0;
              final listHeight = constraints.maxHeight -
                  searchBarHeight -
                  categoryBarHeight -
                  paddingHeight;

              return Column(
                children: [
                  // 顶部搜索和分类区域
                  Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 搜索框
                        Container(
                          height: searchBarHeight,
                          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: '搜索作品名称、简介、标签、作者',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5)),
                              prefixIcon: Icon(Icons.search,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            onSubmitted: (value) {
                              setState(() {
                                _cards = [];
                                _currentPage = 1;
                              });
                              _onRefresh();
                            },
                          ),
                        ),
                        // 分类和排序区域
                        Container(
                          height: categoryBarHeight,
                          margin: const EdgeInsets.only(bottom: 0),
                          child: Row(
                            children: [
                              // 分类选择
                              Expanded(
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  children: [
                                    _buildCategoryChip('全部', null),
                                    _buildCategoryChip('单人', 'single'),
                                    _buildCategoryChip('多人', 'multi'),
                                  ],
                                ),
                              ),
                              // 排序按钮
                              Container(
                                margin: const EdgeInsets.only(right: 16),
                                child: Row(
                                  children: [
                                    _buildSortChip('最新', 'time'),
                                    const SizedBox(width: 12),
                                    _buildSortChip('最热', 'downloads'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 列表区域
                  SizedBox(
                    height: listHeight,
                    child: SmartRefresher(
                      controller: _refreshController,
                      enablePullDown: true,
                      enablePullUp: true,
                      header: WaterDropMaterialHeader(
                        backgroundColor: Theme.of(context).primaryColor,
                        color: Colors.white,
                      ),
                      footer: const ClassicFooter(
                        loadStyle: LoadStyle.ShowWhenLoading,
                        completeDuration: Duration(milliseconds: 500),
                        loadingText: '加载中...',
                        canLoadingText: '释放加载更多',
                        idleText: '上拉加载更多',
                        failedText: '加载失败，请重试',
                        noDataText: '没有更多数据了',
                        textStyle: TextStyle(color: Colors.white70),
                      ),
                      onRefresh: _onRefresh,
                      onLoading: _onLoading,
                      child: _isLoading && _currentPage == 1
                          ? ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: 5,
                              itemBuilder: (context, index) =>
                                  _buildSkeletonItem(),
                            )
                          : _cards.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _cards.length,
                                  itemBuilder: (context, index) {
                                    return _buildCardItem(_cards[index]);
                                  },
                                ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_isLoading) {
      return Container(
        height: MediaQuery.of(context).size.height - 100,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    if (_isError) {
      return Container(
        height: MediaQuery.of(context).size.height - 100,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '下拉刷新重试',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      height: MediaQuery.of(context).size.height - 100,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无在线角色卡',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '下拉刷新试试',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(OnlineRoleCard card) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OnlineRoleCardDetailPage(card: card),
          ),
        );
      },
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

  Widget _buildCategoryChip(String label, String? value) {
    final isSelected = _currentCategory == value;
    return Container(
      margin: const EdgeInsets.only(right: 24),
      child: InkWell(
        onTap: () {
          setState(() {
            _currentCategory = value;
            _cards = [];
            _currentPage = 1;
          });
          _onRefresh();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 12,
              height: 2,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () {
        setState(() {
          _sortBy = value;
          _cards = [];
          _currentPage = 1;
        });
        _onRefresh();
      },
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white60,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }
}

class ShimmerEffect extends StatefulWidget {
  final Widget child;

  const ShimmerEffect({
    super.key,
    required this.child,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
