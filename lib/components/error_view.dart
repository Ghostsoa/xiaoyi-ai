import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String? message;
  final String? buttonText;
  final VoidCallback? onRetry;
  final double? iconSize;
  final Color? iconColor;
  final TextStyle? messageStyle;
  final TextStyle? buttonStyle;

  const ErrorView({
    super.key,
    this.message = '出错了，请稍后重试',
    this.buttonText = '重试',
    this.onRetry,
    this.iconSize = 64.0,
    this.iconColor,
    this.messageStyle,
    this.buttonStyle,
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
            Icon(
              Icons.error_outline,
              size: iconSize,
              color: iconColor ?? theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message!,
              style: messageStyle ??
                  theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: onRetry,
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
