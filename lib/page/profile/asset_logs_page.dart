import 'package:flutter/material.dart';
import '../../net/profile/profile_service.dart';
import 'package:intl/intl.dart';
import '../../components/custom_snack_bar.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class AssetLogsPage extends StatefulWidget {
  const AssetLogsPage({super.key});

  @override
  State<AssetLogsPage> createState() => _AssetLogsPageState();
}

class _AssetLogsPageState extends State<AssetLogsPage> {
  final _profileService = ProfileService();
  final RefreshController _refreshController = RefreshController();
  final List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _logs.clear();
      _currentPage = 1;
      _hasMore = true;
    });
    await _loadLogs();
  }

  Future<void> _onLoading() async {
    if (!_hasMore) {
      _refreshController.loadNoData();
      return;
    }
    _currentPage++;
    await _loadLogs();
  }

  Future<void> _loadLogs() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final (result, message) = await _profileService.getAssetLogs(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (result != null && mounted) {
        final logs = (result['logs'] as List).cast<Map<String, dynamic>>();
        final pagination = result['pagination'] as Map<String, dynamic>;

        setState(() {
          if (_currentPage == 1) {
            _logs.clear();
            _logs.addAll(logs);
            _refreshController.refreshCompleted();
          } else {
            _logs.addAll(logs);
            _refreshController.loadComplete();
          }
          _hasMore = _logs.length < (pagination['total'] as int);
          if (!_hasMore) {
            _refreshController.loadNoData();
          }
          _isLoading = false;
        });
      } else if (mounted) {
        CustomSnackBar.show(
          context,
          message: message ?? '加载资产变动记录失败',
        );
        setState(() {
          _isLoading = false;
          if (_currentPage == 1) {
            _refreshController.refreshFailed();
          } else {
            _refreshController.loadFailed();
          }
        });
      }
    } catch (e) {
      print('加载资产变动记录失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_currentPage == 1) {
            _refreshController.refreshFailed();
          } else {
            _refreshController.loadFailed();
          }
        });
      }
    }
  }

  String _getChangeTypeText(int changeType) {
    switch (changeType) {
      case 1:
        return '获赠';
      case 2:
        return '消耗';
      case 3:
        return '退款';
      case 4:
        return '赠送';
      default:
        return '其他';
    }
  }

  Color _getAmountColor(double amount) {
    return amount >= 0 ? Colors.green : Colors.red;
  }

  IconData _getChangeTypeIcon(int changeType) {
    switch (changeType) {
      case 1:
        return Icons.card_giftcard;
      case 2:
        return Icons.shopping_cart_outlined;
      case 3:
        return Icons.replay_outlined;
      case 4:
        return Icons.redeem_outlined;
      default:
        return Icons.swap_horiz_outlined;
    }
  }

  Color _getChangeTypeColor(int changeType) {
    switch (changeType) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '资产变动记录',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
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
          child: SmartRefresher(
            controller: _refreshController,
            enablePullDown: true,
            enablePullUp: true,
            header: WaterDropMaterialHeader(
              backgroundColor: Theme.of(context).primaryColor,
              color: Colors.white,
            ),
            footer: const ClassicFooter(
              loadStyle: LoadStyle.ShowWhenLoading,
              completeDuration: Duration(milliseconds: 500),
              loadingText: '加载中...',
              canLoadingText: '释放加载更多',
              idleText: '上拉加载更多',
              failedText: '加载失败，请重试',
              noDataText: '没有更多数据了',
              textStyle: TextStyle(color: Colors.white70),
            ),
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            child: _isLoading && _currentPage == 1
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: 20,
                    itemBuilder: (context, index) => _buildSkeletonItem(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final amount = (log['amount'] as num).toDouble();
                      final dateTime = DateTime.parse(log['created_at']);
                      final formattedDate =
                          DateFormat('MM-dd HH:mm').format(dateTime);

                      return InkWell(
                        onTap: () => _showLogDetail(log),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                                width: 0.5,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 左侧图标和类型
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  _getChangeTypeIcon(log['change_type']),
                                  color:
                                      _getChangeTypeColor(log['change_type']),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 中间内容
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _getChangeTypeText(
                                              log['change_type']),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.5),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (log['remark'] != null &&
                                        log['remark'].isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        log['remark'],
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 右侧金额
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${log['change_type'] == 2 ? "-" : (amount >= 0 ? "+" : "")}${log['change_type'] == 2 ? amount.abs().toStringAsFixed(2) : amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: log['change_type'] == 2
                                          ? Colors.red
                                          : _getAmountColor(amount),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '小懿币: ${log['balance'].toStringAsFixed(2)}',
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
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  void _showLogDetail(Map<String, dynamic> log) {
    final amount = (log['amount'] as num).toDouble();
    final dateTime = DateTime.parse(log['created_at']);
    final formattedDate = DateFormat('yyyy年MM月dd日 HH:mm:ss').format(dateTime);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部把手
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 类型和时间
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getChangeTypeColor(log['change_type'])
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getChangeTypeIcon(log['change_type']),
                              color: _getChangeTypeColor(log['change_type']),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getChangeTypeText(log['change_type']),
                              style: TextStyle(
                                color: _getChangeTypeColor(log['change_type']),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 金额变动
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '变动',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${log['change_type'] == 2 ? "-" : (amount >= 0 ? "+" : "")}${log['change_type'] == 2 ? amount.abs().toStringAsFixed(2) : amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: log['change_type'] == 2
                              ? Colors.red
                              : _getAmountColor(amount),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 当前余额
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '小懿币',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${log['balance'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (log['exp'] != 0) ...[
                    const SizedBox(height: 12),
                    // 经验值变动
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '经验变动',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${log['exp'] >= 0 ? "+" : ""}${log['exp']}',
                          style: TextStyle(
                            color: log['exp'] >= 0 ? Colors.green : Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (log['remark'] != null && log['remark'].isNotEmpty) ...[
                    const SizedBox(height: 16),
                    // 备注信息
                    Text(
                      '备注信息',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        log['remark'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧图标骨架
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 12),
          // 中间内容骨架
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 右侧金额骨架
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 90,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
