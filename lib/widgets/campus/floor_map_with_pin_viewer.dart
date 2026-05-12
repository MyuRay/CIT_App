import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/firebase_campus_provider.dart';
import '../../data/campus/classroom_map_pilot_search.dart';
import '../../data/campus/pilot_narashino_1f1_classrooms.dart';
import '../../data/campus/pilot_narashino_2f1_classrooms.dart';
import '../../data/campus/pilot_narashino_3f1_classrooms.dart';
import '../../data/campus/pilot_narashino_3f2_classrooms.dart';
import '../../data/campus/pilot_narashino_3f3_classrooms.dart';
import '../../data/campus/pilot_narashino_5f1_classrooms.dart';
import '../../data/campus/pilot_narashino_5f2_classrooms.dart';
import '../../data/campus/pilot_narashino_5f3_classrooms.dart';
import '../../data/campus/pilot_narashino_7f1_classrooms.dart';
import '../../data/campus/pilot_narashino_7f2_classrooms.dart';
import '../../data/campus/pilot_narashino_8f1_classrooms.dart';
import '../../data/campus/pilot_narashino_8f2_classrooms.dart';
import '../../data/campus/pilot_narashino_12f1_classrooms.dart';
import '../../data/campus/pilot_narashino_12f2_classrooms.dart';
import '../../data/campus/pilot_narashino_12f3_classrooms.dart';
import '../../data/campus/pilot_narashino_12f4_classrooms.dart';
import '../../data/campus/pilot_narashino_12f5_classrooms.dart';
import '../../data/campus/pilot_narashino_12f6_classrooms.dart';
import '../../data/campus/pilot_narashino_12f7_classrooms.dart';
import '../../data/campus/pilot_narashino_12f8_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_4_b1_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_4_b2_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_4_1f_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_4_2f_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_4_3f_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_4_4f_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_4_5f_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_4_6f_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_4_7f_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_4_8f_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_4_9f_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_6_1f_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_6_2f_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_6_3f_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_6_4f_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_6_5f_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_7f1_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_7f2_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_7f3_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_7f4_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_7f5_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_7f6_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_7f7_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_7f8_classrooms.dart';
import '../../data/campus/pilot_tsudanuma_7f9_classrooms.dart';
import '../../models/campus/campus_classroom_location.dart';
import '../common/animated_image_placeholder.dart';
import '../common/floor_map_viewport_fit.dart';
import 'narashino_1f1_schematic_map.dart';
import 'narashino_2f1_schematic_map.dart';
import 'narashino_3f1_schematic_map.dart';
import 'narashino_5f1_schematic_map.dart';
import 'narashino_7f1_floor_map.dart';
import 'narashino_8f1_schematic_map.dart';
import 'narashino_12f1_schematic_map.dart';
import 'narashino_floor_plan_legal_copy.dart';
import 'tsudanuma_4_b1_floor_map.dart';
import 'tsudanuma_4_b2_floor_map.dart';
import 'tsudanuma_4_1f_floor_map.dart';
import 'tsudanuma_4_2f_floor_map.dart';
import 'tsudanuma_4_3f_floor_map.dart';
import 'tsudanuma_4_4f_floor_map.dart';
import 'tsudanuma_4_5f_floor_map.dart';
import 'tsudanuma_4_6f_floor_map.dart';
import 'tsudanuma_4_7f_floor_map.dart';
import 'tsudanuma_4_8f_floor_map.dart';
import 'tsudanuma_4_9f_floor_map.dart';
import 'tsudanuma_6_1f_floor_map.dart';
import 'tsudanuma_6_2f_floor_map.dart';
import 'tsudanuma_6_3f_floor_map.dart';
import 'tsudanuma_6_4f_floor_map.dart';
import 'tsudanuma_6_5f_floor_map.dart';
import 'tsudanuma_7f1_floor_map.dart';
import 'tsudanuma_7f2_floor_map.dart';
import 'tsudanuma_7f3_floor_map.dart';
import 'tsudanuma_7f4_floor_map.dart';
import 'tsudanuma_7f5_floor_map.dart';
import 'tsudanuma_7f6_floor_map.dart';
import 'tsudanuma_7f7_floor_map.dart';
import 'tsudanuma_7f8_floor_map.dart';
import 'tsudanuma_7f9_floor_map.dart';

