import 'package:flutter/material.dart';
import '../../../model/chat_message.dart';
import '../../../model/character_card.dart';
import 'message_bubble.dart';

class ChatMessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final Color aiBubbleColor;
  final Color aiTextColor;
  final Color userBubbleColor;
  final Color userTextColor;
  final StatusBarType statusBarType;
  final Function(String)? onActionSelected;
  final Function(ChatMessage)? onMessageEdited;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.aiBubbleColor,
    required this.aiTextColor,
    required this.userBubbleColor,
    required this.userTextColor,
    required this.statusBarType,
    this.onActionSelected,
    this.onMessageEdited,
  });

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
        return MessageBubble(
          message: messages[reversedIndex],
          bubbleColor:
              messages[reversedIndex].isUser ? userBubbleColor : aiBubbleColor,
          textColor:
              messages[reversedIndex].isUser ? userTextColor : aiTextColor,
          statusBarType: statusBarType,
          onActionSelected: onActionSelected,
          onMessageEdited: onMessageEdited,
        );
      },
    );
  }
}
