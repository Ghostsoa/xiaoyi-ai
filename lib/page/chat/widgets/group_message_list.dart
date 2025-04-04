import 'package:flutter/material.dart';
import '../../../model/chat_message.dart';
import '../../../model/character_card.dart';
import 'group_message_bubble.dart';
import 'dart:convert';

class GroupMessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final Color aiBubbleColor;
  final Color aiTextColor;
  final Color userBubbleColor;
  final Color userTextColor;
  final StatusBarType statusBarType;
  final Function(String)? onActionSelected;
  final Function(ChatMessage)? onMessageEdited;
  final List<GroupCharacter> characters;

  const GroupMessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.aiBubbleColor,
    required this.aiTextColor,
    required this.userBubbleColor,
    required this.userTextColor,
    required this.statusBarType,
    required this.characters,
    this.onActionSelected,
    this.onMessageEdited,
  });

  GroupCharacter? _findCharacterByName(String name) {
    try {
      if (!name.contains(':')) {
        return characters.firstWhere((char) => char.name == name);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String? _getNameFromMessage(ChatMessage message) {
    if (message.isUser) return null;
    try {
      final data = json.decode(message.content);
      return data['name'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 80,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final reversedIndex = messages.length - 1 - index;
        final message = messages[reversedIndex];
        final name = _getNameFromMessage(message);
        final character = name != null ? _findCharacterByName(name) : null;

        return GroupMessageBubble(
          message: message,
          bubbleColor: message.isUser ? userBubbleColor : aiBubbleColor,
          textColor: message.isUser ? userTextColor : aiTextColor,
          statusBarType: statusBarType,
          onActionSelected: onActionSelected,
          onMessageEdited: onMessageEdited,
          character: character,
          showAvatar: true,
        );
      },
    );
  }
}
