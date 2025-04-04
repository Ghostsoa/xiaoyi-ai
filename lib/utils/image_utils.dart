import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../components/custom_snack_bar.dart';
import 'dart:typed_data';
import 'dart:convert';

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// 选择并裁剪图片
  static Future<File?> pickAndCropImage(BuildContext context) async {
    try {
      // 检查权限
      final permission = await _checkPermission(context);
      if (!permission) return null;

      // 显示选择来源的底部弹窗
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera, color: Colors.white),
                  title:
                      const Text('拍摄照片', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text('从相册选择',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.white70),
                  title:
                      const Text('取消', style: TextStyle(color: Colors.white70)),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );

      if (source == null) return null;

      // 选择图片
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image == null) return null;

      // 裁剪图片
      final File? croppedFile = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImageCropPage(
            image: File(image.path),
          ),
        ),
      );

      return croppedFile;
    } catch (e) {
      print('Pick and crop image error: $e');
      if (context.mounted) {
        CustomSnackBar.show(context, message: '选择图片失败：$e');
      }
      return null;
    }
  }

  /// 检查权限
  static Future<bool> _checkPermission(BuildContext context) async {
    // 检查相机权限
    final cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied) {
      final result = await Permission.camera.request();
      if (result.isDenied && context.mounted) {
        CustomSnackBar.show(context, message: '需要相机权限才能拍摄照片');
        return false;
      }
    }

    // 检查相册权限
    final photosStatus = await Permission.photos.status;
    if (photosStatus.isDenied) {
      final result = await Permission.photos.request();
      if (result.isDenied && context.mounted) {
        CustomSnackBar.show(context, message: '需要相册权限才能选择照片');
        return false;
      }
    }

    return true;
  }

  /// 选择图片
  static Future<File?> pickImage(BuildContext context) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      print('选择图片失败: $e');
      return null;
    }
  }

  /// 将图片转换为统一格式的base64字符串
  static Future<String> convertImageToBase64(File imageFile) async {
    try {
      // 读取图片文件
      final bytes = await imageFile.readAsBytes();

      // 解码图片
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // 创建画布并绘制图片
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 保持原始宽高比，但限制最大尺寸为1920x1080
      double width = image.width.toDouble();
      double height = image.height.toDouble();
      if (width > 1920) {
        height = height * (1920 / width);
        width = 1920;
      }
      if (height > 1080) {
        width = width * (1080 / height);
        height = 1080;
      }

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, width, height),
        Paint(),
      );

      // 获取图片数据
      final picture = recorder.endRecording();
      final img = await picture.toImage(width.round(), height.round());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final compressedBytes = byteData!.buffer.asUint8List();

      // 转换为base64
      return base64Encode(compressedBytes);
    } catch (e) {
      print('Convert image error: $e');
      rethrow;
    }
  }

  /// 从base64还原为图片数据
  static Uint8List base64ToImage(String base64String) {
    return base64Decode(base64String);
  }
}

class ImageCropPage extends StatefulWidget {
  final File image;

