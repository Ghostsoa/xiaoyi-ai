import 'package:flutter/material.dart';
import '../../../../net/admin/agent_card_service.dart';
import '../../../../net/admin/user_service.dart';
import '../../../../components/loading_overlay.dart';
import '../../../../components/custom_snack_bar.dart';

class QualificationPage extends StatefulWidget {
  const QualificationPage({super.key});

  @override
  State<QualificationPage> createState() => _QualificationPageState();
}

class _QualificationPageState extends State<QualificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _agentCardService = AdminAgentCardService();
  final _userService = AdminUserService();

  // 申请列表数据
  List<int> _applicantIds = [];
  Map<int, Map<String, dynamic>> _applicantDetails = {};
  bool _loadingApplicants = false;
  String? _applicantsError;

  // 已授权用户列表数据
  List<int> _qualifiedUserIds = [];
  Map<int, Map<String, dynamic>> _qualifiedUserDetails = {};
  bool _loadingQualifiedUsers = false;
  String? _qualifiedUsersError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadApplicants();
    _loadQualifiedUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 加载申请列表
  Future<void> _loadApplicants() async {
    setState(() {
      _loadingApplicants = true;
      _applicantsError = null;
    });

    try {
      final (applicants, error) = await _agentCardService.getApplications();

      if (applicants != null) {
        setState(() {
          _applicantIds = applicants;
          _loadingApplicants = false;
        });

        // 获取每个申请人的详细信息
        for (final id in applicants) {
          await _loadUserDetail(id, isApplicant: true);
        }
      } else {
        setState(() {
          _applicantsError = error;
          _loadingApplicants = false;
        });
      }
    } catch (e) {
      setState(() {
        _applicantsError = e.toString();
        _loadingApplicants = false;
      });
    }
  }

  // 加载已授权用户列表
  Future<void> _loadQualifiedUsers() async {
    setState(() {
      _loadingQualifiedUsers = true;
      _qualifiedUsersError = null;
    });

    try {
      final (users, error) = await _agentCardService.getQualifiedUsers();

      if (users != null) {
        setState(() {
          _qualifiedUserIds = users;
          _loadingQualifiedUsers = false;
        });

        // 获取每个已授权用户的详细信息
        for (final id in users) {
          await _loadUserDetail(id, isApplicant: false);
        }
      } else {
        setState(() {
          _qualifiedUsersError = error;
          _loadingQualifiedUsers = false;
        });
      }
    } catch (e) {
      setState(() {
        _qualifiedUsersError = e.toString();
        _loadingQualifiedUsers = false;
      });
    }
  }

  // 加载用户详情
  Future<void> _loadUserDetail(int userId, {required bool isApplicant}) async {
    try {
      final (detail, error) = await _userService.getUserDetail(userId);

      if (detail != null) {
        setState(() {
          if (isApplicant) {
            _applicantDetails[userId] = detail;
          } else {
            _qualifiedUserDetails[userId] = detail;
          }
        });
      }
    } catch (e) {
      print('获取用户 $userId 详情失败: $e');
    }
  }

  // 批准申请
  Future<void> _approveApplication(int userId) async {
    try {
      final message = await LoadingOverlay.show(
        context,
        future: () => _agentCardService.approveApplication(userId),
        text: '批准申请中...',
      );

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: message ?? '审批成功',
        );

        // 刷新列表
        await _loadApplicants();
        await _loadQualifiedUsers();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: '批准失败: ${e.toString()}',
        );
      }
    }
  }

  // 撤销资格
  Future<void> _revokeQualification(int userId) async {
    try {
      final message = await LoadingOverlay.show(
        context,
        future: () => _agentCardService.revokeQualification(userId),
        text: '撤销资格中...',
      );

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: message ?? '撤销成功',
        );

        // 刷新列表
        await _loadQualifiedUsers();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: '撤销失败: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 标签页头部
        Container(
          height: 48,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: '资格申请列表'),
              Tab(text: '已授权用户'),
            ],
          ),
        ),
        // 标签页内容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 申请列表标签页
              _buildApplicantsTab(),
              // 已授权用户标签页
              _buildQualifiedUsersTab(),
            ],
          ),
        ),
      ],
    );
  }

  // 构建申请列表标签页
  Widget _buildApplicantsTab() {
    if (_loadingApplicants) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_applicantsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '加载申请列表失败',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _applicantsError!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadApplicants,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (_applicantIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              color: Colors.white.withOpacity(0.6),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无申请记录',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadApplicants,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('刷新'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplicants,
      color: Theme.of(context).primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _applicantIds.length,
        itemBuilder: (context, index) {
          final userId = _applicantIds[index];
          final userDetail = _applicantDetails[userId];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 0,
            color: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        radius: 20,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userDetail?['username'] ?? '用户 #$userId',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (userDetail != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'ID: $userId | 邮箱: ${userDetail['email'] ?? '未设置'}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _approveApplication(userId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: const Text('批准'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 构建已授权用户标签页
  Widget _buildQualifiedUsersTab() {
    if (_loadingQualifiedUsers) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_qualifiedUsersError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '加载已授权用户列表失败',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _qualifiedUsersError!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQualifiedUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (_qualifiedUserIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              color: Colors.white.withOpacity(0.6),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无已授权用户',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQualifiedUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('刷新'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQualifiedUsers,
      color: Theme.of(context).primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _qualifiedUserIds.length,
        itemBuilder: (context, index) {
          final userId = _qualifiedUserIds[index];
          final userDetail = _qualifiedUserDetails[userId];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 0,
            color: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        radius: 20,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userDetail?['username'] ?? '用户 #$userId',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (userDetail != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'ID: $userId | 邮箱: ${userDetail['email'] ?? '未设置'}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _revokeQualification(userId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: const Text('撤销资格'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
