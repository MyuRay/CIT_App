import 'package:flutter/material.dart';

/// Pairs custom feature colors with readable text in both themes.
abstract final class AppColors {
  static double contrastRatio(Color foreground, Color background) {
    final painted = Color.alphaBlend(foreground, background);
    final a = painted.computeLuminance();
    final b = background.computeLuminance();
    return (a > b ? a + 0.05 : b + 0.05) / (a > b ? b + 0.05 : a + 0.05);
  }

  static Color onColor(Color background) =>
      contrastRatio(Colors.white, background) >=
              contrastRatio(Colors.black, background)
          ? Colors.white
          : Colors.black;

  static Color ensureContrast(
    Color preferred,
    Color background, {
    double minimum = 4.5,
  }) {
    final opaque = Color.alphaBlend(preferred, background);
    if (contrastRatio(opaque, background) >= minimum) return opaque;
    final target = onColor(background);
    var low = 0.0;
    var high = 1.0;
    for (var i = 0; i < 24; i++) {
      final middle = (low + high) / 2;
      if (contrastRatio(Color.lerp(opaque, target, middle)!, background) >=
          minimum) {
        high = middle;
      } else {
        low = middle;
      }
    }
    return Color.lerp(opaque, target, high)!;
  }

  static Color tintedSurface(BuildContext context, Color seed) =>
      Color.alphaBlend(
        seed.withValues(alpha: 0.12),
        Theme.of(context).colorScheme.surfaceContainerLow,
      );

  static Color accent(BuildContext context, Color? seed) {
    final scheme = Theme.of(context).colorScheme;
    seed ??= scheme.primary;
    var result = seed;
    for (final background in [
      scheme.surface,
      scheme.surfaceContainerHighest,
      tintedSurface(context, seed),
    ]) {
      result = ensureContrast(result, background);
    }
    return result;
  }

  static Color snackBarSurface(BuildContext context, Color seed) =>
      ensureContrast(
        seed,
        Theme.of(context).colorScheme.onInverseSurface,
        minimum: 7,
      );
}
