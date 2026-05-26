import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/firebase_campus_provider.dart';
import '../../widgets/campus/narashino_floor_plan_legal_copy.dart';
import '../../widgets/campus/narashino_local_floor_plan.dart'
    show NarashinoAssetFloorPlanImage;
import '../../widgets/campus/pan_gate_interactive_viewer.dart';
import '../../widgets/campus/tsudanuma_4_1f_floor_map.dart';
import '../../widgets/campus/tsudanuma_4_2f_floor_map.dart';
import '../../widgets/campus/tsudanuma_4_3f_floor_map.dart';
import '../../widgets/campus/tsudanuma_4_4f_floor_map.dart';
import '../../widgets/campus/tsudanuma_4_5f_floor_map.dart';
import '../../widgets/campus/tsudanuma_4_6f_floor_map.dart';
import '../../widgets/campus/tsudanuma_4_7f_floor_map.dart';
import '../../widgets/campus/tsudanuma_4_8f_floor_map.dart';
import '../../widgets/campus/tsudanuma_4_9f_floor_map.dart';
import '../../widgets/campus/tsudanuma_4_b1_floor_map.dart';
import '../../widgets/campus/tsudanuma_4_b2_floor_map.dart';
import '../../widgets/campus/tsudanuma_6_1f_floor_map.dart';
import '../../widgets/campus/tsudanuma_6_2f_floor_map.dart';
import '../../widgets/campus/tsudanuma_6_3f_floor_map.dart';
import '../../widgets/campus/tsudanuma_6_4f_floor_map.dart';
import '../../widgets/campus/tsudanuma_6_5f_floor_map.dart';
import '../../widgets/campus/tsudanuma_7f1_floor_map.dart';
import '../../widgets/campus/tsudanuma_7f2_floor_map.dart';
import '../../widgets/campus/tsudanuma_7f3_floor_map.dart';
import '../../widgets/campus/tsudanuma_7f4_floor_map.dart';
import '../../widgets/campus/tsudanuma_7f5_floor_map.dart';
import '../../widgets/campus/tsudanuma_7f6_floor_map.dart';
import '../../widgets/campus/tsudanuma_7f7_floor_map.dart';
import '../../widgets/campus/tsudanuma_7f8_floor_map.dart';
import '../../widgets/campus/tsudanuma_7f9_floor_map.dart';
import '../../widgets/common/animated_image_placeholder.dart';
import '../../widgets/campus_map_widget.dart';

/// 津田沼キャンパスでフロアマップの下からシートを出す校舎と、その階。
/// Storage のみ: `tsudanuma_{buildingId}_{floor}F.png`
const Map<String, List<int>> kTsudanumaBuildingFloors = {
  '4': [-2, -1, 1, 2, 3, 4, 5, 6, 7, 8, 9],
  '6': [1, 2, 3, 4, 5],
  '7': [1, 2, 3, 4, 5, 6, 7, 8, 9],
};

bool tsudanumaBuildingHasFloorMapsSheet(String buildingId) =>
    kTsudanumaBuildingFloors.containsKey(buildingId);

/// 階タブ・全画面ヘッダ用（地下は B2 / B1）。
String tsudanumaFloorTabLabel(int floor) {
  switch (floor) {
    case -2:
      return 'B2';
    case -1:
      return 'B1';
    default:
      return '$floor階';
  }
}

Future<void> _openInGoogleMaps(double lat, double lng) async {
  final url =
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

String? _tsudanumaLocalFloorAssetOrNull({
  required String buildingId,
  required int floor,
}) {
  if (buildingId == '4') {
    switch (floor) {
      case -2:
        return kTsudanuma4B2FloorPlanAsset;
      case -1:
        return kTsudanuma4B1FloorPlanAsset;
      case 1:
        return kTsudanuma4F1FloorPlanAsset;
      case 2:
        return kTsudanuma4F2FloorPlanAsset;
      case 3:
        return kTsudanuma4F3FloorPlanAsset;
      case 4:
        return kTsudanuma4F4FloorPlanAsset;
      case 5:
        return kTsudanuma4F5FloorPlanAsset;
      case 6:
        return kTsudanuma4F6FloorPlanAsset;
      case 7:
        return kTsudanuma4F7FloorPlanAsset;
      case 8:
        return kTsudanuma4F8FloorPlanAsset;
      case 9:
        return kTsudanuma4F9FloorPlanAsset;
      default:
        return null;
    }
  }
  if (buildingId == '6') {
    switch (floor) {
      case 1:
        return kTsudanuma6F1FloorPlanAsset;
      case 2:
        return kTsudanuma6F2FloorPlanAsset;
      case 3:
        return kTsudanuma6F3FloorPlanAsset;
      case 4:
        return kTsudanuma6F4FloorPlanAsset;
      case 5:
        return kTsudanuma6F5FloorPlanAsset;
      default:
        return null;
    }
  }
  if (buildingId == '7') {
    switch (floor) {
      case 1:
        return kTsudanuma7F1FloorPlanAsset;
      case 2:
        return kTsudanuma7F2FloorPlanAsset;
      case 3:
        return kTsudanuma7F3FloorPlanAsset;
      case 4:
        return kTsudanuma7F4FloorPlanAsset;
      case 5:
        return kTsudanuma7F5FloorPlanAsset;
      case 6:
        return kTsudanuma7F6FloorPlanAsset;
      case 7:
        return kTsudanuma7F7FloorPlanAsset;
      case 8:
        return kTsudanuma7F8FloorPlanAsset;
      case 9:
        return kTsudanuma7F9FloorPlanAsset;
      default:
        return null;
    }
  }
  return null;
}

void _showTsudanumaFloorsFullscreen(
  BuildContext context, {
  required String buildingId,
  required String buildingName,
  required List<int> floors,
  required int initialFloor,
  required double latitude,
  required double longitude,
}) {
  var initialIndex = floors.indexOf(initialFloor);
  if (initialIndex < 0) initialIndex = 0;
  showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierColor: Colors.black,
    builder:
        (ctx) => _TsudanumaFloorsFullscreenDialog(
          buildingId: buildingId,
          buildingName: buildingName,
          floors: floors,
          initialPage: initialIndex,
          latitude: latitude,
          longitude: longitude,
        ),
  );
}

