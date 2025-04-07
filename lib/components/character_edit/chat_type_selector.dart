import 'package:flutter/material.dart';
import '../../model/character_card.dart';

class ChatTypeSelector extends StatelessWidget {
  final ChatType value;
  final ValueChanged<ChatType?> onChanged;
  final StatusBarType statusBarType;
  final Function(StatusBarType) onStatusBarTypeChanged;
  final TextEditingController statusBarController;

  const ChatTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.statusBarType,
    required this.onStatusBarTypeChanged,
    required this.statusBarController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '聊天类型',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 2,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.8),
                Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<ChatType>(
            value: value,
            dropdownColor: Theme.of(context).primaryColor.withOpacity(0.9),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            items: ChatType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type == ChatType.single ? '单人聊天' : '群聊',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
                // 如果切换到群聊模式且当前是沉浸式状态栏，则自动切换到自定义模式
                if (value == ChatType.group &&
                    statusBarType == StatusBarType.immersive) {
                  onStatusBarTypeChanged(StatusBarType.custom);
                  statusBarController.text = '';
                }
              }
            },
          ),
        ),
      ],
    );
  }
}
