import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/user_provider.dart';
import '../../../models/community/cwitter_post.dart';
import '../../../models/community/cwitter_reply.dart';
import '../../../services/community/cwitter_service.dart';

final _leadingMentionPattern = RegExp(r'^@([a-z0-9_]+)\s', caseSensitive: false);

String? parseLeadingMention(String body) {
  final match = _leadingMentionPattern.firstMatch(body.trim());
  return match?.group(1)?.toLowerCase();
}

String summarizeReplyContext(String text, {int maxLength = 80}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return '（内容なし）';
  if (trimmed.length <= maxLength) return trimmed;
  return '${trimmed.substring(0, maxLength)}…';
}

CwitterReply? resolveReplyTarget({
  required CwitterReply reply,
  required CwitterPost post,
  required List<CwitterReply> replies,
}) {
  if (reply.inReplyToReplyId != null) {
    for (final candidate in replies) {
      if (candidate.id == reply.inReplyToReplyId) {
        return candidate;
      }
    }
  }

  final mention = parseLeadingMention(reply.body);
  if (mention == null) return null;

  final replyIndex = replies.indexWhere((item) => item.id == reply.id);
  if (replyIndex > 0) {
    for (var i = replyIndex - 1; i >= 0; i--) {
      final candidate = replies[i];
      if (CwitterService.normalizeCwitterId(candidate.cwitterId) == mention) {
        return candidate;
      }
    }
  }

  if (CwitterService.normalizeCwitterId(post.cwitterId) == mention &&
      reply.authorId != post.authorId) {
    return null;
  }

  return null;
}

class CwitterReplyContextPreview extends ConsumerWidget {
  const CwitterReplyContextPreview({
    super.key,
    required this.authorId,
    required this.authorName,
    required this.cwitterId,
    required this.body,
    this.onTap,
  });

  final String authorId;
  final String authorName;
  final String cwitterId;
  final String body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.65);
    final resolvedName = resolveAuthorDisplayName(
      ref.watch(
        authorDisplayNameProvider((authorId: authorId, fallback: authorName)),
      ),
      authorName,
    );

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: const Color(0xFF4CAF50),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$resolvedName @${cwitterId.isEmpty ? 'unknown' : cwitterId}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: mutedColor,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            summarizeReplyContext(body),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.82),
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      ),
    );
  }
}
