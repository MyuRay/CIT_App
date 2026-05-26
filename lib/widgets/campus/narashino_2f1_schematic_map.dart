import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

/// 新習志野2号館1階フロア図のアセットパス（`pubspec.yaml` の `assets/images/` 配下）。
const String kNarashino2F1FloorPlanAsset =
    'assets/images/classroom_map/narashino_2_1f.png';

/// 新習志野2号館6階フロア図（専用アセット。研究室のみの区画のためパイロット検索には載せない）。
const String kNarashino2F6FloorPlanAsset =
    'assets/images/classroom_map/narashino_2_6f.png';

/// 2号館の 2・3・4・5・7・8・9階で共通利用するフロア図（合成1枚）。6階は [kNarashino2F6FloorPlanAsset]。
const String kNarashino2Floors2345789Asset =
    'assets/images/classroom_map/narashino_2_floors_2345789.png';

/// [FloorMapWidget] がアセット画像を使う 2 号館の階（1 階を除く上層）。
const Set<int> kNarashino2BuildingLocalImageFloorsUpper = {2, 3, 4, 5, 6, 7, 8, 9};

/// 2号館上層フロアの教室マップ用画像パス（6階のみ専用、その他は合成図）。
String narashino2UpperFloorsCompositeAssetPath(int floor) {
  if (floor == 6) return kNarashino2F6FloorPlanAsset;
  return kNarashino2Floors2345789Asset;
}

/// 2 号館の [floor] がアプリ内アセットのフロア図か（1 階および上記階）。
bool narashinoBuilding2FloorUsesLocalAsset(int floor) =>
    floor == 1 || kNarashino2BuildingLocalImageFloorsUpper.contains(floor);

/// 新習志野2号館1階のフロア図（アセット画像）。
///
/// ピンは親の [Stack] で [Positioned.fill] + [Align] により重ねる想定（正規化座標 0〜1）。
class Narashino2F1SchematicMap extends StatelessWidget {
  const Narashino2F1SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino2F1FloorPlanAsset);
  }
}

/// 教室マップの [FloorMapWidget] 用：2号館1階のサムネイル＋タップで全画面。
class Narashino2F1FloorMapThumbnail extends StatelessWidget {
  const Narashino2F1FloorMapThumbnail({
    super.key,
    this.width,
    this.height,
    this.onThumbnailTap,
  });

  final double? width;
  final double? height;
  final VoidCallback? onThumbnailTap;

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorMapThumbnail(
      assetPath: kNarashino2F1FloorPlanAsset,
      fullScreenTitle: '新習志野 · 2号館1階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}

/// 2号館1階のフロア図を全画面で拡大表示。
void showNarashino2F1SchematicFullScreen(BuildContext context) {
  showNarashinoAssetFloorPlanFullScreen(
    context,
    assetPath: kNarashino2F1FloorPlanAsset,
    fullScreenTitle: '新習志野 · 2号館1階',
  );
}

/// 教室マップの [FloorMapWidget] 用：2号館上層（6階は専用アセット、それ以外は合成図）。
class Narashino2UpperFloorsMapThumbnail extends StatelessWidget {
  const Narashino2UpperFloorsMapThumbnail({
    super.key,
    required this.floor,
    this.width,
    this.height,
    this.onThumbnailTap,
  });

  final int floor;
  final double? width;
  final double? height;
  final VoidCallback? onThumbnailTap;

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorMapThumbnail(
      assetPath: narashino2UpperFloorsCompositeAssetPath(floor),
      fullScreenTitle: '新習志野 · 2号館$floor階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
