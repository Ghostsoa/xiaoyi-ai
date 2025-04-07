import 'package:flutter/material.dart';

class PlazaCategoryBar extends StatelessWidget {
  final String? currentCategory;
  final String sortBy;
  final Function(String?) onCategoryChanged;
  final Function(String) onSortChanged;

  const PlazaCategoryBar({
    super.key,
    required this.currentCategory,
    required this.sortBy,
    required this.onCategoryChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(bottom: 0),
      child: Row(
        children: [
          // 分类选择
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(context, '全部', null),
                _buildCategoryChip(context, '单人', 'single'),
                _buildCategoryChip(context, '多人', 'multi'),
              ],
            ),
          ),
          // 排序按钮
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                _buildSortChip('最新', 'time'),
                const SizedBox(width: 12),
                _buildSortChip('最热', 'downloads'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String label, String? value) {
    final isSelected = currentCategory == value;
    return Container(
      margin: const EdgeInsets.only(right: 24),
      child: InkWell(
        onTap: () => onCategoryChanged(value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 15,
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

  Widget _buildSortChip(String label, String value) {
    final isSelected = sortBy == value;
    return InkWell(
      onTap: () => onSortChanged(value),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white60,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }
}
