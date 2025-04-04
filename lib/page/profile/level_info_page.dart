import 'package:flutter/material.dart';

class LevelInfoPage extends StatelessWidget {
  final Map<String, dynamic> assetData;

  const LevelInfoPage({
    super.key,
    required this.assetData,
  });

  String _getLevelTitle(int level) {
    if (level >= 3) {
      return '劳懿';
    } else if (level == 2) {
      return '小懿';
    } else {
      return '小小懿';
    }
  }

  Color _getLevelColor(int level) {
    if (level >= 3) {
      return const Color(0xFFFFD700); // 金色
    } else if (level == 2) {
      return const Color(0xFF40E0D0); // 青绿色
    } else {
      return const Color(0xFFB0C4DE); // 淡蓝灰色
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = assetData['level'] as int;
    final exp = assetData['exp'] as int;
    final nextLevelExp = assetData['next_level_exp'] as int;
    final currentLevelExp = assetData['current_level_exp'] as int;
    final expProgress = (assetData['exp_progress'] as num).toDouble();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '等级说明',
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
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 当前等级信息
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.military_tech,
                          size: 32,
                          color: _getLevelColor(level),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getLevelTitle(level),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _getLevelColor(level),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '当前经验: $exp',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '当前等级所需: $currentLevelExp',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '下一级所需: $nextLevelExp',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: expProgress / 100,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getLevelColor(level),
                            ),
                            minHeight: 8,
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              '${expProgress.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                height: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 等级说明
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '等级制度说明',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLevelItem(
                      '小小懿',
                      '初入江湖的新手，正在努力成长中~',
                      const Color(0xFFB0C4DE),
                    ),
                    const SizedBox(height: 16),
                    _buildLevelItem(
                      '小懿',
                      '初有所成，展现出不俗的潜力！',
                      const Color(0xFF40E0D0),
                    ),
                    const SizedBox(height: 16),
                    _buildLevelItem(
                      '劳懿',
                      '实力非凡，已是江湖翘楚！',
                      const Color(0xFFFFD700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelItem(String title, String description, Color color) {
    return Row(
      children: [
        Icon(
          Icons.military_tech,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
