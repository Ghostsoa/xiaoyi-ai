import 'package:flutter/material.dart';
import '../custom_dialog.dart';

class AboutUsDialog {
  static void show(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    CustomDialog.show(
      context: context,
      title: '关于我们',
      width: width * 0.9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Text(
            '小懿AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '版本 1.0.0',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '小懿AI是一款专注于角色扮演的AI助手应用。我们致力于为用户提供安全、有趣、富有创意的对话体验。通过先进的AI技术，为您打造专属的虚拟角色互动空间。',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '关闭',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
