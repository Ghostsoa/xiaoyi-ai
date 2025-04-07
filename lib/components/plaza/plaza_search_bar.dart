import 'package:flutter/material.dart';

class PlazaSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;

  const PlazaSearchBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          isDense: true,
          hintText: '搜索作品名称、简介、标签、作者',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(Icons.search,
              color: Colors.white.withOpacity(0.5), size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}
