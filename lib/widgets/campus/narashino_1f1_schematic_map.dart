import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

/// 新習志野1号館1階フロア図のアセットパス（`pubspec.yaml` の `assets/images/` 配下）。
const String kNarashino1F1FloorPlanAsset =
    'assets/images/classroom_map/narashino_1_1f.png';

/// 新習志野1号館1階のフロア図（アセット画像）。
class Narashino1F1SchematicMap extends StatelessWidget {
  const Narashino1F1SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino1F1FloorPlanAsset);
  }
}

/// 教室マップの [FloorMapWidget] 用：1号館1階のサムネイル＋タップで全画面。
class Narashino1F1FloorMapThumbnail extends StatelessWidget {
  const Narashino1F1FloorMapThumbnail({
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
      assetPath: kNarashino1F1FloorPlanAsset,
      fullScreenTitle: '新習志野 · 1号館1階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