/// 教室マップのピン付き全画面フロア図の AppBar 高さ（キャンパス・講義棟・参照階・教室行の 4 行用）。
const double kFloorMapPinDialogToolbarHeight = 120.0;

/// 教室・フロアピン用全画面フロア図の AppBar タイトル。
///
/// [tsudanuma_building_floor_sheet] の館フロア全画面ヘッダ（津田沼キャンパス / 講義棟 / 参照階）に揃える。
Widget _floorMapPinDialogAppBarTitle(
  BuildContext context,
  CampusClassroomLocation room,
) {
  final theme = Theme.of(context);
  final campusLine = switch (room.campus) {
    'tsudanuma' => '津田沼キャンパス',
    'narashino' => '新習志野キャンパス',
    _ => room.campus,
  };

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        campusLine,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 13,
          height: 1.2,
        ),
      ),
      Text(
        '講義棟 · ${room.buildingDisplayName}',
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        '参照階 · ${room.floorCaption}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 14,
          height: 1.25,
        ),
      ),
      Text(
        room.floorMapDialogRoomDetailLine,
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

/// 教室のフロア見取り図を全画面で表示し、正規化座標でピンを重ねる。
///
/// 津田沼6号館1〜5階・7号館1〜9階など（同梱図）は Firebase を使わずアプリ内画像を表示し、津田沼4号館1〜9階・B1・B2・新習志野各号館のアプリ内床図も同様です（Storage を使わない場合）。
void showFloorMapWithPinDialog(
  BuildContext context,
  WidgetRef ref,
  CampusClassroomLocation room,
) {
  final resolved = resolveLatestPilotLocation(room);
  if (kDebugMode) {
    debugPrint(
      '📍 FloorMap pin ${resolved.roomCode} (${resolved.pinLabel ?? resolved.pinMapLabel}) '
      'pinX=${resolved.pinX} pinY=${resolved.pinY}',
    );
  }
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => _FloorMapWithPinDialog(room: resolved),
  );
}

