import 'dart:math' as math;

import 'package:flutter/material.dart';

/// マイページ（アバター）方向を指すコンパクトな吹き出し。
class HomeMyPageGuideBubble extends StatelessWidget {
  const HomeMyPageGuideBubble({
    super.key,
    required this.message,
    this.tapHint = '(タップで確認)',
    this.onTap,
  });

  final String message;
  final String tapHint;
  final VoidCallback? onTap;

  /// しっぽ + 内側パディング込みの横幅（1行表示用）。
  static double contentWidth(
    BuildContext context, {
    required String message,
    required String tapHint,
  }) {
    final theme = Theme.of(context);
    final introStyle = theme.textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.15,
    );
    final hintStyle = theme.textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: 10,
      height: 1.1,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);

    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final textWidth = math.max(
      measure(message, introStyle),
      measure(tapHint, hintStyle),
    );
    return 7 + 16 + textWidth;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = scheme.errorContainer;
    final onFill = scheme.onErrorContainer;
    final introStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
      color: onFill,
      fontWeight: FontWeight.w700,
      height: 1.15,
    );
    final hintStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
      color: onFill.withValues(alpha: 0.85),
      fontWeight: FontWeight.w500,
      fontSize: 10,
      height: 1.1,
    );

    final bubble = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomPaint(
          size: const Size(7, 12),
          painter: _BubbleTailPainter(color: fill),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                softWrap: false,
                style: introStyle,
              ),
              Text(
                tapHint,
                softWrap: false,
                style: hintStyle,
              ),
            ],
          ),
        ),
      ],
    );

    if (onTap == null) return bubble;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: bubble,
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  _BubbleTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path =
        Path()
          ..moveTo(size.width, 0)
          ..lineTo(0, size.height / 2)
          ..lineTo(size.width, size.height)
          ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
