import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class CwitterTagsRow extends StatelessWidget {
  const CwitterTagsRow({super.key, required this.tags, this.compact = false});

  final List<String> tags;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children:
          tags
              .take(AppConstants.cwitterTagsMaxCount)
              .map((tag) => CwitterTagChip(tag: tag, compact: compact))
              .toList(),
    );
  }
}

/// 表示名と並べても行を広げない、単一行のハッシュタグチップ。
class CwitterTagChip extends StatelessWidget {
  const CwitterTagChip({
    super.key,
    required this.tag,
    this.compact = false,
    this.onTap,
  });

  final String tag;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fontSize = compact ? 10.0 : 11.0;
    final horizontalPadding = compact ? 6.0 : 8.0;
    final verticalPadding = compact ? 2.0 : 3.0;
    final textColor =
        isDark ? const Color(0xFF9AE6A0) : const Color(0xFF2E7D32);
    final backgroundColor =
        isDark
            ? textColor.withValues(alpha: 0.22)
            : const Color(0xFF4CAF50).withValues(alpha: 0.12);
    final borderColor =
        isDark
            ? textColor.withValues(alpha: 0.55)
            : const Color(0xFF4CAF50).withValues(alpha: 0.28);

    final label = Text(
      '#$tag',
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: fontSize,
        height: 1.2,
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
    );
    // ActionChip の最小タップ領域で名前の行が高くならないよう、
    // 表示用とタップ可能なタグに同じ余白を使用する。
    final chip = Material(
      color: backgroundColor,
      shape: StadiumBorder(side: BorderSide(color: borderColor)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: label,
        ),
      ),
    );
    if (onTap == null) return chip;

    return Semantics(
      button: true,
      child: Tooltip(message: '#$tag を使っている人を見る', child: chip),
    );
  }
}
