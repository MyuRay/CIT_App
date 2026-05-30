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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            displayName,
            style: nameStyle ??
                theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isOfficial) ...[
          const SizedBox(width: 6),
          const CwitterOfficialTag(),
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(width: 6),
          Flexible(
            child: CwitterTagsRow(tags: tags, compact: compact),
          ),
        ],
      ],
    );
  }
}
