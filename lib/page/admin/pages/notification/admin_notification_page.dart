import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../components/custom_snack_bar.dart';
import '../../../../components/confirm_dialog.dart';
import '../../../../net/admin/notification_service.dart';
import 'notification_editor_page.dart';

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({super.key});

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _notifications = [];
  String? _searchQuery;
  int? _selectedType;
  int _page = 1;
  int _totalPages = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AdminNotificationService.getNotifications(
        page: _page,
        pageSize: 20,
        query: _searchQuery,
        type: _selectedType,
      );

      if (result.success && result.notifications != null) {
        setState(() {
          _notifications = result.notifications!;
          _totalPages = ((result.total ?? 0) / 20).ceil();
          _hasMore = _page < _totalPages;
        });
      } else {
        if (mounted) {
          CustomSnackBar.show(context, message: result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '加载通知失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _search() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
    });
    _loadNotifications(refresh: true);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = null;
    });
    _loadNotifications(refresh: true);
  }

  void _toggleTypeFilter(int type) {
    setState(() {
      if (_selectedType == type) {
        _selectedType = null;
      } else {
        _selectedType = type;
      }
    });
    _loadNotifications(refresh: true);
  }

  Future<void> _deleteNotification(int id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '删除通知',
      content: '确定要删除该通知吗？此操作不可恢复。',
      confirmText: '删除',
      cancelText: '取消',
      isDestructive: true,
    );

    if (confirmed) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await AdminNotificationService.deleteNotification(id);
        if (mounted) {
          if (result.success) {
            CustomSnackBar.show(context, message: result.message);
            _loadNotifications(refresh: true);
          } else {
            CustomSnackBar.show(context, message: result.message);
          }
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(context, message: '删除通知失败: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _loadNextPage() {
    if (_hasMore && !_isLoading) {
      setState(() {
        _page++;
      });
      _loadNotifications();
    }
  }

  void _loadPreviousPage() {
    if (_page > 1 && !_isLoading) {
      setState(() {
        _page--;
      });
      _loadNotifications();
    }
  }

  Future<void> _createOrEditNotification(
      Map<String, dynamic>? notification) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NotificationEditorPage(notification: notification),
      ),
    );

    if (result == true) {
      _loadNotifications(refresh: true);
    }
  }

  String _getTypeString(int type) {
    switch (type) {
      case NotificationType.system:
        return '系统通知';
      case NotificationType.announcement:
        return '公告';
      case NotificationType.personal:
        return '个人通知';
      case NotificationType.promotion:
        return '促销活动';
      case NotificationType.maintenance:
        return '维护通知';
      default:
        return '未知类型';
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '无限期';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime.toLocal());
    } catch (e) {
      return '格式错误';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部标题和操作区
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications, size: 24),
              const SizedBox(width: 8),
              const Text(
                '通知管理',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed:
                    _isLoading ? null : () => _createOrEditNotification(null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  '创建通知',
                  style: TextStyle(fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),

        // 搜索和筛选区域
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 搜索栏
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '搜索通知标题或内容',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                      onSubmitted: (_) => _search(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _search,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text('搜索'),
                  ),
                ],
              ),

              // 类型过滤器
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    const Text('筛选: ', style: TextStyle(fontSize: 13)),
                    _buildTypeFilterChip(NotificationType.system),
                    _buildTypeFilterChip(NotificationType.announcement),
                    _buildTypeFilterChip(NotificationType.personal),
                    _buildTypeFilterChip(NotificationType.promotion),
                    _buildTypeFilterChip(NotificationType.maintenance),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 通知列表
        Expanded(
          child: _isLoading && _notifications.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '暂无通知',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _createOrEditNotification(null),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('创建通知'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () => _loadNotifications(refresh: true),
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _notifications.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final notification = _notifications[index];
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  tileColor: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.02),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          notification['title'] ?? '无标题',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getTypeColor(
                                              notification['type'] as int? ??
                                                  0),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _getTypeString(
                                              notification['type'] as int? ??
                                                  0),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  notification['content'] ??
                                                      '无内容',
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Flexible(
                                                child: Text(
                                                  '过期: ${_formatDateTime(notification['expired_at'] as String?)}',
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton(
                                        onPressed: () =>
                                            _createOrEditNotification(
                                                notification),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          '编辑',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => _deleteNotification(
                                            notification['id'] as int),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          '删除',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // 分页控制
                        if (_totalPages > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_page > 1)
                                  IconButton(
                                    icon: const Icon(Icons.navigate_before,
                                        size: 18),
                                    onPressed: _loadPreviousPage,
                                    tooltip: '上一页',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text('$_page / $_totalPages',
                                      style: const TextStyle(fontSize: 13)),
                                ),
                                if (_hasMore)
                                  IconButton(
                                    icon: const Icon(Icons.navigate_next,
                                        size: 18),
                                    onPressed: _loadNextPage,
                                    tooltip: '下一页',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ),

                        // 加载指示器
                        if (_isLoading)
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            height: 4,
                            child: const LinearProgressIndicator(),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }

  Color _getTypeColor(int type) {
    switch (type) {
      case NotificationType.system:
        return Colors.blue;
      case NotificationType.announcement:
        return Colors.green;
      case NotificationType.personal:
        return Colors.purple;
      case NotificationType.promotion:
        return Colors.orange;
      case NotificationType.maintenance:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTypeFilterChip(int type) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(_getTypeString(type)),
      selected: isSelected,
      onSelected: (_) => _toggleTypeFilter(type),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: isSelected ? _getTypeColor(type) : Colors.grey.shade200,
      selectedColor: _getTypeColor(type),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? _getTypeColor(type) : Colors.grey.shade400,
          width: 1,
        ),
      ),
    );
  }
}
