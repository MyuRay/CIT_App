import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/schedule_provider.dart';
import '../../../models/community/cwitter_post.dart';
import '../../../models/community/cwitter_profile_activity.dart';
import '../../../models/community/cwitter_reply.dart';
import '../../../services/community/cwitter_service.dart';
import '../community_time_format.dart';
import 'cwitter_author_header.dart';
import 'cwitter_body_text.dart';
import 'cwitter_handle_text.dart';
import 'cwitter_more_menu.dart';
import 'cwitter_post_card.dart';
import 'cwitter_post_images_grid.dart';
import 'cwitter_report_helper.dart';
import 'cwitter_reply_sheet.dart';
import '../../../screens/user_block/block_confirmation_dialog.dart';

class CwitterActivityCard extends ConsumerWidget {
  const CwitterActivityCard({super.key, required this.activity});

  final CwitterProfileActivity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (activity.kind) {
      case CwitterProfileActivityKind.post:
        return CwitterPostCard(post: activity.post!);
      case CwitterProfileActivityKind.reply:
        return _ReplyActivityCard(
          reply: activity.reply!,
          parentPost: activity.parentPost,
        );
      case CwitterProfileActivityKind.recweet:
        return CwitterPostCard(
          post: activity.post!,
          recweet: activity.recweet,
        );
    }
  }
}

class _ReplyActivityCard extends ConsumerWidget {
  const _ReplyActivityCard({
    required this.reply,
    this.parentPost,
  });

  final CwitterReply reply;
  final CwitterPost? parentPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.65);
    final uid = ref.watch(currentUserIdProvider);
    final isOwner = uid != null && uid == reply.authorId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: parentPost != null
            ? () => CwitterReplySheet.show(context, parentPost!)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.reply,
                          size: 14,
                          color: const Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '返信',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatCommunityRelativeTime(reply.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mutedColor,
                    ),
                  ),
                  CwitterMoreMenu(
                    isOwner: isOwner,
                    onDeleteReply: isOwner
                        ? () => CwitterService.deleteReply(
                              postId: reply.postId,
                              replyId: reply.id,
                              userId: uid,
                            )
                        : null,
                    onReport: isOwner
                        ? null
                        : () {
                            if (parentPost == null) return;
                            showCwitterReplyReportDialog(
                              context,
                              post: parentPost!,
                              reply: reply,
                            );
                          },
                    onBlock: isOwner
                        ? null
                        : () => showBlockConfirmationDialog(
                              context,
                              blockedUserId: reply.authorId,
                              blockedUserName: reply.displayName,
                              blockedUserCwitterId: reply.cwitterId,
                            ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CwitterAuthorHeader(
                authorId: reply.authorId,
                displayName: reply.displayName,
                cwitterId: reply.cwitterId,
                profileImageUrl: reply.profileImageUrl,
              ),
              if (parentPost != null) ...[
                const SizedBox(height: 10),
                _QuotedPostPreview(post: parentPost!),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  '元のCweetを表示できません',
                  style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
                ),
              ],
              const SizedBox(height: 10),
              if (reply.body.isNotEmpty)
                CwitterBodyText(
                  text: reply.body,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              if (reply.hasImages) ...[
                SizedBox(height: reply.body.isNotEmpty ? 8 : 0),
                CwitterPostImagesGrid(
                  imageUrls: reply.imageUrls,
                  heroTagPrefix: 'cwitterActivityReply_${reply.id}',
                ),
              ],
              if (parentPost != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        CwitterReplySheet.show(context, parentPost!),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('スレッドを見る'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuotedPostPreview extends StatelessWidget {
  const _QuotedPostPreview({required this.post});

  final CwitterPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.65);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
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
          Row(
            children: [
              Flexible(
                child: Text(
                  post.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: CwitterHandleText(
                  cwitterId: post.cwitterId,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (post.body.isNotEmpty)
            CwitterBodyText(
              text: post.body,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
              maxLines: 3,
            ),
          if (post.hasImages) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: CwitterPostImagesGrid(
                imageUrls: post.imageUrls,
                heroTagPrefix: 'cwitterQuote_${post.id}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
