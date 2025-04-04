import 'dart:async';
import 'package:flutter/material.dart';
import '../../../net/admin/statistics_service.dart';
import '../../../components/loading_indicator.dart';
import '../../../components/custom_snack_bar.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _statisticsService = AdminStatisticsService();
  Map<String, dynamic>? _monthlyStats;
  List<Map<String, dynamic>>? _dailyStats;
  Map<String, dynamic>? _monitorStats;
  Timer? _monitorTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    // 每30秒更新一次系统监控数据
    _monitorTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadMonitorStats();
    });
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final futures = await Future.wait([
        _statisticsService.getMonthlyStats(),
        _statisticsService.getDailyStats(),
        _statisticsService.getMonitorStats(),
      ]);

      if (mounted) {
        setState(() {
          final (monthlyStats, _) =
              futures[0] as (Map<String, dynamic>?, String?);
          final (dailyStats, _) =
              futures[1] as (List<Map<String, dynamic>>?, String?);
          final (monitorStats, _) =
              futures[2] as (Map<String, dynamic>?, String?);

          _monthlyStats = monthlyStats;
          _dailyStats = dailyStats;
          _monitorStats = monitorStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '加载数据失败：$e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMonitorStats() async {
    try {
      final (stats, message) = await _statisticsService.getMonitorStats();
      if (stats != null && mounted) {
        setState(() => _monitorStats = stats);
      } else if (mounted && message != null) {
        print('加载系统监控数据失败: $message');
      }
    } catch (e) {
      print('加载系统监控数据失败: $e');
    }
  }

  String _formatNumber(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
    } else if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 基础数据统计
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '基础数据统计',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _monthlyStats?['month'] ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      label: '总用户数',
                      value: _formatNumber(_monthlyStats?['total_users'] ?? 0),
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      label: '总付费用户',
                      value: _formatNumber(
                          _monthlyStats?['total_paying_users'] ?? 0),
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      label: '本月新增付费',
                      value: _formatNumber(
                          _monthlyStats?['monthly_new_paying_users'] ?? 0),
                      icon: Icons.trending_up,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      label: '总请求数',
                      value:
                          _formatNumber(_monthlyStats?['total_requests'] ?? 0),
                      icon: Icons.bar_chart,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 今日数据
        if (_dailyStats?.isNotEmpty ?? false)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '今日数据',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _dailyStats?.first['date'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        label: '新增用户',
                        value:
                            _formatNumber(_dailyStats?.first['new_users'] ?? 0),
                        icon: Icons.person_add,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        label: '登录用户',
                        value: _formatNumber(
                            _dailyStats?.first['login_users'] ?? 0),
                        icon: Icons.login,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        label: '新增付费',
                        value: _formatNumber(
                            _dailyStats?.first['new_paying_users'] ?? 0),
                        icon: Icons.attach_money,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        label: '总付费用户',
                        value: _formatNumber(
                            _dailyStats?.first['total_paying_users'] ?? 0),
                        icon: Icons.group,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // 近7天数据趋势
        if (_dailyStats != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '近7天数据趋势',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                for (final data in _dailyStats!.reversed) ...[
                  _buildDailyStatItem(data),
                  if (data != _dailyStats!.first)
                    const Divider(height: 16, color: Colors.white24),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 系统监控
        if (_monitorStats != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '系统监控',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '更新时间: ${_formatDate(_monitorStats!['updated_at'])}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMonitorItem(
                        label: 'CPU使用率',
                        value:
                            '${_monitorStats!['cpu']['usage'].toStringAsFixed(1)}%',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMonitorItem(
                        label: '内存使用率',
                        value:
                            '${_monitorStats!['memory']['usage'].toStringAsFixed(1)}%',
                        subValue:
                            '已用: ${_formatBytes(_monitorStats!['memory']['used'])}',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMonitorItem(
                        label: '带宽使用率',
                        value:
                            '${_monitorStats!['network']['bandwidth'].toStringAsFixed(1)}%',
                        subValue:
                            '发送: ${_formatBytes(_monitorStats!['network']['bytes_sent'])}',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMonitorItem(
                        label: '磁盘IO使用率',
                        value:
                            '${_monitorStats!['disk']['io_usage'].toStringAsFixed(1)}%',
                        subValue:
                            '读: ${_formatBytes(_monitorStats!['disk']['read_bytes'])}',
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStatItem(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data['date'],
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDailyStatValue(
                label: '新增用户',
                value: data['new_users'],
                color: Colors.blue,
              ),
              const SizedBox(width: 24),
              _buildDailyStatValue(
                label: '登录用户',
                value: data['login_users'],
                color: Colors.green,
              ),
              const SizedBox(width: 24),
              _buildDailyStatValue(
                label: '新增付费',
                value: data['new_paying_users'],
                color: Colors.orange,
              ),
              const SizedBox(width: 24),
              _buildDailyStatValue(
                label: '总付费用户',
                value: data['total_paying_users'],
                color: Colors.purple,
              ),
              const SizedBox(width: 24),
              _buildDailyStatValue(
                label: '请求次数',
                value: data['request_count'],
                color: Colors.teal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyStatValue({
    required String label,
    required int value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatNumber(value),
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMonitorItem({
    required String label,
    required String value,
    String? subValue,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 4),
            Text(
              subValue,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
