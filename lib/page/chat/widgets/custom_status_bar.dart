import 'package:flutter/material.dart';
import 'dart:convert';

class CustomStatusBar extends StatefulWidget {
  final String content;
  final Color textColor;

  const CustomStatusBar({
    super.key,
    required this.content,
    required this.textColor,
  });

  @override
  State<CustomStatusBar> createState() => _CustomStatusBarState();
}

class _CustomStatusBarState extends State<CustomStatusBar> {
  bool _showStatus = true;
  Map<String, dynamic>? _statusData;

  @override
  void initState() {
    super.initState();
    _parseContent();
  }

  @override
  void didUpdateWidget(CustomStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _parseContent();
    }
  }

  void _parseContent() {
    try {
      _statusData = json.decode(widget.content) as Map<String, dynamic>;
    } catch (e) {
      _statusData = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_statusData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showStatus = !_showStatus;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _showStatus
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: widget.textColor.withOpacity(0.6),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '状态信息',
                style: TextStyle(
                  color: widget.textColor.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (_showStatus) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.textColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _statusData!.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}：',
                        style: TextStyle(
                          color: widget.textColor.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            color: widget.textColor.withOpacity(0.8),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
