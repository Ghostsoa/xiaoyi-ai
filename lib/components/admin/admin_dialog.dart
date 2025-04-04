import 'package:flutter/material.dart';

class AdminDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final double? width;
  final Color? titleColor;
  final EdgeInsetsGeometry? contentPadding;

  const AdminDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.width,
    this.titleColor,
    this.contentPadding,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    double? width,
    Color? titleColor,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AdminDialog(
        title: title,
        content: content,
        actions: actions,
        width: width,
        titleColor: titleColor,
        contentPadding: contentPadding,
      ),
    );
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    bool danger = false,
  }) async {
    final result = await show<bool>(
      context: context,
      title: title,
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelText ?? '取消',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmText ?? '确定',
            style: TextStyle(
              color: danger ? Colors.red : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: width ?? MediaQuery.of(context).size.width * 0.85,
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.95),
              Theme.of(context).colorScheme.secondary.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor ?? Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: contentPadding ?? const EdgeInsets.all(16),
                child: content,
              ),
            ),
            // 操作按钮
            if (actions != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                child: OverflowBar(
                  children: actions!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
