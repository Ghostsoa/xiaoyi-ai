import 'package:flutter/material.dart';
import '../../../../net/admin/key_manager_service.dart';
import '../../../../components/custom_snack_bar.dart';
import '../../../../components/loading_overlay.dart';
import 'model_keys_page.dart';

class ModelSeriesPage extends StatefulWidget {
  const ModelSeriesPage({super.key});

  @override
  State<ModelSeriesPage> createState() => _ModelSeriesPageState();
}

class _ModelSeriesPageState extends State<ModelSeriesPage> {
  final _keyManagerService = KeyManagerService();
  final _searchController = TextEditingController();
  List<ModelSeries> _allSeries = [];
  List<ModelSeries> _filteredSeries = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadModelSeries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadModelSeries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final series = await _keyManagerService.getAllModelSeries();
      setState(() {
        _allSeries = series;
        _filteredSeries = series;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterSeries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSeries = _allSeries;
      } else {
        _filteredSeries = _allSeries
            .where((series) =>
                series.name.toLowerCase().contains(query.toLowerCase()) ||
                series.comment.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _deleteSeries(ModelSeries series) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除模型系列 "${series.name}" 吗？这将同时删除所有关联的密钥。'),
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
        future: () => _keyManagerService.deleteModelSeries(series.name),
      );

      if (mounted) {
        CustomSnackBar.show(context, message: '成功删除模型系列');
        _loadModelSeries();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '删除失败: $e');
      }
    }
  }

  void _showAddSeriesDialog() {
    final nameController = TextEditingController();
    final commentController = TextEditingController();
    final modelsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加模型系列'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '系列名称',
                  hintText: '例如：gpt, gemini',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: modelsController,
                decoration: const InputDecoration(
                  labelText: '模型列表',
                  hintText: '多个模型用逗号分隔，例如：gpt-4,gpt-3.5-turbo',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: '备注说明',
                  hintText: '例如：OpenAI GPT系列模型',
                ),
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
              final name = nameController.text.trim();
              final comment = commentController.text.trim();
              final modelsText = modelsController.text.trim();

              if (name.isEmpty || modelsText.isEmpty) {
                CustomSnackBar.show(
                  context,
                  message: '系列名称和模型列表不能为空',
                );
                return;
              }

              final models = modelsText
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              final series = ModelSeries(
                name: name,
                models: models,
                comment: comment,
              );

              Navigator.of(context).pop();

              try {
                await LoadingOverlay.show(
                  context,
                  future: () => _keyManagerService.addModelSeries(series),
                );

                if (mounted) {
                  CustomSnackBar.show(context, message: '成功添加模型系列');
                  _loadModelSeries();
                }
              } catch (e) {
                if (mounted) {
                  CustomSnackBar.show(context, message: '添加失败: $e');
                }
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showSeriesDetails(ModelSeries series) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModelKeysPage(seriesName: series.name),
      ),
    ).then((_) {
      // 返回时刷新列表
      _loadModelSeries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: '搜索模型系列',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterSeries,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('加载失败: $_errorMessage'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadModelSeries,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : _filteredSeries.isEmpty
                        ? const Center(child: Text('暂无模型系列'))
                        : _buildSeriesTable(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSeriesDialog,
        tooltip: '添加模型系列',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSeriesTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 表头
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(
                      '系列名称',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: Text(
                      '模型列表',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: Text(
                      '备注',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 120),
                ],
              ),
            ),
            const Divider(color: Colors.white30, height: 1),
            // 表内容
            ...List.generate(_filteredSeries.length, (index) {
              final series = _filteredSeries[index];
              return Container(
                decoration: BoxDecoration(
                  border: index != _filteredSeries.length - 1
                      ? const Border(bottom: BorderSide(color: Colors.white24))
                      : null,
                  color: index % 2 == 0
                      ? Colors.transparent
                      : Colors.black.withOpacity(0.2),
                ),
                child: InkWell(
                  onTap: () => _showSeriesDetails(series),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 160,
                          child: Text(
                            series.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 240,
                          child: Text(
                            series.models.join(", "),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: Text(
                            series.comment,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.key,
                                    size: 20, color: Colors.white),
                                tooltip: '管理密钥',
                                onPressed: () => _showSeriesDetails(series),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh,
                                    size: 20, color: Colors.white),
                                tooltip: '刷新',
                                onPressed: _loadModelSeries,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 20, color: Colors.white),
                                tooltip: '删除系列',
                                onPressed: () => _deleteSeries(series),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
