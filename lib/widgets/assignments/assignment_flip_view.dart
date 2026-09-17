import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Only the visible face participates in input and semantics. Reduced motion
/// switches immediately, and the timetable keeps its existing scroll position.
class AssignmentFlipView extends StatelessWidget {
  const AssignmentFlipView({
    super.key,
    required this.showAssignments,
    required this.timetable,
    required this.assignments,
  });
  final bool showAssignments;
  final Widget timetable, assignments;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: showAssignments ? 1 : 0),
    duration:
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 480),
    curve: Curves.easeInOutCubic,
    builder: (context, value, _) {
      final back = value >= 0.5;
      final angle = back ? (value - 1) * math.pi : value * math.pi;
      return IgnorePointer(
        ignoring: value != 0 && value != 1,
        child: Transform(
          alignment: Alignment.center,
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
          child: IndexedStack(
            index: back ? 1 : 0,
            sizing: StackFit.expand,
            children: [timetable, assignments],
          ),
        ),
      );
    },
  );
}
