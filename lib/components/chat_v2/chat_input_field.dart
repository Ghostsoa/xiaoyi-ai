import 'package:flutter/material.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback? onSend;
  final VoidCallback? onPanelToggle;
  final FocusNode? focusNode;
  final String hintText;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final EdgeInsetsGeometry? padding;
  final int? maxLines;
  final int? minLines;

  const ChatInputField({
    Key? key,
    required this.controller,
    this.isLoading = false,
    this.onSend,
    this.onPanelToggle,
    this.focusNode,
    this.hintText = '输入消息...',
    this.backgroundColor = Colors.black26,
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
    this.padding,
    this.maxLines = 5,
    this.minLines = 1,
  }) : super(key: key);

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _hasText = false;
  bool _isFocused = false;
  late AnimationController _animationController;
  late Animation<double> _sendButtonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_updateTextState);

    // 设置发送按钮动画
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _sendButtonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _focusNode.removeListener(_handleFocusChange);
    widget.controller.removeListener(_updateTextState);
    _animationController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _updateTextState() {
    final hasText = widget.controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
      if (hasText) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _handleSubmit() {
    if (!_hasText || widget.isLoading || widget.onSend == null) return;
    widget.onSend!();
  }

  void _insertParentheses() {
    final TextEditingController controller = widget.controller;
    final TextSelection selection = controller.selection;
    final String currentText = controller.text;

    // 插入括号
    final newText = currentText.substring(0, selection.start) +
        '()' +
        currentText.substring(selection.end);

    // 更新文本
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + 1, // 将光标放在括号中间
      ),
    );

    // 确保输入框保持焦点
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: widget.padding ??
          EdgeInsets.symmetric(horizontal: 8, vertical: _isFocused ? 10 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 左侧面板图标
          IconButton(
            icon: Icon(Icons.menu, color: widget.iconColor),
            onPressed: widget.onPanelToggle,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            splashRadius: 20,
          ),
          const SizedBox(width: 4),
          // 输入框区域
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isFocused
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isFocused
                      ? primaryColor.withOpacity(0.5)
                      : Colors.white.withOpacity(0.2),
                  width: _isFocused ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // 括号输入按钮
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _insertParentheses,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          child: Text(
                            '( )',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: widget.iconColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 输入框
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration.collapsed(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: widget.textColor.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                      maxLines: widget.maxLines,
                      minLines: widget.minLines,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _handleSubmit(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          ScaleTransition(
            scale: _sendButtonScaleAnimation,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _hasText ? _handleSubmit : null,
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _hasText && !widget.isLoading
                        ? primaryColor
                        : Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: _hasText && !widget.isLoading
                        ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: widget.isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(widget.iconColor),
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: _hasText
                              ? Colors.white
                              : widget.iconColor.withOpacity(0.5),
                          size: 22,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
