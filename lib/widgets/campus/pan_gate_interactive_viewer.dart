import 'package:flutter/material.dart';

/// `InteractiveViewer` で拡大中だけパンを有効にし、等倍では横スワイプを [`PageView`] へ渡します。
class PanGateInteractiveViewer extends StatefulWidget {
  const PanGateInteractiveViewer({
    super.key,
    required this.child,
    this.minScale = 0.8,
    this.maxScale = 4,
  });

  final Widget child;
  final double minScale;
  final double maxScale;

  static const double _panScaleThreshold = 1.015;

  @override
  State<PanGateInteractiveViewer> createState() => _PanGateInteractiveViewerState();
}

class _PanGateInteractiveViewerState extends State<PanGateInteractiveViewer> {
  final TransformationController _tc = TransformationController();

  @override
  void initState() {
    super.initState();
    _tc.addListener(_onTransformed);
  }

  void _onTransformed() => setState(() {});

  @override
  void dispose() {
    _tc
      ..removeListener(_onTransformed)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _tc.value.getMaxScaleOnAxis();
    final panEnabled = scale > PanGateInteractiveViewer._panScaleThreshold;

    return InteractiveViewer(
      transformationController: _tc,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
      panEnabled: panEnabled,
      child: widget.child,
    );
  }
}
