import '../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/providers/firebase_menu_provider.dart';
import 'common/animated_image_placeholder.dart';
import 'common/safe_cached_network_image.dart';

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
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                child: SafeCachedNetworkImage(
                  imageUrl: imageUrl,
                  width: width,
                  height: height,
                  fit: fit,
                  placeholder: _buildLoadingWidget(context),
                  errorWidget: _buildErrorWidget(
                    context,
                    kIsWeb ? 'ネットワークエラー' : 'Firebase画像の読み込みエラー',
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
  bool _isInteractingWithImage = false;
  double _dragOffset = 0;
  bool _isDismissing = false;
  bool _showHint = true;
  bool _showChrome = true;
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

  void _handleDoubleTap(
    String campusKey,
    TapDownDetails details,
    Size viewportSize,
  ) {
    final controller = _transformationControllers[campusKey];
    if (controller == null) return;

    final scale = controller.value.getMaxScaleOnAxis();
    final isCurrentlyZoomed = scale > 1.1;

    if (isCurrentlyZoomed) {
      controller.value = Matrix4.identity();
    } else {
      final newScale = _zoomedScale;
      final tapPosition = details.localPosition;
      final viewportCenter = Offset(
        viewportSize.width / 2,
        viewportSize.height / 2,
      );
      final translateX = viewportCenter.dx - (tapPosition.dx * newScale);
      final translateY = viewportCenter.dy - (tapPosition.dy * newScale);

      controller.value =
          Matrix4.identity()
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
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - (_dragOffset / 360)).clamp(0.32, 1.0).toDouble();
    final dragScale = (1 - (_dragOffset / 1400)).clamp(0.9, 1.0).toDouble();
    final campuses = widget.campusOptions.keys.toList();

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
                    physics:
                        (_isImageZoomed || _isInteractingWithImage)
                            ? const NeverScrollableScrollPhysics()
                            : const PageScrollPhysics(),
                    itemCount: campuses.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final campusId = campuses[index];
                      return _buildCampusPage(context, campusId);
                    },
                  ),
                ),
                if (_showChrome) _buildTopControls(context),
                if (_showChrome && _showHint && !_isImageZoomed)
                  _buildDoubleTapHint(context),
                if (_showChrome) _buildCampusSelector(context),
              ],
            ),
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

        final imageWidget = SafeCachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          placeholder: const AnimatedImagePlaceholder(
            width: 220,
            height: 220,
            borderRadius: 12,
            borderColor: Colors.white24,
          ),
          errorWidget: _buildMessage(
            context,
            'メニュー画像の読み込みに失敗しました',
            icon: Icons.error_outline,
          ),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            return Material(
              color: Colors.transparent,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() => _showChrome = !_showChrome),
                onDoubleTapDown:
                    (details) => _handleDoubleTap(
                      campusId,
                      details,
                      constraints.biggest,
                    ),
                child: InteractiveViewer(
                  transformationController:
                      _transformationControllers[campusId],
                  minScale: 0.5,
                  maxScale: 4.0,
                  panEnabled: true,
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
                  child: SizedBox.expand(child: imageWidget),
                ),
              ),
            );
          },
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
    final campusChips =
        entries.map((entry) {
          final selected = entry.key == _currentCampus;
          return ChoiceChip(
            label: Text(
              entry.value,
              style: TextStyle(
                color:
                    selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.85),
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
            side:
                selected
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
                                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_getWeekdayName(date)}曜日',
                            style: TextStyle(
                              fontSize: 12,
                              color: isToday ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
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
                                      child: SafeCachedNetworkImage(
                                        imageUrl: imageUrl,
                                        width: 100,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        placeholder: Container(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget: Container(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  : Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outlineVariant,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                 Icon(Icons.error, color: AppColors.accent(context, Colors.red)),
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
  bool _showChrome = true;
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

  void _handleDoubleTap(TapDownDetails details, Size viewportSize) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final isCurrentlyZoomed = scale > 1.1;

    if (isCurrentlyZoomed) {
      _transformationController.value = Matrix4.identity();
    } else {
      final newScale = _zoomedScale;
      final tapPosition = details.localPosition;
      final viewportCenter = Offset(
        viewportSize.width / 2,
        viewportSize.height / 2,
      );
      final translateX = viewportCenter.dx - (tapPosition.dx * newScale);
      final translateY = viewportCenter.dy - (tapPosition.dy * newScale);

      _transformationController.value =
          Matrix4.identity()
            ..translate(translateX, translateY)
            ..scale(newScale);
    }
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
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - (_dragOffset / 360)).clamp(0.32, 1.0).toDouble();
    final dragScale = (1 - (_dragOffset / 1400)).clamp(0.9, 1.0).toDouble();

    final imageWidget = SafeCachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      placeholder: const AnimatedImagePlaceholder(
        width: 220,
        height: 220,
        borderRadius: 12,
        borderColor: Colors.white24,
      ),
      errorWidget: const Center(
        child: Icon(Icons.broken_image, color: Colors.white70, size: 48),
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
                          onTap:
                              () => setState(() => _showChrome = !_showChrome),
                          onDoubleTapDown:
                              (details) => _handleDoubleTap(
                                details,
                                constraints.biggest,
                              ),
                          child: InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: 0.5,
                            maxScale: 4.0,
                            panEnabled: _isImageZoomed,
                            child: SizedBox.expand(child: imageWidget),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // 閉じるボタン
                if (_showChrome)
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
                if (_showChrome && _showHint && !_isImageZoomed)
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
                            'ダブルタップで拡大・縮小、ドラッグで移動できます',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
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
}
