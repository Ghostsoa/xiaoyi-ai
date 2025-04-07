import 'package:flutter/material.dart';
import '../../dao/storage_dao.dart';
import '../../components/custom_snack_bar.dart';
import 'asset_logs_page.dart';
import 'level_info_page.dart';
import 'settings_page.dart';
import 'sponsor_page.dart';
import '../admin/admin_page.dart';
import '../../net/role_card/online_role_card_service.dart';
import '../../model/online_role_card.dart';
import '../plaza/online_role_card_detail_page.dart';
import '../../components/profile/visibility_filter_bar.dart';
import '../../components/profile/user_role_card_item.dart';
import '../../components/plaza/plaza_empty_state.dart';
import '../../components/plaza/skeleton_card_item.dart';
import '../../components/profile/check_in_card.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? assetData;

  const ProfilePage({
    super.key,
    this.assetData,
  });

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  final _storageDao = StorageDao();
  final _roleCardService = OnlineRoleCardService();
  final _checkInKey = GlobalKey<CheckInCardState>();
  Map<String, dynamic>? _userData;
  List<OnlineRoleCard>? _roleCards;
  bool _isInitialLoading = false;
  bool _isPaginationLoading = false;
  bool _isError = false;
  int _currentPage = 1;
  int _total = 0;
  String _visibility = 'all'; // 默认显示全部

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRoleCards();
  }

  Future<void> _loadUserData() async {
    final userData = _storageDao.getUser();
    if (userData != null) {
      setState(() {
        _userData = userData;
      });
    }
  }

  Future<void> _loadRoleCards() async {
    if (_isInitialLoading || _isPaginationLoading) return;

    setState(() {
      _isInitialLoading = true;
      _isError = false;
    });

    try {
      _currentPage = 1;
      final result = await _roleCardService.getUserRoleCards(
        page: _currentPage,
        visibility: _visibility,
      );

      if (mounted) {
        setState(() {
          _roleCards = result.list;
          _total = result.total;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _isInitialLoading = false;
        });
        CustomSnackBar.show(context, message: '加载角色卡列表失败: $e');
      }
    }
  }

  Future<void> _loadMoreRoleCards() async {
    if (_isInitialLoading ||
        _isPaginationLoading ||
        (_roleCards?.length ?? 0) >= _total) {
      return;
    }

    setState(() {
      _isPaginationLoading = true;
    });

    try {
      final result = await _roleCardService.getUserRoleCards(
        page: _currentPage + 1,
        visibility: _visibility,
      );

      if (mounted) {
        setState(() {
          _roleCards = [...?_roleCards, ...result.list];
          _total = result.total;
          _currentPage++;
          _isPaginationLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPaginationLoading = false;
        });
        CustomSnackBar.show(context, message: '加载更多角色卡失败: $e');
      }
    }
  }

  void _handleVisibilityChanged(String visibility) {
    if (_visibility != visibility) {
      setState(() {
        _visibility = visibility;
        _roleCards = null; // 清空当前列表
        _currentPage = 1;
      });
      _loadRoleCards();
    }
  }

  void _navigateToDetail(OnlineRoleCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnlineRoleCardDetailPage(card: card),
      ),
    );
  }

  bool get _isAdmin => _userData?['user']?['role'] == 2;

  String _getLevelTitle(int level) {
    if (level >= 3) {
      return '劳懿';
    } else if (level == 2) {
      return '小懿';
    } else {
      return '小小懿';
    }
  }

  Color _getLevelColor(int level) {
    if (level >= 3) {
      return const Color(0xFFFFD700); // 金色
    } else if (level == 2) {
      return const Color(0xFF40E0D0); // 青绿色
    } else {
      return const Color(0xFFB0C4DE); // 淡蓝灰色
    }
  }

  Future<void> _deleteRoleCard(OnlineRoleCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          '确认删除',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '确定要删除角色卡"${card.title}"吗？此操作不可恢复。',
          style: const TextStyle(color: Colors.white70),
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

    if (confirm == true) {
      try {
        await _roleCardService.deleteCard(card.code);
        await _loadRoleCards(); // 重新加载列表
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

  Future<void> _toggleCardStatus(OnlineRoleCard card, int newStatus) async {
    try {
      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _roleCardService.toggleCardStatus(card.code, newStatus);

      // 关闭加载指示器
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 更新本地数据
      if (mounted) {
        setState(() {
          // 创建一个新的修改后的角色卡对象
          final updatedCard = OnlineRoleCard(
            id: card.id,
            code: card.code,
            userId: card.userId,
            authorName: card.authorName,
            title: card.title,
            description: card.description,
            tags: card.tags,
            category: card.category,
            rawDataUrl: card.rawDataUrl,
            coverUrl: card.coverUrl,
            status: newStatus, // 更新状态
            downloads: card.downloads,
            createdAt: card.createdAt,
            updatedAt: card.updatedAt,
          );

          // 在列表中找到并替换角色卡
          final index =
              _roleCards?.indexWhere((c) => c.code == card.code) ?? -1;
          if (index != -1 && _roleCards != null) {
            _roleCards![index] = updatedCard;
          }
        });

        // 显示成功消息
        CustomSnackBar.show(
          context,
          message: '角色卡状态已更新为${newStatus == 1 ? '公开' : '非公开'}',
        );
      }
    } catch (e) {
      // 关闭加载指示器
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 显示错误消息
      if (mounted) {
        CustomSnackBar.show(context, message: '更新角色卡状态失败: $e');
      }
    }
  }

  // 刷新签到状态的方法
  void refreshCheckInStatus() {
    _checkInKey.currentState?.refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final userData = _userData;
    final user =
        userData != null ? userData['user'] as Map<String, dynamic>? : null;
    final username = user?['username'] as String? ?? '未登录';
    final email = user?['email'] as String? ?? '';
    final id = user?['id']?.toString() ?? '';

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
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 用户名和等级
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            username,
                            style: const TextStyle(
                              fontSize: 28,
                              height: 1.2,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // ID和称号
                    Row(
                      children: [
                        Text(
                          'ID: $id',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: widget.assetData != null
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LevelInfoPage(
                                        assetData: widget.assetData!,
                                      ),
                                    ),
                                  )
                              : null,
                          child: Row(
                            children: [
                              Icon(
                                Icons.military_tech,
                                size: 20,
                                color: _getLevelColor(
                                    widget.assetData?['level'] ?? 1),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getLevelTitle(widget.assetData?['level'] ?? 1),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _getLevelColor(
                                      widget.assetData?['level'] ?? 1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(widget.assetData?['exp_progress'] as num?)?.toStringAsFixed(1) ?? '0.0'}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _getLevelColor(
                                          widget.assetData?['level'] ?? 1)
                                      .withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 邮箱
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 32),
                    // 资产信息
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SponsorPage(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.diamond_outlined,
                            size: 28,
                            color: Color(0xFFFFD700),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '小懿币',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFFFD700),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.assetData?['balance']?.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFD700),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFFFFD700),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 签到卡片
                    CheckInCard(key: _checkInKey),
                    const SizedBox(height: 24),
                    // 数据统计
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AssetLogsPage(),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.receipt_long,
                                      color: Theme.of(context).primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '变动记录',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text(
                                      '查看详情',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white.withOpacity(0.3),
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '畅谈时长',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.assetData?['remaining_hours']?.toStringAsFixed(1) ?? '0.0'}h',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_isAdmin) ...[
                      const SizedBox(height: 24),
                      // 管理员入口
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminPage(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.redAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '管理员控制台',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '系统管理与数据监控',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    // 已发布作品标题
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '已发布作品',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              tooltip: '刷新',
                              icon: const Icon(
                                Icons.refresh_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              onPressed: _loadRoleCards,
                            ),
                            IconButton(
                              tooltip: '设置',
                              icon: const Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SettingsPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    // 可见性筛选栏
                    VisibilityFilterBar(
                      currentVisibility: _visibility,
                      onVisibilityChanged: _handleVisibilityChanged,
                    ),
                  ],
                ),
              ),
            ),
            // 已发布作品列表
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildRoleCardList(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCardList() {
    if (_isInitialLoading && (_roleCards == null || _roleCards!.isEmpty)) {
      return Column(
        children: List.generate(
          3,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: SkeletonCardItem(),
          ),
        ),
      );
    }

    if (_isError) {
      return PlazaEmptyState(
        isLoading: false,
        isError: true,
      );
    }

    if (_roleCards == null || _roleCards!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                '暂无已发布作品',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...List.generate(
          _roleCards!.length,
          (index) => UserRoleCardItem(
            card: _roleCards![index],
            onTap: _navigateToDetail,
            onDelete: _deleteRoleCard,
            onToggleStatus: _toggleCardStatus,
          ),
        ),
        // 加载更多
        if (_roleCards!.length < _total)
          InkWell(
            onTap: _loadMoreRoleCards,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: _isPaginationLoading
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : Text(
                      '加载更多 (${_roleCards!.length}/$_total)',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}
