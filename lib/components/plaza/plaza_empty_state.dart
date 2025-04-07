import 'package:flutter/material.dart';

class PlazaEmptyState extends StatelessWidget {
  final bool isLoading;
  final bool isError;

  const PlazaEmptyState({
    super.key,
    required this.isLoading,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: MediaQuery.of(context).size.height - 100,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (isError) {
      return Container(
        height: MediaQuery.of(context).size.height - 100,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '下拉刷新重试',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height - 100,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无在线角色卡',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '下拉刷新试试',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
