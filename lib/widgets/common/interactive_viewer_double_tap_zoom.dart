import 'package:flutter/widgets.dart';

/// [InteractiveViewer] 用: ダブルタップで等倍と [zoomScale] を切り替え。
///
/// [details.localPosition] は、ビューポートと同じ大きさの [GestureDetector] 等の
/// ローカル座標（＝拡大の基準点）であること。
void interactiveViewerToggleZoomAtFocalPoint(
  TransformationController controller,
  TapDownDetails details, {
  double zoomScale = 2.5,
  double zoomedThreshold = 1.05,
}) {
  final currentScale = controller.value.getMaxScaleOnAxis();
  if (currentScale > zoomedThreshold) {
    controller.value = Matrix4.identity();
    return;
  }
  final focal = details.localPosition;
  controller.value = Matrix4.identity()
    ..translate(focal.dx, focal.dy)
    ..scale(zoomScale)
    ..translate(-focal.dx, -focal.dy);
}
