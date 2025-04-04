import 'package:flutter/material.dart';
import '../net/image/image_loader_service.dart';

class CachedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<CachedNetworkImage> createState() => _CachedNetworkImageState();
}

class _CachedNetworkImageState extends State<CachedNetworkImage>
    with SingleTickerProviderStateMixin {
  static final Map<String, ValueNotifier<ImageProvider?>> _imageCache = {};
  final _imageLoader = ImageLoaderService();
  late ValueNotifier<ImageProvider?> _imageNotifier;
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _imageNotifier = _imageCache.putIfAbsent(
      widget.imageUrl,
      () => ValueNotifier<ImageProvider?>(null),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _loadImage();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    if (_imageNotifier.value != null) {
      setState(() => _isLoading = false);
      _fadeController.forward();
      return;
    }

    try {
      final image = await _imageLoader.loadImage(widget.imageUrl);
      if (!mounted) return;

      _imageNotifier.value = image.image;
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
      _fadeController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ValueListenableBuilder<ImageProvider?>(
        valueListenable: _imageNotifier,
        builder: (context, imageProvider, child) {
          if (_isLoading) {
            return widget.placeholder ??
                const Center(
                  child: CircularProgressIndicator(),
                );
          }

          if (_hasError || imageProvider == null) {
            return widget.errorWidget ??
                Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.grey,
                  ),
                );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              if (widget.placeholder != null) widget.placeholder!,
              FadeTransition(
                opacity: _fadeAnimation,
                child: Image(
                  image: imageProvider,
                  fit: widget.fit ?? BoxFit.cover,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
