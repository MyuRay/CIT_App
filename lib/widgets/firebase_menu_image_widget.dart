import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/providers/firebase_menu_provider.dart';
import 'common/animated_image_placeholder.dart';

class FirebaseMenuImageWidget extends ConsumerWidget {
  final String campus;
  final DateTime? date;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Map<String, String>? campusNavigationMap;
  const FirebaseMenuImageWidget({
    super.key,
    required this.campus,
    this.date,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.campusNavigationMap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 今日の画像のみサポート（日付指定は将来拡張）
    debugPrint('FirebaseMenuImageWidget: campus=$campus をリクエスト中');
    final imageUrlAsync = ref.watch(firebaseTodayMenuProvider(campus));

    return imageUrlAsync.when(
      data: (imageUrl) {
        debugPrint(
          'FirebaseMenuImageWidget: campus=$campus, imageUrl=$imageUrl',
        );
        if (imageUrl == null) {
          debugPrint('FirebaseMenuImageWidget: campus=$campus で画像URLが null');
          return _buildNoMenuWidget(context);
        }

        return _buildImageWidget(context, ref, imageUrl);
      },
      loading: () {
        debugPrint('FirebaseMenuImageWidget: campus=$campus ロード中...');
        return _buildLoadingWidget(context);
      },
      error: (error, _) {
        debugPrint('FirebaseMenuImageWidget: campus=$campus エラー: $error');
        return _buildErrorWidget(context, 'メニュー画像の読み込みに失敗しました');
      },
    );
  }

  Widget _buildImageWidget(
    BuildContext context,
    WidgetRef ref,
    String imageUrl,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          // メイン画像（クリックで拡大表示）
          GestureDetector(
            onTap: () {
              final campusOptions = _buildCampusOptions();
              _showFullScreenImage(
                context,
                initialCampus: campus,
                campusOptions: campusOptions,
              );
            },
            child: Hero(
              tag: 'cafeteria_menu_$campus',
              transitionOnUserGestures: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    kIsWeb
                        ? // Web版：Image.networkを使用（Firebase SDKでCORS解決済み）
                        Image.network(
                          imageUrl,
                          width: width,
                          height: height,
                          fit: fit,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildLoadingWidget(context);
                          },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Firebase画像読み込みエラー: $error');
                            debugPrint('StackTrace: $stackTrace');
                            return _buildErrorWidget(
                              context,
                              'ネットワークエラー (Status: 0)',
                            );
                          },
                        )
                        : // モバイル版：CachedNetworkImageを使用
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: width,
                          height: height,
                          fit: fit,
                          placeholder:
                              (context, url) => _buildLoadingWidget(context),
                          errorWidget:
                              (context, url, error) => _buildErrorWidget(
                                context,
                                'Firebase画像の読み込みエラー',
                              ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _buildCampusOptions() {
    final options = <String, String>{};
    if (campusNavigationMap != null && campusNavigationMap!.isNotEmpty) {
      options.addAll(campusNavigationMap!);
    }
    options.putIfAbsent(campus, () => _defaultCampusName(campus));
    return options;
  }

  String _defaultCampusName(String code) {
    switch (code) {
      case 'td':
        return '津田沼';
      case 'sd1':
        return '新習志野1F';
      case 'sd2':
        return '新習志野2F';
      default:
        return code;
    }
  }

  Widget _buildNoMenuWidget(BuildContext context) {
    return Container(
      width: width ?? 200,
      height: height ?? 150,
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
              Icons.free_breakfast,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '今週はお休みです',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return AnimatedImagePlaceholder(width: width ?? 200, height: height ?? 150);
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Container(
      width: width ?? 200,
      height: height ?? 150,
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
              Icons.restaurant_menu,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              kIsWeb ? 'Web版開発中\n画像は近日対応予定' : message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            if (!kIsWeb) // Web版では再試行ボタンを隠す
              TextButton(
                onPressed: () => _refreshImage(null),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                child: const Text('再試行', style: TextStyle(fontSize: 12)),
              ),
            if (kIsWeb)
              TextButton(
                onPressed: () async {
                  const url = 'https://www.cit-s.com/dining/';
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                child: const Text('公式サイト', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  void _refreshImage(WidgetRef? ref) {
    if (ref != null) {
      // プロバイダーを無効化して再取得
      ref.invalidate(firebaseTodayMenuProvider(campus));
    }
  }

  void _showFullScreenImage(
    BuildContext context, {
    required String initialCampus,
    required Map<String, String> campusOptions,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder:
          (context) => _FullScreenMenuImageDialog(
            initialCampus: initialCampus,
            campusOptions: campusOptions,
          ),
    );
  }
}

/// フルスクリーン画像ダイアログ（InteractiveViewer使用）
/// - ピンチズーム/パン
/// - ダブルタップでズーム（タップ位置中心拡大）
/// - ズーム中はPageView無効化
/// - 等倍時のみ下スワイプで閉じる
class _FullScreenMenuImageDialog extends ConsumerStatefulWidget {
  const _FullScreenMenuImageDialog({
    required this.initialCampus,
    required this.campusOptions,
  });

  final String initialCampus;
  final Map<String, String> campusOptions;

  @override
  ConsumerState<_FullScreenMenuImageDialog> createState() =>
      _FullScreenMenuImageDialogState();
}

class _FullScreenMenuImageDialogState
    extends ConsumerState<_FullScreenMenuImageDialog> {
  late String _currentCampus;
  late final PageController _pageController;
  final Map<String, TransformationController> _transformationControllers = {};
  bool _isImageZoomed = false;
  double _dragOffset = 0;
  bool _isDismissing = false;
  bool _showHint = true;
  static const double _zoomedScale = 2.5;

  @override
  void initState() {
    super.initState();
    final campuses = widget.campusOptions.keys.toList();
    _currentCampus =
        campuses.contains(widget.initialCampus)
            ? widget.initialCampus
            : (campuses.isNotEmpty ? campuses.first : widget.initialCampus);
    final initialIndex = campuses.indexOf(_currentCampus);
    _pageController = PageController(
      initialPage: initialIndex >= 0 ? initialIndex : 0,
    );

    // 各キャンパスごとにTransformationControllerを作成
    for (final campus in campuses) {
      final controller = TransformationController();
      controller.addListener(() => _onTransformationChanged(campus));
      _transformationControllers[campus] = controller;
    }

    // 3秒後にヒントを消す
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  @override
  void dispose() {
    for (final controller in _transformationControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onTransformationChanged(String campusKey) {
    if (campusKey != _currentCampus) return;
    final controller = _transformationControllers[campusKey];
    if (controller == null) return;

    final scale = controller.value.getMaxScaleOnAxis();
    final isZoomed = scale > 1.1;
    if (_isImageZoomed != isZoomed) {
      setState(() => _isImageZoomed = isZoomed);
    }
  }

  void _handleDoubleTap(String campusKey, TapDownDetails details) {
    final controller = _transformationControllers[campusKey];
    if (controller == null) return;

    final scale = controller.value.getMaxScaleOnAxis();
    final isCurrentlyZoomed = scale > 1.1;

    if (isCurrentlyZoomed) {
      controller.value = Matrix4.identity();
    } else {
      final screenSize = MediaQuery.of(context).size;
      final screenCenterX = screenSize.width / 2;
      final screenCenterY = screenSize.height / 2;

      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        controller.value = Matrix4.identity()..scale(_zoomedScale);
        return;
      }

      final globalTapPosition = renderBox.localToGlobal(details.localPosition);
      final offsetX = globalTapPosition.dx - screenCenterX;
      final offsetY = globalTapPosition.dy - screenCenterY;

      final newScale = _zoomedScale;
      final translateX = -offsetX * (newScale - 1);
      final translateY = -offsetY * (newScale - 1);

      controller.value = Matrix4.identity()
        ..translate(translateX, translateY)
        ..scale(newScale);
    }
  }

  void _onPageChanged(int index) {
    final campuses = widget.campusOptions.keys.toList();
    if (index < 0 || index >= campuses.length) return;

    final previousCampus = _currentCampus;
    final newCampus = campuses[index];

    if (previousCampus != newCampus) {
      // 前のページのズームをリセット
      final prevController = _transformationControllers[previousCampus];
      if (prevController != null) {
        prevController.value = Matrix4.identity();
      }
    }

    setState(() {
      _currentCampus = newCampus;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDismissing || _isImageZoomed) return;
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDismissing || _isImageZoomed) return;
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragOffset.abs() > 120 || velocity.abs() > 700) {
      _isDismissing = true;
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - (_dragOffset.abs() / 400)).clamp(0.3, 1.0).toDouble();
    final campuses = widget.campusOptions.keys.toList();

    return Dialog.fullscreen(
      backgroundColor: Colors.black.withValues(alpha: opacity),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
            child: Transform.translate(
          offset: Offset(0, _dragOffset),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PageView.builder(
                    controller: _pageController,
                  physics: _isImageZoomed
                        ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                    itemCount: campuses.length,
                    onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        final campusId = campuses[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildCampusPage(context, campusId),
                    );
                  },
                ),
              ),
              _buildTopControls(context),
              if (_showHint && !_isImageZoomed) _buildDoubleTapHint(context),
              _buildCampusSelector(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampusPage(BuildContext context, String campusId) {
    final imageAsync = ref.watch(firebaseTodayMenuProvider(campusId));

                        return imageAsync.when(
      data: (imageUrl) {
        if (imageUrl == null || imageUrl.isEmpty) {
          return _buildMessage(context, 'この食堂のメニュー画像は登録されていません');
        }

        final imageWidget = kIsWeb
            ? Image.network(
                imageUrl,
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
                errorBuilder:
                    (context, error, stackTrace) => _buildMessage(
                      context,
                      'メニュー画像の読み込みに失敗しました',
                      icon: Icons.error_outline,
                    ),
              )
            : CachedNetworkImage(
                            imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder:
                    (context, url) => const AnimatedImagePlaceholder(
                      width: 220,
                      height: 220,
                      borderRadius: 12,
                      borderColor: Colors.white24,
                          ),
                errorWidget:
                    (context, url, error) => _buildMessage(
                            context,
                      'メニュー画像の読み込みに失敗しました',
                            icon: Icons.error_outline,
                          ),
                        );

        return Center(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTapDown: (details) =>
                  _handleDoubleTap(campusId, details),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  transformationController:
                      _transformationControllers[campusId],
                  minScale: 0.5,
                  maxScale: 4.0,
                  panEnabled: true,
                  child: imageWidget,
                ),
              ),
            ),
          ),
        );
      },
      loading:
          () => const Center(
            child: AnimatedImagePlaceholder(
              width: 240,
              height: 240,
              borderRadius: 16,
              borderColor: Colors.white24,
            ),
          ),
      error:
          (_, __) => _buildMessage(
            context,
            '画像の読み込みに失敗しました',
            icon: Icons.error_outline,
      ),
    );
  }

  Widget _buildDoubleTapHint(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding + 100,
      child: Center(
        child: AnimatedOpacity(
          opacity: _showHint ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ダブルタップで拡大・縮小',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 8,
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

  Widget _buildCampusSelector(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final entries = widget.campusOptions.entries.toList();
    final campusChips = entries.map((entry) {
      final selected = entry.key == _currentCampus;
      return ChoiceChip(
        label: Text(
          entry.value,
          style: TextStyle(
            color:
                selected ? Colors.white : Colors.white.withValues(alpha: 0.85),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: selected,
        onSelected: (_) {
          final targetIndex = entries.indexWhere((e) => e.key == entry.key);
          if (targetIndex != -1) {
            setState(() => _currentCampus = entry.key);
            if (_pageController.hasClients) {
              _pageController.animateToPage(
                targetIndex,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            }
          }
        },
        selectedColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.black54,
        surfaceTintColor: Colors.transparent,
        side: selected
            ? null
            : BorderSide(color: Colors.white.withValues(alpha: 0.35)),
        showCheckmark: false,
      );
    }).toList();

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding + 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: campusChips,
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// 週間メニュー表示用のFirebase版ウィジェット
class FirebaseWeeklyMenuWidget extends ConsumerWidget {
  final String campus;

  const FirebaseWeeklyMenuWidget({super.key, required this.campus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyUrlsAsync = ref.watch(firebaseWeeklyMenuProvider(campus));

    return weeklyUrlsAsync.when(
      data: (weeklyUrls) {
        if (weeklyUrls.isEmpty) {
          return const Center(child: Text('週間メニューがありません'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '今週のメニュー',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () {
                    ref.invalidate(firebaseWeeklyMenuProvider(campus));
                  },
                  tooltip: '更新',
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: weeklyUrls.length,
                itemBuilder: (context, index) {
                  final entry = weeklyUrls.entries.elementAt(index);
                  final dateKey = entry.key;
                  final imageUrl = entry.value;

                  final date = DateTime.parse(dateKey);
                  final isToday = _isToday(date);

                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isToday
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_getWeekdayName(date)}曜日',
                            style: TextStyle(
                              fontSize: 12,
                              color: isToday ? Colors.white : Colors.black87,
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child:
                              imageUrl != null
                                  ? GestureDetector(
                                    onTap:
                                        () => _showFullScreenImage(
                                          context,
                                          imageUrl,
                                        ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child:
                                          kIsWeb
                                              ? Image.network(
                                                imageUrl,
                                                width: 100,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Container(
                                                    color: Colors.grey.shade200,
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
                                                      color:
                                                          Colors.grey.shade100,
                                                      child: Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade400,
                                                      ),
                                                    ),
                                              )
                                              : CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                width: 100,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                placeholder:
                                                    (context, url) => Container(
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                      ),
                                                    ),
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => Container(
                                                      color:
                                                          Colors.grey.shade100,
                                                      child: Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade400,
                                                      ),
                                                    ),
                                              ),
                                    ),
                                  )
                                  : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(height: 8),
                Text('週間メニューの読み込みに失敗しました: $error'),
                TextButton(
                  onPressed:
                      () => ref.invalidate(firebaseWeeklyMenuProvider(campus)),
                  child: const Text('再試行'),
                ),
              ],
            ),
          ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getWeekdayName(DateTime date) {
    const weekdays = ['', '月', '火', '水', '木', '金', '土', '日'];
    return weekdays[date.weekday];
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => _SingleImageFullScreenDialog(imageUrl: imageUrl),
    );
  }
}

/// 単一画像用のフルスクリーンダイアログ（InteractiveViewer使用）
class _SingleImageFullScreenDialog extends StatefulWidget {
  const _SingleImageFullScreenDialog({required this.imageUrl});

  final String imageUrl;

  @override
  State<_SingleImageFullScreenDialog> createState() =>
      _SingleImageFullScreenDialogState();
}

class _SingleImageFullScreenDialogState
    extends State<_SingleImageFullScreenDialog> {
  late final TransformationController _transformationController;
  bool _isImageZoomed = false;
  double _dragOffset = 0;
  bool _isDismissing = false;
  bool _showHint = true;
  static const double _zoomedScale = 2.5;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);

    // 3秒後にヒントを消す
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

  void _handleDoubleTap(TapDownDetails details) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final isCurrentlyZoomed = scale > 1.1;

    if (isCurrentlyZoomed) {
      _transformationController.value = Matrix4.identity();
    } else {
      final screenSize = MediaQuery.of(context).size;
      final screenCenterX = screenSize.width / 2;
      final screenCenterY = screenSize.height / 2;

      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        _transformationController.value =
            Matrix4.identity()..scale(_zoomedScale);
      return;
    }

      final globalTapPosition = renderBox.localToGlobal(details.localPosition);
      final offsetX = globalTapPosition.dx - screenCenterX;
      final offsetY = globalTapPosition.dy - screenCenterY;

      final newScale = _zoomedScale;
      final translateX = -offsetX * (newScale - 1);
      final translateY = -offsetY * (newScale - 1);

      _transformationController.value = Matrix4.identity()
        ..translate(translateX, translateY)
        ..scale(newScale);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDismissing || _isImageZoomed) return;
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDismissing || _isImageZoomed) return;
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragOffset.abs() > 120 || velocity.abs() > 700) {
      _isDismissing = true;
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - (_dragOffset.abs() / 400)).clamp(0.3, 1.0).toDouble();

    final imageWidget = kIsWeb
        ? Image.network(
            widget.imageUrl,
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
            errorBuilder:
                (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white70,
                    size: 48,
                  ),
                ),
          )
        : CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.contain,
            placeholder:
                (context, url) => const AnimatedImagePlaceholder(
                  width: 220,
                  height: 220,
                  borderRadius: 12,
                  borderColor: Colors.white24,
                ),
            errorWidget:
                (context, url, error) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white70,
                    size: 48,
                  ),
                ),
          );

    return Dialog.fullscreen(
      backgroundColor: Colors.black.withValues(alpha: opacity),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
            child: Transform.translate(
          offset: Offset(0, _dragOffset),
              child: Stack(
                children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTapDown: _handleDoubleTap,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 0.5,
                          maxScale: 4.0,
                          panEnabled: true,
                          child: imageWidget,
                        ),
                      ),
                    ),
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
              // ヒント
              if (_showHint && !_isImageZoomed)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _showHint ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ダブルタップで拡大・縮小',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
