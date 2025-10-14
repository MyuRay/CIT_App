import 'package:flutter/material.dart';

/// Animated skeleton placeholder used while images are loading.
class AnimatedImagePlaceholder extends StatefulWidget {
  const AnimatedImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.borderColor,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final Color? borderColor;

  @override
  State<AnimatedImagePlaceholder> createState() =>
      _AnimatedImagePlaceholderState();
}

class _AnimatedImagePlaceholderState extends State<AnimatedImagePlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = scheme.surface;
    final borderColor = widget.borderColor ?? Theme.of(context).dividerColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            widget.width ??
            (constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0);
        final height =
            widget.height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : 120.0);

        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final color = Color.lerp(base, highlight, _animation.value)!;
            return Container(
              width: width.isFinite ? width : null,
              height: height.isFinite ? height : null,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(color: borderColor),
                color: color,
              ),
            );
          },
        );
      },
    );
  }
}
