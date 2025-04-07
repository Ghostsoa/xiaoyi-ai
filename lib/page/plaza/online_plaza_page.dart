import 'package:flutter/material.dart';
import '../../model/online_role_card.dart';
import '../../net/role_card/online_role_card_service.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'online_role_card_detail_page.dart';

// 导入自定义组件
import '../../components/plaza/plaza_search_bar.dart';
import '../../components/plaza/plaza_category_bar.dart';
import '../../components/plaza/role_card_item.dart';
import '../../components/plaza/skeleton_card_item.dart';
import '../../components/plaza/plaza_empty_state.dart';

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
  bool _isInitialLoading = false; // 初始加载状态
  bool _isPaginationLoading = false; // 分页加载状态
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
    if (_isInitialLoading || _isPaginationLoading) return;

    setState(() {
      _isInitialLoading = true; // 设置为加载状态
      _cards = []; // 清空现有数据，显示骨架屏
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
          _isInitialLoading = false;
        });
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _isInitialLoading = false;
        });
        _refreshController.refreshFailed();
      }
    }
  }

  Future<void> _onLoading() async {
    if (_isInitialLoading || _isPaginationLoading || _cards.length >= _total) {
      _refreshController.loadComplete();
      return;
    }

    setState(() {
      _isPaginationLoading = true;
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
          _isPaginationLoading = false;
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
          _isPaginationLoading = false;
        });
        _refreshController.loadFailed();
      }
    }
  }

  void _handleCategoryChanged(String? category) {
    if (_currentCategory != category) {
      setState(() {
        _currentCategory = category;
        // 不清空卡片，提供无缝体验
        _currentPage = 1;
      });
      _onRefresh();
    }
  }

  void _handleSortChanged(String sortBy) {
    if (_sortBy != sortBy) {
      setState(() {
        _sortBy = sortBy;
        // 不清空卡片，提供无缝体验
        _currentPage = 1;
      });
      _onRefresh();
    }
  }

  void _handleSearch(String value) {
    setState(() {
      // 不清空卡片，提供无缝体验
      _currentPage = 1;
    });
    _onRefresh();
  }

  void _navigateToDetail(OnlineRoleCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnlineRoleCardDetailPage(card: card),
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
                        PlazaSearchBar(
                          controller: _searchController,
                          onSubmitted: _handleSearch,
                        ),
                        // 分类和排序区域
                        PlazaCategoryBar(
                          currentCategory: _currentCategory,
                          sortBy: _sortBy,
                          onCategoryChanged: _handleCategoryChanged,
                          onSortChanged: _handleSortChanged,
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
                      child: _isInitialLoading && _cards.isEmpty
                          ? ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: 5,
                              itemBuilder: (context, index) =>
                                  const SkeletonCardItem(),
                            )
                          : _cards.isEmpty && !_isInitialLoading
                              ? PlazaEmptyState(
                                  isLoading: _isInitialLoading,
                                  isError: _isError,
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _cards.length,
                                  itemBuilder: (context, index) {
                                    return RoleCardItem(
                                      card: _cards[index],
                                      onTap: _navigateToDetail,
                                    );
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
}
