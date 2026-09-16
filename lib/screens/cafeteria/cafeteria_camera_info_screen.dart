import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async';
import '../../services/cafeteria/cafeteria_camera_service.dart';
import '../../core/providers/settings_provider.dart';

class CafeteriaCameraInfoScreen extends ConsumerStatefulWidget {
  const CafeteriaCameraInfoScreen({super.key});

  @override
  ConsumerState<CafeteriaCameraInfoScreen> createState() =>
      _CafeteriaCameraInfoScreenState();
}

class _CafeteriaCameraInfoScreenState
    extends ConsumerState<CafeteriaCameraInfoScreen> {
  Timer? _refreshTimer;
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 5分毎に画像を更新
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        setState(() {
          _lastUpdate = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // カメラの表示順序を取得（メインキャンパスに基づく）
  List<Map<String, String>> _getCameraOrder() {
    final preferredCampus = ref.watch(preferredBusCampusProvider);

    if (preferredCampus == 'narashino') {
      // 新習志野がメインキャンパスの場合：新習志野1F → 新習志野2F → 津田沼
      return [
        {'key': 'narashino1', 'name': '新習志野1F', 'hours': '月〜土 11:00〜14:00'},
        {'key': 'narashino2', 'name': '新習志野2F', 'hours': '月〜金 11:00〜14:00'},
        {'key': 'tsudanuma', 'name': '津田沼', 'hours': '月〜土 11:00〜14:00'},
      ];
    } else {
      // 津田沼がメインキャンパスの場合（デフォルト）：津田沼 → 新習志野1F → 新習志野2F
      return [
        {'key': 'tsudanuma', 'name': '津田沼', 'hours': '月〜土 11:00〜14:00'},
        {'key': 'narashino1', 'name': '新習志野1F', 'hours': '月〜土 11:00〜14:00'},
        {'key': 'narashino2', 'name': '新習志野2F', 'hours': '月〜金 11:00〜14:00'},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraOrder = _getCameraOrder();
    return Scaffold(
      appBar: AppBar(title: const Text('食堂カメラ稼働時間')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 説明カード
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.videocam,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '食堂カメラについて',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '各食堂の混雑状況をカメラで確認できます。',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 稼働時間テーブル
            Text(
              'カメラ稼働時間',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                    width: 1,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            '食堂名',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            '稼働時間',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _buildTableRow('津田沼', '月～土\n11:00～14:00', context),
                    _buildTableRow('新習志野1F', '月～土\n11:00～14:00', context),
                    _buildTableRow('新習志野2F', '月～金\n11:00～14:00', context),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 注意事項
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '注意事項',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• カメラは稼働時間内のみ利用可能です\n• 混雑状況により映像が遅延する場合があります\n• メンテナンス等で利用できない場合があります\n• 画像は5分毎に自動更新されます',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // カメラ画像セクション
            Text(
              'ライブカメラ',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // カメラ画像を順番に表示（メインキャンパスに基づく順序）
            ...cameraOrder.asMap().entries.map((entry) {
              final index = entry.key;
              final camera = entry.value;
              return Column(
                children: [
                  _buildCameraCard(
                    context,
                    camera['key']!,
                    camera['name']!,
                    camera['hours']!,
                  ),
                  if (index < cameraOrder.length - 1)
                    const SizedBox(height: 16),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraCard(
    BuildContext context,
    String cafeteriaKey,
    String cafeteriaName,
    String operatingHours,
  ) {
    final now = DateTime.now();
    final isActive = CafeteriaCameraService.isCameraActive(
      cafeteria: cafeteriaKey,
      now: now,
    );
    final imageUrl =
        isActive ? CafeteriaCameraService.getCameraUrl(cafeteriaKey) : null;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.videocam,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cafeteriaName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        operatingHours,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? '稼働中' : '停止中',
                    style: TextStyle(
                      color: AppColors.onColor(isActive ? Colors.green : Colors.grey),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // カメラ画像
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child:
                  isActive && imageUrl != null
                      ? _CafeteriaCameraImage(
                        cafeteriaKey: cafeteriaKey,
                        cafeteriaName: cafeteriaName,
                        imageUrl: imageUrl,
                        // 5分単位のバケット。自動更新時にリセットされる。
                        refreshBucket:
                            _lastUpdate.millisecondsSinceEpoch ~/
                            (1000 * 60 * 5),
                      )
                      : _buildPlaceholderImage(
                        context,
                        cafeteriaName,
                        'カメラは稼働時間外です',
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(
    BuildContext context,
    String cafeteriaName,
    String message,
  ) {
    return Container(
      color: Colors.grey.shade900,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              cafeteriaName,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String name, String time, BuildContext context) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(name, style: const TextStyle(fontSize: 15)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(time, style: const TextStyle(fontSize: 15)),
        ),
      ],
    );
  }
}

/// カメラ画像。取得失敗・ハング時にスピナーが回り続けないよう、
/// タイムアウトと手動再読み込みで復帰できるようにする。
class _CafeteriaCameraImage extends StatefulWidget {
  const _CafeteriaCameraImage({
    required this.cafeteriaKey,
    required this.cafeteriaName,
    required this.imageUrl,
    required this.refreshBucket,
  });

  final String cafeteriaKey;
  final String cafeteriaName;
  final String imageUrl;
  final int refreshBucket;

  @override
  State<_CafeteriaCameraImage> createState() => _CafeteriaCameraImageState();
}

class _CafeteriaCameraImageState extends State<_CafeteriaCameraImage> {
  // 読み込みがこの時間を超えたら失敗扱いにして、無限スピナーを防ぐ。
  static const Duration _loadTimeout = Duration(seconds: 12);

  int _attempt = 0;
  bool _failed = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _startTimeout();
  }

  @override
  void didUpdateWidget(covariant _CafeteriaCameraImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 5分ごとの自動更新（バケット変化）でリセットして再取得を試みる。
    if (oldWidget.refreshBucket != widget.refreshBucket) {
      _attempt = 0;
      _failed = false;
      _startTimeout();
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_loadTimeout, () {
      if (mounted && !_failed) {
        setState(() => _failed = true);
      }
    });
  }

  void _stopTimeout() {
    _timeoutTimer?.cancel();
  }

  void _retry() {
    setState(() {
      _attempt++;
      _failed = false;
    });
    _startTimeout();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return _buildError();
    }

    // 試行ごとにキャッシュバスティングして、失敗した取得が
    // 5分間キャッシュに残り続けないようにする。
    final separator = widget.imageUrl.contains('?') ? '&' : '?';
    final url = '${widget.imageUrl}${separator}a=$_attempt';

    return CachedNetworkImage(
      key: ValueKey('${widget.cafeteriaKey}_${widget.refreshBucket}_$_attempt'),
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      maxWidthDiskCache: 1920,
      maxHeightDiskCache: 1080,
      imageBuilder: (context, imageProvider) {
        _stopTimeout();
        return Image(
          image: imageProvider,
          fit: BoxFit.cover,
          width: double.infinity,
        );
      },
      placeholder:
          (context, _) => Container(
            color: Colors.grey.shade900,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      errorWidget: (context, errorUrl, error) {
        debugPrint('カメラ画像読み込みエラー: $errorUrl, error: $error');
        _stopTimeout();
        // ビルド中の setState を避けつつ失敗状態へ遷移。
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_failed) {
            setState(() => _failed = true);
          }
        });
        return Container(
          color: Colors.grey.shade900,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      },
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }

  Widget _buildError() {
    return Container(
      color: Colors.grey.shade900,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 56, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            Text(
              widget.cafeteriaName,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'カメラ画像を取得できませんでした',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade600),
              ),
              label: const Text('再読み込み'),
            ),
          ],
        ),
      ),
    );
  }
}
