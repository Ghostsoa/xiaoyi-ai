import 'package:flutter/material.dart';
import '../../../../components/custom_snack_bar.dart';
import '../../../../components/admin/admin_dialog.dart';
import '../../../../components/loading_indicator.dart';
import '../../../../net/admin/log_service.dart';

class LogManagePage extends StatefulWidget {
  const LogManagePage({super.key});

  @override
  State<LogManagePage> createState() => _LogManagePageState();
}

class _LogManagePageState extends State<LogManagePage> {
  final _logService = AdminLogService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _logs = [];
  int _currentPage = 1;
  int _totalCount = 0;
  static const _pageSize = 20;

  // 筛选条件
  int? _selectedSeverity;
  String? _selectedModule;
  String? _selectedFunction;
  DateTime? _startTime;
  DateTime? _endTime;

  // 日志配置和统计信息
  Map<String, dynamic>? _logConfig;
  Map<String, dynamic>? _logStats;
  List<String> _modules = [];
  List<String> _functions = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // 并行加载数据
      final futures = await Future.wait([
        _logService.getLogConfig(),
        _logService.getLogStats(),
        _logService.getModules(),
      ]);

      if (mounted) {
        setState(() {
          final (config, _) = futures[0] as (Map<String, dynamic>?, String?);
          final (stats, _) = futures[1] as (Map<String, dynamic>?, String?);
          final (modules, _) = futures[2] as (List<String>?, String?);

          _logConfig = config;
          _logStats = stats;
          _modules = modules ?? [];
        });

        // 加载完基础数据后，再加载日志列表
        await _loadLogs();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '加载数据失败：$e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLogs() async {
    if (_isLoading && _logs.isNotEmpty) return; // 防止重复加载

    setState(() => _isLoading = true);

    try {
      final (result, message) = await _logService.getErrorLogs(
        page: _currentPage,
        pageSize: _pageSize,
        severity: _selectedSeverity,
        module: _selectedModule,
        function: _selectedFunction,
        startTime: _startTime?.toIso8601String(),
        endTime: _endTime?.toIso8601String(),
      );

      if (result != null && mounted) {
        setState(() {
          _logs = (result['list'] as List).cast<Map<String, dynamic>>();
          _totalCount = result['total'] as int;
          _isLoading = false;
        });
      } else if (mounted) {
        CustomSnackBar.show(context, message: message ?? '加载日志失败');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '加载日志失败：$e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFunctions() async {
    if (_selectedModule == null) {
      setState(() => _functions = []);
      return;
    }

    try {
      final (functions, message) = await _logService.getFunctions(
        module: _selectedModule,
      );

      if (functions != null && mounted) {
        setState(() => _functions = functions);
      } else if (mounted) {
        // 如果获取函数列表失败，清空函数列表但不显示错误
        print('加载函数列表失败: $message');
        setState(() => _functions = []);
      }
    } catch (e) {
      // 如果发生错误，清空函数列表但不显示错误
      print('加载函数列表失败: $e');
      if (mounted) {
        setState(() => _functions = []);
      }
    }
  }

  Future<void> _triggerCleanup() async {
    final confirmed = await AdminDialog.confirm(
      context,
      title: '触发日志清理',
      content: '确定要手动触发日志清理吗？此操作将清理超过保留期限的日志。',
      confirmText: '确定',
      cancelText: '取消',
    );

    if (confirmed && mounted) {
      final message = await _logService.triggerCleanup();
      if (mounted) {
        CustomSnackBar.show(context, message: message ?? '触发日志清理失败');
        if (message?.contains('成功') ?? false) {
          _loadInitialData();
        }
      }
    }
  }

  String _getSeverityText(int severity) {
    switch (severity) {
      case 1:
        return '信息';
      case 2:
        return '警告';
      case 3:
        return '错误';
      case 4:
        return '严重';
      default:
        return '未知';
    }
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      case 4:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showLogDetail(Map<String, dynamic> log) async {
    await AdminDialog.show(
      context: context,
      title: '日志详情',
      width: 800,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', '#${log['id']}'),
            _buildDetailRow('模块', log['module']),
            _buildDetailRow('函数', log['function']),
            _buildDetailRow(
              '级别',
              _getSeverityText(log['severity']),
              color: _getSeverityColor(log['severity']),
            ),
            _buildDetailRow('时间', log['created_at']),
            _buildDetailRow('用户ID', log['user_id'].toString()),
            const Divider(height: 32),
            const Text(
              '错误信息',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                log['message'],
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            if (log['stack'] != null) ...[
              const SizedBox(height: 16),
              const Text(
                '堆栈信息',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log['stack'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            if (log['extra_data'] != null) ...[
              const SizedBox(height: 16),
              const Text(
                '额外数据',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log['extra_data'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_totalCount / _pageSize).ceil();

    return Column(
      children: [
        // 顶部统计栏
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧统计数据
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow(
                      label: '总日志数',
                      value: _logStats?['total_logs']?.toString() ?? '-',
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      label: '今日日志',
                      value: _logStats?['today_logs']?.toString() ?? '-',
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      label: '保留天数',
                      value: _logStats?['retention_days']?.toString() ?? '-',
                    ),
                  ],
                ),
              ),
              // 右侧清理按钮
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _triggerCleanup,
                    icon:
                        const Icon(Icons.cleaning_services_outlined, size: 18),
                    label: const Text('清理日志'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '下次清理: ${_logConfig?['next_cleanup_time'] ?? '-'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 筛选栏
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              // 错误级别
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<int>(
                  value: _selectedSeverity,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '级别',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部')),
                    for (var i = 1; i <= 4; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(_getSeverityText(i)),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSeverity = value;
                      _currentPage = 1;
                      _loadLogs();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              // 模块
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  value: _selectedModule,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '模块',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部')),
                    for (final module in _modules)
                      DropdownMenuItem(
                        value: module,
                        child: Text(
                          module,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedModule = value;
                      _selectedFunction = null;
                      _functions = []; // 立即清空函数列表
                      _currentPage = 1;
                    });
                    // 异步加载函数列表和日志
                    Future.wait([
                      _loadFunctions(),
                      _loadLogs(),
                    ]);
                  },
                ),
              ),
              const SizedBox(width: 16),
              // 函数
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  value: _selectedFunction,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '函数',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部')),
                    for (final function in _functions)
                      DropdownMenuItem(
                        value: function,
                        child: Text(
                          function,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _selectedModule == null || _functions.isEmpty
                      ? null
                      : (value) {
                          setState(() {
                            _selectedFunction = value;
                            _currentPage = 1;
                          });
                          _loadLogs();
                        },
                ),
              ),
              const SizedBox(width: 16),
              // 时间范围
              if (_startTime != null && _endTime != null)
                Chip(
                  label: Text(
                    '${_startTime!.toString().split(' ')[0]} 至 ${_endTime!.toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _startTime = null;
                      _endTime = null;
                      _currentPage = 1;
                      _loadLogs();
                    });
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (range != null && mounted) {
                      setState(() {
                        _startTime = range.start;
                        _endTime = range.end;
                        _currentPage = 1;
                        _loadLogs();
                      });
                    }
                  },
                  tooltip: '选择时间范围',
                ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _selectedSeverity = null;
                    _selectedModule = null;
                    _selectedFunction = null;
                    _startTime = null;
                    _endTime = null;
                    _currentPage = 1;
                    _loadLogs();
                  });
                },
                tooltip: '重置筛选',
              ),
            ],
          ),
        ),

        // 日志列表
        Expanded(
          child: _isLoading
              ? const Center(child: LoadingIndicator())
              : _logs.isEmpty
                  ? Center(
                      child: Text(
                        '暂无日志记录',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) =>
                          _buildLogItem(_logs[index]),
                    ),
        ),

        // 分页栏
        if (_totalCount > 0)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '共 $_totalCount 条记录',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() {
                            _currentPage--;
                            _loadLogs();
                          });
                        }
                      : null,
                ),
                Text(
                  '$_currentPage / $totalPages',
                  style: const TextStyle(color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < totalPages
                      ? () {
                          setState(() {
                            _currentPage++;
                            _loadLogs();
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatRow({required String label, required String value}) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showLogDetail(log),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 时间和ID行
                Row(
                  children: [
                    Text(
                      log['created_at'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '#${log['id']}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 级别和模块行
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _getSeverityColor(log['severity']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getSeverityText(log['severity']),
                        style: TextStyle(
                          color: _getSeverityColor(log['severity']),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${log['module']} > ${log['function']}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 错误信息行
                Text(
                  log['message'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
