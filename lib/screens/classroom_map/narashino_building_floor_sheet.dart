import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/firebase_campus_provider.dart';
import '../../widgets/campus/narashino_12f1_schematic_map.dart';
import '../../widgets/campus/narashino_1f1_schematic_map.dart';
import '../../widgets/campus/narashino_2f1_schematic_map.dart';
import '../../widgets/campus/narashino_3f1_schematic_map.dart';
import '../../widgets/campus/narashino_5f1_schematic_map.dart';
import '../../widgets/campus/narashino_7f1_floor_map.dart';
import '../../widgets/campus/narashino_8f1_schematic_map.dart';
import '../../widgets/campus/narashino_floor_plan_legal_copy.dart';
import '../../widgets/campus/narashino_local_floor_plan.dart'
    show NarashinoAssetFloorPlanImage;
import '../../widgets/campus/pan_gate_interactive_viewer.dart';
import '../../widgets/common/animated_image_placeholder.dart';
import '../../widgets/campus_map_widget.dart';

/// 新習志野キャンパスでフロアマップの下からシートを出す校舎と、その階（1始まり）。
/// Storage のみの階: `narashino_{buildingId}_{floor}F.png`
const Map<String, List<int>> kNarashinoBuildingFloors = {
  '1': [1],
  '2': [1, 2, 3, 4, 5, 6, 7, 8, 9],
  '3': [1, 2, 3],
  '5': [1, 2, 3],
  '7': [1, 2],
  '8': [1, 2],
  '12': [1, 2, 3, 4, 5, 6, 7, 8],
};

bool narashinoBuildingHasFloorMapsSheet(String buildingId) =>
    kNarashinoBuildingFloors.containsKey(buildingId);

/// 画面上の階ラベル（地上は「N階」）。
String narashinoFloorDisplayLabel(int floor) => '$floor階';

Future<void> _openInGoogleMaps(double lat, double lng) async {
  final url =
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

/// 講義棟シート・アセット両方が参照する、アセットがある場合のアセットパス。
String? _narashinoLocalFloorAssetOrNull({
  required String buildingId,
  required int floor,
}) {
  switch (buildingId) {
    case '1':
      if (floor == 1) return kNarashino1F1FloorPlanAsset;
      return null;
    case '2':
      if (floor == 1) return kNarashino2F1FloorPlanAsset;
      if (narashinoBuilding2FloorUsesLocalAsset(floor)) {
        return narashino2UpperFloorsCompositeAssetPath(floor);
      }
      return null;
    case '3':
      switch (floor) {
        case 1:
          return kNarashino3F1FloorPlanAsset;
        case 2:
          return kNarashino3F2FloorPlanAsset;
        case 3:
          return kNarashino3F3FloorPlanAsset;
        default:
          return null;
      }
    case '5':
      switch (floor) {
        case 1:
          return kNarashino5F1FloorPlanAsset;
        case 2:
          return kNarashino5F2FloorPlanAsset;
        case 3:
          return kNarashino5F3FloorPlanAsset;
        default:
          return null;
      }
    case '7':
      switch (floor) {
        case 1:
          return kNarashino7F1FloorPlanAsset;
        case 2:
          return kNarashino7F2FloorPlanAsset;
        default:
          return null;
      }
    case '8':
      switch (floor) {
        case 1:
          return kNarashino8F1FloorPlanAsset;
        case 2:
          return kNarashino8F2FloorPlanAsset;
        default:
          return null;
      }
    case '12':
      switch (floor) {
        case 1:
          return kNarashino12F1FloorPlanAsset;
        case 2:
          return kNarashino12F2FloorPlanAsset;
        case 3:
          return kNarashino12F3FloorPlanAsset;
        case 4:
          return kNarashino12F4FloorPlanAsset;
        case 5:
          return kNarashino12F5FloorPlanAsset;
        case 6:
          return kNarashino12F6FloorPlanAsset;
        case 7:
          return kNarashino12F7FloorPlanAsset;
        case 8:
          return kNarashino12F8FloorPlanAsset;
        default:
          return null;
      }
    default:
      return null;
  }
}

void _showNarashinoFloorsFullscreen(
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
        (ctx) => _NarashinoFloorsFullscreenDialog(
          buildingId: buildingId,
          buildingName: buildingName,
          floors: floors,
          initialPage: initialIndex,
          latitude: latitude,
          longitude: longitude,
        ),
  );
}

