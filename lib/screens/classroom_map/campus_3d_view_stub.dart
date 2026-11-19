import '../../services/campus_game/campus_game_view_bridge.dart';
import 'package:flutter/material.dart';

class Campus3dView extends StatelessWidget {
  const Campus3dView({
    super.key,
    required this.campus,
    this.experience = 'map',
    this.reducedMotion = false,
    this.gameBridge,
    this.fullscreen = false,
    this.onToggleFullscreen,
    this.onExitFullscreen,
    this.onResetViewer,
  });
  final String campus;
  final String experience;
  final bool reducedMotion;
  final CampusGameViewBridge? gameBridge;
  final bool fullscreen;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onExitFullscreen;
  final VoidCallback? onResetViewer;
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('この端末では3D表示を利用できません'));
}
