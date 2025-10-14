import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import '../core/providers/firebase_menu_provider.dart';

class FirebaseBusTimetableWidget extends ConsumerStatefulWidget {
  final double? width;
  final double? height;
  final BoxFit fit;
  
  const FirebaseBusTimetableWidget({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  ConsumerState<FirebaseBusTimetableWidget> createState() => _FirebaseBusTimetableWidgetState();
}

class _FirebaseBusTimetableWidgetState extends ConsumerState<FirebaseBusTimetableWidget> {
  bool _isPreCaching = false;

  @override
  void initState() {
    super.initState();
    // ウィジェット作成時にプリキャッシングを開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preCacheAssetImage();
    });
  }

  // アセット画像をプリキャッシング
  void _preCacheAssetImage() async {
    if (_isPreCaching || !mounted) return;
    
    setState(() {
      _isPreCaching = true;
    });
    
    try {
      // アセット画像をプリキャッシング
      await precacheImage(
        const AssetImage('assets/images/bus_timetable.png'),
        context,
      );
      debugPrint('バス時刻表アセット画像のプリキャッシング完了');
      
      // Firebase画像もプリロードを試行（バックグラウンドで）
      _preCacheFirebaseImage();
    } catch (e) {
      debugPrint('バス時刻表アセット画像のプリキャッシングエラー: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPreCaching = false;
        });
      }
    }
  }

  // Firebase画像をバックグラウンドでプリキャッシング
  void _preCacheFirebaseImage() {
    // プロバイダーから画像URLを非同期で取得
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (!mounted) return;
      
      try {
        final imageUrl = await ref.read(firebaseBusTimetableProvider.future);
        if (imageUrl != null && mounted) {
          if (kIsWeb) {
            // Web版：Image.networkでプリロード
            if (!mounted) return;
            await precacheImage(NetworkImage(imageUrl), context);
          } else {
            // モバイル版：CachedNetworkImageでプリロード
            await CachedNetworkImage.evictFromCache(imageUrl);
            final imageProvider = CachedNetworkImageProvider(imageUrl);
            if (!mounted) return;
            await precacheImage(imageProvider, context);
          }
          debugPrint('Firebase画像のプリキャッシング完了: $imageUrl');
        }
      } catch (e) {
        debugPrint('Firebase画像のプリキャッシングエラー: $e');
        // エラーは無視（フォールバックはアセット画像）
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('FirebaseBusTimetableWidget: バス時刻表をリクエスト中');
    final imageUrlAsync = ref.watch(firebaseBusTimetableProvider);

    return imageUrlAsync.when(
      data: (imageUrl) {
        debugPrint('FirebaseBusTimetableWidget: imageUrl=$imageUrl');
        if (imageUrl == null) {
          debugPrint('FirebaseBusTimetableWidget: 画像URLが null - アセット画像を使用');
          return _buildAssetImageWidget(context);
        }

        return _buildImageWidget(context, ref, imageUrl);
      },
      loading: () {
        debugPrint('FirebaseBusTimetableWidget: ロード中...');
        return _buildLoadingWidget(context);
      },
      error: (error, _) {
        debugPrint('FirebaseBusTimetableWidget: エラー: $error - アセット画像にフォールバック');
        return _buildAssetImageWidget(context);
      },
    );
  }

  Widget _buildImageWidget(BuildContext context, WidgetRef ref, String imageUrl) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          // メイン画像（クリックで拡大表示）
          GestureDetector(
            onTap: () => _showFullScreenImage(context, imageUrl, false),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: kIsWeb
                  ? // Web版：Image.networkを使用（Firebase SDKでCORS解決済み）
                    Image.network(
                      imageUrl,
                      width: widget.width,
                      height: widget.height,
                      fit: widget.fit,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildLoadingWidget(context);
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Firebase画像読み込みエラー: $error - アセット画像にフォールバック');
                        return _buildAssetImageWidget(context);
                      },
                    )
                  : // モバイル版：CachedNetworkImageを使用
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: widget.width,
                      height: widget.height,
                      fit: widget.fit,
                      placeholder: (context, url) => _buildLoadingWidget(context),
                      errorWidget: (context, url, error) {
                        debugPrint('CachedNetworkImage読み込みエラー: $error - アセット画像にフォールバック');
                        return _buildAssetImageWidget(context);
                      },
                    ),
            ),
          ),
          // バス時刻表ラベル
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '学バス',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetImageWidget(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          // アセット画像（クリックで拡大表示）
          GestureDetector(
            onTap: () => _showFullScreenAssetImage(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/bus_timetable.png',
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('アセット画像読み込みエラー: $error');
                  return _buildErrorWidget(context, 'バス時刻表の読み込みに失敗しました');
                },
              ),
            ),
          ),
          // オフラインラベル
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'オフライン',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return _BusLoadingPlaceholder(
      width: widget.width ?? 200,
      height: widget.height ?? 150,
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Container(
      width: widget.width ?? 200,
      height: widget.height ?? 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl, bool isAsset) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black87,
        child: Stack(
          children: [
            // フルスクリーン画像（ズーム・パン対応）
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0, // バス時刻表は詳細が多いので5倍まで拡大可能
                child: kIsWeb
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFullScreenError();
                        },
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => _buildFullScreenError(),
                      ),
              ),
            ),
            // 閉じるボタン
            Positioned(
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
            ),
            // タイトル
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '学バス時刻表',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // ピンチアウトのヒント（下部）
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ピンチで拡大・縮小、ドラッグで移動できます',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenAssetImage(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black87,
        child: Stack(
          children: [
            // フルスクリーン画像（ズーム・パン対応）
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Image.asset(
                  'assets/images/bus_timetable.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFullScreenError();
                  },
                ),
              ),
            ),
            // 閉じるボタン
            Positioned(
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
            ),
            // タイトル（オフライン版）
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '学バス時刻表（オフライン版）',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // ピンチアウトのヒント（下部）
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ピンチで拡大・縮小、ドラッグで移動できます',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenError() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.white, size: 48),
          SizedBox(height: 16),
          Text(
            'バス時刻表の読み込みに失敗しました',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _BusLoadingPlaceholder extends StatefulWidget {
  const _BusLoadingPlaceholder({required this.width, required this.height});

  final double width;
  final double height;

  @override
  State<_BusLoadingPlaceholder> createState() => _BusLoadingPlaceholderState();
}

class _BusLoadingPlaceholderState extends State<_BusLoadingPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = scheme.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final color = Color.lerp(base, highlight, _animation.value)!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
            color: color,
          ),
          child: Center(
            child: Icon(
              Icons.directions_bus,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              size: 28,
            ),
          ),
        );
      },
    );
  }
}
