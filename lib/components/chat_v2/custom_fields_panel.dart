import 'package:flutter/material.dart';
import '../../net/session/session_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CustomFieldsPanel extends StatefulWidget {
  final bool isLoading;
  final Map<String, dynamic>? customFields;
  final Function()? onClose;
  final String sessionId;
  final Function(Map<String, dynamic>)? onFieldsUpdated;
  final VoidCallback? onUndoLastRound;
  final VoidCallback? onUndoMultipleRounds;
  final VoidCallback? onClearHistory;
  final Color userBubbleColor;
  final Color aiBubbleColor;
  final Color userTextColor;
  final Color aiTextColor;
  final Function(Color) onUserBubbleColorChanged;
  final Function(Color) onAiBubbleColorChanged;
  final Function(Color) onUserTextColorChanged;
  final Function(Color) onAiTextColorChanged;
  final List<Map<String, dynamic>> regexStyles;
  final Function(List<Map<String, dynamic>>) onRegexStylesChanged;

  const CustomFieldsPanel({
    Key? key,
    required this.isLoading,
    this.customFields,
    this.onClose,
    required this.sessionId,
    this.onFieldsUpdated,
    this.onUndoLastRound,
    this.onUndoMultipleRounds,
    this.onClearHistory,
    required this.userBubbleColor,
    required this.aiBubbleColor,
    required this.userTextColor,
    required this.aiTextColor,
    required this.onUserBubbleColorChanged,
    required this.onAiBubbleColorChanged,
    required this.onUserTextColorChanged,
    required this.onAiTextColorChanged,
    required this.regexStyles,
    required this.onRegexStylesChanged,
  }) : super(key: key);

  @override
  State<CustomFieldsPanel> createState() => _CustomFieldsPanelState();
}

