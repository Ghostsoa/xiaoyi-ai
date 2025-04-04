import 'dart:async';
import 'package:flutter/material.dart';
import '../../components/custom_snack_bar.dart';
import '../../net/lottery/lottery_service.dart';

class LotteryPage extends StatefulWidget {
  const LotteryPage({super.key});

  @override
  State<LotteryPage> createState() => _LotteryPageState();
}

class _LotteryPageState extends State<LotteryPage>
    with SingleTickerProviderStateMixin {
  final _lotteryService = LotteryService();

  // 九宫格的奖品，使用后端的Value值来表示
  final List<Map<String, dynamic>> _prizes = [
    {'name': '520币', 'value': 520, 'color': Colors.deepPurple},
    {'name': '100币', 'value': 100, 'color': Colors.amber},
    {'name': '20币', 'value': 20, 'color': Colors.orange},
    {'name': '5币', 'value': 5, 'color': Colors.green},
    {'name': '1币', 'value': 1, 'color': Colors.blue},
    {'name': '-1币', 'value': -1, 'color': Colors.pink},
    {'name': '-5币', 'value': -5, 'color': Colors.red},
    {'name': '-10币', 'value': -10, 'color': Colors.red.shade900},
  ];

  int _currentHighlightIndex = 0;
  bool _isSpinning = false;
  Timer? _spinTimer;
  int _spinCount = 0;
  int _targetPrizeIndex = -1;
  Map<String, dynamic>? _wonPrize;

  // 动画控制器
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animationController.value = 1.0;
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // 开始抽奖
  Future<void> _startLottery() async {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _spinCount = 0;
      _targetPrizeIndex = -1;
      _wonPrize = null;
    });

    // 先快速转动九宫格
    _spinFast();

    // 调用抽奖API
    final result = await _lotteryService.draw();
    print('抽奖结果: $result');

    if (result['success']) {
      final prize = result['prize'];
      print('获得奖品: $prize');
      // 使用Value属性匹配奖品
      final value = prize['Value'];
      final prizeIndex = _prizes.indexWhere((p) => p['value'] == value);

      if (prizeIndex != -1) {
        print('找到匹配奖品索引: $prizeIndex, 奖品: ${_prizes[prizeIndex]}');
        // 计算九宫格位置对应的真实索引
        int gridIndex = prizeIndex >= 4 ? prizeIndex + 1 : prizeIndex;
        _targetPrizeIndex = gridIndex;
        print('目标九宫格索引: $_targetPrizeIndex');

        // 创建包含前端和后端字段的混合奖品对象
        _wonPrize = {
          'name': _prizes[prizeIndex]['name'],
          'value': prize['Value'],
          'color': _prizes[prizeIndex]['color'],
          // 保留后端原始数据
          'ID': prize['ID'],
          'Name': prize['Name'],
          'Value': prize['Value'],
          'Probability': prize['Probability'],
        };
      } else {
        print('未找到匹配奖品，Value: $value');
        // 回退策略：使用接近的值
        _prizes.sort((a, b) {
          return (a['value'] - value)
              .abs()
              .compareTo((b['value'] - value).abs());
        });
        final closestPrize = _prizes[0];
        final closestIndex = _prizes.indexOf(closestPrize);
        int gridIndex = closestIndex >= 4 ? closestIndex + 1 : closestIndex;
        _targetPrizeIndex = gridIndex;
        print('使用最接近的奖品: $closestPrize, 索引: $_targetPrizeIndex');

        _wonPrize = {
          ...closestPrize,
          'ID': prize['ID'],
          'Name': prize['Name'],
          'Value': prize['Value'],
          'Probability': prize['Probability'],
        };
      }
    } else {
      // 抽奖失败
      _spinTimer?.cancel();
      setState(() {
        _isSpinning = false;
      });

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: result['error'],
        );
      }
    }
  }

  // 快速转动
  void _spinFast() {
    _spinTimer?.cancel();

    _spinTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        // 环绕式转动：0->1->2->5->8->7->6->3->0...
        switch (_currentHighlightIndex) {
          case 0:
            _currentHighlightIndex = 1;
            break;
          case 1:
            _currentHighlightIndex = 2;
            break;
          case 2:
            _currentHighlightIndex = 5;
            break;
          case 5:
            _currentHighlightIndex = 8;
            break;
          case 8:
            _currentHighlightIndex = 7;
            break;
          case 7:
            _currentHighlightIndex = 6;
            break;
          case 6:
            _currentHighlightIndex = 3;
            break;
          case 3:
            _currentHighlightIndex = 0;
            break;
          default:
            _currentHighlightIndex = 0; // 安全处理
        }
        _spinCount++;
      });

      // 如果已经设置了目标奖品，且已经转动了至少20次，开始减速
      if (_targetPrizeIndex != -1 && _spinCount > 20) {
        _spinTimer?.cancel();
        _spinSlow();
      }
    });
  }

  // 慢速转动，直到停在目标奖品上
  void _spinSlow() {
    print('开始减速，目标位置: $_targetPrizeIndex');
    _spinTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        // 环绕式转动：0->1->2->5->8->7->6->3->0...
        switch (_currentHighlightIndex) {
          case 0:
            _currentHighlightIndex = 1;
            break;
          case 1:
            _currentHighlightIndex = 2;
            break;
          case 2:
            _currentHighlightIndex = 5;
            break;
          case 5:
            _currentHighlightIndex = 8;
            break;
          case 8:
            _currentHighlightIndex = 7;
            break;
          case 7:
            _currentHighlightIndex = 6;
            break;
          case 6:
            _currentHighlightIndex = 3;
            break;
          case 3:
            _currentHighlightIndex = 0;
            break;
          default:
            _currentHighlightIndex = 0; // 安全处理
        }
      });

      // 检查是否到达目标位置的前一个位置
      bool isNextPositionTarget = false;
      switch (_currentHighlightIndex) {
        case 0:
          isNextPositionTarget = _targetPrizeIndex == 1;
          break;
        case 1:
          isNextPositionTarget = _targetPrizeIndex == 2;
          break;
        case 2:
          isNextPositionTarget = _targetPrizeIndex == 5;
          break;
        case 5:
          isNextPositionTarget = _targetPrizeIndex == 8;
          break;
        case 8:
          isNextPositionTarget = _targetPrizeIndex == 7;
          break;
        case 7:
          isNextPositionTarget = _targetPrizeIndex == 6;
          break;
        case 6:
          isNextPositionTarget = _targetPrizeIndex == 3;
          break;
        case 3:
          isNextPositionTarget = _targetPrizeIndex == 0;
          break;
      }

      if (isNextPositionTarget) {
        _spinTimer?.cancel();
        print('到达目标前一个位置: $_currentHighlightIndex, 目标: $_targetPrizeIndex');

        // 最后一次转动，停在目标奖品上
        Future.delayed(const Duration(milliseconds: 300), () {
          setState(() {
            _currentHighlightIndex = _targetPrizeIndex;
          });
          print('已到达目标位置: $_currentHighlightIndex');

          // 显示中奖结果
          Future.delayed(const Duration(milliseconds: 500), () {
            _showWinResult();
            setState(() {
              _isSpinning = false;
            });
          });
        });
      }
    });
  }

  // 显示中奖结果
  void _showWinResult() {
    if (_wonPrize != null && mounted) {
      final isPositive = _wonPrize!['Value'] > 0;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isPositive ? '恭喜中奖！' : '很遗憾...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.deepPurple : Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.emoji_events : Icons.mood_bad,
                size: 60,
                color: isPositive ? Colors.amber : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                isPositive
                    ? '您获得了 ${_wonPrize!['Name'] ?? _wonPrize!['name']}'
                    : '您抽中了 ${_wonPrize!['Name'] ?? _wonPrize!['name']}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.black87 : Colors.red.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPositive
                    ? '+${_wonPrize!['Value'].abs()} 小懿币'
                    : '-${_wonPrize!['Value'].abs()} 小懿币',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.deepOrange : Colors.red,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isPositive ? '太棒了！' : '知道了'),
            ),
          ],
        ),
      );
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
          '小懿抽奖',
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // 标题
                Text(
                  '幸运九宫格',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(1, 1),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '每次抽奖需要保持账户至少50小懿币',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),
                // 九宫格
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          final isCenter = index == 4;
                          final isHighlighted =
                              index == _currentHighlightIndex && !isCenter;

                          if (isCenter) {
                            // 中心按钮
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: _isSpinning ? null : _startLottery,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.transparent,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _isSpinning ? '抽奖中...' : '开始\n抽奖',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          // 普通奖品格子
                          final prize = _prizes[index > 4 ? index - 1 : index];

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? Colors.white
                                  : prize['color'].withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isHighlighted
                                    ? Colors.yellow
                                    : Colors.white.withOpacity(0.3),
                                width: isHighlighted ? 3 : 1,
                              ),
                              boxShadow: isHighlighted
                                  ? [
                                      BoxShadow(
                                        color: Colors.yellow.withOpacity(0.6),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                prize['name'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isHighlighted
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // 说明
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '抽奖规则',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...[
                          '1. 抽奖需要保持账户余额至少50小懿币',
                          '2. 每次抽奖有机会获得不同数量的小懿币',
                          '3. 抽奖有冷却时间，请勿频繁操作',
                          '4. 最终解释权归平台所有'
                        ].map((text) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            )),
                        const SizedBox(height: 16),
                        const Text(
                          '抽奖说明',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '抽奖功能仅为娱乐，请勿盲目上头',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '概率说明:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Table(
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(1),
                          },
                          children: [
                            _buildProbabilityRow(
                                "520币", "0.8%", Colors.deepPurple),
                            _buildProbabilityRow("100币", "1%", Colors.amber),
                            _buildProbabilityRow("20币", "5.2%", Colors.orange),
                            _buildProbabilityRow("5币", "10%", Colors.green),
                            _buildProbabilityRow("1币", "30%", Colors.blue),
                            _buildProbabilityRow("扣除1币", "33%", Colors.pink),
                            _buildProbabilityRow("扣除5币", "15%", Colors.red),
                            _buildProbabilityRow(
                                "扣除10币", "5%", Colors.red.shade900),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TableRow _buildProbabilityRow(String prize, String probability, Color color) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                prize,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Text(
          probability,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
