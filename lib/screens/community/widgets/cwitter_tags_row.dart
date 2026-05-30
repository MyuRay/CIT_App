import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class CwitterTagsRow extends StatelessWidget {
  const CwitterTagsRow({
    super.key,
    required this.tags,
    this.compact = false,
  });

  final List<String> tags;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fontSize = compact ? 10.0 : 11.0;
    final horizontalPadding = compact ? 6.0 : 8.0;
    final verticalPadding = compact ? 2.0 : 3.0;
    final textColor =
        isDark ? const Color(0xFF9AE6A0) : const Color(0xFF2E7D32);
    final backgroundColor = isDark
        ? textColor.withValues(alpha: 0.22)
        : const Color(0xFF4CAF50).withValues(alpha: 0.12);
    final borderColor = isDark
        ? textColor.withValues(alpha: 0.55)
        : const Color(0xFF4CAF50).withValues(alpha: 0.28);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tags
          .take(AppConstants.cwitterTagsMaxCount)
          .map(
            (tag) => Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                '#$tag',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: fontSize,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
