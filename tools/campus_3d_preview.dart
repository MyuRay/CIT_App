import 'package:cit_app/screens/classroom_map/campus_3d_screen.dart';
import 'package:cit_app/widgets/campus_map_widget.dart';
import 'package:flutter/material.dart';

// Isolated visual/playability QA; no Firebase or real user data.
void main() => runApp(
  MaterialApp(
    theme: ThemeData(
      colorSchemeSeed: const Color(0xff1976d2),
      useMaterial3: true,
    ),
    home: Builder(
      builder:
          (context) => Scaffold(
            appBar: AppBar(title: const Text('Campus map and game preview')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const Campus3dScreen(),
                            ),
                          ),
                      child: const Text('3Dマップを開く'),
                    ),
                    const SizedBox(height: 12),
                    const CampusBusGameButton(),
                  ],
                ),
              ),
            ),
          ),
    ),
  ),
);
