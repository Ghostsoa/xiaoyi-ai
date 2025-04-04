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
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? assetData;

  const ProfilePage({
    super.key,
    this.assetData,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  final _storageDao = StorageDao();
  final _roleCardService = OnlineRoleCardService();
  Map<String, dynamic>? _userData;
  List<OnlineRoleCard>? _roleCards;
  bool _isLoadingCards = false;

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
    if (_isLoadingCards) return;

    setState(() {
      _isLoadingCards = true;
    });

    try {
      final result = await _roleCardService.getUserRoleCards();
      if (mounted) {
        setState(() {
          _roleCards = result.list;
          _isLoadingCards = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCards = false;
        });
        CustomSnackBar.show(context, message: '加载角色卡列表失败: $e');
      }
    }
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
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
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
                              onPressed: _loadRoleCards,
                            ),
                            IconButton(
                              tooltip: '设置',
                              icon: const Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                                size: 24,
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
                  ],
                ),
              ),
            ),
            // 已发布作品列表
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
    if (_isLoadingCards) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
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
      children: _roleCards!.map((card) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${card.id}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            card.title,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.download_outlined,
                          size: 13,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${card.downloads}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(card.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteRoleCard(card),
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red.withOpacity(0.7),
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
