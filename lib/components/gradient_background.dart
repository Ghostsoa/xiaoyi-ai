import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? gradientColors;
  final AlignmentGeometry? begin;
  final AlignmentGeometry? end;

  const GradientBackground({
    super.key,
    required this.child,
    this.gradientColors,
    this.begin,
    this.end,
  });

  @override
  Widget build(BuildContext context) {
    // 默认使用深邃优雅的渐变色
    final defaultColors = [
      const Color(0xFF1F1D2B), // 深邃的靛青色
      const Color(0xFF252837), // 深蓝灰色
      const Color(0xFF2D2D3F), // 深紫灰色
    ];

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin ?? Alignment.topCenter,
          end: end ?? Alignment.bottomCenter,
          colors: gradientColors ?? defaultColors,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}
