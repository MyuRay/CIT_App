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
  });

  final String displayName;
  final String cwitterId;
  final List<String> tags;
  final bool compact;
  final TextStyle? nameStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOfficial = AppConstants.isOfficialCwitterAccount(cwitterId);
    final resolvedNameStyle = nameStyle ??
        theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        );

    final limitedTags = tags.take(AppConstants.cwitterTagsMaxCount).toList();

    // 表示名・公式タグ・各ハッシュタグを 1 つの Wrap にまとめることで、
    // 文字サイズの都合でタグが折り返した場合も、2 個目以降が列の左端
    // （＝ ID と同じ列）から並ぶようにする。
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxNameWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : null;
        final nameText = Text(
          displayName,
          style: resolvedNameStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

        return Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (isOfficial)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: maxNameWidth != null
                        ? ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxNameWidth),
                            child: nameText,
                          )
                        : nameText,
                  ),
                  const SizedBox(width: 6),
                  const CwitterOfficialTag(),
                ],
              )
            else if (maxNameWidth != null)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxNameWidth),
                child: nameText,
              )
            else
              nameText,
            ...limitedTags.map(
              (tag) => CwitterTagChip(tag: tag, compact: compact),
            ),
          ],
        );
      },
    );
  }
}