class _NarashinoFloorsFullscreenDialog extends StatefulWidget {
  const _NarashinoFloorsFullscreenDialog({
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
  State<_NarashinoFloorsFullscreenDialog> createState() =>
      _NarashinoFloorsFullscreenDialogState();
}

class _NarashinoFloorsFullscreenDialogState
    extends State<_NarashinoFloorsFullscreenDialog> {
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
                '新習志野キャンパス',
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
                '参照階 · ${narashinoFloorDisplayLabel(_floor)}',
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
                  return NarashinoBuildingFloorFullscreenBody(
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

/// 全画面1ページ分（アセットまたは Firebase）。
class NarashinoBuildingFloorFullscreenBody extends ConsumerWidget {
  const NarashinoBuildingFloorFullscreenBody({
    super.key,
    required this.buildingId,
    required this.floor,
  });

  final String buildingId;
  final int floor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetPath =
        _narashinoLocalFloorAssetOrNull(
          buildingId: buildingId,
          floor: floor,
        );
    if (assetPath != null) {
      return PanGateInteractiveViewer(
        minScale: 0.55,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: NarashinoAssetFloorPlanImage(
            assetPath: assetPath,
            fitWholeInViewport: true,
          ),
        ),
      );
    }

    final floorMapAsync = ref.watch(
      floorMapProvider({
        'campus': 'narashino',
        'building': buildingId,
        'floor': floor,
      }),
    );

    return floorMapAsync.when(
      data: (mapUrl) => narashinoNetworkFloorFullscreen(mapUrl),
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

/// Firebase のフロア画像（ページ横スワイプと両立させる）。
Widget narashinoNetworkFloorFullscreen(String? mapUrl) {
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

/// 新習志野の指定校舎について、階タブ付きフロアマップシートを表示する。
Future<void> showNarashinoBuildingFloorMapsBottomSheet(
  BuildContext context, {
  required String buildingId,
  required String buildingName,
  required double latitude,
  required double longitude,
}) {
  final floors = kNarashinoBuildingFloors[buildingId]!;
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
                    '新習志野キャンパス · $buildingName',
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
                    for (final f in floors) Tab(text: '$f階'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final f in floors)
                        _NarashinoFloorPane(
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

Widget _narashinoSheetFloorPlanThumbnail(
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
    _showNarashinoFloorsFullscreen(
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
  switch (buildingId) {
    case '1':
      if (floor == 1) {
        return Narashino1F1FloorMapThumbnail(
          height: h,
          onThumbnailTap: openFloorPager,
        );
      }
      break;
    case '2':
      if (narashinoBuilding2FloorUsesLocalAsset(floor)) {
        return floor == 1
            ? Narashino2F1FloorMapThumbnail(
              height: h,
              onThumbnailTap: openFloorPager,
            )
            : Narashino2UpperFloorsMapThumbnail(
              floor: floor,
              height: h,
              onThumbnailTap: openFloorPager,
            );
      }
      break;
    case '3':
      switch (floor) {
        case 1:
          return Narashino3F1FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        case 2:
          return Narashino3F2FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        case 3:
          return Narashino3F3FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        default:
          break;
      }
      break;
    case '5':
      switch (floor) {
        case 1:
          return Narashino5F1FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        case 2:
          return Narashino5F2FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        case 3:
          return Narashino5F3FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        default:
          break;
      }
      break;
    case '7':
      switch (floor) {
        case 1:
          return Narashino7F1FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        case 2:
          return Narashino7F2FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        default:
          break;
      }
      break;
    case '8':
      switch (floor) {
        case 1:
          return Narashino8F1FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        case 2:
          return Narashino8F2FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        default:
          break;
      }
      break;
    case '12':
      switch (floor) {
        case 1:
          return Narashino12F1FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        case 2:
          return Narashino12F2FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        case 3:
          return Narashino12F3FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        case 4:
          return Narashino12F4FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        case 5:
          return Narashino12F5FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        case 6:
          return Narashino12F6FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        case 7:
          return Narashino12F7FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        case 8:
          return Narashino12F8FloorMapThumbnail(
            height: h,
            onThumbnailTap: openFloorPager,
          );
        default:
          break;
      }
      break;
  }
  return FloorMapWidget(
    campus: 'narashino',
    building: buildingId,
    floor: floor,
    height: h,
    onTapForFullscreen: openFloorPager,
  );
}

class _NarashinoFloorPane extends StatelessWidget {
  const _NarashinoFloorPane({
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
          _narashinoSheetFloorPlanThumbnail(
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
