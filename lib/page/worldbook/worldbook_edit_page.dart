import 'package:flutter/material.dart';
import '../../net/worldbook/worldbook_service.dart';
import '../../components/loading_overlay.dart';
import '../../components/custom_snack_bar.dart';

class WorldbookEditPage extends StatefulWidget {
  final Map<String, dynamic>? entry;

  const WorldbookEditPage({
    super.key,
    this.entry,
  });

  @override
  State<WorldbookEditPage> createState() => _WorldbookEditPageState();
}

class _WorldbookEditPageState extends State<WorldbookEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _keywordController = TextEditingController();
  final _worldbookService = WorldbookService();

  double _priority = 0; // 默认优先级为0

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!['title'] ?? '';
      _contentController.text = widget.entry!['content'] ?? '';
      _keywordController.text = widget.entry!['keyword'] ?? '';
      _priority = (widget.entry!['priority'] ?? 0).toDouble();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final data = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'priority': _priority.round(),
        'keyword': _keywordController.text.trim(),
      };

      final (success, message) = await LoadingOverlay.show(
        context,
        future: () => widget.entry == null
            ? _worldbookService.createWorldbookEntry(data)
            : _worldbookService.updateWorldbookEntry(widget.entry!['id'], data),
      );

      if (!mounted) return;

      CustomSnackBar.show(
        context,
        message: message,
      );

      if (success) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.show(
        context,
        message: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.entry == null ? '添加世界书条目' : '编辑世界书条目',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _submit,
              child: const Text(
                '保存',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题输入
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '标题',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入标题';
                    }
                    if (value.length > 100) {
                      return '标题最大长度为100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 关键词输入
                TextFormField(
                  controller: _keywordController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '关键词',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    helperText: '请输入需要匹配的关键词',
                    helperStyle:
                        TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入关键词';
                    }
                    if (value.length > 100) {
                      return '关键词最大长度为100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 优先级输入
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '优先级',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _priority.round().toString(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '数值越大优先级越高（0-10）',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withOpacity(0.1),
                        valueIndicatorColor: Colors.white,
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                      child: Slider(
                        value: _priority,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: _priority.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            _priority = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 内容输入
                TextFormField(
                  controller: _contentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '内容',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  maxLines: null,
                  minLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入内容';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
