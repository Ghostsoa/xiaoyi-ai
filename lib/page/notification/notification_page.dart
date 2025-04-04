import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../components/custom_snack_bar.dart';
import '../../net/notification/notification_service.dart';
import 'notification_skeleton.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  int _page = 1;
  int _totalPages = 1;
  bool _hasMore = false;
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  int _currentTab = 0;
  final NotificationService _notificationService = NotificationService();
  String? _expandedNotificationId;

  // 通知类型
  static const List<Map<String, dynamic>> _tabs = [
    {'title': '全部', 'isRead': null},
    {'title': '未读', 'isRead': false},
    {'title': '已读', 'isRead': true},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadNotifications(refresh: true);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTab = _tabController.index;
        _expandedNotificationId = null; // 切换标签时收起展开的通知
      });
      _loadNotifications(refresh: true);
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _isLoading = true;
      });
    }

    try {
      // 将isRead参数转换为API所需的status参数
      final status = _tabs[_currentTab]['isRead'] == null
          ? null
          : _tabs[_currentTab]['isRead']
              ? 2
              : 1; // 1表示未读，2表示已读

      final result = await _notificationService.getNotifications(
        page: _page,
        pageSize: 20,
        status: status,
      );

      // 正确访问数据结构
      if (result['code'] == 200 && result['data'] != null) {
        final Map<String, dynamic> data =
            result['data'] as Map<String, dynamic>;
        final List<dynamic> notificationsList = data['list'] ?? [];
        final int total = data['total'] ?? 0;

        setState(() {
          if (refresh) {
            _notifications = List<Map<String, dynamic>>.from(notificationsList);
          } else {
            _notifications
                .addAll(List<Map<String, dynamic>>.from(notificationsList));
          }
          _totalPages = (total / 20).ceil();
          _hasMore = _page < _totalPages;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          CustomSnackBar.show(context, message: result['message'] ?? '获取通知失败');
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '加载通知失败: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _page++;
      _isLoading = true;
    });
    await _loadNotifications();
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications(refresh: true);
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead([notificationId]);

      // 更新本地状态
      setState(() {
        final index = _notifications.indexWhere(
            (n) => n['notification_id'].toString() == notificationId);
        if (index != -1) {
          _notifications[index]['status'] = 2; // 2表示已读
          _notifications[index]['read_at'] = DateTime.now().toIso8601String();
        }
      });

      CustomSnackBar.show(context, message: '已标记为已读');
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '标记已读失败: $e');
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      if (mounted) {
        CustomSnackBar.show(context, message: '已全部标记为已读');
        _refreshNotifications();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '标记全部已读失败: $e');
      }
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} 分钟前';
        } else {
          return '${difference.inHours} 小时前';
        }
      } else if (difference.inDays < 30) {
        return '${difference.inDays} 天前';
      } else {
        return DateFormat('yyyy-MM-dd').format(dateTime);
      }
    } catch (e) {
      return '未知时间';
    }
  }

  String _getNotificationTypeText(int type) {
    switch (type) {
      case 1:
        return '系统';
      case 2:
        return '公告';
      case 3:
        return '个人';
      case 4:
        return '促销';
      case 5:
        return '维护';
      default:
        return '其他';
    }
  }

  Color _getNotificationTypeColor(int type) {
    switch (type) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('通知中心'),
        actions: [
          TextButton.icon(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all, size: 18, color: Colors.white70),
            label: const Text('全部已读',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                )),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _tabs.map((tab) => Tab(text: tab['title'])).toList(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            ],
            stops: const [0.1, 0.9],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshNotifications,
            displacement: 20,
            color: Colors.white,
            backgroundColor: Theme.of(context).primaryColor,
            child: _isLoading && _notifications.isEmpty
                ? ListView.builder(
                    itemCount: 10,
                    padding: const EdgeInsets.all(0),
                    itemBuilder: (context, index) =>
                        const NotificationSkeleton(),
                  )
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_none_outlined,
                              size: 64,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无通知',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(0),
                        itemCount: _notifications.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _notifications.length) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                            );
                          }

                          final notification = _notifications[index];
                          // 获取通知详情
                          final Map<String, dynamic> notificationData =
                              notification['notification']
                                      as Map<String, dynamic>? ??
                                  {};
                          // 获取通知状态
                          final bool isUnread =
                              notification['status'] == 1; // 1表示未读，2表示已读

                          // 从通知详情中获取类型、标题、内容
                          final int notificationType =
                              notificationData['type'] as int? ?? 0;
                          final String title =
                              notificationData['title'] as String? ?? '未知标题';
                          final String content =
                              notificationData['content'] as String? ?? '';
                          final String createdAt =
                              notification['created_at'] as String? ?? '';

                          final String notificationId =
                              notification['notification_id'].toString();
                          final bool isExpanded =
                              _expandedNotificationId == notificationId;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (_expandedNotificationId == notificationId) {
                                  _expandedNotificationId = null; // 收起
                                } else {
                                  _expandedNotificationId =
                                      notificationId; // 展开
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(isExpanded ? 0.15 : 0.1),
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (isUnread)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(
                                              top: 6, right: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      else
                                        const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _getNotificationTypeColor(
                                                            notificationType),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    _getNotificationTypeText(
                                                        notificationType),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Icon(
                                                  isExpanded
                                                      ? Icons.keyboard_arrow_up
                                                      : Icons
                                                          .keyboard_arrow_down,
                                                  color: Colors.white70,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              content,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white70,
                                              ),
                                              maxLines: isExpanded ? null : 2,
                                              overflow: isExpanded
                                                  ? null
                                                  : TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _formatDateTime(createdAt),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                                if (isUnread)
                                                  GestureDetector(
                                                    onTap: () {
                                                      // 阻止事件冒泡，单独处理点击
                                                      _markAsRead(notification[
                                                              'notification_id']
                                                          .toString());
                                                    },
                                                    behavior:
                                                        HitTestBehavior.opaque,
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.1),
                                                            spreadRadius: 0,
                                                            blurRadius: 4,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        '标记已读',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                        ),
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
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }
}
