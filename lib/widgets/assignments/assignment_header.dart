import 'package:flutter/material.dart';

class AssignmentHeader extends StatelessWidget {
  const AssignmentHeader({
    super.key,
    required this.semesterButton,
    required this.showAssignments,
    required this.onToggle,
    this.toggleAnchorKey,
  });
  final Widget semesterButton;
  final bool showAssignments;
  final VoidCallback onToggle;
  final GlobalKey? toggleAnchorKey;

  static AppBar appBar(
    BuildContext context, {
    required Widget semesterButton,
    required bool showAssignments,
    required VoidCallback onToggle,
    required List<Widget> actions,
    GlobalKey? toggleAnchorKey,
  }) {
    return AppBar(
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 12,
      title: _ScheduleHeaderScroller(
        builder:
            (constraints) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Keep the semester and assignment switches visible together,
                // and let the remaining actions scroll without adding a row.
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: AssignmentHeader(
                    semesterButton: semesterButton,
                    showAssignments: showAssignments,
                    onToggle: onToggle,
                    toggleAnchorKey: toggleAnchorKey,
                  ),
                ),
                const SizedBox(width: 8),
                ...actions,
              ],
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: semesterButton),
        const SizedBox(width: 8),
        Semantics(
          key: toggleAnchorKey,
          toggled: showAssignments,
          child: Tooltip(
            message: showAssignments ? '時間割に戻る' : '課題管理を開く',
            child: TextButton.icon(
              key: const ValueKey('assignment-flip-button'),
              onPressed: onToggle,
              icon: Icon(
                showAssignments
                    ? Icons.calendar_view_week
                    : Icons.assignment_outlined,
                size: 20,
              ),
              label: Text(showAssignments ? '時間割' : '課題', maxLines: 1),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor:
                    showAssignments ? colors.secondaryContainer : null,
                foregroundColor:
                    showAssignments ? colors.onSecondaryContainer : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleHeaderScroller extends StatefulWidget {
  const _ScheduleHeaderScroller({required this.builder});
  final Widget Function(BoxConstraints) builder;
  @override
  State<_ScheduleHeaderScroller> createState() =>
      _ScheduleHeaderScrollerState();
}

class _ScheduleHeaderScrollerState extends State<_ScheduleHeaderScroller> {
  final controller = ScrollController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder:
        (context, constraints) => Scrollbar(
          controller: controller,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          thickness: 3,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            key: const ValueKey('schedule-header-scroll'),
            controller: controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 8),
            child: widget.builder(constraints),
          ),
        ),
  );
}
