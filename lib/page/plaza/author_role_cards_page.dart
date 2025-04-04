import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../model/online_role_card.dart';
import '../../net/role_card/online_role_card_service.dart';
import '../../components/custom_snack_bar.dart';
import '../../components/cached_network_image.dart';
import 'online_role_card_detail_page.dart';

class AuthorRoleCardsPage extends StatefulWidget {
  final String authorId;
  final String authorName;

  const AuthorRoleCardsPage({
    super.key,
    required this.authorId,
    required this.authorName,
  });

  @override
  State<AuthorRoleCardsPage> createState() => _AuthorRoleCardsPageState();
}

class _AuthorRoleCardsPageState extends State<AuthorRoleCardsPage> {
  final _onlineRoleCardService = OnlineRoleCardService();
  final RefreshController _refreshController = RefreshController();
  List<OnlineRoleCard>? _cards;
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _onlineRoleCardService.getAuthorRoleCards(
        widget.authorId,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (_currentPage == 1) {
            _cards = result.list;
          } else {
            _cards = [...?_cards, ...result.list];
          }
          _hasMore = _cards!.length < result.total;
          _isLoading = false;
        });
        _refreshController.refreshCompleted();
        if (!_hasMore) {
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
        _refreshController.refreshFailed();
        CustomSnackBar.show(context, message: e.toString());
      }
    }
  }

  Future<void> _onRefresh() async {
    _currentPage = 1;
    await _loadCards();
  }

  Future<void> _onLoading() async {
    if (!_hasMore) {
      _refreshController.loadNoData();
      return;
    }
    _currentPage++;
    await _loadCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
        child: Column(
          children: [
            // 自定义AppBar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.authorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '已发布 ${_cards?.length ?? 0} 个作品',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 内容区域
            Expanded(
              child: _isLoading && _currentPage == 1
                  ? const Center(child: CircularProgressIndicator())
                  : _cards == null || _cards!.isEmpty
                      ? Center(
                          child: Text(
                            '暂无作品',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
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
                            padding: const EdgeInsets.all(16),
                            itemCount: _cards!.length,
                            itemBuilder: (context, index) {
                              final card = _cards![index];
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          OnlineRoleCardDetailPage(card: card),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 封面图
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: SizedBox(
                                          width: 64,
                                          height: 64,
                                          child: CachedNetworkImage(
                                            imageUrl: card.coverUrl,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // 信息
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    card.title,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: card.category ==
                                                            'single'
                                                        ? const Color(
                                                            0xFF1E90FF)
                                                        : const Color(
                                                            0xFFFFD700),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: (card.category ==
                                                                    'single'
                                                                ? const Color(
                                                                    0xFF1E90FF)
                                                                : const Color(
                                                                    0xFFFFD700))
                                                            .withOpacity(0.3),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        card.category ==
                                                                'single'
                                                            ? Icons
                                                                .person_outline
                                                            : Icons
                                                                .people_outline,
                                                        color: Colors.white,
                                                        size: 12,
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        card.category ==
                                                                'single'
                                                            ? '单人'
                                                            : '多人',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              card.description,
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.download_outlined,
                                                  size: 12,
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${card.downloads}',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.5),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                if (card.tags.isNotEmpty &&
                                                    card.tags.any((tag) =>
                                                        tag.isNotEmpty)) ...[
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      card.tags
                                                          .where((tag) =>
                                                              tag.isNotEmpty)
                                                          .map((tag) => '#$tag')
                                                          .join(' '),
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.5),
                                                        fontSize: 11,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            )
          ],
        ),
      ),
    );
  }
}
