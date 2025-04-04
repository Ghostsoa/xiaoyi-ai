import 'package:flutter/material.dart';
import '../custom_dialog.dart';

class PrivacyPolicyDialog {
  static void show(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    CustomDialog.show(
      context: context,
      title: '隐私政策',
      width: width * 0.9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '我们重视您的隐私',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '1. 信息收集',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '我们仅收集必要的用户信息（如邮箱、用户名）用于账号管理和服务提供。对话内容将被加密存储，用于提供AI服务和改善用户体验。',
                  style:
                      TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                ),
                SizedBox(height: 16),
                Text(
                  '2. 信息使用',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '收集的信息仅用于：\n• 提供和改进AI对话服务\n• 个性化用户体验\n• 账号管理和安全验证\n• 必要的系统通知',
                  style:
                      TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                ),
                SizedBox(height: 16),
                Text(
                  '3. 信息安全',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '我们采用业界标准的加密技术保护您的个人信息和对话内容。未经您的同意，我们不会向第三方分享您的个人信息。',
                  style:
                      TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                ),
                SizedBox(height: 16),
                Text(
                  '4. 用户权利',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '您有权：\n• 访问和修改您的个人信息\n• 删除您的账号和相关数据\n• 选择退出个性化服务\n• 了解您的信息使用情况',
                  style:
                      TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                ),
                SizedBox(height: 16),
                Text(
                  '5. 政策更新',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '我们保留随时更新本隐私政策的权利。更新后的政策将在应用内发布，并通知用户重要变更。',
                  style:
                      TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                ),
                SizedBox(height: 16),
                Text(
                  '如您对我们的隐私政策有任何疑问，请通过应用内的反馈功能联系我们。',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '我知道了',
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
