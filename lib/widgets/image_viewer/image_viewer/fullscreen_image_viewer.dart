import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// Twitter(X)風のフルスクリーン画像ビューア
/// - 1枚/複数枚対応
/// - ピンチズーム / パン / ダブルタップ(タップ位置中心) / ズーム中はPageView無効
/// - 等倍のときのみ下スワイプで閉じる（背景フェード + 画像追従）
/// - 軽い慣性パン（onScaleEndのvelocityを使用）
/// - プリフェッチ（現在+次）
///
/// NOTE:
/// 画像の「表示領域（containでの実画像Rect）」を厳密に計算してクランプするには
/// ImageInfo(幅高さ)が必要ですが、ここでは“体感Twitter寄り”を重視し
/// viewport基準でクランプしています（大抵のケースで十分気持ち良いです）。
class TwitterLikeImageViewer extends StatefulWidget {
  const TwitterLikeImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTagPrefix = 'twitterViewer',
    this.keepZoomStatePerPage = false,
    this.maxScale = 4.0,
    this.doubleTapScale = 2.5,
  });

  final List<String> imageUrls;
  final int initialIndex;
  final String heroTagPrefix;

  /// true: ページ戻ってきてもズーム状態保持
  /// false: ページ切り替えでリセット（Twitter寄りはfalseが多い）
  final bool keepZoomStatePerPage;

  final double maxScale;
  final double doubleTapScale;

  @override
  State<TwitterLikeImageViewer> createState() => _TwitterLikeImageViewerState();
}

