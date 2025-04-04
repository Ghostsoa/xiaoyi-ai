import 'package:flutter/material.dart';
import '../../../../components/custom_snack_bar.dart';
import '../../../../net/admin/device_management_service.dart';

class UserDevicesPage extends StatefulWidget {
  final int userId;

  const UserDevicesPage({super.key, required this.userId});

  @override
  State<UserDevicesPage> createState() => _UserDevicesPageState();
}

class _UserDevicesPageState extends State<UserDevicesPage> {
  final DeviceManagementService _deviceService = DeviceManagementService();

  List<dynamic> _devices = [];
  bool _isLoading = false;
  Map<String, dynamic>? _userInfo;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _deviceService.getUserDevices(widget.userId);

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _devices = result['data']['devices'] ?? [];
        _userInfo = result['data']['user_info'];
      } else {
        if (mounted) {
          CustomSnackBar.show(context,
              message: result['message'] ?? '获取用户设备失败');
        }
      }
    });
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

  String _getDeviceStatusText(int status) {
    switch (status) {
      case 0:
        return '正常';
      case 1:
        return '已禁用';
      default:
        return '未知';
    }
  }

  Color _getDeviceStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
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

  Future<void> _unbanDevice(String deviceCode) async {
    final result = await _deviceService.unbanDevice(deviceCode);

    if (result['success']) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: '设备已解除禁用',
        );
      }
      _loadDevices(); // 刷新设备列表
    } else {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: result['message'] ?? '解除禁用失败',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text('用户 ${_userInfo?['username'] ?? widget.userId} 的设备'),
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
            : _devices.isEmpty
                ? Center(
                    child: Text(
                      '该用户没有关联设备',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  )
                : Column(
                    children: [
                      if (_userInfo != null)
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
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
                                          _userInfo!['username'] ?? '未知用户',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _userInfo!['email'] ?? '',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '设备总数: ${_devices.length}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '用户ID: ${_userInfo!['id'] ?? ''}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _devices.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final device = _devices[index];
                            final isBlacklisted = device['status'] == 1;

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
                                        const Icon(
                                          Icons.devices,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            device['device_code'] ?? '未知设备',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getDeviceStatusColor(
                                                    device['status'] ?? 0)
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: _getDeviceStatusColor(
                                                  device['status'] ?? 0),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            _getDeviceStatusText(
                                                device['status'] ?? 0),
                                            style: TextStyle(
                                              color: _getDeviceStatusColor(
                                                  device['status'] ?? 0),
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
                                                '设备名称: ${device['device_name'] ?? '未命名'}',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '最后登录: ${_formatTime(device['last_login'])}',
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
                                                '绑定状态: ${_getBindingStatusText(device['binding_status'] ?? 0)}',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '绑定时间: ${_formatTime(device['binding_time'])}',
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
                                    if (isBlacklisted)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.lock_open,
                                                size: 16),
                                            label: const Text('解除禁用'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                            ),
                                            onPressed: () => _unbanDevice(
                                                device['device_code']),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
