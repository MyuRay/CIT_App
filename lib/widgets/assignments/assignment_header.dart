import 'package:flutter/material.dart';

class AssignmentHeader extends StatelessWidget {
  const AssignmentHeader({
    super.key,
    required this.semesterButton,
    required this.showAssignments,
    required this.onToggle,
  });
  final Widget semesterButton;
  final bool showAssignments;
  final VoidCallback onToggle;

  static AppBar appBar(
    BuildContext context, {
    required Widget semesterButton,
    required bool showAssignments,
    required VoidCallback onToggle,
    required List<Widget> actions,
  }) {
    // Keep every action directly accessible without squeezing either switch.
    final twoRows =
        MediaQuery.sizeOf(context).width < 384 ||
        MediaQuery.textScalerOf(context).scale(14) > 18;
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 12,
      title: AssignmentHeader(
        semesterButton: semesterButton,
        showAssignments: showAssignments,
        onToggle: onToggle,
      ),
      actions: twoRows ? null : actions,
      bottom:
          twoRows
              ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: SizedBox(
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions,
                    ),
                  ),
                ),
              )
              : null,
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
