import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../common/firebase_storage_image.dart';

/// プロフィール表示用アバター（画像 or 頭文字）
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.displayName,
    this.colorSeed,
    this.radius = 40,
    this.initialTextStyle,
  });

  final String? imageUrl;
  final String displayName;
  final String? colorSeed;
  final double radius;
  final TextStyle? initialTextStyle;

  int get _colorValue {
    final seed = (colorSeed?.isNotEmpty == true) ? colorSeed! : displayName;
    return seed.codeUnits.fold<int>(0, (a, b) => a + b) | 0xFF4CAF50;
  }

  String get _initial {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_colorValue);
    final background = AppColors.tintedSurface(context, color);
    final foreground = AppColors.ensureContrast(color, background);
    final url = imageUrl?.trim();

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: background,
        child: ClipOval(
          child: FirebaseStorageImage(
            imageUrl: url,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: Center(
              child: Text(
                _initial,
                style: TextStyle(
                  fontSize: radius * 0.8,
                  color: foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            errorWidget: Container(
              width: radius * 2,
              height: radius * 2,
              color: background,
              alignment: Alignment.center,
              child: Text(
                _initial,
                style: TextStyle(
                  fontSize: radius * 0.8,
                  color: foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      child: Text(
        _initial,
        style:
            initialTextStyle?.copyWith(color: foreground) ??
            TextStyle(
              fontSize: radius * 0.8,
              color: foreground,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
