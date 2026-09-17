import 'package:flutter/material.dart';

/// A compact visual button with a full touch target inside the app bar.
class SemesterSwitchButton extends StatelessWidget {
  const SemesterSwitchButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showCalendar =
              constraints.maxWidth >= 148 &&
              MediaQuery.textScalerOf(context).scale(14) <= 18;
          // Keep the actual semester identifiable beside the assignment switch.
          // The full year/semester remains in the tooltip and semantics label.
          final compactLabel = label.replaceFirst(RegExp(r'^\d{4}年度\s*'), '');
          final displayLabel = showCalendar || compactLabel.isEmpty ? label : compactLabel;
          return Tooltip(
            message: '学期を切り替え\n$label',
            excludeFromSemantics: true,
            child: TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: colors.onPrimaryContainer,
                backgroundColor: colors.primaryContainer,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                visualDensity: VisualDensity.standard,
                tapTargetSize: MaterialTapTargetSize.padded,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors.outlineVariant),
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showCalendar) ...[
                    const Icon(Icons.calendar_month_outlined, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      displayLabel,
                      semanticsLabel: '学期を切り替え、選択中：$label',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