/// アセット床図のレイアウト確定後にピクセルでピンを置く（読み込み前に高さ 0 の `Align` だけだとピンが動かないように見えることがある）。
Widget _tsudanumaAssetFloorWithPin({
  required CampusClassroomLocation room,
  required Widget floorImage,
  double mapWidth = 400,
}) {
  return SizedBox(
    width: mapWidth,
    child: Stack(
      alignment: Alignment.topLeft,
      clipBehavior: Clip.none,
      children: [
        floorImage,
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              if (w <= 1 || h <= 1) {
                return const SizedBox.shrink();
              }
              final x = room.pinXNormalized * w;
              final y = room.pinYNormalized * h;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: x,
                    top: y,
                    child: IgnorePointer(
                      // ラベル幅に依存せず、マーカー全体の中心を指定座標に合わせる。
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, -0.5),
                        child: _pinMarker(
                          room.pinMapLabel,
                          scale: room.pinMarkerScale,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _FloorMapWithPinDialog extends ConsumerWidget {
  const _FloorMapWithPinDialog({required this.room});

  final CampusClassroomLocation room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (usesTsudanuma7F1AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma7F1FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma7F2AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma7F2FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma7F3AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma7F3FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma7F4AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma7F4FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma7F5AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma7F5FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma7F6AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma7F6FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma7F7AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma7F7FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma7F8AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma7F8FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma7F9AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma7F9FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma4B2AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma4B2FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma4F1AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma4F1FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma6F1AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma6F1FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma6F2AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma6F2FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma6F3AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma6F3FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma6F4AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma6F4FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma6F5AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma6F5FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma4F2AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma4F2FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma4F3AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma4F3FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma4F4AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma4F4FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma4F5AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma4F5FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma4F6AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma4F6FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma4F8AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma4F8FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma4F9AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma4F9FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma4F7AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma4F7FloorMapBody(room: room),
      );
    }

    if (usesTsudanuma4B1AppFloorMap(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Tsudanuma4B1FloorMapBody(room: room),
      );
    }

    if (usesNarashino3F3AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino3F3SchematicMapBody(room: room),
      );
    }

    if (usesNarashino3F2AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino3F2SchematicMapBody(room: room),
      );
    }

    if (usesNarashino3F1AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino3F1SchematicMapBody(room: room),
      );
    }

    if (usesNarashino5F3AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino5F3SchematicMapBody(room: room),
      );
    }

    if (usesNarashino5F2AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino5F2SchematicMapBody(room: room),
      );
    }

    if (usesNarashino5F1AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino5F1SchematicMapBody(room: room),
      );
    }

    if (usesNarashino8F2AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino8F2SchematicMapBody(room: room),
      );
    }

    if (usesNarashino7F2AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino7F2SchematicMapBody(room: room),
      );
    }

    if (usesNarashino7F1AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino7F1SchematicMapBody(room: room),
      );
    }

    if (usesNarashino8F1AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino8F1SchematicMapBody(room: room),
      );
    }

    if (usesNarashino12F8AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino12F8SchematicMapBody(room: room),
      );
    }

    if (usesNarashino12F7AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino12F7SchematicMapBody(room: room),
      );
    }

    if (usesNarashino12F6AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino12F6SchematicMapBody(room: room),
      );
    }

    if (usesNarashino12F5AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino12F5SchematicMapBody(room: room),
      );
    }

    if (usesNarashino12F4AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino12F4SchematicMapBody(room: room),
      );
    }

    if (usesNarashino12F3AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino12F3SchematicMapBody(room: room),
      );
    }

    if (usesNarashino12F2AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino12F2SchematicMapBody(room: room),
      );
    }

    if (usesNarashino12F1AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino12F1SchematicMapBody(room: room),
      );
    }

    if (usesNarashino2F1AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino2F1SchematicMapBody(room: room),
      );
    }

    if (usesNarashino1F1AppSchematic(room)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _Narashino1F1SchematicMapBody(room: room),
      );
    }

    final asyncUrl = ref.watch(
      floorMapProvider({
        'campus': room.campus,
        'building': room.buildingId,
        'floor': room.floor,
      }),
    );

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: asyncUrl.when(
        data: (url) {
          if (url == null || url.isEmpty) {
            return _errorScaffold(
              context,
              'フロアマップが見つかりません（Storage: ${room.campus}_${room.buildingId}_${room.floor}F.png）',
            );
          }
          return _NetworkMapBody(room: room, mapUrl: url);
        },
        loading:
            () => const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: AnimatedImagePlaceholder(
                  width: 220,
                  height: 220,
                  borderRadius: 12,
                  borderColor: Colors.white24,
                ),
              ),
            ),
        error: (_, __) => _errorScaffold(context, 'フロアマップの読み込みに失敗しました'),
      ),
    );
  }

  Widget _errorScaffold(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}

class _Tsudanuma7F1FloorMapBody extends StatefulWidget {
  const _Tsudanuma7F1FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma7F1FloorMapBody> createState() =>
      _Tsudanuma7F1FloorMapBodyState();
}

class _Tsudanuma7F1FloorMapBodyState extends State<_Tsudanuma7F1FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma7F1FloorPlanMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma7F2FloorMapBody extends StatefulWidget {
  const _Tsudanuma7F2FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma7F2FloorMapBody> createState() =>
      _Tsudanuma7F2FloorMapBodyState();
}

class _Tsudanuma7F2FloorMapBodyState extends State<_Tsudanuma7F2FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma7F2SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma7F3FloorMapBody extends StatefulWidget {
  const _Tsudanuma7F3FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma7F3FloorMapBody> createState() =>
      _Tsudanuma7F3FloorMapBodyState();
}

class _Tsudanuma7F3FloorMapBodyState extends State<_Tsudanuma7F3FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma7F3SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma7F4FloorMapBody extends StatefulWidget {
  const _Tsudanuma7F4FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma7F4FloorMapBody> createState() =>
      _Tsudanuma7F4FloorMapBodyState();
}

class _Tsudanuma7F4FloorMapBodyState extends State<_Tsudanuma7F4FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma7F4SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma7F5FloorMapBody extends StatefulWidget {
  const _Tsudanuma7F5FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma7F5FloorMapBody> createState() =>
      _Tsudanuma7F5FloorMapBodyState();
}

class _Tsudanuma7F5FloorMapBodyState extends State<_Tsudanuma7F5FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma7F5SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma7F6FloorMapBody extends StatefulWidget {
  const _Tsudanuma7F6FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma7F6FloorMapBody> createState() =>
      _Tsudanuma7F6FloorMapBodyState();
}

