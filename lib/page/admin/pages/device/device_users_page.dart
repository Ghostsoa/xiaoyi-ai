import 'package:flutter/material.dart';
import '../../../../components/custom_snack_bar.dart';
import '../../../../net/admin/device_management_service.dart';
import 'user_devices_page.dart';

class DeviceUsersPage extends StatefulWidget {
  final String deviceCode;

  const DeviceUsersPage({super.key, required this.deviceCode});

  @override
  State<DeviceUsersPage> createState() => _DeviceUsersPageState();
}

class _DeviceUsersPageState extends State<DeviceUsersPage> {
  final DeviceManagementService _deviceService = DeviceManagementService();

  List<dynamic> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _deviceService.getDeviceUsers(widget.deviceCode);

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _users = result['data'] ?? [];
      } else {
        if (mounted) {
          CustomSnackBar.show(context,
              message: result['message'] ?? '获取设备关联用户失败');
        }
      }
    });
  }

  void _showUserDevices(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDevicesPage(userId: userId),
      ),
    );
  }

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '未知';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  String _getUserStatusText(int status) {
    switch (status) {
      case 0:
        return '已停用';
      case 1:
        return '正常';
      case 2:
        return '封禁中';
      default:
        return '未知';
    }
  }

  Color _getUserStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getRoleText(int role) {
    switch (role) {
      case 0:
        return '普通用户';
      case 1:
        return '管理员';
      case 2:
        return '超级管理员';
      default:
        return '未知';
    }
  }

  String _getBindingStatusText(int status) {
    switch (status) {
      case 0:
        return '临时设备';
      case 1:
        return '主要设备';
      default:
        return '未知';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text('设备 ${widget.deviceCode} 的关联用户'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : _users.isEmpty
                ? Center(
                    child: Text(
                      '该设备没有关联用户',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  )
                : ListView.builder(
                    itemCount: _users.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                    backgroundColor: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.7),
                                    child: const Icon(Icons.person,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['username'] ?? '未知用户',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user['email'] ?? '',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getUserStatusColor(
                                              user['status'] ?? 0)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _getUserStatusColor(
                                            user['status'] ?? 0),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _getUserStatusText(user['status'] ?? 0),
                                      style: TextStyle(
                                        color: _getUserStatusColor(
                                            user['status'] ?? 0),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '角色: ${_getRoleText(user['role'] ?? 0)}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '绑定状态: ${_getBindingStatusText(user['binding_status'] ?? 0)}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '用户ID: ${user['id'] ?? ''}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '最后登录: ${_formatTime(user['last_login'])}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.devices, size: 16),
                                  label: const Text('查看用户所有设备'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _showUserDevices(user['id']),
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
}
