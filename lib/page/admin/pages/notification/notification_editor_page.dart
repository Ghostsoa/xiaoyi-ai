import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../net/admin/notification_service.dart';
import '../../../../components/custom_snack_bar.dart';

class NotificationEditorPage extends StatefulWidget {
  final Map<String, dynamic>? notification;

  const NotificationEditorPage({super.key, this.notification});

  @override
  State<NotificationEditorPage> createState() => _NotificationEditorPageState();
}

class _NotificationEditorPageState extends State<NotificationEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime? _expiredAt;
  bool _isGlobal = true;
  int _type = NotificationType.system;
  String _userIds = '';
  bool _isLoading = false;

  bool get _isEditMode => widget.notification != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _titleController.text = widget.notification!['title'] ?? '';
      _contentController.text = widget.notification!['content'] ?? '';
      _type = widget.notification!['type'] as int? ?? NotificationType.system;
      _isGlobal = widget.notification!['is_global'] as bool? ?? true;
      if (widget.notification!['expired_at'] != null) {
        _expiredAt =
            DateTime.parse(widget.notification!['expired_at'] as String);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiredAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            _expiredAt ?? DateTime.now().add(const Duration(hours: 1))),
      );

      if (pickedTime != null) {
        setState(() {
          _expiredAt = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _clearExpiredAt() {
    setState(() {
      _expiredAt = null;
    });
  }

  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      CustomSnackBar.show(context, message: '请输入通知标题');
      return false;
    }

    if (_contentController.text.trim().isEmpty) {
      CustomSnackBar.show(context, message: '请输入通知内容');
      return false;
    }

    if (!_isGlobal && _userIds.trim().isEmpty) {
      CustomSnackBar.show(context, message: '请输入用户ID');
      return false;
    }

    return true;
  }

  List<int>? _parseUserIds() {
    if (_isGlobal || _userIds.trim().isEmpty) {
      return null;
    }

    final ids = _userIds
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => int.tryParse(e))
        .where((e) => e != null)
        .map((e) => e!)
        .toList();

    return ids.isEmpty ? null : ids;
  }

  Future<void> _saveNotification() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      final expiredAt = _expiredAt?.toUtc().toIso8601String();
      final userIds = _parseUserIds();

      if (_isEditMode) {
        // 更新通知
        final result = await AdminNotificationService.updateNotification(
          id: widget.notification!['id'],
          title: title,
          content: content,
          type: _type,
          isGlobal: _isGlobal,
          expiredAt: expiredAt,
        );

        if (mounted) {
          if (result.success) {
            CustomSnackBar.show(context, message: result.message);
            Navigator.pop(context, true);
          } else {
            CustomSnackBar.show(context, message: result.message);
          }
        }
      } else {
        // 创建通知
        final result = await AdminNotificationService.createNotification(
          title: title,
          content: content,
          type: _type,
          isGlobal: _isGlobal,
          expiredAt: expiredAt,
          userIds: userIds,
        );

        if (mounted) {
          if (result.success) {
            CustomSnackBar.show(context, message: result.message);
            Navigator.pop(context, true);
          } else {
            CustomSnackBar.show(context, message: result.message);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '保存通知失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getTypeString(int type) {
    switch (type) {
      case NotificationType.system:
        return '系统通知';
      case NotificationType.announcement:
        return '公告';
      case NotificationType.personal:
        return '个人通知';
      case NotificationType.promotion:
        return '促销活动';
      case NotificationType.maintenance:
        return '维护通知';
      default:
        return '未知类型';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '编辑通知' : '创建通知'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveNotification,
            icon: const Icon(Icons.save),
            label: Text(_isLoading ? '保存中...' : '保存'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withOpacity(0.8),
                secondaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 标题部分
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '通知信息',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // 标题
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '通知标题',
                        hintText: '输入通知标题',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入通知标题';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // 内容
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: '通知内容',
                        hintText: '输入通知内容',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入通知内容';
                        }
                        return null;
                      },
                      maxLines: 6,
                      minLines: 4,
                    ),

                    // 通知类型
                    const SizedBox(height: 20.0),
                    const Text(
                      '通知类型',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        _buildTypeChip(NotificationType.system),
                        _buildTypeChip(NotificationType.announcement),
                        _buildTypeChip(NotificationType.personal),
                        _buildTypeChip(NotificationType.promotion),
                        _buildTypeChip(NotificationType.maintenance),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // 发送设置部分
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '发送设置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // 发送范围
                    SwitchListTile(
                      title: const Text('全局通知'),
                      subtitle: const Text('通知将发送给所有用户'),
                      value: _isGlobal,
                      onChanged: (value) {
                        setState(() {
                          _isGlobal = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    if (!_isGlobal) ...[
                      const SizedBox(height: 8.0),
                      TextFormField(
                        initialValue: _userIds,
                        decoration: const InputDecoration(
                          labelText: '用户ID',
                          hintText: '输入用户ID，多个ID用逗号分隔',
                          border: OutlineInputBorder(),
                          helperText: '示例: 1,2,3,4,5',
                          prefixIcon: Icon(Icons.people),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入用户ID';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          _userIds = value;
                        },
                      ),
                    ],

                    // 过期时间
                    const SizedBox(height: 16.0),
                    const Text(
                      '过期时间（可选）',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(4.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event, color: Colors.grey),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                _expiredAt == null
                                    ? '点击选择过期时间'
                                    : DateFormat('yyyy-MM-dd HH:mm')
                                        .format(_expiredAt!),
                                style: TextStyle(
                                  color: _expiredAt == null
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                            ),
                            if (_expiredAt != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: _clearExpiredAt,
                                tooltip: '清除日期',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 保存按钮
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    _isLoading ? '保存中...' : '保存通知',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isLoading ? const LinearProgressIndicator() : null,
    );
  }

  Widget _buildTypeChip(int type) {
    final isSelected = _type == type;
    return ChoiceChip(
      label: Text(_getTypeString(type)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _type = type;
          });
        }
      },
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : _getTypeColor(type),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: _getTypeColor(type).withOpacity(0.1),
      selectedColor: _getTypeColor(type),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getTypeColor(type),
          width: 1,
        ),
      ),
    );
  }

  Color _getTypeColor(int type) {
    switch (type) {
      case NotificationType.system:
        return Colors.blue;
      case NotificationType.announcement:
        return Colors.green;
      case NotificationType.personal:
        return Colors.purple;
      case NotificationType.promotion:
        return Colors.orange;
      case NotificationType.maintenance:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
