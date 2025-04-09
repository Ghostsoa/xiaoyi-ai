import 'package:flutter/material.dart';
import '../../../../components/custom_text_field.dart';
import '../../../../components/custom_snack_bar.dart';
import '../../../../components/admin/admin_dialog.dart';
import '../../../../net/admin/user_service.dart';
import '../../../../components/loading_indicator.dart';
import '../../../../net/admin/asset_service.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final _searchController = TextEditingController();
  final _userService = AdminUserService();
  final _assetService = AdminAssetService();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _users = [];
  int _currentPage = 1;
  int _totalCount = 0;
  static const _pageSize = 20;
  String _searchType = 'username'; // 默认搜索类型
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(_onScroll);
    _loadPackageInfo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final totalPages = (_totalCount / _pageSize).ceil();

    if (_isLoading || _isLoadingMore || _currentPage >= totalPages) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    await _loadUsers(isLoadMore: true);

    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _loadUsers({bool isLoadMore = false}) async {
    if (_isLoading && !isLoadMore) return;

    setState(() {
      _isLoading = !isLoadMore;
    });

    try {
      final searchText = _searchController.text.trim();

      // 根据搜索类型和关键词构建查询参数
      int? id;
      String? email;
      String? username;

      if (searchText.isNotEmpty) {
        switch (_searchType) {
          case 'id':
            id = int.tryParse(searchText);
            break;
          case 'email':
            email = searchText;
            break;
          case 'username':
            username = searchText;
            break;
        }
      }

      final (result, message) = await _userService.getUserList(
        page: _currentPage,
        pageSize: _pageSize,
        id: id,
        email: email,
        username: username,
      );

      if (result != null && mounted) {
        final newUsers = (result['list'] as List).cast<Map<String, dynamic>>();

        setState(() {
          if (isLoadMore) {
            _users.addAll(newUsers);
          } else {
            _users = newUsers;
          }
          _totalCount = result['total'] as int;
          _isLoading = false;
        });
      } else if (mounted) {
        CustomSnackBar.show(
          context,
          message: message ?? '加载用户列表失败',
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: '加载用户列表失败：$e',
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  String _formatBalance(dynamic balance) {
    if (balance is num) {
      return balance.toStringAsFixed(2);
    }
    return balance.toString();
  }

  Future<void> _showUserDetail(int userId) async {
    AdminDialog.show(
      context: context,
      title: '用户详情',
      width: 800,
      content: DefaultTabController(
        length: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TabBar(
              tabs: [
                Tab(text: '基本信息'),
                Tab(text: '资产记录'),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: TabBarView(
                  children: [
                    // 基本信息标签页
                    FutureBuilder<(Map<String, dynamic>?, String?)>(
                      future: _userService.getUserDetail(userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: LoadingIndicator(size: 40),
                          );
                        }

                        if (snapshot.hasError) {
                          return Text(
                            '加载失败：${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          );
                        }

                        final (user, message) = snapshot.data!;
                        if (user == null) {
                          return Text(
                            message ?? '加载失败',
                            style: const TextStyle(color: Colors.red),
                          );
                        }

                        final asset = user['asset'] as Map<String, dynamic>;

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '基本信息',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildDetailTable([
                                {'label': 'ID', 'value': '${user['id']}'},
                                {'label': '用户名', 'value': user['username']},
                                {'label': '邮箱', 'value': user['email']},
                                {
                                  'label': '性别',
                                  'value': _getGenderText(user['gender'])
                                },
                                {
                                  'label': '角色',
                                  'value': _getRoleText(user['role'])
                                },
                                {
                                  'label': '状态',
                                  'value': _getStatusText(user['status'])
                                },
                                {
                                  'label': '创建时间',
                                  'value': _formatDateTime(user['created_at'])
                                },
                              ]),
                              const SizedBox(height: 24),
                              const Text(
                                '资产信息',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildDetailTable([
                                {
                                  'label': '余额',
                                  'value': _formatBalance(asset['balance'])
                                },
                                {'label': '等级', 'value': '${asset['level']}'},
                                {'label': '经验值', 'value': '${asset['exp']}'},
                                {
                                  'label': '创建时间',
                                  'value': _formatDateTime(asset['created_at'])
                                },
                                {
                                  'label': '更新时间',
                                  'value': _formatDateTime(asset['updated_at'])
                                },
                              ]),
                            ],
                          ),
                        );
                      },
                    ),
                    // 资产记录标签页
                    _AssetLogsView(userId: userId),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '关闭',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTable(List<Map<String, String>> items) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(80),
        1: FlexColumnWidth(),
      },
      children: items.map((item) {
        return TableRow(
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${item['label']}：',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  item['value']!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final status = user['status'] as int;
    final isEnable = status == 0; // 如果当前是0(禁用)，则启用；如果是1(正常)，则禁用
    final confirmed = await AdminDialog.confirm(
      context,
      title: isEnable ? '启用用户' : '禁用用户',
      content: '确定要${isEnable ? '启用' : '禁用'}用户 "${user['username']}" 吗？',
      confirmText: isEnable ? '启用' : '禁用',
      cancelText: '取消',
      danger: !isEnable,
    );

    if (confirmed) {
      final controller = TextEditingController();
      final reason = await AdminDialog.show<String>(
        context: context,
        title: '请输入原因',
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '请输入${isEnable ? '启用' : '禁用'}原因',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            border: const UnderlineInputBorder(),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(
              '取消',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text(
              '确定',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );

      if (reason != null && reason.isNotEmpty && mounted) {
        final message = await _userService.updateUserStatus(
          user['id'],
          status: isEnable ? 1 : 0,
          reason: reason,
        );

        if (mounted) {
          CustomSnackBar.show(context, message: message ?? '操作失败');
          if (message?.contains('成功') ?? false) {
            _loadUsers();
          }
        }
      }
    }
  }

  Future<void> _updateUserRole(Map<String, dynamic> user) async {
    final currentRole = user['role'] as int;
    final newRole = currentRole == 1 ? 2 : 1;

    final confirmed = await AdminDialog.confirm(
      context,
      title: '更改用户角色',
      content:
          '确定要将用户 "${user['username']}" 的角色从${_getRoleText(currentRole)}更改为${_getRoleText(newRole)}吗？',
      confirmText: '更改',
      cancelText: '取消',
      danger: newRole == 2,
    );

    if (confirmed && mounted) {
      final message = await _userService.updateUserRole(
        user['id'],
        role: newRole,
      );

      if (mounted) {
        CustomSnackBar.show(context, message: message ?? '操作失败');
        if (message?.contains('成功') ?? false) {
          _loadUsers();
        }
      }
    }
  }

  Future<void> _kickUser(Map<String, dynamic> user) async {
    final confirmed = await AdminDialog.confirm(
      context,
      title: '踢出用户',
      content: '确定要踢出用户 "${user['username']}" 吗？',
      confirmText: '踢出',
      cancelText: '取消',
      danger: true,
    );

    if (confirmed && mounted) {
      final message = await _userService.kickUser(
        user['id'],
        reason: '管理员操作',
      );

      if (mounted) {
        CustomSnackBar.show(context, message: message ?? '操作失败');
        if (message?.contains('成功') ?? false) {
          _loadUsers();
        }
      }
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await AdminDialog.show(
      context: context,
      title: '删除用户',
      width: 400,
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '你正在删除用户 "${user['username']}"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '此操作将永久删除该用户及其所有相关数据，无法恢复！',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: reasonController,
              label: '删除原因',
              hint: '请输入删除该用户的原因',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '删除原因不能为空';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop(true);
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red,
          ),
          child: const Text('删除'),
        ),
      ],
    );

    if (confirmed && mounted) {
      final message = await _userService.deleteUser(
        user['id'],
        reason: reasonController.text.trim(),
      );

      if (mounted) {
        CustomSnackBar.show(context, message: message ?? '删除用户失败');
        if (message?.contains('成功') ?? false) {
          _loadUsers();
        }
      }
    }

    reasonController.dispose();
  }

  Future<void> _updateBalance(Map<String, dynamic> user) async {
    final controller = TextEditingController();
    final amountController = TextEditingController();

    final result = await AdminDialog.show<(double, String)?>(
      context: context,
      title: '更新余额',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '用户：${user['username']}',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: amountController,
            label: '金额',
            hint: '输入金额（正数增加，负数减少）',
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: controller,
            label: '备注',
            hint: '请输入操作备注',
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            '取消',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
        TextButton(
          onPressed: () {
            final amount = double.tryParse(amountController.text);
            if (amount == null) {
              CustomSnackBar.show(context, message: '请输入有效的金额');
              return;
            }
            if (controller.text.isEmpty) {
              CustomSnackBar.show(context, message: '请输入操作备注');
              return;
            }
            Navigator.of(context).pop((amount, controller.text));
          },
          child: const Text(
            '确定',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );

    if (result != null && mounted) {
      final (amount, remark) = result;
      final message = await _assetService.updateBalance(
        user['id'],
        amount: amount,
        remark: remark,
      );

      if (mounted) {
        CustomSnackBar.show(context, message: message ?? '操作失败');
        if (message?.contains('成功') ?? false) {
          _loadUsers();
        }
      }
    }
  }

  Future<void> _addExp(Map<String, dynamic> user) async {
    final controller = TextEditingController();
    final expController = TextEditingController();

    final result = await AdminDialog.show<(int, String)?>(
      context: context,
      title: '增加经验值',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '用户：${user['username']}',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: expController,
            label: '经验值',
            hint: '输入要增加的经验值',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: controller,
            label: '备注',
            hint: '请输入操作备注',
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            '取消',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
        TextButton(
          onPressed: () {
            final exp = int.tryParse(expController.text);
            if (exp == null || exp <= 0) {
              CustomSnackBar.show(context, message: '请输入有效的经验值');
              return;
            }
            if (controller.text.isEmpty) {
              CustomSnackBar.show(context, message: '请输入操作备注');
              return;
            }
            Navigator.of(context).pop((exp, controller.text));
          },
          child: const Text(
            '确定',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );

    if (result != null && mounted) {
      final (exp, remark) = result;
      final message = await _assetService.addExp(
        user['id'],
        exp: exp,
        remark: remark,
      );

      if (mounted) {
        CustomSnackBar.show(context, message: message ?? '操作失败');
        if (message?.contains('成功') ?? false) {
          _loadUsers();
        }
      }
    }
  }

  Future<void> _resetAsset(Map<String, dynamic> user) async {
    final confirmed = await AdminDialog.confirm(
      context,
      title: '重置资产',
      content: '确定要重置用户 "${user['username']}" 的所有资产吗？\n此操作不可恢复！',
      confirmText: '重置',
      cancelText: '取消',
      danger: true,
    );

    if (confirmed && mounted) {
      final message = await _assetService.resetAsset(user['id']);

      if (mounted) {
        CustomSnackBar.show(context, message: message ?? '操作失败');
        if (message?.contains('成功') ?? false) {
          _loadUsers();
        }
      }
    }
  }

  String _getGenderText(int gender) {
    switch (gender) {
      case 1:
        return '男';
      case 2:
        return '女';
      default:
        return '未知';
    }
  }

  String _getRoleText(int role) {
    switch (role) {
      case 1:
        return '普通用户';
      case 2:
        return '管理员';
      default:
        return '未知';
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return '禁用';
      case 1:
        return '正常';
      default:
        return '未知';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索栏
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              // 搜索输入框
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: CustomTextField(
                    controller: _searchController,
                    hint:
                        '搜索用户${_searchType == "id" ? "(ID)" : _searchType == "email" ? "(邮箱)" : ""}',
                    prefixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search,
                            color: Colors.white70, size: 20),
                        const SizedBox(width: 4),
                        // 搜索类型选择器
                        GestureDetector(
                          onTap: () {
                            _showSearchTypeMenu();
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _searchType == 'username'
                                    ? '用户名'
                                    : _searchType == 'email'
                                        ? '邮箱'
                                        : 'ID',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.white70, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                    keyboardType: _searchType == 'id'
                        ? TextInputType.number
                        : TextInputType.text,
                    onSubmitted: (_) => _handleSearch(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 搜索按钮 - 改为图标
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: _handleSearch,
                tooltip: '搜索',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 用户列表 - 添加下拉刷新
        Expanded(
          child: _isLoading
              ? const Center(child: LoadingIndicator())
              : Column(
                  children: [
                    // 搜索结果信息
                    if (_searchController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              '搜索结果: ${_getSearchDescription()}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '共 $_totalCount 条记录',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    // 列表或空结果提示
                    Expanded(
                      child: _users.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isEmpty
                                        ? '暂无用户数据'
                                        : '未找到符合条件的用户',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _handleRefresh,
                              color: const Color(0xFF3B82F6),
                              backgroundColor: const Color(0xFF1E293B),
                              child: ListView.separated(
                                controller: _scrollController,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount:
                                    _users.length + (_isLoadingMore ? 1 : 0),
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                  color: Colors.white24,
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  if (index == _users.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: LoadingIndicator(size: 24),
                                      ),
                                    );
                                  }

                                  final user = _users[index];
                                  return _buildUserExpansionTile(user);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildUserExpansionTile(Map<String, dynamic> user) {
    final status = user['status'] as int;
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Row(
          children: [
            Text(
              '#${user['id']}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              user['username'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: status == 1
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getStatusText(status),
                style: TextStyle(
                  color: status == 1 ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('邮箱', user['email']),
                const SizedBox(height: 8),
                _buildInfoRow('性别', _getGenderText(user['gender'])),
                const SizedBox(height: 8),
                _buildInfoRow('角色', _getRoleText(user['role'])),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 基础操作按钮
                    PopupMenuButton<String>(
                      tooltip: '基础操作',
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'detail',
                          child: Row(
                            children: [
                              const Icon(Icons.visibility_outlined, size: 18),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('查看详情'),
                                  Text(
                                    '查看用户的完整信息',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'status',
                          child: Row(
                            children: [
                              Icon(
                                status == 1
                                    ? Icons.block_outlined
                                    : Icons.check_circle_outlined,
                                size: 18,
                                color: status == 1 ? Colors.red : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(status == 1 ? '禁用用户' : '启用用户'),
                                  Text(
                                    status == 1 ? '禁止用户登录和使用' : '允许用户正常使用',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'role',
                          child: Row(
                            children: [
                              const Icon(Icons.admin_panel_settings_outlined,
                                  size: 18, color: Colors.orange),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('更改角色'),
                                  Text(
                                    '修改用户的系统角色',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'kick',
                          child: Row(
                            children: [
                              const Icon(Icons.logout_outlined,
                                  size: 18, color: Colors.red),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('踢出用户',
                                      style: TextStyle(color: Colors.red)),
                                  Text(
                                    '强制用户下线',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_forever_outlined,
                                  size: 18, color: Colors.red),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('删除用户',
                                      style: TextStyle(color: Colors.red)),
                                  Text(
                                    '永久删除用户及相关数据',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'detail':
                            _showUserDetail(user['id']);
                            break;
                          case 'status':
                            _toggleUserStatus(user);
                            break;
                          case 'role':
                            _updateUserRole(user);
                            break;
                          case 'kick':
                            _kickUser(user);
                            break;
                          case 'delete':
                            _deleteUser(user);
                            break;
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    // 资产操作按钮
                    PopupMenuButton<String>(
                      tooltip: '资产操作',
                      icon: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'balance',
                          child: Row(
                            children: [
                              const Icon(Icons.money, size: 18),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('更新余额'),
                                  Text(
                                    '增加或减少用户余额',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'exp',
                          child: Row(
                            children: [
                              const Icon(Icons.star_border, size: 18),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('增加经验'),
                                  Text(
                                    '增加用户经验值',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'reset',
                          child: Row(
                            children: [
                              const Icon(Icons.restart_alt,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('重置资产',
                                      style: TextStyle(color: Colors.red)),
                                  Text(
                                    '重置用户所有资产',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'balance':
                            _updateBalance(user);
                            break;
                          case 'exp':
                            _addExp(user);
                            break;
                          case 'reset':
                            _resetAsset(user);
                            break;
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label：',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _handleSearch() {
    _currentPage = 1;
    _users = []; // 清空现有用户列表
    _loadUsers();
  }

  // 获取当前搜索条件描述
  String _getSearchDescription() {
    final searchText = _searchController.text.trim();
    if (searchText.isEmpty) {
      return '所有用户';
    }

    switch (_searchType) {
      case 'id':
        return 'ID: $searchText';
      case 'email':
        return '邮箱: $searchText';
      case 'username':
        return '用户名: $searchText';
      default:
        return searchText;
    }
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = packageInfo;
    });
  }

  void _showSearchTypeMenu() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(
          value: 'username',
          child: Text('用户名'),
        ),
        const PopupMenuItem(
          value: 'email',
          child: Text('邮箱'),
        ),
        const PopupMenuItem(
          value: 'id',
          child: Text('ID'),
        ),
      ],
    ).then((String? value) {
      if (value != null) {
        setState(() {
          _searchType = value;
          if (value == 'id' &&
              !RegExp(r'^\d+$').hasMatch(_searchController.text)) {
            _searchController.clear();
          }
        });
      }
    });
  }

  // 下拉刷新处理方法
  Future<void> _handleRefresh() async {
    _currentPage = 1;
    await _loadUsers();
    return;
  }
}

class _AssetLogsView extends StatefulWidget {
  final int userId;

  const _AssetLogsView({required this.userId});

  @override
  State<_AssetLogsView> createState() => _AssetLogsViewState();
}

class _AssetLogsViewState extends State<_AssetLogsView> {
  final _userService = AdminUserService();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _logs = [];
  int _currentPage = 1;
  int _totalCount = 0;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _logs.length < _totalCount) {
        _loadLogs();
      }
    }
  }

  Future<void> _loadLogs() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final (result, message) = await _userService.getUserAssetLogs(
        widget.userId,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (result != null && mounted) {
        final logs = (result['logs'] as List).cast<Map<String, dynamic>>();
        final pagination = result['pagination'] as Map<String, dynamic>;

        setState(() {
          if (_currentPage == 1) {
            _logs = logs;
          } else {
            _logs.addAll(logs);
          }
          _totalCount = pagination['total'] as int;
          _currentPage++;
          _isLoading = false;
        });
      } else if (mounted) {
        CustomSnackBar.show(context, message: message ?? '加载资产变动记录失败');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '加载资产变动记录失败：$e');
        setState(() => _isLoading = false);
      }
    }
  }

  String _getChangeTypeText(int changeType) {
    switch (changeType) {
      case 1:
        return '充值';
      case 2:
        return '消费';
      case 3:
        return '退款';
      case 4:
        return '赠送';
      default:
        return '其他';
    }
  }

  Color _getAmountColor(num amount) {
    return amount >= 0 ? Colors.green : Colors.red;
  }

  String _formatDateTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _logs.isEmpty && !_isLoading
              ? Center(
                  child: Text(
                    '暂无资产变动记录',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _logs.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _logs.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: LoadingIndicator(size: 24),
                        ),
                      );
                    }

                    final log = _logs[index];
                    final amount = log['amount'] as num;
                    final balance = log['balance'] as num;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getChangeTypeText(log['change_type']),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatDateTime(log['created_at']),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log['remark'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '操作者ID: ${log['operator_id']}',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.5),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${amount >= 0 ? "+" : ""}${amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: _getAmountColor(amount),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '余额: ${balance.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (log['exp_change'] != 0 ||
                                  log['level_change'] != 0) ...[
                                const SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (log['exp_change'] != 0)
                                      Text(
                                        '经验值: ${log['before_exp']} → ${log['after_exp']} (${log['exp_change'] >= 0 ? "+" : ""}${log['exp_change']})',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (log['level_change'] != 0)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: log['exp_change'] != 0 ? 4 : 0,
                                        ),
                                        child: Text(
                                          '等级: ${log['before_level']} → ${log['after_level']} (${log['level_change'] >= 0 ? "+" : ""}${log['level_change']})',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.5),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Colors.white24),
                      ],
                    );
                  },
                ),
        ),
        if (_isLoading && _logs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: LoadingIndicator(size: 24),
          ),
      ],
    );
  }
}
