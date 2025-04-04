import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../model/chat_message.dart';
import '../../../model/character_card.dart';
import 'custom_status_bar.dart';
import 'immersive_status_bar.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final Color bubbleColor;
  final Color textColor;
  final StatusBarType statusBarType;
  final Function(String)? onActionSelected;
  final Function(ChatMessage)? onMessageEdited;

  const MessageBubble({
    super.key,
    required this.message,
    required this.bubbleColor,
    required this.textColor,
    required this.statusBarType,
    this.onActionSelected,
    this.onMessageEdited,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  List<Map<String, String>>? _contentParts;
  String? _statusContent;
  bool _isEditing = false;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _parseMessage();
    _initControllers();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initControllers() {
    if (_contentParts == null) {
      _controllers = [];
      return;
    }
    _controllers = _contentParts!.map((part) {
      return TextEditingController(text: part['text'] ?? '');
    }).toList();
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.content != widget.message.content) {
      _parseMessage();
      _initControllers();
    }
  }

  void _parseMessage() {
    if (!widget.message.isUser) {
      try {
        if (widget.statusBarType == StatusBarType.custom) {
          final jsonData = json.decode(widget.message.content);
          if (jsonData['content'] != null) {
            final content = jsonData['content'] as String;
            _contentParts = _parseContentTags(content);
            if (jsonData['status'] != null) {
              _statusContent = json.encode(jsonData['status']);
            }
          } else {
            _contentParts = [
              {'text': widget.message.content, 'type': 'text'}
            ];
          }
        } else if (widget.statusBarType == StatusBarType.immersive) {
          final jsonData = json.decode(widget.message.content);
          if (jsonData['content'] != null) {
            final content = jsonData['content'] as String;
            _contentParts = _parseContentTags(content);
            if (jsonData['status'] != null) {
              _statusContent = json.encode(jsonData['status']);
            }
          } else {
            _contentParts = [
              {'text': widget.message.content, 'type': 'text'}
            ];
          }
        } else {
          _contentParts = [
            {'text': widget.message.content, 'type': 'text'}
          ];
        }
      } catch (e) {
        _contentParts = [
          {'text': widget.message.content, 'type': 'text'}
        ];
      }
    } else {
      _contentParts = [
        {'text': widget.message.content, 'type': 'text'}
      ];
    }
  }

  List<Map<String, String>> _parseContentTags(String content) {
    final parts = <Map<String, String>>[];
    final RegExp tagPattern = RegExp(r'<(scene|action|thought|s)>(.*?)</\1>');

    for (final match in tagPattern.allMatches(content)) {
      // 只添加标签内容
      parts.add({'text': match.group(2) ?? '', 'type': match.group(1) ?? ''});
    }

    return parts;
  }

  TextStyle _getStyleForType(String type) {
    final baseStyle = TextStyle(
      color: widget.textColor,
      fontSize: 15,
      height: 1.4,
    );
    switch (type) {
      case 's':
        return baseStyle.copyWith(
          fontWeight: FontWeight.w500,
        );
      case 'action':
        return baseStyle.copyWith(
          color: const Color(0xFFFFB74D),
          fontSize: 14,
          height: 1.5,
        );
      case 'scene':
        return baseStyle.copyWith(
          color: widget.textColor.withOpacity(0.85),
          fontSize: 13.5,
          height: 1.6,
          letterSpacing: 0.2,
        );
      case 'thought':
        return baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: widget.textColor.withOpacity(0.6),
          fontSize: 14,
          height: 1.5,
        );
      default:
        return baseStyle;
    }
  }

  String _rebuildContent(List<Map<String, String>> parts) {
    final StringBuffer buffer = StringBuffer();
    for (final part in parts) {
      final type = part['type'];
      final text = part['text'] ?? '';
      buffer.write('<$type>$text</$type>');
    }
    return buffer.toString();
  }

  void _saveChanges() {
    if (_contentParts == null) return;

    for (int i = 0; i < _contentParts!.length; i++) {
      _contentParts![i] = {
        ..._contentParts![i],
        'text': _controllers[i].text,
      };
    }

    final newContent = _rebuildContent(_contentParts!);
    if (widget.statusBarType == StatusBarType.custom ||
        widget.statusBarType == StatusBarType.immersive) {
      try {
        final jsonData = json.decode(widget.message.content);
        jsonData['content'] = newContent;
        final updatedMessage = ChatMessage(
          isUser: widget.message.isUser,
          content: json.encode(jsonData),
          timestamp: widget.message.timestamp,
        );
        widget.onMessageEdited?.call(updatedMessage);
      } catch (e) {
        final updatedMessage = ChatMessage(
          isUser: widget.message.isUser,
          content: newContent,
          timestamp: widget.message.timestamp,
        );
        widget.onMessageEdited?.call(updatedMessage);
      }
    } else {
      final updatedMessage = ChatMessage(
        isUser: widget.message.isUser,
        content: newContent,
        timestamp: widget.message.timestamp,
      );
      widget.onMessageEdited?.call(updatedMessage);
    }

    setState(() {
      _isEditing = false;
    });
  }

  Widget _buildEditableContent(Map<String, String> part, int index) {
    final type = part['type'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: TextField(
        controller: _controllers[index],
        style: _getStyleForType(type),
        maxLines: null,
        minLines: 1,
        decoration: InputDecoration(
          filled: true,
          fillColor: type == 'scene'
              ? widget.textColor.withOpacity(0.08)
              : Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: type == 'scene'
                ? BorderSide(
                    color: widget.textColor.withOpacity(0.1),
                    width: 0.5,
                  )
                : BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          prefixIcon: Icon(
            type == 'scene'
                ? Icons.remove_red_eye_outlined
                : type == 'action'
                    ? Icons.directions_run
                    : type == 'thought'
                        ? Icons.psychology
                        : Icons.text_fields,
            color: type == 'action'
                ? const Color(0xFFFFB74D)
                : widget.textColor.withOpacity(0.5),
            size: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: widget.bubbleColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isEditing) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _contentParts?.map((part) {
                    final type = part['type'] ?? 'text';
                    if (type == 'scene') {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.textColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.textColor.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2, right: 6),
                              child: Icon(
                                Icons.remove_red_eye_outlined,
                                size: 13,
                                color: widget.textColor.withOpacity(0.5),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                part['text'] ?? '',
                                style: _getStyleForType(type),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (type == 'action' || type == 'thought')
                            Padding(
                              padding: const EdgeInsets.only(right: 6, top: 3),
                              child: Icon(
                                type == 'action'
                                    ? Icons.directions_run
                                    : Icons.psychology,
                                size: 13,
                                color: type == 'action'
                                    ? const Color(0xFFFFB74D)
                                    : widget.textColor.withOpacity(0.4),
                              ),
                            ),
                          Flexible(
                            child: Text(
                              part['text'] ?? '',
                              style: _getStyleForType(type),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList() ??
                  [],
            ),
          ] else ...[
            ..._contentParts?.asMap().entries.map((entry) {
                  return _buildEditableContent(entry.value, entry.key);
                }) ??
                [],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: widget.textColor.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: _saveChanges,
                  child: Text(
                    '保存',
                    style: TextStyle(
                      color: widget.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!widget.message.isUser && _statusContent != null) ...[
            const SizedBox(height: 4),
            if (widget.statusBarType == StatusBarType.custom)
              CustomStatusBar(
                content: _statusContent!,
                textColor: widget.textColor,
              )
            else if (widget.statusBarType == StatusBarType.immersive)
              ImmersiveStatusBar(
                content: _statusContent!,
                textColor: widget.textColor,
                onActionSelected: widget.onActionSelected,
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: widget.message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          widget.message.isUser
              ? ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  child: _buildMessageContent(),
                )
              : Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onLongPress: widget.onMessageEdited != null
                            ? () => setState(() => _isEditing = true)
                            : null,
                        child: _buildMessageContent(),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
