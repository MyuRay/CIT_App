import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import 'cwitter_handle_text.dart';
import 'cwitter_tags_row.dart';

/// 表示名・公式タグ・ハッシュタグを同一行に並べる。
class CwitterAuthorNameRow extends StatelessWidget {
  const CwitterAuthorNameRow({
    super.key,
    required this.displayName,
    required this.cwitterId,
    this.tags = const [],
    this.compact = false,
    this.nameStyle,
    this.onTagTap,
  });

  final String displayName;
  final String cwitterId;
  final List<String> tags;
  final bool compact;
  final TextStyle? nameStyle;
  final ValueChanged<String>? onTagTap;

  TextStyle? _resolveNameStyle(ThemeData theme) =>
      nameStyle ??
      theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOfficial = AppConstants.isOfficialCwitterAccount(cwitterId);
    final resolvedNameStyle = _resolveNameStyle(theme);

    final limitedTags = tags.take(AppConstants.cwitterTagsMaxCount).toList();

    final name = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            displayName,
            style: resolvedNameStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isOfficial) ...[
          const SizedBox(width: 6),
          const CwitterOfficialTag(),
        ],
      ],
    );
    if (limitedTags.isEmpty) return name;

    final tagStrip = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < limitedTags.length; index++) ...[
            if (index > 0) const SizedBox(width: 6),
            CwitterTagChip(
              tag: limitedTags[index],
              compact: compact,
              onTap:
                  onTagTap == null ? null : () => onTagTap!(limitedTags[index]),
            ),
          ],
        ],
      ),
    );

    // 名前は実際に必要な幅だけ使い、残りをすべてタグに渡す。
    // 長い名前には上限を設け、タグを折り返さずに表示領域を確保する。
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [name, const SizedBox(width: 6), tagStrip],
          );
        }
        return Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    (constraints.maxWidth - 6).clamp(0.0, double.infinity) *
                    (isOfficial ? 0.5 : 0.4),
              ),
              child: name,
            ),
            const SizedBox(width: 6),
            Expanded(child: tagStrip),
          ],
        );
      },
    );
  }
}