class _TsudanumaFloorsFullscreenDialog extends StatefulWidget {
  const _TsudanumaFloorsFullscreenDialog({
    required this.buildingId,
    required this.buildingName,
    required this.floors,
    required this.initialPage,
    required this.latitude,
    required this.longitude,
  });

  final String buildingId;
  final String buildingName;
  final List<int> floors;
  final int initialPage;
  final double latitude;
  final double longitude;

  @override
  State<_TsudanumaFloorsFullscreenDialog> createState() =>
      _TsudanumaFloorsFullscreenDialogState();
}

class _TsudanumaFloorsFullscreenDialogState
    extends State<_TsudanumaFloorsFullscreenDialog> {
  late final PageController _pageController;
  late int _pageIndex;

  @override
  void initState() {
    super.initState();
    final i = widget.initialPage.clamp(0, widget.floors.length - 1);
    _pageIndex = i;
    _pageController = PageController(initialPage: i);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _floor => widget.floors[_pageIndex];

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            tooltip: '閉じる',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '津田沼キャンパス',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
              Text(
                '講義棟 · ${widget.buildingName}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '参照階 · ${tsudanumaFloorTabLabel(_floor)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.25,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Googleマップで開く',
              icon: const Icon(Icons.map_outlined),
              onPressed:
                  () => _openInGoogleMaps(widget.latitude, widget.longitude),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.floors.length,
                onPageChanged:
                    (i) => setState(() => _pageIndex = i.clamp(
                          0,
                          widget.floors.length - 1,
                        )),
                itemBuilder: (context, i) {
                  return TsudanumaBuildingFloorFullscreenBody(
                    buildingId: widget.buildingId,
                    floor: widget.floors[i],
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                4,
                12,
                MediaQuery.paddingOf(context).bottom + 10,
              ),
              child: narashinoFloorPlanFullscreenLegalFooter(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 全画面（1ページ）の津田沼フロア図。
class TsudanumaBuildingFloorFullscreenBody extends ConsumerWidget {
  const TsudanumaBuildingFloorFullscreenBody({
    super.key,
    required this.buildingId,
    required this.floor,
  });

  final String buildingId;
  final int floor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path =
        _tsudanumaLocalFloorAssetOrNull(buildingId: buildingId, floor: floor);
    if (path != null) {
      return PanGateInteractiveViewer(
        minScale: 0.55,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: NarashinoAssetFloorPlanImage(
            assetPath: path,
            fitWholeInViewport: true,
          ),
        ),
      );
    }

    final floorMapAsync = ref.watch(
      floorMapProvider({
        'campus': 'tsudanuma',
        'building': buildingId,
        'floor': floor,
      }),
    );

    return floorMapAsync.when(
      data: (mapUrl) => tsudanumaNetworkFloorFullscreen(mapUrl),
      loading:
          () =>
              const Center(child: AnimatedImagePlaceholder(width: 120, height: 120)),
      error: (_, _) => Center(
        child: Text(
          'フロアマップの読み込みに失敗しました',
          style: TextStyle(color: Colors.grey.shade400),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

Widget tsudanumaNetworkFloorFullscreen(String? mapUrl) {
  if (mapUrl == null || mapUrl.isEmpty) {
    return Center(
      child: Text(
        'この階のフロア画像が見つかりません（Storage を確認してください）',
        style: TextStyle(color: Colors.grey.shade400),
        textAlign: TextAlign.center,
      ),
    );
  }

  return PanGateInteractiveViewer(
    minScale: 0.55,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cw = constraints.maxWidth;
          final ch = constraints.maxHeight;
          if (cw <= 0 || ch <= 0) return const SizedBox.shrink();

          Widget image;
          if (kIsWeb) {
            image = Image.network(
              mapUrl,
              width: cw,
              height: ch,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const AnimatedImagePlaceholder(width: 120, height: 120);
              },
              errorBuilder:
                  (_, __, ___) => Icon(Icons.broken_image, color: Colors.grey.shade500),
            );
          } else {
            image = CachedNetworkImage(
              imageUrl: mapUrl,
              width: cw,
              height: ch,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: AnimatedImagePlaceholder(width: 120, height: 120),
              ),
              errorWidget:
                  (_, __, ___) => Icon(Icons.broken_image, color: Colors.grey.shade500),
            );
          }
          return Center(child: image);
        },
      ),
    ),
  );
}

/// 津田沼の指定校舎について、階タブ付きフロアマップシートを表示する。
Future<void> showTsudanumaBuildingFloorMapsBottomSheet(
  BuildContext context, {
  required String buildingId,
  required String buildingName,
  required double latitude,
  required double longitude,
}) {
  final floors = kTsudanumaBuildingFloors[buildingId]!;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final h = MediaQuery.sizeOf(sheetContext).height * 0.52;
      final fewFloors = floors.length <= 3;
      return SizedBox(
        height: h,
        child: Material(
          color: Theme.of(sheetContext).colorScheme.surface,
          child: DefaultTabController(
            length: floors.length,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    '津田沼キャンパス · $buildingName',
                    textAlign: TextAlign.center,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
                TabBar(
                  isScrollable: !fewFloors,
                  tabAlignment:
                      fewFloors ? TabAlignment.fill : TabAlignment.center,
                  labelColor: Theme.of(sheetContext).colorScheme.primary,
                  tabs: [
                    for (final f in floors) Tab(text: tsudanumaFloorTabLabel(f)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final f in floors)
                        _TsudanumaFloorPane(
                          buildingId: buildingId,
                          buildingName: buildingName,
                          floors: floors,
                          floor: f,
                          mapHeight: h * 0.44,
                          latitude: latitude,
                          longitude: longitude,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _tsudanumaSheetFloorPlanThumbnail(
  BuildContext context, {
  required String buildingId,
  required String buildingName,
  required List<int> sheetFloors,
  required int floor,
  required double mapHeight,
  required double latitude,
  required double longitude,
}) {
  void openFloorPager() {
    _showTsudanumaFloorsFullscreen(
      context,
      buildingId: buildingId,
      buildingName: buildingName,
      floors: sheetFloors,
      initialFloor: floor,
      latitude: latitude,
      longitude: longitude,
    );
  }

  final h = mapHeight.clamp(160, 400).toDouble();
  final path =
      _tsudanumaLocalFloorAssetOrNull(buildingId: buildingId, floor: floor);
  if (path != null) {
    return TsudanumaAssetFloorThumbnailForSheet(
      assetPath: path,
      sheetTitle: '$buildingName · ${tsudanumaFloorTabLabel(floor)}',
      height: h,
      onTap: openFloorPager,
    );
  }

  return FloorMapWidget(
    campus: 'tsudanuma',
    building: buildingId,
    floor: floor,
    height: h,
    onTapForFullscreen: openFloorPager,
  );
}

/// 津田沼アセットPNG（一覧と同じ外観だがタップで全階ページャを開く）。
class TsudanumaAssetFloorThumbnailForSheet extends StatelessWidget {
  const TsudanumaAssetFloorThumbnailForSheet({
    super.key,
    required this.assetPath,
    required this.sheetTitle,
    required this.height,
    required this.onTap,
  });

  final String assetPath;
  final String sheetTitle;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: Colors.grey.shade100,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.center,
              child: SizedBox(
                width: 400,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (context, error, stackTrace) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '$sheetTitle の画像がありません。\n$assetPath',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TsudanumaFloorPane extends StatelessWidget {
  const _TsudanumaFloorPane({
    required this.buildingId,
    required this.buildingName,
    required this.floors,
    required this.floor,
    required this.mapHeight,
    required this.latitude,
    required this.longitude,
  });

  final String buildingId;
  final String buildingName;
  final List<int> floors;
  final int floor;
  final double mapHeight;
  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tsudanumaSheetFloorPlanThumbnail(
            context,
            buildingId: buildingId,
            buildingName: buildingName,
            sheetFloors: floors,
            floor: floor,
            mapHeight: mapHeight,
            latitude: latitude,
            longitude: longitude,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                kNarashinoLocalFloorPlanDisclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openInGoogleMaps(latitude, longitude),
                icon: const Icon(Icons.directions),
                label: const Text('Googleマップで開く'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