class _Tsudanuma7F6FloorMapBodyState extends State<_Tsudanuma7F6FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma7F6SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma7F7FloorMapBody extends StatefulWidget {
  const _Tsudanuma7F7FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma7F7FloorMapBody> createState() =>
      _Tsudanuma7F7FloorMapBodyState();
}

class _Tsudanuma7F7FloorMapBodyState extends State<_Tsudanuma7F7FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma7F7SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma7F8FloorMapBody extends StatefulWidget {
  const _Tsudanuma7F8FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma7F8FloorMapBody> createState() =>
      _Tsudanuma7F8FloorMapBodyState();
}

class _Tsudanuma7F8FloorMapBodyState extends State<_Tsudanuma7F8FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma7F8SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma7F9FloorMapBody extends StatefulWidget {
  const _Tsudanuma7F9FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma7F9FloorMapBody> createState() =>
      _Tsudanuma7F9FloorMapBodyState();
}

class _Tsudanuma7F9FloorMapBodyState extends State<_Tsudanuma7F9FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma7F9SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma4B1FloorMapBody extends StatefulWidget {
  const _Tsudanuma4B1FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma4B1FloorMapBody> createState() =>
      _Tsudanuma4B1FloorMapBodyState();
}

class _Tsudanuma4B1FloorMapBodyState extends State<_Tsudanuma4B1FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma4B1SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma4B2FloorMapBody extends StatefulWidget {
  const _Tsudanuma4B2FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma4B2FloorMapBody> createState() =>
      _Tsudanuma4B2FloorMapBodyState();
}

class _Tsudanuma4B2FloorMapBodyState extends State<_Tsudanuma4B2FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma4B2SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma4F1FloorMapBody extends StatefulWidget {
  const _Tsudanuma4F1FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma4F1FloorMapBody> createState() =>
      _Tsudanuma4F1FloorMapBodyState();
}

class _Tsudanuma4F1FloorMapBodyState extends State<_Tsudanuma4F1FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma4F1SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma6F1FloorMapBody extends StatefulWidget {
  const _Tsudanuma6F1FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma6F1FloorMapBody> createState() =>
      _Tsudanuma6F1FloorMapBodyState();
}

class _Tsudanuma6F1FloorMapBodyState extends State<_Tsudanuma6F1FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma6F1SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma6F2FloorMapBody extends StatefulWidget {
  const _Tsudanuma6F2FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma6F2FloorMapBody> createState() =>
      _Tsudanuma6F2FloorMapBodyState();
}

class _Tsudanuma6F2FloorMapBodyState extends State<_Tsudanuma6F2FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma6F2SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma6F3FloorMapBody extends StatefulWidget {
  const _Tsudanuma6F3FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma6F3FloorMapBody> createState() =>
      _Tsudanuma6F3FloorMapBodyState();
}

class _Tsudanuma6F3FloorMapBodyState extends State<_Tsudanuma6F3FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma6F3SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma6F4FloorMapBody extends StatefulWidget {
  const _Tsudanuma6F4FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma6F4FloorMapBody> createState() =>
      _Tsudanuma6F4FloorMapBodyState();
}

class _Tsudanuma6F4FloorMapBodyState extends State<_Tsudanuma6F4FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma6F4SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma6F5FloorMapBody extends StatefulWidget {
  const _Tsudanuma6F5FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma6F5FloorMapBody> createState() =>
      _Tsudanuma6F5FloorMapBodyState();
}

class _Tsudanuma6F5FloorMapBodyState extends State<_Tsudanuma6F5FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma6F5SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma4F2FloorMapBody extends StatefulWidget {
  const _Tsudanuma4F2FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma4F2FloorMapBody> createState() =>
      _Tsudanuma4F2FloorMapBodyState();
}

class _Tsudanuma4F2FloorMapBodyState extends State<_Tsudanuma4F2FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma4F2SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma4F3FloorMapBody extends StatefulWidget {
  const _Tsudanuma4F3FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma4F3FloorMapBody> createState() =>
      _Tsudanuma4F3FloorMapBodyState();
}

