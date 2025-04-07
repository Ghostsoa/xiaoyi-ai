import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dao/character_card_dao.dart';
import '../../service/character_card_service.dart';
import '../../service/chat_history_service.dart';
import '../../utils/chat_export_import_util.dart';
import '../../components/loading_overlay.dart';
import '../../components/custom_snack_bar.dart';

class ImportPage extends StatefulWidget {
  final ChatHistoryService chatHistoryService;

  const ImportPage({super.key, required this.chatHistoryService});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  bool _isLoading = false;
  String? _importResult;
  late CharacterCardService _characterCardService;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    final prefs = await SharedPreferences.getInstance();
    final characterCardDao = CharacterCardDao(prefs);
    _characterCardService = CharacterCardService(characterCardDao, 'user123');
  }

  Future<void> _importFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);

        // 使用加载动画并导入文件
        String importSummary = await LoadingOverlay.show(
          context,
          text: '正在导入数据...',
          future: () => ChatExportImportUtil.importFromFile(
            file,
            _characterCardService,
            widget.chatHistoryService,
          ),
        );

        setState(() {
          _importResult = importSummary;
        });
      } else {
        setState(() {
          _importResult = '未选择文件';
        });
      }
    } catch (e) {
      setState(() {
        _importResult = '导入失败: $e';
      });
      CustomSnackBar.show(context, message: '导入失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '导入数据',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题和说明
                const Text(
                  '导入备份数据',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '您可以导入之前备份的角色卡和聊天记录。导入的数据将会覆盖当前的数据。',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),

                // 从文件导入
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '选择备份文件',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '选择之前从应用中导出的备份文件（.json）',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _importFromFile,
                        icon: const Icon(Icons.file_upload),
                        label: const Text('选择文件'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),

                // 导入结果
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),

                if (_importResult != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: _importResult!.contains('导入完成')
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _importResult!.contains('导入完成')
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _importResult!.contains('导入完成')
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _importResult!.contains('导入完成')
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _importResult!.contains('导入完成') ? '导入成功' : '导入失败',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _importResult!.contains('导入完成')
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _importResult!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