class _CustomFieldsPanelState extends State<CustomFieldsPanel>
    with SingleTickerProviderStateMixin {
  final SessionService _sessionService = SessionService();
  late Map<String, dynamic> _editableFields = {};
  bool _isEditing = false;
  bool _isSaving = false;
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initEditableFields();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomFieldsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customFields != widget.customFields) {
      _initEditableFields();
    }
  }

  void _initEditableFields() {
    if (widget.customFields != null) {
      _editableFields = Map<String, dynamic>.from(widget.customFields!);
    } else {
      _editableFields = {};
    }
  }

  // 保存自定义字段
  Future<void> _saveCustomFields() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _sessionService.updateCustomFields(
          widget.sessionId, _editableFields);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });

        // 通知父组件字段已更新
        if (widget.onFieldsUpdated != null) {
          widget.onFieldsUpdated!(_editableFields);
        }

        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('自定义字段已保存')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        // 显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  // 更新字段值
  void _updateFieldValue(String key, dynamic value) {
    setState(() {
      _editableFields[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 半透明遮罩（点击关闭侧边栏）
        GestureDetector(
          onTap: _isEditing ? null : widget.onClose,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.2,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        // 侧边栏内容
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: MediaQuery.of(context).size.width * 0.8,
          color: const Color(0xFF1A1A1A),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 面板标题和操作按钮
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // 添加安全区域的额外空间
                    SizedBox(height: MediaQuery.of(context).padding.top),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '面板',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!widget.isLoading && _currentIndex == 0)
                          Row(
                            children: [
                              if (_isEditing) ...[
                                // 取消按钮
                                TextButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () {
                                          setState(() {
                                            _isEditing = false;
                                            _initEditableFields();
                                          });
                                        },
                                  child: Text(
                                    '取消',
                                    style: TextStyle(
                                      color: _isSaving
                                          ? Colors.white.withOpacity(0.5)
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                                // 保存按钮
                                TextButton(
                                  onPressed:
                                      _isSaving ? null : _saveCustomFields,
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          '保存',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ] else ...[
                                // 编辑按钮
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = true;
                                    });
                                  },
                                  splashRadius: 20,
                                  tooltip: '编辑字段',
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 添加 TabBar
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.list_alt),
                              SizedBox(width: 8),
                              Text('字段'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.settings),
                              SizedBox(width: 8),
                              Text('设置'),
                            ],
                          ),
                        ),
                      ],
                      indicatorColor: Colors.blue,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                    ),
                  ],
                ),
              ),

              // 面板内容
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 字段页面
                    _buildFieldsPage(),
                    // 设置页面
                    _buildSettingsPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 构建字段页面
  Widget _buildFieldsPage() {
    if (widget.isLoading) {
      return _buildSkeletonLoading();
    }

    if (_editableFields.isEmpty) {
      return const Center(
        child: Text(
          '没有自定义字段',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _editableFields.length,
      itemBuilder: (context, index) {
        final key = _editableFields.keys.elementAt(index);
        final value = _editableFields[key];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _isEditing
              ? _buildEditableFieldItem(key, value)
              : _buildFieldItem(key, value),
        );
      },
    );
  }

  // 构建设置页面
  Widget _buildSettingsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 操作设置
        const Text(
          '操作设置',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsItem(
          icon: Icons.undo,
          title: '撤销上一轮',
          onTap: widget.onUndoLastRound,
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          icon: Icons.undo_rounded,
          title: '撤销多轮对话',
          onTap: widget.onUndoMultipleRounds,
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          icon: Icons.delete_forever,
          title: '清空历史记录',
          onTap: widget.onClearHistory,
          color: Colors.red,
        ),

        const SizedBox(height: 32),

        // 外观设置
        const Text(
          '外观设置',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // 用户气泡颜色
        _buildColorPickerItem(
          title: '用户气泡颜色',
          currentColor: widget.userBubbleColor,
          onColorChanged: widget.onUserBubbleColorChanged,
        ),
        const SizedBox(height: 12),

        // AI气泡颜色
        _buildColorPickerItem(
          title: 'AI气泡颜色',
          currentColor: widget.aiBubbleColor,
          onColorChanged: widget.onAiBubbleColorChanged,
        ),
        const SizedBox(height: 12),

        // 用户文字颜色
        _buildColorPickerItem(
          title: '用户文字颜色',
          currentColor: widget.userTextColor,
          onColorChanged: widget.onUserTextColorChanged,
        ),
        const SizedBox(height: 12),

        // AI文字颜色
        _buildColorPickerItem(
          title: 'AI文字颜色',
          currentColor: widget.aiTextColor,
          onColorChanged: widget.onAiTextColorChanged,
        ),

        const SizedBox(height: 32),

        // 高级配置
        const Text(
          '高级配置',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // 正则表达式样式列表
        ...widget.regexStyles
            .map((style) => _buildRegexStyleItem(style))
            .toList(),

        // 添加新规则按钮
        const SizedBox(height: 12),
        _buildSettingsItem(
          icon: Icons.add,
          title: '添加新规则',
          onTap: _showAddRegexStyleDialog,
          color: Colors.blue,
        ),
      ],
    );
  }

  // 构建颜色选择器项
  Widget _buildColorPickerItem({
    required String title,
    required Color currentColor,
    required Function(Color) onColorChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showColorPicker(
          title: title,
          currentColor: currentColor,
          onColorChanged: onColorChanged,
        ),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 显示颜色选择器对话框
  void _showColorPicker({
    required String title,
    required Color currentColor,
    required Function(Color) onColorChanged,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: onColorChanged,
            pickerAreaHeightPercent: 0.8,
            enableAlpha: true,
            displayThumbColor: true,
            paletteType: PaletteType.hsvWithHue,
            labelTypes: const [],
            pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10)),
            hexInputBar: true,
            colorHistory: const [
              Colors.blue,
              Color(0xFF1A1A1A),
              Colors.green,
              Colors.red,
              Colors.purple,
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '确定',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  // 构建设置项
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    Color color = Colors.white,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建可编辑的字段项
  Widget _buildEditableFieldItem(String fieldName, dynamic fieldValue) {
    // 处理数值类型 (int, double)
    if (fieldValue is num) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: fieldValue.toString(),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF333333),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                if (fieldValue is int) {
                  _updateFieldValue(
                      fieldName, int.tryParse(value) ?? fieldValue);
                } else if (fieldValue is double) {
                  _updateFieldValue(
                      fieldName, double.tryParse(value) ?? fieldValue);
                }
              }
            },
          ),
        ],
      );
    }

    // 处理布尔类型
    else if (fieldValue is bool) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            fieldName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch(
            value: fieldValue,
            onChanged: (value) {
              _updateFieldValue(fieldName, value);
            },
            activeColor: Colors.green,
          ),
        ],
      );
    }

    // 处理字符串类型
    else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: fieldValue.toString(),
            style: const TextStyle(color: Colors.white),
            maxLines: null,
            minLines: fieldValue.toString().length > 50 ? 3 : 1,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF333333),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (value) {
              _updateFieldValue(fieldName, value);
            },
          ),
        ],
      );
    }
  }

  // 构建骨架屏加载效果
  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // 显示5个骨架项
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _SkeletonItem(index: index),
        );
      },
    );
  }

  // 根据字段值类型构建不同的显示组件
  Widget _buildFieldItem(String fieldName, dynamic fieldValue) {
    // 处理数值类型 (int, double)
    if (fieldValue is num) {
      bool isPercentage = fieldName.toLowerCase().contains('率') ||
          fieldName.toLowerCase().contains('概率') ||
          fieldName.toLowerCase().contains('百分比') ||
          (fieldValue is double && fieldValue <= 1.0);

      final double progressValue =
          isPercentage && fieldValue is double && fieldValue <= 1.0
              ? fieldValue
              : fieldValue is int
                  ? fieldValue / 100.0
                  : fieldValue / 100.0;

      final String displayValue = isPercentage
          ? "${(fieldValue is double && fieldValue <= 1.0 ? fieldValue * 100 : fieldValue).toStringAsFixed(1)}%"
          : fieldValue.toString();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fieldName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                displayValue,
                style: TextStyle(
                  color: _getColorForValue(progressValue),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF333333),
              valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorForValue(progressValue)),
              minHeight: 8,
            ),
          ),
        ],
      );
    }

    // 处理布尔类型
    else if (fieldValue is bool) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            fieldName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: fieldValue
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              fieldValue ? "是" : "否",
              style: TextStyle(
                color: fieldValue ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    // 处理字符串类型
    else {
      bool isShortText = fieldValue.toString().length < 50;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(8),
            ),
            child: isShortText
                ? Text(
                    fieldValue.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fieldValue.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      );
    }
  }

  // 根据值获取颜色
  Color _getColorForValue(double value) {
    if (value < 0.3) return Colors.red;
    if (value < 0.6) return Colors.orange;
    if (value < 0.8) return Colors.yellow;
    return Colors.green;
  }

  // 构建正则表达式样式项
  Widget _buildRegexStyleItem(Map<String, dynamic> style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditRegexStyleDialog(style),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      style['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteRegexStyle(style),
                      iconSize: 20,
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  style['regex'] as String,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Color(style['color'] as int),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (style['isBold'] as bool)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '粗体',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (style['isItalic'] as bool) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '斜体',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 显示添加正则表达式样式对话框
  void _showAddRegexStyleDialog() {
    _showRegexStyleDialog(
      title: '添加新规则',
      initialStyle: {
        'name': '',
        'regex': '',
        'color': Colors.orange.value,
        'isBold': false,
        'isItalic': false,
      },
      onSubmit: (style) {
        final newStyles =
            [...widget.regexStyles, style].cast<Map<String, dynamic>>();
        widget.onRegexStylesChanged(newStyles);
      },
    );
  }

  // 显示编辑正则表达式样式对话框
  void _showEditRegexStyleDialog(Map<String, dynamic> style) {
    _showRegexStyleDialog(
      title: '编辑规则',
      initialStyle: Map.from(style),
      onSubmit: (newStyle) {
        final index = widget.regexStyles.indexWhere(
          (s) => s['name'] == style['name'],
        );
        if (index != -1) {
          final newStyles = List<Map<String, dynamic>>.from(widget.regexStyles);
          newStyles[index] = newStyle;
          widget.onRegexStylesChanged(newStyles);
        }
      },
    );
  }

  // 删除正则表达式样式
  void _deleteRegexStyle(Map<String, dynamic> style) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '删除规则',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '确定要删除"${style['name']}"规则吗？',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final newStyles = widget.regexStyles
                  .where((s) => s['name'] != style['name'])
                  .toList()
                  .cast<Map<String, dynamic>>();
              widget.onRegexStylesChanged(newStyles);
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // 显示正则表达式样式对话框
  void _showRegexStyleDialog({
    required String title,
    required Map<String, dynamic> initialStyle,
    required Function(Map<String, dynamic>) onSubmit,
  }) {
    final nameController =
        TextEditingController(text: initialStyle['name'] as String);
    final regexController =
        TextEditingController(text: initialStyle['regex'] as String);
    Color selectedColor = Color(initialStyle['color'] as int);
    bool isBold = initialStyle['isBold'] as bool;
    bool isItalic = initialStyle['isItalic'] as bool;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 名称输入
                const Text(
                  '规则名称',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 正则表达式输入
                const Text(
                  '正则表达式',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: regexController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 颜色选择
                const Text(
                  '文字颜色',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    _showColorPicker(
                      title: '选择文字颜色',
                      currentColor: selectedColor,
                      onColorChanged: (color) {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '点击选择颜色',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 样式选择
                const Text(
                  '文字样式',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('粗体'),
                      selected: isBold,
                      onSelected: (value) {
                        setState(() {
                          isBold = value;
                        });
                      },
                      backgroundColor: Colors.white.withOpacity(0.1),
                      selectedColor: Colors.blue,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isBold ? Colors.white : Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('斜体'),
                      selected: isItalic,
                      onSelected: (value) {
                        setState(() {
                          isItalic = value;
                        });
                      },
                      backgroundColor: Colors.white.withOpacity(0.1),
                      selectedColor: Colors.blue,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isItalic ? Colors.white : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isEmpty ||
                    regexController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写完整信息')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                onSubmit({
                  'name': nameController.text,
                  'regex': regexController.text,
                  'color': selectedColor.value,
                  'isBold': isBold,
                  'isItalic': isItalic,
                });
              },
              child: const Text(
                '确定',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 骨架项组件，带有动画效果
class _SkeletonItem extends StatefulWidget {
  final int index;

  const _SkeletonItem({required this.index});

  @override
  State<_SkeletonItem> createState() => _SkeletonItemState();
}

class _SkeletonItemState extends State<_SkeletonItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 字段名称骨架
            Container(
              width: 120 + (widget.index % 3) * 40, // 不同宽度，更自然
              height: 20,
              decoration: BoxDecoration(
                color: Color(0xFF333333).withOpacity(_animation.value),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // 值骨架 - 50%概率显示进度条样式，50%概率显示文本框样式
            if (widget.index % 2 == 0) ...[
              // 进度条样式骨架（数值类型）
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Spacer(),
                  Container(
                    width: 50,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Color(0xFF333333).withOpacity(_animation.value),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFF333333).withOpacity(_animation.value),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ] else ...[
              // 文本框样式骨架（字符串类型）
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                height: 60 + (widget.index % 3) * 20, // 不同高度，更自然
                decoration: BoxDecoration(
                  color: Color(0xFF333333).withOpacity(_animation.value),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
