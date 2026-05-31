import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'animated_image_placeholder.dart';

const _kHintText = 'ダブルタップで拡大・縮小、ドラッグで移動できます';
const _kZoomedScale = 2.5;

/// ネットワーク画像を学食メニューと同じ操作感でフルスクリーン表示する。
Future<void> showInteractiveFullscreenNetworkImage(
  BuildContext context, {
  required String imageUrl,
  String? title,
  double maxScale = 4.0,
  String? fallbackAssetPath,
  String? errorMessage,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    builder: (context) => interactiveFullscreenNetworkImageDialog(
      imageUrl: imageUrl,
      title: title,
      maxScale: maxScale,
      fallbackAssetPath: fallbackAssetPath,
      errorMessage: errorMessage,
    ),
  );
}

/// [showDialog] の builder 内で直接使えるネットワーク画像ダイアログ。
Widget interactiveFullscreenNetworkImageDialog({
  required String imageUrl,
  String? title,
  double maxScale = 4.0,
  String? fallbackAssetPath,
  String? errorMessage,
}) {
  return _InteractiveFullscreenImageDialog(
    title: title,
    maxScale: maxScale,
    child: _NetworkFullscreenImage(
      imageUrl: imageUrl,
      fallbackAssetPath: fallbackAssetPath,
      errorMessage: errorMessage,
    ),
  );
}

/// アセット画像を学食メニューと同じ操作感でフルスクリーン表示する。
Future<void> showInteractiveFullscreenAssetImage(
  BuildContext context, {
  required String assetPath,
  String? title,
  double maxScale = 4.0,
  String? errorMessage,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    builder: (context) => interactiveFullscreenAssetImageDialog(
      assetPath: assetPath,
      title: title,
      maxScale: maxScale,
      errorMessage: errorMessage,
    ),
  );
}

/// [showDialog] の builder 内で直接使えるアセット画像ダイアログ。
Widget interactiveFullscreenAssetImageDialog({
  required String assetPath,
  String? title,
  double maxScale = 4.0,
  String? errorMessage,
}) {
  return _InteractiveFullscreenImageDialog(
    title: title,
    maxScale: maxScale,
    child: _AssetFullscreenImage(
      assetPath: assetPath,
      errorMessage: errorMessage,
    ),
  );
}

/// 複数のネットワーク画像を PageView でフルスクリーン表示する（Cwitter 投稿画像向け）。
Future<void> showInteractiveFullscreenNetworkImageGallery(
  BuildContext context, {
  required List<String> imageUrls,
  int initialIndex = 0,
  double maxScale = 4.0,
}) {
  if (imageUrls.isEmpty) return Future.value();
  final index = initialIndex.clamp(0, imageUrls.length - 1);
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    builder: (context) => _InteractiveFullscreenImageGalleryDialog(
      imageUrls: imageUrls,
      initialIndex: index,
      maxScale: maxScale,
    ),
  );
}

class _InteractiveFullscreenImageDialog extends StatefulWidget {
  const _InteractiveFullscreenImageDialog({
    required this.child,
    this.title,
    this.maxScale = 4.0,
  });

  final Widget child;
  final String? title;
  final double maxScale;

  @override
  State<_InteractiveFullscreenImageDialog> createState() =>
      _InteractiveFullscreenImageDialogState();
}