class _Tsudanuma4F3FloorMapBodyState extends State<_Tsudanuma4F3FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma4F3SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma4F4FloorMapBody extends StatefulWidget {
  const _Tsudanuma4F4FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma4F4FloorMapBody> createState() =>
      _Tsudanuma4F4FloorMapBodyState();
}

class _Tsudanuma4F4FloorMapBodyState extends State<_Tsudanuma4F4FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma4F4SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma4F5FloorMapBody extends StatefulWidget {
  const _Tsudanuma4F5FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma4F5FloorMapBody> createState() =>
      _Tsudanuma4F5FloorMapBodyState();
}

class _Tsudanuma4F5FloorMapBodyState extends State<_Tsudanuma4F5FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma4F5SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma4F6FloorMapBody extends StatefulWidget {
  const _Tsudanuma4F6FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma4F6FloorMapBody> createState() =>
      _Tsudanuma4F6FloorMapBodyState();
}

class _Tsudanuma4F6FloorMapBodyState extends State<_Tsudanuma4F6FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma4F6SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma4F7FloorMapBody extends StatefulWidget {
  const _Tsudanuma4F7FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma4F7FloorMapBody> createState() =>
      _Tsudanuma4F7FloorMapBodyState();
}

class _Tsudanuma4F7FloorMapBodyState extends State<_Tsudanuma4F7FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma4F7SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma4F8FloorMapBody extends StatefulWidget {
  const _Tsudanuma4F8FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma4F8FloorMapBody> createState() =>
      _Tsudanuma4F8FloorMapBodyState();
}

class _Tsudanuma4F8FloorMapBodyState extends State<_Tsudanuma4F8FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma4F8SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Tsudanuma4F9FloorMapBody extends StatefulWidget {
  const _Tsudanuma4F9FloorMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Tsudanuma4F9FloorMapBody> createState() =>
      _Tsudanuma4F9FloorMapBodyState();
}

