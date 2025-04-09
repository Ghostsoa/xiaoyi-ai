import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool? enabled;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? style;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final InputBorder? border;
  final Color? fillColor;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled,
    this.onChanged,
    this.onSubmitted,
    this.contentPadding,
    this.style,
    this.labelStyle,
    this.hintStyle,
    this.border,
    this.fillColor,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscureText,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        inputFormatters: widget.inputFormatters,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        focusNode: _focusNode,
        style: widget.style ??
            theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white,
            ),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: _focusNode.hasFocus ? Colors.white : Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : widget.suffixIcon,
          contentPadding: widget.contentPadding ??
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: widget.labelStyle ??
              TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
          hintStyle: widget.hintStyle ??
              TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
          border: widget.border ?? _buildBorder(Colors.white.withOpacity(0.3)),
          enabledBorder:
              widget.border ?? _buildBorder(Colors.white.withOpacity(0.3)),
          focusedBorder: widget.border ?? _buildBorder(Colors.white),
          errorBorder: widget.border ?? _buildBorder(theme.colorScheme.error),
          focusedErrorBorder:
              widget.border ?? _buildBorder(theme.colorScheme.error),
          filled: true,
          fillColor: widget.fillColor ?? Colors.white.withOpacity(0.1),
          errorStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: color,
        width: 1.5,
      ),
    );
  }
}