class _InteractiveFullscreenImageDialogState
    extends State<_InteractiveFullscreenImageDialog> {
  late final TransformationController _transformationController;
  bool _isImageZoomed = false;
  double _dragOffset = 0;
  bool _isDismissing = false;
  bool _showHint = true;
  bool _showChrome = true;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController()
      ..addListener(_onTransformationChanged);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final isZoomed = scale > 1.1;
    if (_isImageZoomed != isZoomed) {
      setState(() => _isImageZoomed = isZoomed);
    }
  }

  void _handleDoubleTap(TapDownDetails details, Size viewportSize) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale > 1.1) {
      _transformationController.value = Matrix4.identity();
      return;
    }

    final tapPosition = details.localPosition;
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    final translateX = viewportCenter.dx - (tapPosition.dx * _kZoomedScale);
    final translateY = viewportCenter.dy - (tapPosition.dy * _kZoomedScale);

    _transformationController.value = Matrix4.identity()
      ..translate(translateX, translateY)
      ..scale(_kZoomedScale);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDismissing || _isImageZoomed) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, 420.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDismissing || _isImageZoomed) return;
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragOffset > 110 || velocity > 900) {
      _isDismissing = true;
      Navigator.of(context).pop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - (_dragOffset / 360)).clamp(0.32, 1.0).toDouble();
    final dragScale = (1 - (_dragOffset / 1400)).clamp(0.9, 1.0).toDouble();

    return Dialog.fullscreen(
      backgroundColor: Colors.black.withValues(alpha: opacity),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Transform.scale(
            scale: dragScale,
            child: Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Material(
                        color: Colors.transparent,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => setState(() => _showChrome = !_showChrome),
                          onDoubleTapDown: (details) => _handleDoubleTap(
                            details,
                            constraints.biggest,
                          ),
                          child: InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: 0.5,
                            maxScale: widget.maxScale,
                            panEnabled: _isImageZoomed,
                            child: SizedBox.expand(child: widget.child),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_showChrome) _buildCloseButton(context),
                if (_showChrome && widget.title != null)
                  _buildTitle(context, widget.title!),
                if (_showChrome && _showHint && !_isImageZoomed)
                  _buildHint(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveFullscreenImageGalleryDialog extends StatefulWidget {
  const _InteractiveFullscreenImageGalleryDialog({
    required this.imageUrls,
    required this.initialIndex,
    required this.maxScale,
  });

  final List<String> imageUrls;
  final int initialIndex;
  final double maxScale;

  @override
  State<_InteractiveFullscreenImageGalleryDialog> createState() =>
      _InteractiveFullscreenImageGalleryDialogState();
}

class _InteractiveFullscreenImageGalleryDialogState
    extends State<_InteractiveFullscreenImageGalleryDialog> {
  late final PageController _pageController;
  late int _currentIndex;
  final Map<int, TransformationController> _controllers = {};
  bool _isImageZoomed = false;
  bool _isInteractingWithImage = false;
  double _dragOffset = 0;
  bool _isDismissing = false;
  bool _showHint = true;
  bool _showChrome = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    for (var i = 0; i < widget.imageUrls.length; i++) {
      final controller = TransformationController();
      controller.addListener(() => _onTransformationChanged(i));
      _controllers[i] = controller;
    }
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onTransformationChanged(int index) {
    if (index != _currentIndex) return;
    final controller = _controllers[index];
    if (controller == null) return;
    final scale = controller.value.getMaxScaleOnAxis();
    final isZoomed = scale > 1.1;
    if (_isImageZoomed != isZoomed) {
      setState(() => _isImageZoomed = isZoomed);
    }
  }

  void _handleDoubleTap(
    int index,
    TapDownDetails details,
    Size viewportSize,
  ) {
    final controller = _controllers[index];
    if (controller == null) return;

    final scale = controller.value.getMaxScaleOnAxis();
    if (scale > 1.1) {
      controller.value = Matrix4.identity();
      return;
    }

    final tapPosition = details.localPosition;
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    final translateX = viewportCenter.dx - (tapPosition.dx * _kZoomedScale);
    final translateY = viewportCenter.dy - (tapPosition.dy * _kZoomedScale);

    controller.value = Matrix4.identity()
      ..translate(translateX, translateY)
      ..scale(_kZoomedScale);
  }

  void _onPageChanged(int index) {
    final previousController = _controllers[_currentIndex];
    previousController?.value = Matrix4.identity();
    setState(() {
      _currentIndex = index;
      _isImageZoomed = false;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDismissing || _isImageZoomed) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, 420.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDismissing || _isImageZoomed) return;
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragOffset > 110 || velocity > 900) {
      _isDismissing = true;
      Navigator.of(context).pop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - (_dragOffset / 360)).clamp(0.32, 1.0).toDouble();
    final dragScale = (1 - (_dragOffset / 1400)).clamp(0.9, 1.0).toDouble();

    return Dialog.fullscreen(
      backgroundColor: Colors.black.withValues(alpha: opacity),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Transform.scale(
            scale: dragScale,
            child: Stack(
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: (_isImageZoomed || _isInteractingWithImage)
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                    itemCount: widget.imageUrls.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      return _buildGalleryPage(context, index);
                    },
                  ),
                ),
                if (_showChrome) _buildCloseButton(context),
                if (_showChrome && widget.imageUrls.length > 1)
                  _buildPageIndicator(context),
                if (_showChrome && _showHint && !_isImageZoomed)
                  _buildHint(context, bottomOffset: 56),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryPage(BuildContext context, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => setState(() => _showChrome = !_showChrome),
            onDoubleTapDown: (details) => _handleDoubleTap(
              index,
              details,
              constraints.biggest,
            ),
            child: InteractiveViewer(
              transformationController: _controllers[index],
              minScale: 0.5,
              maxScale: widget.maxScale,
              panEnabled: _isImageZoomed,
              onInteractionStart: (_) {
                if (!_isInteractingWithImage) {
                  setState(() => _isInteractingWithImage = true);
                }
              },
              onInteractionEnd: (_) {
                if (_isInteractingWithImage) {
                  setState(() => _isInteractingWithImage = false);
                }
              },
              child: SizedBox.expand(
                child: _NetworkFullscreenImage(imageUrl: widget.imageUrls[index]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding + 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_currentIndex + 1} / ${widget.imageUrls.length}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

Widget _buildCloseButton(BuildContext context) {
  return Positioned(
    top: MediaQuery.of(context).padding.top + 8,
    right: 16,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
  );
}

Widget _buildTitle(BuildContext context, String title) {
  return Positioned(
    top: MediaQuery.of(context).padding.top + 8,
    left: 16,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

Widget _buildHint(BuildContext context, {double bottomOffset = 24}) {
  final bottomPadding = MediaQuery.of(context).padding.bottom;
  return Positioned(
    bottom: bottomPadding + bottomOffset,
    left: 16,
    right: 16,
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          _kHintText,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    ),
  );
}

class _NetworkFullscreenImage extends StatelessWidget {
  const _NetworkFullscreenImage({
    required this.imageUrl,
    this.fallbackAssetPath,
    this.errorMessage,
  });

  final String imageUrl;
  final String? fallbackAssetPath;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const AnimatedImagePlaceholder(
            width: 220,
            height: 220,
            borderRadius: 12,
            borderColor: Colors.white24,
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            _buildErrorWidget(context),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      placeholder: (context, url) => const AnimatedImagePlaceholder(
        width: 220,
        height: 220,
        borderRadius: 12,
        borderColor: Colors.white24,
      ),
      errorWidget: (context, url, error) => _buildErrorWidget(context),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (fallbackAssetPath != null) {
      return Image.asset(
        fallbackAssetPath!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorMessage(),
      );
    }
    return _buildErrorMessage();
  }

  Widget _buildErrorMessage() {
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return const Center(
      child: Icon(Icons.broken_image, color: Colors.white70, size: 48),
    );
  }
}

class _AssetFullscreenImage extends StatelessWidget {
  const _AssetFullscreenImage({
    required this.assetPath,
    this.errorMessage,
  });

  final String assetPath;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        if (errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.white70, size: 48),
        );
      },
    );
  }
}