class _Tsudanuma4F9FloorMapBodyState extends State<_Tsudanuma4F9FloorMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: _tsudanumaAssetFloorWithPin(
                  room: room,
                  floorImage: const Tsudanuma4F9SchematicMap(),
                  mapWidth: mapWidth,
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino2F1SchematicMapBody extends StatefulWidget {
  const _Narashino2F1SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino2F1SchematicMapBody> createState() =>
      _Narashino2F1SchematicMapBodyState();
}

class _Narashino2F1SchematicMapBodyState
    extends State<_Narashino2F1SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino2F1SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino3F1SchematicMapBody extends StatefulWidget {
  const _Narashino3F1SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino3F1SchematicMapBody> createState() =>
      _Narashino3F1SchematicMapBodyState();
}

class _Narashino3F1SchematicMapBodyState
    extends State<_Narashino3F1SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino3F1SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino3F2SchematicMapBody extends StatefulWidget {
  const _Narashino3F2SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino3F2SchematicMapBody> createState() =>
      _Narashino3F2SchematicMapBodyState();
}

class _Narashino3F2SchematicMapBodyState
    extends State<_Narashino3F2SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino3F2SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino3F3SchematicMapBody extends StatefulWidget {
  const _Narashino3F3SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino3F3SchematicMapBody> createState() =>
      _Narashino3F3SchematicMapBodyState();
}

class _Narashino3F3SchematicMapBodyState
    extends State<_Narashino3F3SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino3F3SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino5F3SchematicMapBody extends StatefulWidget {
  const _Narashino5F3SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino5F3SchematicMapBody> createState() =>
      _Narashino5F3SchematicMapBodyState();
}

class _Narashino5F3SchematicMapBodyState
    extends State<_Narashino5F3SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino5F3SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino5F2SchematicMapBody extends StatefulWidget {
  const _Narashino5F2SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino5F2SchematicMapBody> createState() =>
      _Narashino5F2SchematicMapBodyState();
}

class _Narashino5F2SchematicMapBodyState
    extends State<_Narashino5F2SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino5F2SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino5F1SchematicMapBody extends StatefulWidget {
  const _Narashino5F1SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino5F1SchematicMapBody> createState() =>
      _Narashino5F1SchematicMapBodyState();
}

class _Narashino5F1SchematicMapBodyState
    extends State<_Narashino5F1SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino5F1SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino8F2SchematicMapBody extends StatefulWidget {
  const _Narashino8F2SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino8F2SchematicMapBody> createState() =>
      _Narashino8F2SchematicMapBodyState();
}

class _Narashino8F2SchematicMapBodyState
    extends State<_Narashino8F2SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino8F2SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino8F1SchematicMapBody extends StatefulWidget {
  const _Narashino8F1SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino8F1SchematicMapBody> createState() =>
      _Narashino8F1SchematicMapBodyState();
}

class _Narashino8F1SchematicMapBodyState
    extends State<_Narashino8F1SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino8F1SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino7F1SchematicMapBody extends StatefulWidget {
  const _Narashino7F1SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino7F1SchematicMapBody> createState() =>
      _Narashino7F1SchematicMapBodyState();
}

class _Narashino7F1SchematicMapBodyState
    extends State<_Narashino7F1SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino7F1SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino7F2SchematicMapBody extends StatefulWidget {
  const _Narashino7F2SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino7F2SchematicMapBody> createState() =>
      _Narashino7F2SchematicMapBodyState();
}

class _Narashino7F2SchematicMapBodyState
    extends State<_Narashino7F2SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino7F2SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino12F8SchematicMapBody extends StatefulWidget {
  const _Narashino12F8SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino12F8SchematicMapBody> createState() =>
      _Narashino12F8SchematicMapBodyState();
}

class _Narashino12F8SchematicMapBodyState
    extends State<_Narashino12F8SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino12F8SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino12F7SchematicMapBody extends StatefulWidget {
  const _Narashino12F7SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino12F7SchematicMapBody> createState() =>
      _Narashino12F7SchematicMapBodyState();
}

class _Narashino12F7SchematicMapBodyState
    extends State<_Narashino12F7SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino12F7SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino12F6SchematicMapBody extends StatefulWidget {
  const _Narashino12F6SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino12F6SchematicMapBody> createState() =>
      _Narashino12F6SchematicMapBodyState();
}

class _Narashino12F6SchematicMapBodyState
    extends State<_Narashino12F6SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino12F6SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino12F5SchematicMapBody extends StatefulWidget {
  const _Narashino12F5SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino12F5SchematicMapBody> createState() =>
      _Narashino12F5SchematicMapBodyState();
}

class _Narashino12F5SchematicMapBodyState
    extends State<_Narashino12F5SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino12F5SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino12F4SchematicMapBody extends StatefulWidget {
  const _Narashino12F4SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino12F4SchematicMapBody> createState() =>
      _Narashino12F4SchematicMapBodyState();
}

class _Narashino12F4SchematicMapBodyState
    extends State<_Narashino12F4SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino12F4SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino12F3SchematicMapBody extends StatefulWidget {
  const _Narashino12F3SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino12F3SchematicMapBody> createState() =>
      _Narashino12F3SchematicMapBodyState();
}

class _Narashino12F3SchematicMapBodyState
    extends State<_Narashino12F3SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino12F3SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino12F2SchematicMapBody extends StatefulWidget {
  const _Narashino12F2SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino12F2SchematicMapBody> createState() =>
      _Narashino12F2SchematicMapBodyState();
}

class _Narashino12F2SchematicMapBodyState
    extends State<_Narashino12F2SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino12F2SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino12F1SchematicMapBody extends StatefulWidget {
  const _Narashino12F1SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino12F1SchematicMapBody> createState() =>
      _Narashino12F1SchematicMapBodyState();
}

class _Narashino12F1SchematicMapBodyState
    extends State<_Narashino12F1SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino12F1SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

class _Narashino1F1SchematicMapBody extends StatefulWidget {
  const _Narashino1F1SchematicMapBody({required this.room});

  final CampusClassroomLocation room;

  @override
  State<_Narashino1F1SchematicMapBody> createState() =>
      _Narashino1F1SchematicMapBodyState();
}

class _Narashino1F1SchematicMapBodyState
    extends State<_Narashino1F1SchematicMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    const mapWidth = 400.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: SizedBox(
                  width: mapWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      const Narashino1F1SchematicMap(),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment(
                              2 * room.pinXNormalized - 1,
                              2 * room.pinYNormalized - 1,
                            ),
                            child: _pinMarker(
                              room.pinMapLabel,
                              scale: room.pinMarkerScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}

Widget _pinMarker(String label, {double scale = 1.0}) {
  final s = scale.clamp(0.5, 1.0);
  final len = label.length;
  final double maxLabelWidthBase;
  final double fontSizeBase;
  final int maxLines;
  final EdgeInsets paddingBase;
  if (len > 44) {
    maxLabelWidthBase = 280;
    fontSizeBase = 8;
    maxLines = 8;
    paddingBase = const EdgeInsets.symmetric(horizontal: 6, vertical: 4);
  } else if (len > 30) {
    maxLabelWidthBase = 248;
    fontSizeBase = 9;
    maxLines = 7;
    paddingBase = const EdgeInsets.symmetric(horizontal: 6, vertical: 4);
  } else if (len > 18) {
    maxLabelWidthBase = 200;
    fontSizeBase = 10;
    maxLines = 5;
    paddingBase = const EdgeInsets.symmetric(horizontal: 7, vertical: 4);
  } else if (len > 14) {
    maxLabelWidthBase = 180;
    fontSizeBase = 11;
    maxLines = 4;
    paddingBase = const EdgeInsets.symmetric(horizontal: 7, vertical: 4);
  } else {
    maxLabelWidthBase = 168;
    fontSizeBase = 12;
    maxLines = 4;
    paddingBase = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
  }
  final maxLabelWidth = (maxLabelWidthBase * s).clamp(96.0, 320.0);
  final fontSize = (fontSizeBase * s).clamp(5.0, 14.0);
  final iconSize = (44 * s).clamp(22.0, 44.0);
  final padding = EdgeInsets.fromLTRB(
    paddingBase.left * s,
    paddingBase.top * s,
    paddingBase.right * s,
    paddingBase.bottom * s,
  );
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.place,
        color: Colors.redAccent.shade200,
        size: iconSize,
        shadows: [Shadow(blurRadius: 6 * s, color: Colors.black54)],
      ),
      Material(
        color: Colors.white,
        elevation: 2 * s,
        borderRadius: BorderRadius.circular((6 * s).clamp(4.0, 8.0)),
        child: Padding(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxLabelWidth),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
                height: 1.2,
              ),
              maxLines: maxLines,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    ],
  );
}

