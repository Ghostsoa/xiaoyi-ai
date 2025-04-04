import 'package:flutter/material.dart';

class MessageEditDialog extends StatefulWidget {
  final List<Map<String, String>> contentParts;
  final Function(List<Map<String, String>>) onSave;

  const MessageEditDialog({
    super.key,
    required this.contentParts,
    required this.onSave,
  });

  @override
  State<MessageEditDialog> createState() => _MessageEditDialogState();
}

class _MessageEditDialogState extends State<MessageEditDialog> {
  late List<Map<String, String>> _editedParts;
  final Map<String, String> _typeNames = {
    'scene': '场景描述',
    'action': '动作',
    'thought': '思考',
    'text': '普通文本',
    's': '强调',
  };

  @override
  void initState() {
    super.initState();
    _editedParts = List.from(widget.contentParts);
  }

  Widget _buildEditField(int index) {
    final part = _editedParts[index];
    final type = part['type'] ?? 'text';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _typeNames[type] ?? '文本',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: part['text'] ?? '',
            style: const TextStyle(color: Colors.white),
            maxLines: type == 'scene' ? 3 : 1,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _editedParts[index] = {
                  ...part,
                  'text': value,
                };
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '编辑回复内容',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(
                    _editedParts.length,
                    (index) => _buildEditField(index),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '取消',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    widget.onSave(_editedParts);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
