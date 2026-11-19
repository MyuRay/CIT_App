import 'dart:math' as math;

import 'package:flutter/material.dart';

const _guideTailWidth = 12.0;

/// マイページ（アバター）を指す、しっぽと本体がつながった吹き出し。
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
      measure(message.replaceAll('{menu}', '≡'), introStyle),
      measure(tapHint, hintStyle),
    );
    return _guideTailWidth + 20 + textWidth;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? Colors.black : Colors.white;
    final onFill = dark ? Colors.white : Colors.black;
    final shape = _GuideBubbleBorder(
      side: BorderSide(color: onFill, width: 1.5),
    );
    final introStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
      color: onFill,
      fontWeight: FontWeight.w700,
      height: 1.15,
    );
    final hintStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
      color: onFill,
      fontWeight: FontWeight.w500,
      fontSize: 10,
      height: 1.1,
    );

    final bubble = Material(
      color: fill,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_guideTailWidth + 10, 6, 10, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    if (message.contains('{menu}')) ...[
                      TextSpan(text: message.split('{menu}').first),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.menu, size: 14, color: onFill),
                      ),
                      TextSpan(text: message.split('{menu}').last),
                    ] else
                      TextSpan(text: message),
                  ],
                ),
                maxLines: tapHint.isEmpty ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: introStyle,
              ),
              if (tapHint.isNotEmpty)
                Text(
                  tapHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: hintStyle,
                ),
            ],
          ),
        ),
      ),
    );

    if (onTap == null) return bubble;
    return Tooltip(message: message.replaceAll('{menu}', '≡'), child: bubble);
  }
}

/// 本体と曲線のしっぽを一つの輪郭にし、つなぎ目の縦線を作らない。
class _GuideBubbleBorder extends OutlinedBorder {
  const _GuideBubbleBorder({required super.side});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  _GuideBubbleBorder copyWith({BorderSide? side}) =>
      _GuideBubbleBorder(side: side ?? this.side);

  @override
  ShapeBorder scale(double t) => _GuideBubbleBorder(side: side.scale(t));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    if (rect.isEmpty) return Path();
    final tailWidth = math.min(_guideTailWidth, rect.width / 3);
    final body = Rect.fromLTRB(
      rect.left + tailWidth,
      rect.top,
      rect.right,
      rect.bottom,
    );
    final radius = math.min(14.0, body.shortestSide / 2);
    final outline =
        Path()
          ..addRRect(RRect.fromRectAndRadius(body, Radius.circular(radius)));
    final center = rect.center.dy;
    final half = math.min(7.0, rect.height * 0.22);
    final overlap = math.min(3.0, body.width / 4);
    final tail =
        Path()
          ..moveTo(body.left + overlap, center - half)
          ..quadraticBezierTo(
            body.left - 1,
            center + half * 0.15,
            rect.left,
            center + half,
          )
          ..quadraticBezierTo(
            rect.left + tailWidth * 0.65,
            center + half,
            body.left + overlap,
            center + half * 0.6,
          )
          ..close();
    return Path.combine(PathOperation.union, outline, tail);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(side.width), textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(
      getOuterPath(rect.deflate(side.width / 2), textDirection: textDirection),
      Paint()
        ..color = side.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = side.width
        ..strokeJoin = StrokeJoin.round,
    );
  }
}
