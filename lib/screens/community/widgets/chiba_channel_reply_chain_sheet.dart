import 'package:flutter/material.dart';

import '../../../models/community/chiba_channel_comment.dart';
import '../../../utils/community/chiba_channel_reply_chain.dart';
import '../community_time_format.dart';
import 'cwitter_post_images_grid.dart';

class ChibaChannelReplyChainSheet extends StatelessWidget {
  const ChibaChannelReplyChainSheet({
    super.key,
    required this.chain,
    required this.threadAuthorId,
    required this.highlightCommentNumber,
    required this.scrollController,
  });

  final List<ChibaChannelComment> chain;
  final String threadAuthorId;
  final int highlightCommentNumber;
  final ScrollController scrollController;

  static Future<void> show(
    BuildContext context, {
    required List<ChibaChannelComment> allComments,
    required ChibaChannelComment fromComment,
    required int anchorNumber,
    required String threadAuthorId,
  }) {
    final chain = ChibaChannelReplyChain.resolveChainForAnchor(
      fromComment: fromComment,
      anchorNumber: anchorNumber,
      allComments: allComments,
    );
    if (chain.isEmpty) return Future.value();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return ChibaChannelReplyChainSheet(
            chain: chain,
            threadAuthorId: threadAuthorId,
            highlightCommentNumber: anchorNumber,
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                '返信の流れ',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: chain.length,
            separatorBuilder: (context, index) => _ChainConnector(
              isLast: index == chain.length - 1,
            ),
            itemBuilder: (context, index) {
              final comment = chain[index];
              final isHighlighted =
                  comment.commentNumber == highlightCommentNumber;
              return _ChainCommentCard(
                comment: comment,
                threadAuthorId: threadAuthorId,
                isHighlighted: isHighlighted,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChainConnector extends StatelessWidget {
  const _ChainConnector({required this.isLast});

  final bool isLast;

  @override
  Widget build(BuildContext context) {
    if (isLast) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 2, bottom: 2),
      child: Row(
        children: [
          Icon(
            Icons.arrow_downward,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(width: 6),
          Text(
            '返信',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.45),
                ),
          ),
        ],
      ),
    );
  }
}

class _ChainCommentCard extends StatelessWidget {
  const _ChainCommentCard({
    required this.comment,
    required this.threadAuthorId,
    required this.isHighlighted,
  });

  final ChibaChannelComment comment;
  final String threadAuthorId;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isThreadOwner = threadAuthorId.isNotEmpty &&
        comment.authorId == threadAuthorId;

    return Container(
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFF4CAF50).withValues(alpha: 0.45)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${comment.commentNumber}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                comment.displayName,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                comment.displayIdLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isThreadOwner) ...[
                const SizedBox(width: 6),
                const _MiniThreadOwnerBadge(),
              ],
              const Spacer(),
              Text(
                formatCommunityRelativeTime(comment.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          if (comment.inReplyToCommentNumber != null) ...[
            const SizedBox(height: 4),
            Text(
              '>>${comment.inReplyToCommentNumber}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF1565C0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 6),
          if (comment.isDeleted)
            Text(
              '[${ChibaChannelComment.deletedMessage}]',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.45),
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            if (comment.body.isNotEmpty)
              Text(
                comment.body,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            if (comment.hasImages) ...[
              const SizedBox(height: 8),
              CwitterPostImagesGrid(
                imageUrls: comment.imageUrls,
                heroTagPrefix:
                    'chibaChain_${comment.threadId}_${comment.id}',
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MiniThreadOwnerBadge extends StatelessWidget {
  const _MiniThreadOwnerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text(
        'スレ主',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1565C0),
        ),
      ),
    );
  }
}
