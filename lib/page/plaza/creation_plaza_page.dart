import 'package:flutter/material.dart';
import '../../net/image/image_generation_service.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import '../../components/custom_snack_bar.dart';

class CreationPlazaPage extends StatefulWidget {
  const CreationPlazaPage({super.key});

  @override
  State<CreationPlazaPage> createState() => CreationPlazaPageState();
}

class CreationPlazaPageState extends State<CreationPlazaPage> {
  final _promptController = TextEditingController();
  final _imageGenerationService = ImageGenerationService();
  final _scrollController = ScrollController();
  String? _generatedImagePath;
  bool _isGenerating = false;
  bool _isSharing = false;
  bool _isSaving = false;
  String _selectedModel = 'flux';
  int _width = 768;
  int _height = 1024;
  bool _enhance = true;
  bool _nologo = true;

  static const platform = MethodChannel('ai.xiaoyi/image_saver');

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generateImage() async {
    if (_promptController.text.isEmpty) {
      CustomSnackBar.show(
        context,
        message: '请输入提示词',
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedImagePath = null;
    });

    try {
      final imagePath = await _imageGenerationService.generateImage(
        prompt: _promptController.text,
        model: _selectedModel,
        width: _width,
        height: _height,
        enhance: _enhance,
        nologo: _nologo,
      );

      if (imagePath != null && mounted) {
        setState(() {
          _generatedImagePath = imagePath;
        });

        // 生成图片后滚动到底部查看结果
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: '生成图片失败: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _shareImage() async {
    if (_generatedImagePath == null) return;

    setState(() {
      _isSharing = true;
    });

    try {
      await Share.shareXFiles(
        [XFile(_generatedImagePath!)],
        text: '我用AI生成了一张图片',
      );
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: '分享图片失败: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _saveImageToGallery() async {
    if (_generatedImagePath == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 使用flutter_image_gallery_saver保存图片
      await FlutterImageGallerySaver.saveFile(_generatedImagePath!);

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: '图片已保存到相册',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: '保存图片失败: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showFullScreenImage() {
    if (_generatedImagePath == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImage(
          imagePath: _generatedImagePath!,
          onShare: _shareImage,
          onSave: _saveImageToGallery,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.0),
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            key: const PageStorageKey('creationPlazaScroll'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    '图片创作',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // 提示词输入框
                _buildSectionTitle('提示词'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(
                      hintText: '请务必用英文描述你想要生成的图片...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      hintStyle: TextStyle(color: Colors.white60),
                    ),
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

                // 模型选择
                _buildSectionTitle('模型'),
                Row(
                  children: [
                    Expanded(
                      child: _buildModelButton('Flux', 'flux'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModelButton('Turbo', 'turbo'),
                    ),
                  ],
                ),

                // 选项设置
                _buildSectionTitle('选项'),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('增强',
                            style: TextStyle(color: Colors.white)),
                        value: _enhance,
                        activeColor: Colors.blue,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            _enhance = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('无水印',
                            style: TextStyle(color: Colors.white)),
                        value: _nologo,
                        activeColor: Colors.blue,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            _nologo = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                // 图片尺寸设置
                _buildSectionTitle('图片尺寸'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('宽度', style: TextStyle(color: Colors.white70)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_width px',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _width.toDouble(),
                  min: 256,
                  max: 1024,
                  divisions: 12,
                  activeColor: Colors.blue,
                  inactiveColor: Colors.white24,
                  onChanged: (value) {
                    setState(() {
                      _width = value.round();
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('高度', style: TextStyle(color: Colors.white70)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_height px',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _height.toDouble(),
                  min: 256,
                  max: 1024,
                  divisions: 12,
                  activeColor: Colors.blue,
                  inactiveColor: Colors.white24,
                  onChanged: (value) {
                    setState(() {
                      _height = value.round();
                    });
                  },
                ),

                // 预设尺寸比例
                _buildSectionTitle('预设比例'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAspectRatioButton('1:1', 1024, 1024),
                    _buildAspectRatioButton('4:3', 1024, 768),
                    _buildAspectRatioButton('3:4', 768, 1024),
                    _buildAspectRatioButton('16:9', 1024, 576),
                  ],
                ),

                // 预览区域
                if (_generatedImagePath != null) ...[
                  _buildSectionTitle('生成结果'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showFullScreenImage,
                          child: Hero(
                            tag: 'generated_image',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_generatedImagePath!),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _isSaving ? null : _saveImageToGallery,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.photo_library,
                                          color: Colors.white),
                                  label: Text(
                                    _isSaving ? '保存中...' : '保存相册',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side:
                                        const BorderSide(color: Colors.white54),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isSharing ? null : _shareImage,
                                  icon: _isSharing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.share,
                                          color: Colors.white),
                                  label: Text(
                                    _isSharing ? '分享中...' : '分享图片',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side:
                                        const BorderSide(color: Colors.white54),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 生成按钮
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generateImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: _isGenerating
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('正在生成...',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          )
                        : const Text(
                            '生成图片',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelButton(String label, String value) {
    final isSelected = _selectedModel == value;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedModel = value;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.white10,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: isSelected ? 2 : 0,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildAspectRatioButton(String label, int width, int height) {
    final isSelected = _width == width && _height == height;

    return InkWell(
      onTap: () {
        setState(() {
          _width = width;
          _height = height;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String imagePath;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const _FullScreenImage({
    required this.imagePath,
    required this.onShare,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: onSave,
            tooltip: '保存相册',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: onShare,
            tooltip: '分享图片',
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: 'generated_image',
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
