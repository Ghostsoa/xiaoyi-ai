import 'package:flutter/material.dart';
import '../custom_dialog.dart';

class DisclaimerDialog {
  static void show(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    CustomDialog.show(
      context: context,
      title: '免责声明',
      width: width * 0.9,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '请仔细阅读以下声明：',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. 本应用仅供娱乐和学习交流使用，禁止用于任何违法、违规或不当用途。',
                      style: TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '2. 严禁利用本应用生成、传播任何涉及暴力、色情、歧视、政治敏感等违法违规内容。',
                      style: TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '3. AI生成的内容可能存在不准确性，用户应自行判断其真实性和适用性。',
                      style: TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '4. 用户在使用过程中产生的所有内容和行为均由用户本人承担全部责任。',
                      style: TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '5. 如违反上述规定，我们将保留追究相关法律责任的权利。',
                      style: TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '6. 我们保留随时修改本声明的权利，修改后的声明将在应用内公布。',
                      style: TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '本应用的所有权利均归小懿AI所有。本声明的最终解释权归小懿AI所有。',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
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
