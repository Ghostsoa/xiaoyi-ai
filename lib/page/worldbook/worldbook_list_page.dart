import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../net/worldbook/worldbook_service.dart';
import '../../components/loading_overlay.dart';
import '../../components/custom_snack_bar.dart';
import '../../page/worldbook/worldbook_edit_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

class WorldbookListPage extends StatefulWidget {
  final List<int> selectedIds;
  final bool isEditMode;

  const WorldbookListPage({
    super.key,
    this.selectedIds = const [],
    this.isEditMode = false,
  });

  @override
  State<WorldbookListPage> createState() => _WorldbookListPageState();
}

class _WorldbookListPageState extends State<WorldbookListPage> {
  final _worldbookService = WorldbookService();
  final _refreshController = RefreshController();

  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
    _loadEntries();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
    });

    try {
      final result = await _worldbookService.getWorldbookEntries(
        page: _currentPage,
        pageSize: 20,
      );

      setState(() {
        _entries = result.list;
        _hasMore = _entries.length < result.total;
        _currentPage++;
        _isLoading = false;
      });
      _refreshController.refreshCompleted();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      _refreshController.refreshFailed();
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _onLoading() async {
    if (!_hasMore || _isLoading) {
      _refreshController.loadComplete();
      return;
    }

    try {
      final result = await _worldbookService.getWorldbookEntries(
        page: _currentPage,
        pageSize: 20,
      );

      if (mounted) {
        setState(() {
          _entries.addAll(result.list);
          _hasMore = _entries.length < result.total;
          _currentPage++;
        });
      }
      _refreshController.loadComplete();
    } catch (e) {
      _refreshController.loadFailed();
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: e.toString(),
        );
      }
    }
  }

  void _toggleEntry(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.isEditMode ? '编辑世界书' : '选择世界书条目',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (!widget.isEditMode) ...[
              TextButton(
                onPressed: () {
                  final selectedList = _selectedIds.toList();
                  Navigator.pop<List<int>>(context, selectedList);
                },
                child: Text(
                  '确定 (${_selectedIds.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (widget.isEditMode)
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorldbookEditPage(),
                    ),
                  );

                  if (result == true && mounted) {
                    _loadEntries();
                  }
                },
              ),
          ],
        ),
        body: _buildEntryList(),
      ),
    );
  }

  Widget _buildEntryList() {
    if (_isLoading && _entries.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ));
    }

    if (_error != null && _entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadEntries,
              child: const Text(
                '重试',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无条目',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: _hasMore,
      onRefresh: _loadEntries,
      onLoading: _onLoading,
      header: const ClassicHeader(
        refreshStyle: RefreshStyle.Follow,
        idleText: '下拉刷新',
        refreshingText: '刷新中...',
        completeText: '刷新完成',
        failedText: '刷新失败',
        textStyle: TextStyle(color: Colors.white70),
        releaseText: '松手刷新',
        height: 50,
      ),
      footer: CustomFooter(
        builder: (context, mode) {
          Widget body;
          if (mode == LoadStatus.idle) {
            body = const Text("上拉加载", style: TextStyle(color: Colors.white70));
          } else if (mode == LoadStatus.loading) {
            body = const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            );
          } else if (mode == LoadStatus.failed) {
            body = const Text("加载失败", style: TextStyle(color: Colors.white70));
          } else if (mode == LoadStatus.canLoading) {
            body =
                const Text("松手加载更多", style: TextStyle(color: Colors.white70));
          } else {
            body =
                const Text("没有更多数据", style: TextStyle(color: Colors.white70));
          }
          return SizedBox(
            height: 55,
            child: Center(child: body),
          );
        },
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _entries.length,
        separatorBuilder: (context, index) => const Divider(
          color: Colors.white24,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final entry = _entries[index];
          final isSelected = _selectedIds.contains(entry['id']);

          return ListTile(
            title: Row(
              children: [
                Text(
                  '#${entry['id']} ${entry['title']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Text(
                  '关键词: ${entry['keyword'] ?? ''}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '优先级 ${entry['priority']}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            trailing: !widget.isEditMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (checked) => _toggleEntry(entry['id']),
                    activeColor: Theme.of(context).primaryColor,
                    checkColor: Colors.white,
                  )
                : IconButton(
                    icon:
                        const Icon(Icons.delete_outline, color: Colors.white70),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Theme.of(context).primaryColor,
                          title: const Text(
                            '确认删除',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            '确定要删除这个条目吗？此操作不可恢复。',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                '取消',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                '删除',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        final (success, message) = await LoadingOverlay.show(
                          context,
                          future: () => _worldbookService
                              .deleteWorldbookEntry(entry['id']),
                        );

                        if (!mounted) return;

                        CustomSnackBar.show(
                          context,
                          message: message,
                        );

                        if (success) {
                          _loadEntries();
                        }
                      }
                    },
                  ),
            onTap: () {
              if (widget.isEditMode) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorldbookEditPage(entry: entry),
                  ),
                ).then((result) {
                  if (result == true) {
                    _loadEntries();
                  }
                });
              } else {
                _toggleEntry(entry['id']);
              }
            },
          );
        },
      ),
    );
  }
}
