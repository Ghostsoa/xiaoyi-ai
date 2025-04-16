import 'package:flutter/material.dart';
import 'pages/dashboard_page.dart';
import 'pages/user/user_list_page.dart';
import 'pages/log/log_manage_page.dart';
import 'pages/version/version_manage_page.dart';
import 'pages/card/card_manage_page.dart';
import 'pages/notification/admin_notification_page.dart';
import 'pages/key_manager/model_series_page.dart';
import 'pages/plaza/plaza_manage_page.dart';
import 'pages/qualification/qualification_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _isExpanded = false;
  String _currentPage = 'dashboard';
  final List<_NavigationItem> _navigationItems = [
    _NavigationItem(
      id: 'dashboard',
      title: '数据概览',
      icon: Icons.dashboard,
      page: const DashboardPage(),
    ),
    _NavigationItem(
      id: 'user_list',
      title: '用户管理',
      icon: Icons.people,
      page: const UserListPage(),
    ),
    _NavigationItem(
      id: 'card_manage',
      title: '卡密管理',
      icon: Icons.credit_card,
      page: const CardManagePage(),
    ),
    _NavigationItem(
      id: 'plaza_manage',
      title: '大厅管理',
      icon: Icons.public,
      page: const PlazaManagePage(),
    ),
    _NavigationItem(
      id: 'qualification_manage',
      title: '创作资格管理',
      icon: Icons.verified_user,
      page: const QualificationPage(),
    ),
    _NavigationItem(
      id: 'notification_manage',
      title: '通知管理',
      icon: Icons.notifications,
      page: const AdminNotificationPage(),
    ),
    _NavigationItem(
      id: 'model_series',
      title: '模型管理',
      icon: Icons.model_training,
      page: const ModelSeriesPage(),
    ),
    _NavigationItem(
      id: 'version_manage',
      title: '版本管理',
      icon: Icons.update,
      page: const VersionManagePage(),
    ),
    _NavigationItem(
      id: 'log_manage',
      title: '日志管理',
      icon: Icons.receipt_long,
      page: const LogManagePage(),
    ),
  ];

  Widget? get _currentPageWidget {
    return _navigationItems.firstWhere((item) => item.id == _currentPage).page;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // 主内容区域
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.8),
                        Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // 顶部栏
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                _isExpanded ? Icons.menu_open : Icons.menu,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isExpanded = !_isExpanded;
                                });
                              },
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _navigationItems
                                  .firstWhere((item) => item.id == _currentPage)
                                  .title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.exit_to_app,
                                  color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: '退出管理后台',
                            ),
                          ],
                        ),
                      ),
                      // 页面内容
                      Expanded(
                        child: _currentPageWidget ?? const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // 侧边栏导航
          if (_isExpanded)
            Stack(
              children: [
                // 遮罩层
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _isExpanded = false),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ),
                // 侧边栏
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Material(
                    child: Container(
                      width: 220,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.95),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 管理后台标题
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.admin_panel_settings,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    '管理后台',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white24),
                          // 导航菜单
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              children: _navigationItems
                                  .map((item) => _buildNavigationItem(item))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(_NavigationItem item) {
    final isSelected = _currentPage == item.id;
    return InkWell(
      onTap: () {
        setState(() {
          _currentPage = item.id;
          _isExpanded = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem {
  final String id;
  final String title;
  final IconData icon;
  final Widget page;

  _NavigationItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.page,
  });
}
