import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../net/session/world_session_service.dart';
import '../../components/custom_snack_bar.dart';
import 'dart:convert';
import '../../net/session/session_service.dart';
import '../chat_v2/agent_chat_page.dart';
import '../chat_v2/session_init_page.dart';
import '../../components/loading_overlay.dart';
import 'package:package_info_plus/package_info_plus.dart';

class WorldMessagePage extends StatefulWidget {
  const WorldMessagePage({super.key});

  @override
  State<WorldMessagePage> createState() => _WorldMessagePageState();
}

class _WorldMessagePageState extends State<WorldMessagePage> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final _worldSessionService = WorldSessionService();
  final _sessionService = SessionService();
  List<dynamic> _sessions = [];
  bool _isLoading = true;
  int _currentPage = 1;
  static const int _pageSize = 10;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _getAppVersion();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
      });
    } catch (e) {
      print('获取版本信息失败: $e');
    }
  }

  Future<void> _loadSessions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _worldSessionService.getSessions(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (response['code'] == 200 && mounted) {
        final list = response['data']['list'] as List<dynamic>;
        final total = response['data']['total'] as int? ?? 0;

        setState(() {
          _sessions = list;
          _isLoading = false;
          _hasMoreData = _sessions.length < total;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomSnackBar.show(context, message: e.toString());
      }
    }
  }

  Future<void> _loadMoreSessions() async {
    if (!mounted || _isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _worldSessionService.getSessions(
        page: _currentPage + 1,
        pageSize: _pageSize,
      );

      if (response['code'] == 200 && mounted) {
        final list = response['data']['list'] as List<dynamic>;
        final total = response['data']['total'] as int? ?? 0;

        setState(() {
          _sessions.addAll(list);
          _currentPage++;
          _isLoadingMore = false;
          _hasMoreData = _sessions.length < total;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        CustomSnackBar.show(context, message: e.toString());
      }
    }
  }

  Future<void> _onRefresh() async {
    _currentPage = 1;
    await _loadSessions();
    _refreshController.refreshCompleted();
  }

  Future<void> _onLoading() async {
    await _loadMoreSessions();
    if (_hasMoreData) {
      _refreshController.loadComplete();
    } else {
      _refreshController.loadNoData();
    }
  }

  Future<void> _deleteSession(String id) async {
    try {
      final response = await _worldSessionService.deleteSession(id);
      if (response['code'] != 200) {
        throw Exception(response['message'] ?? '删除失败');
      }
      await _loadSessions();
      if (mounted) {
        CustomSnackBar.show(context, message: '删除成功');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '删除失败: $e');
      }
    }
  }

  Future<void> _showDeleteConfirmDialog(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '确认删除',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '确定要删除这个会话吗？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '取消',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteSession(id);
    }
  }

  Future<void> _handleSessionTap(Map<String, dynamic> session) async {
    try {
      final response = await LoadingOverlay.show(
        context,
        future: () => _sessionService.loadSession(session['id']),
      );

      if (response['code'] == 200) {
        final sessionData = response['data'];
        print('初始化字段: ${sessionData['init_fields']}');
        print('会话状态: ${sessionData['status']}');

        // 预加载背景图片
        if (sessionData['background_base64'] != null) {
          final imageData = base64Decode(sessionData['background_base64']
              .toString()
              .replaceFirst(RegExp(r'data:image/[^;]+;base64,'), ''));
          await precacheImage(
            MemoryImage(imageData),
            context,
          );
        }

        if (context.mounted) {
          if (sessionData['status'].toString() == '0') {
            // 未初始化，跳转到初始化页面
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SessionInitPage(
                  sessionId: sessionData['id'],
                  sessionName:
                      sessionData['title'] ?? sessionData['name'] ?? '会话初始化',
                  initFields: List<String>.from(sessionData['init_fields']),
                  coverBase64: sessionData['cover_base64'],
                  backgroundBase64: sessionData['background_base64'],
                ),
              ),
            );
          } else {
            // 不需要初始化，直接跳转到聊天页面
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AgentChatPage(
                  sessionId: sessionData['id'],
                  sessionName:
                      sessionData['title'] ?? sessionData['name'] ?? '未命名',
                  backgroundBase64: sessionData['background_base64'],
                ),
              ),
            );
          }
        }
      } else {
        throw Exception(response['message'] ?? '加载会话失败');
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          message: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        enablePullUp: _hasMoreData,
        onLoading: _onLoading,
        footer: ClassicFooter(
          loadingText: '加载中...',
          canLoadingText: '上拉加载更多',
          idleText: '上拉加载更多',
          noDataText: '没有更多数据了',
          failedText: '加载失败',
          textStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        header: WaterDropHeader(
          waterDropColor: Theme.of(context).primaryColor,
          complete: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.done, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                '刷新完成',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
        ),
        child: _isLoading
            ? _buildSkeletonLoading()
            : _sessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.message_outlined,
                          color: Colors.white38,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '暂无大世界消息',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '当前版本: $_version',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _sessions.length + (_hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      // 如果是最后一项且有更多数据，显示加载指示器
                      if (index == _sessions.length) {
                        return _isLoadingMore
                            ? _buildLoadingItem()
                            : const SizedBox();
                      }

                      final session = _sessions[index];
                      return InkWell(
                        onTap: () => _handleSessionTap(session),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: session['cover_base64'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          base64Decode(session['cover_base64']
                                              .replaceFirst(
                                                  RegExp(
                                                      r'data:image/[^;]+;base64,'),
                                                  '')),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white54,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            session['title'] ??
                                                session['name'] ??
                                                '未命名会话',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: session['status'] == 0
                                                ? const Color(0xFFFF9800)
                                                : const Color(0xFF4CAF50),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            session['status'] == 0
                                                ? '未初始化'
                                                : '进行中',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (session['message_count'] != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 8),
                                            child: Text(
                                              '${session['message_count']}条',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (session['last_message'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          session['last_message'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _showDeleteConfirmDialog(session['id']),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  // 骨架屏加载效果
  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: 5, // 显示5个骨架项
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              // 头像骨架
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题骨架
                    Row(
                      children: [
                        Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 50,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 内容骨架
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // 操作按钮骨架
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 加载更多指示器
  Widget _buildLoadingItem() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '加载更多会话...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
