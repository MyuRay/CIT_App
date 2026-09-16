import 'package:flutter/material.dart';

/// Yellow fill with a darker outline on light surfaces.
class CafeteriaRatingStar extends StatelessWidget {
  const CafeteriaRatingStar({
    super.key,
    this.filled = true,
    this.half = false,
    this.size = 18,
  });
  final bool filled;
  final bool half;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!filled && !half) {
      return Icon(
        Icons.star_border,
        size: size,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
    const yellow = Color(0xFFFFD54F);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Icon(half ? Icons.star_half : Icons.star, size: size, color: yellow),
          if (theme.brightness == Brightness.light)
            Icon(Icons.star_border, size: size, color: const Color(0xFF806000)),
        ],
      ),
    );
  }
}
