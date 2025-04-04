import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../net/admin/key_manager_service.dart';
import '../../../../components/custom_snack_bar.dart';
import '../../../../components/loading_overlay.dart';

class ModelKeysPage extends StatefulWidget {
  final String seriesName;

  const ModelKeysPage({
    super.key,
    required this.seriesName,
  });

  @override
  State<ModelKeysPage> createState() => _ModelKeysPageState();
}

class _ModelKeysPageState extends State<ModelKeysPage> {
  final _keyManagerService = KeyManagerService();
  List<ModelKey> _keys = [];
  List<bool> _selectedKeys = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late ModelSeries _series;

  @override
  void initState() {
    super.initState();
    _loadSeriesAndKeys();
  }

  Future<void> _loadSeriesAndKeys() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // 加载模型系列详情
      _series = await _keyManagerService.getModelSeries(widget.seriesName);

      // 加载该系列的密钥
      final keys = await _keyManagerService.getKeys(widget.seriesName);

      setState(() {
        _keys = keys;
        _selectedKeys = List.filled(keys.length, false);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      _selectedKeys[index] = !_selectedKeys[index];
    });
  }

  void _selectAll(bool? value) {
    if (value == null) return;
    setState(() {
      for (int i = 0; i < _selectedKeys.length; i++) {
        _selectedKeys[i] = value;
      }
    });
  }

  Future<void> _deleteSelectedKeys() async {
    final List<String> keysToDelete = [];
    for (int i = 0; i < _keys.length; i++) {
      if (_selectedKeys[i]) {
        keysToDelete.add(_keys[i].key);
      }
    }

    if (keysToDelete.isEmpty) {
      CustomSnackBar.show(context, message: '请选择要删除的密钥');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${keysToDelete.length} 个密钥吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await LoadingOverlay.show(
        context,
        future: () =>
            _keyManagerService.batchDeleteKeys(widget.seriesName, keysToDelete),
      );

      if (mounted) {
        CustomSnackBar.show(context,
            message: '成功删除 ${keysToDelete.length} 个密钥');
        _loadSeriesAndKeys();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '删除失败: $e');
      }
    }
  }

  Future<void> _deleteSingleKey(ModelKey key) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此密钥吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await LoadingOverlay.show(
        context,
        future: () => _keyManagerService.deleteKey(widget.seriesName, key.key),
      );

      if (mounted) {
        CustomSnackBar.show(context, message: '成功删除密钥');
        _loadSeriesAndKeys();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '删除失败: $e');
      }
    }
  }

  void _showAddKeyDialog() {
    final keyController = TextEditingController();
    final commentController = TextEditingController();
    bool isMultipleKeys = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('添加密钥'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text('批量添加密钥'),
                      subtitle: const Text('每行一个密钥，格式为【密钥】或【密钥,备注】'),
                      value: isMultipleKeys,
                      onChanged: (value) {
                        setState(() {
                          isMultipleKeys = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (isMultipleKeys)
                      TextField(
                        controller: keyController,
                        decoration: const InputDecoration(
                          labelText: '多个密钥',
                          hintText: '每行一个密钥，格式为【密钥】或【密钥,备注】',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 10,
                      )
                    else
                      Column(
                        children: [
                          TextField(
                            controller: keyController,
                            decoration: const InputDecoration(
                              labelText: '密钥',
                              hintText: '输入API密钥',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              labelText: '备注',
                              hintText: '可选备注说明',
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
                  onPressed: () async {
                    if (isMultipleKeys) {
                      final text = keyController.text.trim();
                      if (text.isEmpty) {
                        CustomSnackBar.show(context, message: '请输入密钥');
                        return;
                      }

                      final lines = text.split('\n');
                      final keys = <ModelKey>[];

                      for (final line in lines) {
                        final parts = line.trim().split(',');
                        if (parts.isNotEmpty && parts[0].isNotEmpty) {
                          final key = parts[0].trim();
                          final comment =
                              parts.length > 1 ? parts[1].trim() : '';
                          keys.add(ModelKey(key: key, comment: comment));
                        }
                      }

                      if (keys.isEmpty) {
                        CustomSnackBar.show(context, message: '没有有效的密钥');
                        return;
                      }

                      Navigator.of(context).pop();

                      try {
                        await LoadingOverlay.show(
                          context,
                          future: () => _keyManagerService.addKeys(
                              widget.seriesName, keys),
                        );

                        if (mounted) {
                          CustomSnackBar.show(
                            context,
                            message: '成功添加 ${keys.length} 个密钥',
                          );
                          _loadSeriesAndKeys();
                        }
                      } catch (e) {
                        if (mounted) {
                          CustomSnackBar.show(context, message: '添加失败: $e');
                        }
                      }
                    } else {
                      final key = keyController.text.trim();
                      if (key.isEmpty) {
                        CustomSnackBar.show(context, message: '请输入密钥');
                        return;
                      }

                      final comment = commentController.text.trim();
                      final modelKey = ModelKey(key: key, comment: comment);

                      Navigator.of(context).pop();

                      try {
                        await LoadingOverlay.show(
                          context,
                          future: () => _keyManagerService.addKeys(
                            widget.seriesName,
                            [modelKey],
                          ),
                        );

                        if (mounted) {
                          CustomSnackBar.show(context, message: '成功添加密钥');
                          _loadSeriesAndKeys();
                        }
                      } catch (e) {
                        if (mounted) {
                          CustomSnackBar.show(context, message: '添加失败: $e');
                        }
                      }
                    }
                  },
                  child: const Text('添加'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _copyKeyToClipboard(String key) {
    Clipboard.setData(ClipboardData(text: key)).then((_) {
      CustomSnackBar.show(context, message: '密钥已复制到剪贴板');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('加载失败: $_errorMessage',
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSeriesAndKeys,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (!_isLoading && !_hasError) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '模型系列: ${_series.name}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (_keys.isNotEmpty &&
                                        _selectedKeys.contains(true))
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.white),
                                        label: Text(
                                          '删除选中(${_selectedKeys.where((s) => s).length})',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        onPressed: _deleteSelectedKeys,
                                      ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      icon: const Icon(Icons.add,
                                          color: Colors.white),
                                      label: const Text('添加密钥',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      onPressed: _showAddKeyDialog,
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.refresh,
                                          color: Colors.white),
                                      tooltip: '刷新',
                                      onPressed: _loadSeriesAndKeys,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '备注: ${_series.comment}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '支持模型: ${_series.models.join(", ")}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '密钥数量: ${_keys.length}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_keys.isNotEmpty) _buildKeyTableHeader(),
                    Expanded(
                      child: _keys.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('暂无密钥',
                                      style: TextStyle(color: Colors.white)),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _showAddKeyDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('添加密钥'),
                                  ),
                                ],
                              ),
                            )
                          : _buildKeyTableRows(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildKeyTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white30)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: _selectedKeys.every((selected) => selected),
              tristate: _selectedKeys.any((selected) => selected) &&
                  !_selectedKeys.every((selected) => selected),
              onChanged: _selectAll,
              side: const BorderSide(color: Colors.white70),
              checkColor: Colors.white,
              fillColor: MaterialStateProperty.resolveWith(
                (states) => states.contains(MaterialState.selected)
                    ? Colors.blue
                    : Colors.transparent,
              ),
            ),
          ),
          const Expanded(
            flex: 4,
            child: Text(
              '密钥',
              style:
                  TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              '备注',
              style:
                  TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildKeyTableRows() {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(_keys.length, (index) {
          final key = _keys[index];
          return Container(
            decoration: BoxDecoration(
              border: index != _keys.length - 1
                  ? const Border(bottom: BorderSide(color: Colors.white24))
                  : null,
              color: _selectedKeys[index]
                  ? Colors.white.withOpacity(0.15)
                  : (index % 2 == 0
                      ? Colors.transparent
                      : Colors.black.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Checkbox(
                      value: _selectedKeys[index],
                      onChanged: (value) {
                        _toggleSelection(index);
                      },
                      side: const BorderSide(color: Colors.white70),
                      checkColor: Colors.white,
                      fillColor: MaterialStateProperty.resolveWith(
                        (states) => states.contains(MaterialState.selected)
                            ? Colors.blue
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _maskKey(key.key),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: IconButton(
                            icon: const Icon(Icons.copy,
                                size: 18, color: Colors.white),
                            tooltip: '复制密钥',
                            onPressed: () => _copyKeyToClipboard(key.key),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      key.comment,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: IconButton(
                      icon: const Icon(Icons.delete,
                          size: 18, color: Colors.white),
                      tooltip: '删除',
                      onPressed: () => _deleteSingleKey(key),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // 将密钥中间部分用星号遮盖，保留开头和结尾的几个字符，突出显示
  String _maskKey(String key) {
    if (key.length <= 8) return key;
    return '${key.substring(0, 4)}·····${key.substring(key.length - 4)}';
  }
}
