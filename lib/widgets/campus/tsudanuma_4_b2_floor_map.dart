import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

/// 津田沼4号館B2フロア図のアセット（`pubspec.yaml` で明示登録）。
const String kTsudanuma4B2FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_4_b2.png';

/// 4号館B2のフロア図（アセット画像）。
class Tsudanuma4B2SchematicMap extends StatelessWidget {
  const Tsudanuma4B2SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma4B2FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：4号館B2のサムネイル＋タップで全画面。
class Tsudanuma4B2FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma4B2FloorMapThumbnail({
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
      assetPath: kTsudanuma4B2FloorPlanAsset,
      fullScreenTitle: '津田沼 · 4号館 B2',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
