import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  final String? message;
  final String? buttonText;
  final VoidCallback? onAction;
  final double? iconSize;
  final Color? iconColor;
  final TextStyle? messageStyle;
  final TextStyle? buttonStyle;
  final Widget? customIcon;

  const EmptyView({
    super.key,
    this.message = '暂无数据',
    this.buttonText,
    this.onAction,
    this.iconSize = 64.0,
    this.iconColor,
    this.messageStyle,
    this.buttonStyle,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            customIcon ??
                Icon(
                  Icons.inbox_outlined,
                  size: iconSize,
                  color: iconColor ?? theme.disabledColor,
                ),
            const SizedBox(height: 16),
            Text(
              message!,
              style: messageStyle ??
                  theme.textTheme.bodyLarge?.copyWith(
                    color: theme.disabledColor,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && buttonText != null) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: onAction,
                child: Text(
                  buttonText!,
                  style: buttonStyle ??
                      theme.textTheme.labelLarge?.copyWith(
                        color: theme.primaryColor,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
