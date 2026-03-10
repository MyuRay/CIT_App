import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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

  /// 各ページのズーム状態
  final Map<int, _ZoomStateController> _zoomControllers = {};

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
    for (final c in _zoomControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  _ZoomStateController _controllerFor(int index) {
    return _zoomControllers.putIfAbsent(
      index,
      () => _ZoomStateController(
        onZoomChanged: (z) {
          // 現在ページだけが physics に影響する
          if (_currentPage.value == index) {
            _isZoomed.value = z;
          }
        },
      ),
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
    _controllerFor(index).reset(animated: true);
  }

  void _onPageChanged(int i) {
    _currentPage.value = i;
    _prefetchAround(i);

    // physics判定を新しいページに合わせる
    _isZoomed.value = _controllerFor(i).isZoomed;

    if (!widget.keepZoomStatePerPage) {
      // Twitter寄り：ページを離れたらリセット
      for (final entry in _zoomControllers.entries) {
        if (entry.key != i) {
          entry.value.reset(animated: false);
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
                return Container(color: Colors.black.withOpacity(opacity));
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
                          final ctrl = _controllerFor(index);

                          return _DismissableZoomPage(
                            zoomController: ctrl,
                            dismissDy: _dismissDy,
                            onDismissed: () => Navigator.of(context).maybePop(),
                            child: Center(
                              child: _ZoomableImage(
                                url: url,
                                heroTag: '${widget.heroTagPrefix}_$index',
                                controller: ctrl,
                                maxScale: widget.maxScale,
                                doubleTapScale: widget.doubleTapScale,
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
    required this.zoomController,
    required this.dismissDy,
    required this.onDismissed,
    required this.child,
  });

  final _ZoomStateController zoomController;
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
    final isZoomed = widget.zoomController.isZoomed;

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

/// 画像（CachedNetworkImage） + Twitter風ジェスチャー
class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({
    required this.url,
    required this.heroTag,
    required this.controller,
    required this.maxScale,
    required this.doubleTapScale,
  });

  final String url;
  final String heroTag;
  final _ZoomStateController controller;
  final double maxScale;
  final double doubleTapScale;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage>
    with TickerProviderStateMixin {
  TapDownDetails? _doubleTapDown;

  // ピンチ中の基準
  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;

  // 慣性パン
  AnimationController? _flingCtrl;
  Animation<Offset>? _flingAnim;

  @override
  void dispose() {
    _flingCtrl?.dispose();
    super.dispose();
  }

  void _stopFling() {
    _flingCtrl?.stop();
    _flingCtrl?.dispose();
    _flingCtrl = null;
    _flingAnim = null;
  }

  double _clampScale(double s) => s.clamp(1.0, widget.maxScale);

  Offset _clampOffset({
    required Offset offset,
    required double scale,
    required Size viewport,
  }) {
    // viewport基準での簡易クランプ（体感良い）
    final maxX = (viewport.width * (scale - 1)) / 2;
    final maxY = (viewport.height * (scale - 1)) / 2;

    final dx = offset.dx.clamp(-maxX, maxX);
    final dy = offset.dy.clamp(-maxY, maxY);
    return Offset(dx, dy);
  }

  void _applyTransform({
    required double scale,
    required Offset offset,
    required Size viewport,
    bool notify = true,
  }) {
    final s = _clampScale(scale);
    final o = _clampOffset(offset: offset, scale: s, viewport: viewport);

    widget.controller.setTransform(scale: s, offset: o, notify: notify);
  }

  void _toggleDoubleTap(Size viewport) {
    final currentScale = widget.controller.scale;
    final isZoomed = currentScale > 1.01;

    if (isZoomed) {
      widget.controller.reset(animated: true);
      return;
    }

    final details = _doubleTapDown;
    if (details == null) return;

    final tap = details.localPosition;
    final center = Offset(viewport.width / 2, viewport.height / 2);

    // タップ位置中心に拡大するため、offsetを計算
    // 直感：タップ点が拡大後も同じスクリーン位置に見えるように移動する
    final targetScale = widget.doubleTapScale;
    final deltaFromCenter = (tap - center);

    // 拡大すると delta が scale 倍になるので、その分を相殺する方向にoffsetを動かす
    final targetOffset = -deltaFromCenter * (targetScale - 1);

    _applyTransform(
      scale: targetScale,
      offset: targetOffset,
      viewport: viewport,
    );
  }

  void _startFlingIfNeeded({
    required Velocity velocity,
    required Size viewport,
  }) {
    if (widget.controller.scale <= 1.01) return;

    final v = velocity.pixelsPerSecond;

    // 縦横の速度が小さければ無視
    if (v.distance < 200) return;

    _stopFling();

    // 摩擦っぽく減衰させる（短時間）
    final start = widget.controller.offset;
    final target = start + v * 0.18; // “軽い慣性”程度に

    final clampedTarget = _clampOffset(
      offset: target,
      scale: widget.controller.scale,
      viewport: viewport,
    );

    _flingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _flingAnim = Tween<Offset>(begin: start, end: clampedTarget).animate(
      CurvedAnimation(parent: _flingCtrl!, curve: Curves.easeOutCubic),
    )..addListener(() {
        widget.controller.setTransform(
          scale: widget.controller.scale,
          offset: _flingAnim!.value,
        );
      });

    _flingCtrl!.forward();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTapDown: (d) => _doubleTapDown = d,
          onDoubleTap: () => _toggleDoubleTap(viewport),

          // ピンチ & パン
          onScaleStart: (d) {
            _stopFling();
            _startScale = widget.controller.scale;
            _startOffset = widget.controller.offset;
            _startFocal = d.focalPoint;
          },
          onScaleUpdate: (d) {
            // スケール
            final nextScale = _clampScale(_startScale * d.scale);

            // パン（focalの移動分）
            final focalDelta = d.focalPoint - _startFocal;
            final nextOffset = _startOffset + focalDelta;

            _applyTransform(
              scale: nextScale,
              offset: nextOffset,
              viewport: viewport,
            );
          },
          onScaleEnd: (d) {
            // 端クランプを確実に反映
            _applyTransform(
              scale: widget.controller.scale,
              offset: widget.controller.offset,
              viewport: viewport,
            );

            // 等倍に近いならスナップバック
            if (widget.controller.scale < 1.02) {
              widget.controller.reset(animated: true);
              return;
            }

            // 慣性パン
            _startFlingIfNeeded(velocity: d.velocity, viewport: viewport);
          },

          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: widget.controller,
              builder: (_, __) {
                final m = widget.controller.matrix;
                return Transform(
                  transform: m,
                  child: Hero(
                    tag: widget.heroTag,
                    child: CachedNetworkImage(
                      imageUrl: widget.url,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const SizedBox(
                        height: 80,
                        width: 80,
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white70,
                        size: 42,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// ページ単位のズーム状態を管理するコントローラ
/// - scale / offset を保持
/// - matrix を生成
/// - resetアニメ
class _ZoomStateController extends ChangeNotifier {
  _ZoomStateController({required this.onZoomChanged});

  final void Function(bool isZoomed) onZoomChanged;

  double _scale = 1.0;
  Offset _offset = Offset.zero;

  AnimationController? _resetCtrl;
  Animation<double>? _resetScaleAnim;
  Animation<Offset>? _resetOffsetAnim;

  double get scale => _scale;
  Offset get offset => _offset;

  bool get isZoomed => _scale > 1.01;

  Matrix4 get matrix {
    // 画像の中心基準で拡大縮小したいので translate→scale の順にする
    // ここでは Transform 自体が widget座標系で適用されるため、体感は良い
    return Matrix4.identity()
      ..translate(_offset.dx, _offset.dy)
      ..scale(_scale);
  }

  void setTransform({
    required double scale,
    required Offset offset,
    bool notify = true,
  }) {
    _scale = scale;
    _offset = offset;

    if (notify) {
      notifyListeners();
      onZoomChanged(isZoomed);
    }
  }

  void reset({required bool animated}) {
    _resetCtrl?.stop();
    _resetCtrl?.dispose();
    _resetCtrl = null;

    if (!animated) {
      setTransform(scale: 1.0, offset: Offset.zero);
      return;
    }

    // resetアニメ用の一時controller
    // vsyncが必要なので外側から渡す設計もあるが、ここでは簡易に WidgetsBinding を使わず、
    // 呼び出し側でAnimatedを担保するのが面倒なので、animated resetは外で作るのが理想。
    // ただChangeNotifier内でTickerは持てないので、animated resetは簡易的に「段階的更新」方式にする。
    // → 代わりに即時リセットだと違和感が出るので、ここだけは “擬似アニメ” を採用。

    // 擬似アニメ：16ms間隔で減衰させる（200ms程度）
    final startScale = _scale;
    final startOffset = _offset;

    const totalMs = 180;
    const stepMs = 16;
    int elapsed = 0;

    Timer.periodic(const Duration(milliseconds: stepMs), (t) {
      elapsed += stepMs;
      final p = (elapsed / totalMs).clamp(0.0, 1.0);
      final curve = Curves.easeOut.transform(p);

      final s = _lerpDouble(startScale, 1.0, curve);
      final o = Offset(
        _lerpDouble(startOffset.dx, 0.0, curve),
        _lerpDouble(startOffset.dy, 0.0, curve),
      );

      setTransform(scale: s, offset: o);

      if (p >= 1.0) t.cancel();
    });
  }

  @override
  void dispose() {
    _resetCtrl?.dispose();
    super.dispose();
  }
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

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
