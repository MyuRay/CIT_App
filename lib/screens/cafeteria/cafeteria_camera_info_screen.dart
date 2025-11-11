import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async';
import '../../services/cafeteria/cafeteria_camera_service.dart';
import '../../core/providers/settings_provider.dart';

class CafeteriaCameraInfoScreen extends ConsumerStatefulWidget {
  const CafeteriaCameraInfoScreen({super.key});

  @override
  ConsumerState<CafeteriaCameraInfoScreen> createState() => _CafeteriaCameraInfoScreenState();
}

class _CafeteriaCameraInfoScreenState extends ConsumerState<CafeteriaCameraInfoScreen> {
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
        {
          'key': 'narashino1',
          'name': '新習志野1F',
          'hours': '月〜土 11:00〜14:00',
        },
        {
          'key': 'narashino2',
          'name': '新習志野2F',
          'hours': '月〜金 11:00〜14:00',
        },
        {
          'key': 'tsudanuma',
          'name': '津田沼',
          'hours': '月〜土 11:00〜14:00',
        },
      ];
    } else {
      // 津田沼がメインキャンパスの場合（デフォルト）：津田沼 → 新習志野1F → 新習志野2F
      return [
        {
          'key': 'tsudanuma',
          'name': '津田沼',
          'hours': '月〜土 11:00〜14:00',
        },
        {
          'key': 'narashino1',
          'name': '新習志野1F',
          'hours': '月〜土 11:00〜14:00',
        },
        {
          'key': 'narashino2',
          'name': '新習志野2F',
          'hours': '月〜金 11:00〜14:00',
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraOrder = _getCameraOrder();
    return Scaffold(
      appBar: AppBar(
        title: const Text('食堂カメラ稼働時間'),
      ),
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '各食堂の混雑状況をカメラで確認できます。',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
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

            // 稼働時間テーブル
            Text(
              'カメラ稼働時間',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
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
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '注意事項',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• カメラは稼働時間内のみ利用可能です\n• 混雑状況により映像が遅延する場合があります\n• メンテナンス等で利用できない場合があります\n• 画像は5分毎に自動更新されます',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                  if (index < cameraOrder.length - 1) const SizedBox(height: 16),
                ],
              );
            }).toList(),
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
    final imageUrl = isActive
        ? CafeteriaCameraService.getCameraUrl(cafeteriaKey)
        : null;

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
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        operatingHours,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? '稼働中' : '停止中',
                    style: const TextStyle(
                      color: Colors.white,
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
              child: isActive && imageUrl != null
                  ? CachedNetworkImage(
                      key: ValueKey('${cafeteriaKey}_${_lastUpdate.millisecondsSinceEpoch ~/ (1000 * 60 * 5)}'), // 5分単位のキーでキャッシュを無効化
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      maxWidthDiskCache: 1920, // ディスクキャッシュの最大幅
                      maxHeightDiskCache: 1080, // ディスクキャッシュの最大高さ
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade900,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        debugPrint('カメラ画像読み込みエラー: $url, error: $error');
                        return _buildPlaceholderImage(
                          context,
                          cafeteriaName,
                          'カメラ画像の読み込みに失敗しました',
                        );
                      },
                      fadeInDuration: const Duration(milliseconds: 300),
                      fadeOutDuration: const Duration(milliseconds: 100),
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
            Icon(
              Icons.videocam_off,
              size: 64,
              color: Colors.grey.shade600,
            ),
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
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
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
          child: Text(
            name,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            time,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}
