import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/providers/firebase_campus_provider.dart';
import 'common/animated_image_placeholder.dart';

class CampusMapWidget extends ConsumerWidget {
  final String campus;
  final double? width;
  final double? height;
  final bool showTitle;
  final Map<String, String>? campusNavigationMap;

  const CampusMapWidget({
    super.key,
    required this.campus,
    this.width,
    this.height,
    this.showTitle = true,
    this.campusNavigationMap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campusMapAsync = ref.watch(campusMapProvider(campus));
    final campusOptions = _buildCampusOptions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        campusMapAsync.when(
          data: (mapUrl) {
            debugPrint('🗺️ Campus map data received | campus=$campus, url=$mapUrl');
            if (mapUrl == null || mapUrl.isEmpty) {
              debugPrint('❌ Campus map URL is null or empty | campus=$campus');
              return _buildErrorWidget(context, 'キャンパスマップが見つかりません');
            }
            return _buildMapWidget(context, mapUrl, campusOptions);
          },
          loading: () {
            debugPrint('⏳ Loading campus map | campus=$campus');
            return _buildLoadingWidget(context);
          },
          error: (error, stackTrace) {
            debugPrint('❌ Campus map error | campus=$campus, error=$error');
            debugPrint('❌ StackTrace: $stackTrace');
            return _buildErrorWidget(context, 'キャンパスマップの読み込みに失敗しました');
          },
        ),
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _getCampusDisplayName(campus),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildMapWidget(
    BuildContext context,
    String mapUrl,
    Map<String, String> campusOptions,
  ) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onTap:
              () => _showFullScreenMap(context, campus, mapUrl, campusOptions),
          child:
              kIsWeb
                  ? Image.network(
                    mapUrl,
                    width: width,
                    height: height ?? 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildLoadingWidget(context);
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildErrorWidget(context, 'マップ画像の読み込みエラー');
                    },
                  )
                  : CachedNetworkImage(
                    imageUrl: mapUrl,
                    width: width,
                    height: height ?? 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildLoadingWidget(context),
                    errorWidget:
                        (context, url, error) =>
                            _buildErrorWidget(context, 'マップ画像の読み込みエラー'),
                  ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return AnimatedImagePlaceholder(
      width: width ?? double.infinity,
      height: height ?? 200,
      borderRadius: 8,
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, color: Colors.grey.shade600, size: 32),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _buildCampusOptions() {
    final options = <String, String>{};
    if (campusNavigationMap != null && campusNavigationMap!.isNotEmpty) {
      options.addAll(campusNavigationMap!);
    }
    options.putIfAbsent(campus, () => _getCampusDisplayName(campus));
    return options;
  }

  void _showFullScreenMap(
    BuildContext context,
    String initialCampus,
    String initialMapUrl,
    Map<String, String> campusOptions,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder:
          (context) => _FullScreenCampusMapDialog(
            initialCampus: initialCampus,
            initialMapUrl: initialMapUrl,
            campusOptions: campusOptions,
          ),
    );
  }

  String _getCampusDisplayName(String campus) {
    switch (campus) {
      case 'tsudanuma':
        return '津田沼';
      case 'narashino':
        return '新習志野';
      default:
        return campus;
    }
  }
}

class _FullScreenCampusMapDialog extends ConsumerStatefulWidget {
  const _FullScreenCampusMapDialog({
    required this.initialCampus,
    required this.initialMapUrl,
    required this.campusOptions,
  });

  final String initialCampus;
  final String initialMapUrl;
  final Map<String, String> campusOptions;

  @override
  ConsumerState<_FullScreenCampusMapDialog> createState() =>
      _FullScreenCampusMapDialogState();
}

class _FullScreenCampusMapDialogState
    extends ConsumerState<_FullScreenCampusMapDialog> {
  late final List<MapEntry<String, String>> _entries;
  late int _currentIndex;
  late final PageController _pageController;
  double _dragOffset = 0;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    final entries = widget.campusOptions.entries.toList();
    if (!entries.any((entry) => entry.key == widget.initialCampus)) {
      entries.insert(
        0,
        MapEntry(
          widget.initialCampus,
          widget.campusOptions[widget.initialCampus] ??
              _displayNameFor(widget.initialCampus),
        ),
      );
    }
    if (entries.isEmpty) {
      entries.add(
        MapEntry(
          widget.initialCampus,
          widget.campusOptions[widget.initialCampus] ??
              _displayNameFor(widget.initialCampus),
        ),
      );
    }
    _entries = entries;
    _currentIndex = _entries.indexWhere(
      (entry) => entry.key == widget.initialCampus,
    );
    if (_currentIndex < 0) {
      _currentIndex = 0;
    }
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDismissing) return;
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

