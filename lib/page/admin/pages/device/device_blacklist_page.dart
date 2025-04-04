import 'package:flutter/material.dart';
import '../../../../components/custom_snack_bar.dart';
import '../../../../net/admin/device_management_service.dart';
import 'device_users_page.dart';

class DeviceBlacklistPage extends StatefulWidget {
  const DeviceBlacklistPage({super.key});

  @override
  State<DeviceBlacklistPage> createState() => _DeviceBlacklistPageState();
}

class _DeviceBlacklistPageState extends State<DeviceBlacklistPage> {
  final DeviceManagementService _deviceService = DeviceManagementService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _devices = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _searchText = '';
  int _page = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreDevices();
    }
  }

  Future<void> _loadDevices({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _hasMoreData = true;
        _isLoading = true;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    final result = await _deviceService.getBlacklist(
      page: _page,
      limit: 20,
      search: _searchText.isEmpty ? null : _searchText,
    );

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _devices = refresh
            ? result['data']['devices']
            : [..._devices, ...result['data']['devices']];
        _totalPages = result['data']['total_pages'] ?? 1;
        _hasMoreData = _page < _totalPages;
      } else {
        if (mounted) {
          CustomSnackBar.show(context, message: result['message'] ?? '获取黑名单失败');
        }
      }
    });
  }

  Future<void> _loadMoreDevices() async {
    if (!_hasMoreData || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _page += 1;
    });

    final result = await _deviceService.getBlacklist(
      page: _page,
      limit: 20,
      search: _searchText.isEmpty ? null : _searchText,
    );

    setState(() {
      _isLoadingMore = false;
      if (result['success']) {
        _devices = [..._devices, ...result['data']['devices']];
        _totalPages = result['data']['total_pages'] ?? 1;
        _hasMoreData = _page < _totalPages;
      } else {
        _page -= 1; // 恢复页码
        if (mounted) {
          CustomSnackBar.show(context,
              message: result['message'] ?? '加载更多数据失败');
        }
      }
    });
  }

  void _onSearch(String value) {
    _searchText = value.trim();
    _loadDevices(refresh: true);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchText = '';
    _loadDevices(refresh: true);
  }

  Future<void> _unbanDevice(String deviceCode) async {
    final confirmed = await _showConfirmDialog(
      title: '解除设备禁用',
      content: '确定要解除设备 $deviceCode 的禁用状态吗？',
      confirmText: '解除禁用',
      cancelText: '取消',
    );

    if (confirmed) {
      final result = await _deviceService.unbanDevice(deviceCode);

      if (result['success']) {
        if (mounted) {
          CustomSnackBar.show(context, message: '设备已解除禁用');
        }
        _loadDevices(refresh: true);
      } else {
        if (mounted) {
          CustomSnackBar.show(context, message: result['message'] ?? '解除禁用失败');
        }
      }
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    required String cancelText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showDeviceUsers(String deviceCode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceUsersPage(deviceCode: deviceCode),
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

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '搜索设备号或用户名',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _onSearch,
                  ),
                ),
                if (_searchText.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: _clearSearch,
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : _devices.isEmpty
                    ? Center(
                        child: Text(
                          '暂无黑名单设备',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _devices.length + (_isLoadingMore ? 1 : 0),
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          if (index == _devices.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(
                                    color: Colors.white),
                              ),
                            );
                          }

                          final device = _devices[index];
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
                                          color: Colors.red.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.red,
                                            width: 1,
                                          ),
                                        ),
                                        child: const Text(
                                          '已禁用',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '禁用时间: ${_formatTime(device['created_at'])}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon:
                                            const Icon(Icons.people, size: 16),
                                        label: const Text('查看关联用户'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => _showDeviceUsers(
                                            device['device_code']),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.lock_open,
                                            size: 16),
                                        label: const Text('解除禁用'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                        ),
                                        onPressed: () =>
                                            _unbanDevice(device['device_code']),
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
        ],
      ),
    );
  }
}
