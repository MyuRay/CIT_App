import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'guide_highlight.dart';

Future<bool> showMyPageRelocationGuide(
  BuildContext context, {
  required GlobalKey avatarKey,
}) async {
  final highlight = resolveGuideHighlight(context, avatarKey);
  if (highlight == null) return false;
  final acknowledged = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'マイページの移動案内',
    barrierColor: Colors.transparent,
    transitionDuration:
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
    pageBuilder:
        (_, animation, secondary) => MyPageRelocationGuide(
          target: highlight.rect,
          targetShape: highlight.shape,
          avatarKey: avatarKey,
        ),
    transitionBuilder:
        (_, animation, secondary, child) =>
            FadeTransition(opacity: animation, child: child),
  );
  return acknowledged == true;
}

class MyPageRelocationGuide extends StatefulWidget {
  static const popupCardKey = ValueKey('guide-popup-card');
  const MyPageRelocationGuide({
    super.key,
    required this.target,
    this.avatarKey,
    this.targetShape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    this.title = 'マイページがここに移動しました',
    this.description = 'ホーム左上のアイコンからマイページを開けます。\n各種設定やお問い合わせはこちらから。',
    this.stepLabel,
    this.continueLabel = 'わかりました',
    this.onContinue,
    this.onPrevious,
    this.onSkip,
  });
  final Rect target;
  final ShapeBorder targetShape;
  final GlobalKey? avatarKey;
  final String title, description, continueLabel;
  final String? stepLabel;
  final VoidCallback? onContinue, onPrevious, onSkip;
  @override
  State<MyPageRelocationGuide> createState() => _MyPageRelocationGuideState();
}

