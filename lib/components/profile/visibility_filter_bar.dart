import 'package:flutter/material.dart';

/// 个人作品的可见性筛选组件
class VisibilityFilterBar extends StatelessWidget {
  final String currentVisibility;
  final Function(String) onVisibilityChanged;

  const VisibilityFilterBar({
    super.key,
    required this.currentVisibility,
    required this.onVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      margin: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                _buildFilterChip(context, '全部', 'all'),
                _buildFilterChip(context, '公开', 'public'),
                _buildFilterChip(context, '非公开', 'private'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value) {
    final isSelected = currentVisibility == value;
    return Container(
      margin: const EdgeInsets.only(right: 20),
      child: InkWell(
        onTap: () => onVisibilityChanged(value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 12,
              height: 2,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
