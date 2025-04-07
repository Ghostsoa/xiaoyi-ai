import 'package:flutter/material.dart';
import '../../net/check_in/check_in_service.dart';
import '../../components/custom_snack_bar.dart';

class CheckInCard extends StatefulWidget {
  const CheckInCard({super.key});

  @override
  State<CheckInCard> createState() => CheckInCardState();
}

class CheckInCardState extends State<CheckInCard> {
  final CheckInService _checkInService = CheckInService();
  bool _isLoading = false;
  bool _todayChecked = false;
  int _continuousDays = 0;
  List<bool> _weeklyStatus = List.filled(7, false);
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _loadCheckInStatus();
    _loadWeeklyCheckIn();
  }

  void refreshStatus() {
    if (_lastRefreshTime != null &&
        DateTime.now().difference(_lastRefreshTime!) <
            const Duration(seconds: 5)) {
      print('签到状态刚刚更新过，跳过刷新');
      return;
    }

    print('开始刷新签到状态');
    _loadCheckInStatus();
    _loadWeeklyCheckIn();
  }

  Future<void> _loadCheckInStatus() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final (data, errorMsg) = await _checkInService.getCheckInStatus();

      print('签到状态数据: $data');
      _lastRefreshTime = DateTime.now();

      if (data != null && mounted) {
        // 安全地获取数据
        final todayChecked = data['today_checked'] as bool? ?? false;
        final continuousDays = data['continuous_days'] as int? ?? 0;

        print('今日签到状态: $todayChecked');
        print('连续签到天数: $continuousDays');

        setState(() {
          _todayChecked = todayChecked;
          _continuousDays = continuousDays;
          _isLoading = false;
        });
      } else if (mounted) {
        print('获取签到状态失败: $errorMsg');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('获取签到状态异常: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWeeklyCheckIn() async {
    try {
      final (data, errorMsg) = await _checkInService.getWeeklyCheckIn();

      print('周签到数据: $data');

      if (data != null && mounted && data.containsKey('days')) {
        // 确保是List类型，然后将其转换为List<bool>
        List<dynamic> rawDays = data['days'] as List<dynamic>;
        List<bool> days = rawDays.map((item) => item as bool).toList();

        print('转换后的周签到状态: $days');

        // 检查是否有变化
        bool hasChanged = false;
        if (_weeklyStatus.length != days.length) {
          hasChanged = true;
        } else {
          for (int i = 0; i < days.length; i++) {
            if (_weeklyStatus[i] != days[i]) {
              hasChanged = true;
              break;
            }
          }
        }

        if (hasChanged) {
          print('周签到状态有变化，更新UI');
          setState(() {
            _weeklyStatus = days;
          });
        } else {
          print('周签到状态无变化');
        }
      } else {
        print('获取周签到数据失败或数据格式不正确: $errorMsg, 数据: $data');
      }
    } catch (e) {
      print('获取周签到异常: $e');
      // 处理错误
    }
  }

  Future<void> _performCheckIn() async {
    if (_isLoading || _todayChecked) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final (data, errorMsg) = await _checkInService.checkIn();

      print('签到响应数据: $data');
      print('签到错误信息: $errorMsg');

      if (data != null && mounted) {
        // 确保安全地获取数据
        final todayChecked = data['today_checked'] as bool? ?? false;
        final continuousDays = data['continuous_days'] as int? ?? 0;

        setState(() {
          _todayChecked = todayChecked;
          _continuousDays = continuousDays;
          _isLoading = false;
        });

        // 更新本周签到情况
        await _loadWeeklyCheckIn();

        // 显示签到奖励
        final reward = data['reward'] as num? ?? 0;
        CustomSnackBar.show(
          context,
          message: '签到成功！获得 $reward 小懿币' +
              (continuousDays > 1 ? ' (连续签到$continuousDays天)' : ''),
        );
      } else if (mounted) {
        print('签到失败，显示错误信息: $errorMsg');
        CustomSnackBar.show(context, message: errorMsg ?? '签到失败，请稍后再试');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('签到异常: $e');
      if (mounted) {
        CustomSnackBar.show(context, message: '签到失败: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).cardColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '每日签到',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '连续签到 $_continuousDays 天',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                return _buildDayItem(index);
              }),
            ),
            if (!_todayChecked) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _performCheckIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    disabledForegroundColor: Colors.grey.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '立即签到',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
            if (_continuousDays >= 6)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '连续签到7天可获得10小懿币大奖励！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFFFD700),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayItem(int index) {
    final dayNames = ['一', '二', '三', '四', '五', '六', '日'];
    final isChecked =
        _weeklyStatus.length > index ? _weeklyStatus[index] : false;

    return Column(
      children: [
        Text(
          dayNames[index],
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isChecked
                ? const Color(0xFF4CAF50)
                : Colors.white.withOpacity(0.1),
            border: Border.all(
              color: isChecked
                  ? const Color(0xFF4CAF50)
                  : Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: isChecked
              ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                )
              : null,
        ),
      ],
    );
  }
}