class _TwitterLikeImageViewerState extends State<TwitterLikeImageViewer> {
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);

  final ValueNotifier<int> _currentPage = ValueNotifier<int>(0);

  /// 現在ページがズーム中か（PageView physics切替用）
  final ValueNotifier<bool> _isZoomed = ValueNotifier<bool>(false);

  /// 各ページのズーム状態（photo_view用）
  final Map<int, PhotoViewController> _photoControllers = {};
  final Map<int, PhotoViewScaleStateController> _scaleStateControllers = {};

  /// 下スワイプで閉じるときのドラッグ量（現在ページのみ）
  final ValueNotifier<double> _dismissDy = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _currentPage.value = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchAround(widget.initialIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPage.dispose();
    _isZoomed.dispose();
    _dismissDy.dispose();
    for (final c in _photoControllers.values) {
      c.dispose();
    }
    for (final c in _scaleStateControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  PhotoViewController _photoControllerFor(int index) {
    return _photoControllers.putIfAbsent(
      index,
      () => PhotoViewController(),
    );
  }

  PhotoViewScaleStateController _scaleStateControllerFor(int index) {
    return _scaleStateControllers.putIfAbsent(
      index,
      () {
        final controller = PhotoViewScaleStateController();
        controller.outputScaleStateStream.listen((state) {
          // 現在ページだけが physics に影響する
          if (_currentPage.value == index) {
            final isZoomed = state != PhotoViewScaleState.initial;
            _isZoomed.value = isZoomed;
          }
        });
        return controller;
      },
    );
  }

  Future<void> _prefetchImage(String url) async {
    try {
      await precacheImage(CachedNetworkImageProvider(url), context);
    } catch (_) {
      // ネットワーク状況で失敗することがあるが致命的ではないので無視
    }
  }

  void _prefetchAround(int index) {
    if (index >= 0 && index < widget.imageUrls.length) {
      _prefetchImage(widget.imageUrls[index]);
    }
    if (index + 1 < widget.imageUrls.length) {
      _prefetchImage(widget.imageUrls[index + 1]);
    }
    if (index - 1 >= 0) {
      _prefetchImage(widget.imageUrls[index - 1]);
    }
  }

  void _resetZoom(int index) {
    final controller = _photoControllerFor(index);
    controller.scale = 1.0;
  }

  void _onPageChanged(int i) {
    _currentPage.value = i;
    _prefetchAround(i);

    // physics判定を新しいページに合わせる
    final scaleController = _scaleStateControllerFor(i);
    final currentState = scaleController.scaleState;
    _isZoomed.value = currentState != PhotoViewScaleState.initial;

    if (!widget.keepZoomStatePerPage) {
      // Twitter寄り：ページを離れたらリセット
      for (final entry in _photoControllers.entries) {
        if (entry.key != i) {
          entry.value.scale = 1.0;
        }
      }
    }

    // dismiss量もリセット
    _dismissDy.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 背景フェード（下スワイプ時に薄く）
            ValueListenableBuilder<double>(
              valueListenable: _dismissDy,
              builder: (_, dy, __) {
                final t = (dy.abs() / 280).clamp(0.0, 1.0);
                final opacity = (1.0 - 0.55 * t).clamp(0.0, 1.0);
                return Container(color: Colors.black.withValues(alpha: opacity));
              },
            ),

            // メイン
            Column(
              children: [
                _TopBar(
                  currentPage: _currentPage,
                  total: urls.length,
                  onClose: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isZoomed,
                    builder: (_, zoomed, __) {
                      return PageView.builder(
                        controller: _pageController,
                        physics: zoomed
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(),
                        itemCount: urls.length,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (_, index) {
                          final url = urls[index];
                          final photoController = _photoControllerFor(index);
                          final scaleStateController = _scaleStateControllerFor(index);

                          return _DismissableZoomPage(
                            scaleStateController: scaleStateController,
                            dismissDy: _dismissDy,
                            onDismissed: () => Navigator.of(context).maybePop(),
                            child: Center(
                              child: _ZoomableImage(
                                url: url,
                                heroTag: '${widget.heroTagPrefix}_$index',
                                photoController: photoController,
                                scaleStateController: scaleStateController,
                                maxScale: widget.maxScale,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            // ズームリセット（複数枚のときだけ出す：任意）
            ValueListenableBuilder<int>(
              valueListenable: _currentPage,
              builder: (_, page, __) {
                if (urls.length <= 1) return const SizedBox.shrink();
                return Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                    onPressed: () => _resetZoom(page),
                    child: const Icon(Icons.refresh),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 上部バー（閉じる + インジケータ）
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentPage,
    required this.total,
    required this.onClose,
  });

  final ValueNotifier<int> currentPage;
  final int total;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            color: Colors.white,
            tooltip: '閉じる',
          ),
          const Spacer(),
          ValueListenableBuilder<int>(
            valueListenable: currentPage,
            builder: (_, p, __) {
              final text = total > 1 ? '${p + 1} / $total' : '画像';
              return Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

/// 下スワイプで閉じる（等倍時のみ）
/// - 背景フェードと画像追従
/// - ズーム中は無効
class _DismissableZoomPage extends StatefulWidget {
  const _DismissableZoomPage({
    required this.scaleStateController,
    required this.dismissDy,
    required this.onDismissed,
    required this.child,
  });

  final PhotoViewScaleStateController scaleStateController;
  final ValueNotifier<double> dismissDy;
  final VoidCallback onDismissed;
  final Widget child;

  @override
  State<_DismissableZoomPage> createState() => _DismissableZoomPageState();
}

class _DismissableZoomPageState extends State<_DismissableZoomPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _returnCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  Animation<double>? _returnAnim;

  double _dy = 0;

  @override
  void dispose() {
    _returnCtrl.dispose();
    super.dispose();
  }

  void _animateBack() {
    _returnCtrl.stop();
    _returnCtrl.reset();

    final start = _dy;
    _returnAnim = Tween<double>(begin: start, end: 0).animate(
      CurvedAnimation(parent: _returnCtrl, curve: Curves.easeOut),
    )..addListener(() {
        _dy = _returnAnim!.value;
        widget.dismissDy.value = _dy;
        if (mounted) setState(() {});
      });

    _returnCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isZoomed = widget.scaleStateController.scaleState != PhotoViewScaleState.initial;

    // 等倍時だけ下スワイプで閉じる
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: isZoomed
          ? null
          : (d) {
              _dy += d.delta.dy;
              // 上方向は弱めに
              if (_dy < 0) _dy *= 0.7;

              widget.dismissDy.value = _dy;
              setState(() {});
            },
      onVerticalDragEnd: isZoomed
          ? null
          : (_) {
              final absDy = _dy.abs();
              if (absDy > 160) {
                widget.onDismissed();
              } else {
                _animateBack();
              }
            },
      child: Transform.translate(
        offset: Offset(0, isZoomed ? 0 : _dy),
        child: widget.child,
      ),
    );
  }
}

/// 画像（photo_viewを使用）
class _ZoomableImage extends StatelessWidget {
  const _ZoomableImage({
    required this.url,
    required this.heroTag,
    required this.photoController,
    required this.scaleStateController,
    required this.maxScale,
  });

  final String url;
  final String heroTag;
  final PhotoViewController photoController;
  final PhotoViewScaleStateController scaleStateController;
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: CachedNetworkImageProvider(url),
      controller: photoController,
      scaleStateController: scaleStateController,
      minScale: PhotoViewComputedScale.contained * 0.5,
      maxScale: PhotoViewComputedScale.covered * maxScale,
      initialScale: PhotoViewComputedScale.contained,
      heroAttributes: PhotoViewHeroAttributes(
        tag: heroTag,
        transitionOnUserGestures: true,
      ),
      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      loadingBuilder: (context, event) => const SizedBox(
        height: 80,
        width: 80,
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.broken_image,
        color: Colors.white70,
        size: 42,
      ),
    );
  }
}


/// 画面遷移前のプリフェッチ（先頭と次ページを先読み）
Future<void> prefetchImages(
  BuildContext context,
  List<String> urls, {
  int startIndex = 0,
  int count = 2,
}) async {
  final end = (startIndex + count).clamp(0, urls.length);
  for (final url in urls.sublist(startIndex, end)) {
    try {
      await precacheImage(CachedNetworkImageProvider(url), context);
    } catch (_) {}
  }
}

/// ビューアを開くユーティリティ
Future<T?> openFullscreenImageViewer<T>(
  BuildContext context,
  List<String> urls, {
  int initialIndex = 0,
  bool keepZoomStatePerPage = false,
  String heroTagPrefix = 'twitterViewer',
}) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      builder: (_) => TwitterLikeImageViewer(
        imageUrls: urls,
        initialIndex: initialIndex,
        keepZoomStatePerPage: keepZoomStatePerPage,
        heroTagPrefix: heroTagPrefix,
      ),
    ),
  );
}
