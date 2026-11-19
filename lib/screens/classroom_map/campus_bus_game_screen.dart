import 'package:flutter/material.dart';
import 'campus_3d_screen.dart';

/// A distinct game route, sharing the persistent viewer and host bridge.
class CampusBusGameScreen extends StatelessWidget {
  const CampusBusGameScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xfff36f91),
          brightness: base.brightness,
        ),
      ),
      child: const Campus3dScreen(experience: 'game'),
    );
  }
}