class _MyPageRelocationGuideState extends State<MyPageRelocationGuide>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _cardKey = GlobalKey();
  late final _arrow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  late Rect _target = widget.target;
  late ShapeBorder _targetShape = widget.targetShape;
  Rect _card = Rect.zero;
  bool _refreshScheduled = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() => _refreshGeometry();
  void _refreshGeometry() {
    if (_refreshScheduled) return;
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (!mounted) return;
      final highlight =
          widget.avatarKey == null
              ? null
              : resolveGuideHighlight(context, widget.avatarKey!);
      final overlay =
          Navigator.of(
            context,
            rootNavigator: true,
          ).overlay?.context.findRenderObject();
      final cardBox = _cardKey.currentContext?.findRenderObject();
      Rect? card;
      if (overlay is RenderBox &&
          cardBox is RenderBox &&
          cardBox.attached &&
          cardBox.hasSize) {
        card =
            cardBox.localToGlobal(Offset.zero, ancestor: overlay) &
            cardBox.size;
      }
      if ((highlight != null &&
              (highlight.rect != _target || highlight.shape != _targetShape)) ||
          (card != null && card != _card)) {
        setState(() {
          if (highlight != null) {
            _target = highlight.rect;
            _targetShape = highlight.shape;
          }
          if (card != null) _card = card;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshGeometry();
    if (MediaQuery.disableAnimationsOf(context)) {
      _arrow.stop();
      _arrow.value = 1;
    } else if (!_arrow.isAnimating) {
      _arrow.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _arrow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context), theme = Theme.of(context);
    _refreshGeometry();
    return PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Symmetric margins keep the card at the screen's center at every step.
            final vertical =
                math.max(media.padding.top, media.padding.bottom) + 16;
            final maxHeight = math.max(
              80.0,
              math.min(
                constraints.maxHeight * .72,
                constraints.maxHeight - vertical * 2,
              ),
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _RelocationArrowPainter(
                          target: _target,
                          targetShape: _targetShape,
                          card: _card,
                          animation: _arrow,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: vertical,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      key: MyPageRelocationGuide.popupCardKey,
                      constraints: BoxConstraints(
                        maxWidth: 380,
                        maxHeight: maxHeight,
                      ),
                      child: Material(
                        key: _cardKey,
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (widget.stepLabel != null)
                                Row(
                                  children: [
                                    Expanded(child: Text(widget.stepLabel!)),
                                    TextButton(
                                      onPressed: widget.onSkip,
                                      child: const Text('あとで'),
                                    ),
                                  ],
                                ),
                              Flexible(
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.title,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              height: 1.35,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(widget.description),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  if (widget.onPrevious != null) ...[
                                    OutlinedButton(
                                      onPressed: widget.onPrevious,
                                      child: const Text('戻る'),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Expanded(
                                    child: FilledButton(
                                      autofocus: true,
                                      onPressed:
                                          widget.onContinue ??
                                          () => Navigator.pop(context, true),
                                      child: Text(widget.continueLabel),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RelocationArrowPainter extends CustomPainter {
  _RelocationArrowPainter({
    required this.target,
    required this.targetShape,
    required this.card,
    required this.animation,
  }) : super(repaint: animation);
  final Rect target, card;
  final ShapeBorder targetShape;
  final Animation<double> animation;
  @override
  void paint(Canvas canvas, Size size) {
    final highlight = targetShape.getOuterPath(target.inflate(5));
    final scrim =
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addPath(highlight, Offset.zero);
    canvas.drawPath(
      scrim,
      Paint()..color = Colors.black.withValues(alpha: .68),
    );
    final stroke =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(highlight, stroke);
    if (card.isEmpty) return;
    final delta = target.center - card.center;
    if (delta.distance < 1) return;
    final unit = delta / delta.distance;
    final edge = math.min(
      unit.dx.abs() < .001 ? double.infinity : card.width / 2 / unit.dx.abs(),
      unit.dy.abs() < .001 ? double.infinity : card.height / 2 / unit.dy.abs(),
    );
    final start = card.center + unit * (edge + 12);
    // Find the boundary of the actual button shape along the final tangent.
    final toCard = -unit;
    var low = 0.0, high = target.longestSide + 16;
    for (var i = 0; i < 20; i++) {
      final middle = (low + high) / 2;
      if (highlight.contains(target.center + toCard * middle)) {
        low = middle;
      } else {
        high = middle;
      }
    }
    final end = target.center + toCard * (high + 8);
    final distanceToTarget = (end - start).distance;
    if ((end - start).dx * unit.dx + (end - start).dy * unit.dy < 16) return;
    var normal = Offset(-unit.dy, unit.dx);
    final bend = (distanceToTarget * .18).clamp(18.0, 52.0);
    final midpoint = (start + end) / 2 + normal * bend;
    if (midpoint.dx < 24 || midpoint.dx > size.width - 24) normal = -normal;
    final first = start + unit * (distanceToTarget * .36) + normal * bend;
    final last = end - unit * (distanceToTarget * .3);
    final path =
        Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(first.dx, first.dy, last.dx, last.dy, end.dx, end.dy);
    final metric = path.computeMetrics().first;
    final progress = Curves.easeInOut
        .transform((animation.value / .7).clamp(0.0, 1.0))
        .clamp(.02, 1.0);
    final distance = metric.length * progress;
    stroke.strokeWidth = 3;
    canvas.drawPath(metric.extractPath(0, distance), stroke);
    final tip = metric.getTangentForOffset(distance);
    if (tip == null) return;
    final angle = math.atan2(tip.vector.dy, tip.vector.dx), head = Path();
    for (final offset in [-.55, .55]) {
      head
        ..moveTo(tip.position.dx, tip.position.dy)
        ..lineTo(
          tip.position.dx - 11 * math.cos(angle + offset),
          tip.position.dy - 11 * math.sin(angle + offset),
        );
    }
    canvas.drawPath(head, stroke);
  }

  @override
  bool shouldRepaint(_RelocationArrowPainter old) =>
      target != old.target ||
      targetShape != old.targetShape ||
      card != old.card ||
      animation != old.animation;
}
