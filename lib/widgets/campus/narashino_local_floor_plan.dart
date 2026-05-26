import 'package:flutter/material.dart';

import 'narashino_floor_plan_legal_copy.dart';
import 'pan_gate_interactive_viewer.dart';

/// 新習志野キャンパス用：アセット PNG のフロア図（幅に合わせて縦は画像比）。
class NarashinoAssetFloorPlanImage extends StatelessWidget {
  const NarashinoAssetFloorPlanImage({
    super.key,
    required this.assetPath,
    /// 全画面など：与えられた幅・高さの矩形内に図全体が収まる（`contain`）。
    this.fitWholeInViewport = false,
  });

  final String assetPath;

  /// シートでは幅だけ合わせる。true のときは親の幅・高さいっぱいに収め全体が見える（contain）。
  final bool fitWholeInViewport;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rawW = constraints.maxWidth;
        final w = (rawW.isFinite && rawW > 0) ? rawW : 400.0;

        if (!fitWholeInViewport) {
          return Image.asset(
            assetPath,
            width: w,
            fit: BoxFit.fitWidth,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) {
              return _NarashinoFloorPlanLoadError(
                width: w,
                assetPath: assetPath,
                loadError: error,
              );
            },
          );
        }

        final rawH = constraints.maxHeight;
        final h = (rawH.isFinite && rawH > 0) ? rawH : w;

        return Image.asset(
          assetPath,
          width: w,
          height: h,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) {
            return _NarashinoFloorPlanLoadError(
              width: w,
              assetPath: assetPath,
              loadError: error,
            );
          },
        );
      },
    );
  }
}

class _NarashinoFloorPlanLoadError extends StatelessWidget {
  const _NarashinoFloorPlanLoadError({
    required this.width,
    required this.assetPath,
    this.loadError,
  });

  final double width;
  final String assetPath;
  final Object? loadError;

  @override
  Widget build(BuildContext context) {
    final detail = loadError != null ? '\n\n詳細: $loadError' : '';
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade300,
      child: Text(
        'フロア図の読み込みに失敗しました。\n'
        '$assetPath\n'
        'を配置し、`flutter pub get` のあとアプリを再起動してください。'
        '$detail',
        style: TextStyle(color: Colors.grey.shade900, fontSize: 13, height: 1.35),
      ),
    );
  }
}

/// [FloorMapWidget] 用。
///
/// 校舎シートのタブ内では **タップ**で全画面表示します（全画面ではピンチで拡大・移動できます）。
class NarashinoAssetFloorMapThumbnail extends StatelessWidget {
  const NarashinoAssetFloorMapThumbnail({
    super.key,
    required this.assetPath,
    required this.fullScreenTitle,
    this.width,
    this.height,
    this.onThumbnailTap,
  });

  final String assetPath;
  final String fullScreenTitle;
  final double? width;
  final double? height;
  final VoidCallback? onThumbnailTap;

  void _openFullscreen(BuildContext context) {
    if (onThumbnailTap != null) {
      onThumbnailTap!();
    } else {
      showNarashinoAssetFloorPlanFullScreen(
        context,
        assetPath: assetPath,
        fullScreenTitle: fullScreenTitle,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fixedH = height ?? 200.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cw = constraints.maxWidth;
        var ww = width;
        if (ww == null || !ww.isFinite || ww <= 0) {
          ww = (cw.isFinite && cw > 0) ? cw : MediaQuery.sizeOf(context).width;
        }
        return Container(
          width: ww,
          height: fixedH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Material(
              color: Colors.grey.shade100,
              child: InkWell(
                onTap: () => _openFullscreen(context),
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 400,
                    child: NarashinoAssetFloorPlanImage(
                      assetPath: assetPath,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

void showNarashinoAssetFloorPlanFullScreen(
  BuildContext context, {
  required String assetPath,
  required String fullScreenTitle,
}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder:
        (ctx) => _NarashinoAssetFloorPlanFullscreen(
          assetPath: assetPath,
          fullScreenTitle: fullScreenTitle,
        ),
  );
}

/// `fullScreenTitle` が「キャンパス名 · …」形式のとき、上部に複数行で表示する用。
Widget _fullscreenFloorTitleColumn(String fullScreenTitle) {
  final sep = RegExp(r'\s*[·•･]\s*');
  final parts = fullScreenTitle
      .split(sep)
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  if (parts.length < 2) {
    return Text(fullScreenTitle, maxLines: 3, overflow: TextOverflow.ellipsis);
  }

  final campusFrag = parts.first;
  final campusLine =
      campusFrag.endsWith('キャンパス') ? campusFrag : '$campusFragキャンパス';

  final buildingAndFloor = parts.sublist(1).join(' · ');

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        campusLine,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.88),
          fontSize: 13,
          height: 1.2,
          fontWeight: FontWeight.w500,
        ),
      ),
      Text(
        '講義棟など: $buildingAndFloor',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _NarashinoAssetFloorPlanFullscreen extends StatelessWidget {
  const _NarashinoAssetFloorPlanFullscreen({
    required this.assetPath,
    required this.fullScreenTitle,
  });

  final String assetPath;
  final String fullScreenTitle;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          titleSpacing: 0,
          title: _fullscreenFloorTitleColumn(fullScreenTitle),
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
              child: PanGateInteractiveViewer(
                minScale: 0.55,
                maxScale: 4.0,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: NarashinoAssetFloorPlanImage(
                    assetPath: assetPath,
                    fitWholeInViewport: true,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: narashinoFloorPlanFullscreenLegalFooter(),
            ),
          ],
        ),
      ),
    );
  }
}
