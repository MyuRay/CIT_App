import 'package:flutter/material.dart';

/// パルスアニメーション付きのドットバッジ
/// 通知や新着情報の表示に使用
class PulsingDotBadge extends StatefulWidget {
  const PulsingDotBadge({
    super.key,
    this.size = 12,
    this.color,
    this.tooltipMessage,
  });

  final double size;
  final Color? color;
  final String? tooltipMessage;

  @override
  State<PulsingDotBadge> createState() => _PulsingDotBadgeState();
}

class _PulsingDotBadgeState extends State<PulsingDotBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? Theme.of(context).colorScheme.primary;

    final badge = SizedBox(
      width: widget.size * 2.5,
      height: widget.size * 2.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // パルスエフェクト（外側の広がる円）
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: widget.size * _scaleAnimation.value,
                height: widget.size * _scaleAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor.withOpacity(_opacityAnimation.value * 0.6),
                ),
              );
            },
          ),
          // 中央のドット（常に表示）
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.tooltipMessage != null) {
      return Tooltip(
        message: widget.tooltipMessage!,
        triggerMode: TooltipTriggerMode.tap,
        child: badge,
      );
    }

    return badge;
  }
}