    return Dialog.fullscreen(
      backgroundColor: Colors.black.withOpacity(opacity),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _entries.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildCampusPage(context, entry.key, entry.value),
                );
              },
            ),
            _buildTopControls(context),
            if (_entries.length > 1) _buildCampusSelector(context),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24,
              child: Text(
                _entries[_currentIndex].value,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ピンチで拡大・縮小、ドラッグで移動',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampusPage(
    BuildContext context,
    String campusKey,
    String campusName,
  ) {
    final mapAsync = ref.watch(campusMapProvider(campusKey));

    return mapAsync.when(
      data: (mapUrl) {
        final effectiveUrl =
            mapUrl ??
            (campusKey == widget.initialCampus ? widget.initialMapUrl : null);
        if (effectiveUrl == null || effectiveUrl.isEmpty) {
          return _buildMessage(context, '${campusName}のマップが見つかりません');
        }
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child:
                  kIsWeb
                      ? Image.network(
                        effectiveUrl,
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
                              '${campusName}のマップの読み込みに失敗しました',
                            ),
                      )
                      : CachedNetworkImage(
                        imageUrl: effectiveUrl,
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
                              '${campusName}のマップの読み込みに失敗しました',
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
          (error, _) => _buildMessage(context, '${campusName}のマップの読み込みに失敗しました'),
    );
  }

  Widget _buildCampusSelector(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding + 72,
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
            children:
                _entries.map((entry) {
                  final selected = entry.key == _entries[_currentIndex].key;
                  return ChoiceChip(
                    label: Text(
                      entry.value,
                      style: TextStyle(
                        color:
                            selected
                                ? Colors.white
                                : Colors.white.withOpacity(0.8),
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) {
                      final targetIndex = _entries.indexWhere(
                        (e) => e.key == entry.key,
                      );
                      if (targetIndex != -1) {
                        setState(() {
                          _currentIndex = targetIndex;
                        });
                        _pageController.animateToPage(
                          targetIndex,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Colors.black54,
                    showCheckmark: false,
                  );
                }).toList(),
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

  Widget _buildMessage(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class FloorMapWidget extends ConsumerWidget {
  final String campus;
  final String building;
  final int floor;
  final double? width;
  final double? height;

  const FloorMapWidget({
    super.key,
    required this.campus,
    required this.building,
    required this.floor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final floorMapAsync = ref.watch(
      floorMapProvider({
        'campus': campus,
        'building': building,
        'floor': floor,
      }),
    );
    final campusOptions = {campus: _displayNameFor(campus)};

    return floorMapAsync.when(
      data: (mapUrl) {
        if (mapUrl == null || mapUrl.isEmpty) {
          return _buildErrorWidget(context, 'フロアマップが見つかりません');
        }

        return _buildMapWidget(context, mapUrl, campusOptions);
      },
      loading: () => _buildLoadingWidget(context),
      error: (error, _) => _buildErrorWidget(context, 'フロアマップの読み込みに失敗しました'),
    );
  }

  Widget _buildMapWidget(
    BuildContext context,
    String mapUrl,
    Map<String, String> campusOptions,
  ) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onTap:
              () => _showFullScreenMap(context, campus, mapUrl, campusOptions),
          child:
              kIsWeb
                  ? Image.network(
                    mapUrl,
                    width: width,
                    height: height ?? 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildLoadingWidget(context);
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildErrorWidget(context, 'マップ画像の読み込みエラー');
                    },
                  )
                  : CachedNetworkImage(
                    imageUrl: mapUrl,
                    width: width,
                    height: height ?? 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildLoadingWidget(context),
                    errorWidget:
                        (context, url, error) =>
                            _buildErrorWidget(context, 'マップ画像の読み込みエラー'),
                  ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return AnimatedImagePlaceholder(
      width: width ?? double.infinity,
      height: height ?? 200,
      borderRadius: 8,
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, color: Colors.grey.shade600, size: 32),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenMap(
    BuildContext context,
    String initialCampus,
    String initialMapUrl,
    Map<String, String> campusOptions,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder:
          (context) => _FullScreenCampusMapDialog(
            initialCampus: initialCampus,
            initialMapUrl: initialMapUrl,
            campusOptions: campusOptions,
          ),
    );
  }
}

String _displayNameFor(String campusKey) {
  switch (campusKey) {
    case 'tsudanuma':
      return '津田沼';
    case 'narashino':
      return '新習志野';
    default:
      return campusKey;
  }
}
