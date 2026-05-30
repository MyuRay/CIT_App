import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
    final seed = (colorSeed?.isNotEmpty == true)
        ? colorSeed!
        : displayName;
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
    final url = imageUrl?.trim();

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: color.withValues(alpha: 0.15),
        child: ClipOval(
          child: CachedNetworkImage(
            width: radius * 2,
            height: radius * 2,
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Center(
              child: Text(
                _initial,
                style: TextStyle(
                  fontSize: radius * 0.8,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              width: radius * 2,
              height: radius * 2,
              color: color.withValues(alpha: 0.2),
              alignment: Alignment.center,
              child: Text(
                _initial,
                style: TextStyle(
                  fontSize: radius * 0.8,
                  color: color,
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
      backgroundColor: color.withValues(alpha: 0.2),
      child: Text(
        _initial,
        style: initialTextStyle ??
            TextStyle(
              fontSize: radius * 0.8,
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