class _NetworkMapBody extends StatefulWidget {
  const _NetworkMapBody({required this.room, required this.mapUrl});

  final CampusClassroomLocation room;
  final String mapUrl;

  @override
  State<_NetworkMapBody> createState() => _NetworkMapBodyState();
}

class _NetworkMapBodyState extends State<_NetworkMapBody> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final z = scale > 1.05;
    if (z != _zoomed) setState(() => _zoomed = z);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  Widget _buildImage() {
    if (kIsWeb) {
      return Image.network(
        widget.mapUrl,
        fit: BoxFit.none,
        filterQuality: FilterQuality.medium,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            width: 200,
            height: 200,
            child: AnimatedImagePlaceholder(
              width: 200,
              height: 200,
              borderRadius: 12,
              borderColor: Colors.white24,
            ),
          );
        },
        errorBuilder:
            (context, error, stack) => const Icon(Icons.broken_image, size: 64),
      );
    }
    return CachedNetworkImage(
      imageUrl: widget.mapUrl,
      fit: BoxFit.none,
      filterQuality: FilterQuality.medium,
      placeholder:
          (context, url) => const SizedBox(
            width: 200,
            height: 200,
            child: AnimatedImagePlaceholder(
              width: 200,
              height: 200,
              borderRadius: 12,
              borderColor: Colors.white24,
            ),
          ),
      errorWidget:
          (context, url, error) =>
              const Icon(Icons.broken_image, size: 64, color: Colors.white54),
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: kFloorMapPinDialogToolbarHeight,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _floorMapPinDialogAppBarTitle(context, room),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.05,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(120),
              clipBehavior: Clip.hardEdge,
              child: floorMapViewportFitHost(
                child: Stack(
                  alignment: Alignment.topLeft,
                  clipBehavior: Clip.none,
                  children: [
                    _buildImage(),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Align(
                          alignment: Alignment(
                            2 * room.pinXNormalized - 1,
                            2 * room.pinYNormalized - 1,
                          ),
                          child: _pinMarker(
                            room.pinMapLabel,
                            scale: room.pinMarkerScale,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!_zoomed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanPinDialogLegalFooter(),
            ),
        ],
      ),
    );
  }
}