  const ImageCropPage({
    super.key,
    required this.image,
  });

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  late ui.Image _image;
  bool _isImageLoaded = false;
  Offset? _startDrag;
  Rect _cropRect = Rect.zero;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Size _viewSize = Size.zero;
  Rect _imageRect = Rect.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.image.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
      _isImageLoaded = true;
      _initCropRect();
    });
  }

  void _initCropRect() {
    if (!_isImageLoaded || _viewSize == Size.zero) return;

    final imageSize = Size(_image.width.toDouble(), _image.height.toDouble());
    final screenSize = _viewSize;
    final imageRatio = imageSize.width / imageSize.height;
    final screenRatio = screenSize.width / screenSize.height;

    if (imageRatio > screenRatio) {
      final height = screenSize.width / imageRatio;
      _imageRect = Rect.fromLTWH(
        0,
        (screenSize.height - height) / 2,
        screenSize.width,
        height,
      );
    } else {
      final width = screenSize.height * imageRatio;
      _imageRect = Rect.fromLTWH(
        (screenSize.width - width) / 2,
        0,
        width,
        screenSize.height,
      );
    }

    // 初始化裁剪框为正方形，大小为图片显示区域的较短边的80%
    final cropSize = (_imageRect.width < _imageRect.height
            ? _imageRect.width
            : _imageRect.height) *
        0.8;
    _cropRect = Rect.fromLTWH(
      _imageRect.left + (_imageRect.width - cropSize) / 2,
      _imageRect.top + (_imageRect.height - cropSize) / 2,
      cropSize,
      cropSize,
    );
  }

  // 确保裁剪框在图片范围内
  void _constrainCropRect() {
    if (_cropRect.left < _imageRect.left) {
      _offset =
          Offset(_offset.dx + (_imageRect.left - _cropRect.left), _offset.dy);
    }
    if (_cropRect.top < _imageRect.top) {
      _offset =
          Offset(_offset.dx, _offset.dy + (_imageRect.top - _cropRect.top));
    }
    if (_cropRect.right > _imageRect.right) {
      _offset =
          Offset(_offset.dx - (_cropRect.right - _imageRect.right), _offset.dy);
    }
    if (_cropRect.bottom > _imageRect.bottom) {
      _offset = Offset(
          _offset.dx, _offset.dy - (_cropRect.bottom - _imageRect.bottom));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_isImageLoaded)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _viewSize =
                        Size(constraints.maxWidth, constraints.maxHeight);
                    _initCropRect();
                    return GestureDetector(
                      onScaleStart: (details) {
                        _startDrag = details.focalPoint;
                      },
                      onScaleUpdate: (details) {
                        setState(() {
                          if (details.scale == 1.0) {
                            // 平移
                            if (_startDrag != null) {
                              final delta = details.focalPoint - _startDrag!;
                              _offset += delta;
                              _startDrag = details.focalPoint;
                              _constrainCropRect();
                            }
                          } else {
                            // 缩放
                            final newScale =
                                (_scale * details.scale).clamp(0.5, 3.0);
                            // 计算缩放中心点
                            final focalPoint = details.localFocalPoint;
                            final oldScale = _scale;
                            _scale = newScale;

                            // 调整偏移以保持缩放中心点不变
                            final scaleChange = newScale / oldScale;
                            final focalPointDelta = focalPoint - _offset;
                            _offset =
                                focalPoint - (focalPointDelta * scaleChange);
                            _constrainCropRect();
                          }
                        });
                      },
                      child: CustomPaint(
                        painter: _CropPainter(
                          image: _image,
                          cropRect: _cropRect,
                          scale: _scale,
                          offset: _offset,
                          imageRect: _imageRect,
                        ),
                        size: _viewSize,
                      ),
                    );
                  },
                ),
              ),
            Positioned(
              left: 16,
              bottom: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: IconButton(
                icon: const Icon(Icons.check, color: Colors.white, size: 28),
                onPressed: () async {
                  if (!_isImageLoaded) return;

                  try {
                    final recorder = ui.PictureRecorder();
                    final canvas = Canvas(recorder);

                    // 计算实际裁剪区域
                    final imageSize =
                        Size(_image.width.toDouble(), _image.height.toDouble());
                    final scale = imageSize.width / _imageRect.width;

                    // 计算裁剪区域相对于图片的位置
                    final cropRect = Rect.fromLTWH(
                      (_cropRect.left - _offset.dx - _imageRect.left) * scale,
                      (_cropRect.top - _offset.dy - _imageRect.top) * scale,
                      _cropRect.width * scale,
                      _cropRect.height * scale,
                    );

                    // 确保裁剪区域在图片范围内
                    final validCropRect = Rect.fromLTRB(
                      cropRect.left.clamp(0.0, imageSize.width),
                      cropRect.top.clamp(0.0, imageSize.height),
                      cropRect.right.clamp(0.0, imageSize.width),
                      cropRect.bottom.clamp(0.0, imageSize.height),
                    );

                    // 绘制裁剪后的图片
                    canvas.drawImageRect(
                      _image,
                      validCropRect,
                      Rect.fromLTWH(
                          0, 0, validCropRect.width, validCropRect.height),
                      Paint(),
                    );

                    final picture = recorder.endRecording();
                    final img = await picture.toImage(
                      validCropRect.width.round(),
                      validCropRect.height.round(),
                    );
                    final byteData =
                        await img.toByteData(format: ui.ImageByteFormat.png);
                    final bytes = byteData?.buffer.asUint8List();

                    if (bytes != null) {
                      final targetPath =
                          widget.image.path.replaceAll('.jpg', '_cropped.jpg');
                      final targetFile = File(targetPath);
                      await targetFile.writeAsBytes(bytes);
                      if (mounted) {
                        Navigator.of(context).pop(targetFile);
                      }
                    }
                  } catch (e) {
                    print('Crop image error: $e');
                    if (mounted) {
                      CustomSnackBar.show(context, message: '裁剪图片失败');
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  final ui.Image image;
  final Rect cropRect;
  final double scale;
  final Offset offset;
  final Rect imageRect;

  _CropPainter({
    required this.image,
    required this.cropRect,
    required this.scale,
    required this.offset,
    required this.imageRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 应用缩放和平移
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // 绘制图片
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      imageRect,
      Paint(),
    );
    canvas.restore();

    // 绘制遮罩
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect);

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.srcOver,
    );

    // 绘制裁剪框
    canvas.drawRect(
      cropRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 绘制四个角
    const cornerSize = 20.0;
    const cornerWidth = 3.0;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth;

    // 左上角
    canvas.drawPath(
      Path()
        ..moveTo(cropRect.left, cropRect.top + cornerSize)
        ..lineTo(cropRect.left, cropRect.top)
        ..lineTo(cropRect.left + cornerSize, cropRect.top),
      cornerPaint,
    );

    // 右上角
    canvas.drawPath(
      Path()
        ..moveTo(cropRect.right - cornerSize, cropRect.top)
        ..lineTo(cropRect.right, cropRect.top)
        ..lineTo(cropRect.right, cropRect.top + cornerSize),
      cornerPaint,
    );

    // 右下角
    canvas.drawPath(
      Path()
        ..moveTo(cropRect.right, cropRect.bottom - cornerSize)
        ..lineTo(cropRect.right, cropRect.bottom)
        ..lineTo(cropRect.right - cornerSize, cropRect.bottom),
      cornerPaint,
    );

    // 左下角
    canvas.drawPath(
      Path()
        ..moveTo(cropRect.left + cornerSize, cropRect.bottom)
        ..lineTo(cropRect.left, cropRect.bottom)
        ..lineTo(cropRect.left, cropRect.bottom - cornerSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.cropRect != cropRect ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.imageRect != imageRect;
  }
}
