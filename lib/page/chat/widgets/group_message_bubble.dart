import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../model/chat_message.dart';
import '../../../model/character_card.dart';
import '../../../service/image_service.dart';
import 'custom_status_bar.dart';
import 'immersive_status_bar.dart';

class GroupMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final Color bubbleColor;
  final Color textColor;
  final StatusBarType statusBarType;
  final Function(String)? onActionSelected;
  final Function(ChatMessage)? onMessageEdited;
  final GroupCharacter? character;
  final bool showAvatar;

  const GroupMessageBubble({
    super.key,
    required this.message,
    required this.bubbleColor,
    required this.textColor,
    required this.statusBarType,
    this.onActionSelected,
    this.onMessageEdited,
    this.character,
    this.showAvatar = true,
  });

  @override
  State<GroupMessageBubble> createState() => _GroupMessageBubbleState();
}

class _GroupMessageBubbleState extends State<GroupMessageBubble> {
  Map<String, dynamic>? _messageData;
  String? _statusContent;
  bool _isEditing = false;
  late List<TextEditingController> _controllers;
  List<Map<String, String>>? _contentParts;

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
  void didUpdateWidget(GroupMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.content != widget.message.content) {
      _parseMessage();
      _initControllers();
    }
  }

  void _parseMessage() {
    if (!widget.message.isUser) {
      try {
        _messageData = json.decode(widget.message.content);
        if (_messageData != null) {
          if (_messageData!['content'] is String) {
            try {
              final contentJson = json.decode(_messageData!['content']);
              _messageData = contentJson;
              _messageData!['name'] = _messageData!['name'] ?? '';
            } catch (e) {
              // 如果content不是JSON，保持原样
            }
          }
          if (_messageData!['status'] != null) {
            _statusContent = json.encode(_messageData!['status']);
          }
          if (_messageData!['content'] != null) {
            _contentParts = _parseContentTags(_messageData!['content']);
          }
        }
      } catch (e) {
        _messageData = {'content': widget.message.content};
        _contentParts = [
          {'text': widget.message.content, 'type': 'text'}
        ];
      }
    } else {
      _messageData = {'content': widget.message.content};
      _contentParts = [
        {'text': widget.message.content, 'type': 'text'}
      ];
    }
  }

  List<Map<String, String>> _parseContentTags(String content) {
    final parts = <Map<String, String>>[];
    final RegExp tagPattern = RegExp(r'<(scene|action|thought|s)>(.*?)</\1>');

    for (final match in tagPattern.allMatches(content)) {
      parts.add({'text': match.group(2) ?? '', 'type': match.group(1) ?? ''});
    }

    return parts;
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
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          prefixIcon: Icon(
            type == 'scene'
                ? Icons.movie_outlined
                : type == 'action'
                    ? Icons.directions_run
                    : type == 'thought'
                        ? Icons.psychology
                        : Icons.text_fields,
            color: widget.textColor.withOpacity(0.7),
            size: 18,
          ),
        ),
      ),
    );
  }

  TextStyle _getStyleForType(String type) {
    final baseStyle = TextStyle(
      color: widget.textColor,
      fontSize: 15,
      height: 1.2,
    );
    switch (type) {
      case 's':
        return baseStyle.copyWith(
          fontWeight: FontWeight.w500,
        );
      case 'action':
        return baseStyle.copyWith(
          color: const Color.fromARGB(255, 255, 197, 8),
        );
      case 'scene':
        return baseStyle.copyWith(
          color: widget.textColor.withOpacity(0.7),
          fontSize: 14,
        );
      case 'thought':
        return baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: widget.textColor.withOpacity(0.5),
        );
      default:
        return baseStyle;
    }
  }

  Widget _buildMessageContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.bubbleColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isEditing) ...[
            if (_contentParts != null) ...[
              ..._contentParts!.map((part) {
                final type = part['type'] ?? 'text';
                if (type == 'scene') {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.textColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      part['text'] ?? '',
                      style: _getStyleForType(type),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (type == 'action' || type == 'thought')
                        Padding(
                          padding: const EdgeInsets.only(right: 4, top: 2),
                          child: Icon(
                            type == 'action'
                                ? Icons.directions_run
                                : Icons.psychology,
                            size: 14,
                            color: type == 'action'
                                ? const Color.fromARGB(255, 255, 197, 8)
                                : widget.textColor.withOpacity(0.5),
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
              }),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: widget.message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.message.isUser && widget.showAvatar) ...[
            if (widget.character?.avatarBase64 != null)
              ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: ImageService.imageFromBase64String(
                    widget.character!.avatarBase64!,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.bubbleColor.withOpacity(0.5),
                ),
                child: Center(
                  child: Text(
                    widget.character?.name.characters.first ?? '?',
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: widget.message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!widget.message.isUser && widget.character != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      widget.character!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                GestureDetector(
                  onLongPress:
                      widget.onMessageEdited != null && !widget.message.isUser
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
