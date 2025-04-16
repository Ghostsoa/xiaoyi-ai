import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../net/agent/agent_card_service.dart';
import '../../components/world/world_card_item.dart';
import '../../components/world/world_skeleton_item.dart';
import '../../components/world/world_empty_state.dart';
import '../../components/world/world_search_bar.dart';
import 'world_card_detail_page.dart';
import 'dart:async';

class WorldPlazaPage extends StatefulWidget {
  const WorldPlazaPage({super.key});

  @override
  State<WorldPlazaPage> createState() => _WorldPlazaPageState();
}

class _WorldPlazaPageState extends State<WorldPlazaPage> {
  final _agentCardService = AgentCardService();
  final _refreshController = RefreshController();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _onlineItems = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 1;
  String _keyword = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _onRefresh();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _keyword = value;
      });
      _onRefresh();
    });
  }

  Future<void> _onLoading() async {
    if (_isLoading || !_hasMore) {
      _refreshController.loadComplete();
      return;
    }

    try {
      final result = await _agentCardService.getOnlineCards(
        page: _currentPage,
        pageSize: 10,
        keyword: _keyword.trim().isNotEmpty ? _keyword : null,
      );

      if (!mounted) return;

      setState(() {
        if (result.list.isNotEmpty) {
          _onlineItems.addAll(result.list);
          _hasMore = _onlineItems.length < result.total;
          _currentPage++;
        } else {
          _hasMore = false;
        }
        _isLoading = false;
      });

      if (_hasMore) {
        _refreshController.loadComplete();
      } else {
        _refreshController.loadNoData();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      _refreshController.loadFailed();
    }
  }

  Future<void> _onRefresh() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _onlineItems = [];
      _hasMore = true;
    });

    try {
      final result = await _agentCardService.getOnlineCards(
        page: _currentPage,
        pageSize: 10,
        keyword: _keyword.trim().isNotEmpty ? _keyword : null,
      );

      if (!mounted) return;

      setState(() {
        _onlineItems = result.list;
        if (_onlineItems.isEmpty) {
          _hasMore = false;
          _error = "暂无数据";
        } else {
          _hasMore = _onlineItems.length < result.total;
          _currentPage++;
        }
        _isLoading = false;
      });
      _refreshController.refreshCompleted();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      _refreshController.refreshFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索栏
          WorldSearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),

          // 列表内容
          Expanded(
            child: _error != null && _onlineItems.isEmpty
                ? WorldEmptyState(
                    isLoading: false,
                    isError: true,
                    errorMessage: _error,
                    onRetry: () => _onRefresh(),
                  )
                : _onlineItems.isEmpty && !_isLoading
                    ? WorldEmptyState(
                        isLoading: false,
                        isError: false,
                        onRetry: () => _onRefresh(),
                      )
                    : SmartRefresher(
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
                        child: ListView.builder(
                          itemCount: _isLoading && _onlineItems.isEmpty
                              ? 3
                              : _onlineItems.length,
                          itemBuilder: (context, index) {
                            if (_isLoading && _onlineItems.isEmpty) {
                              return const WorldSkeletonItem();
                            }

                            final item = _onlineItems[index];
                            if (item == null) return const SizedBox();

                            return WorldCardItem(
                              item: item,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        WorldCardDetailPage(cardData: item),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
