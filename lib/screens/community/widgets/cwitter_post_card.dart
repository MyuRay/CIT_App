import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';



import '../../../core/providers/user_provider.dart';

import '../../../core/providers/schedule_provider.dart';

import '../../../models/community/cwitter_post.dart';

import '../../../models/community/cwitter_recweet.dart';

import '../../../services/community/cwitter_service.dart';

import '../community_time_format.dart';

import '../../../core/providers/cwitter_like_override_provider.dart';

import '../../../core/providers/cwitter_recweet_override_provider.dart';

import '../../../core/providers/cwitter_reply_count_override_provider.dart';

import '../../../core/providers/cwitter_provider.dart';

import '../../../core/providers/admin_provider.dart';

import 'cwitter_author_header.dart';

import 'admin_ban_dialog.dart';

import 'cwitter_more_menu.dart';

import 'cwitter_poll_widget.dart';

import 'cwitter_post_images_grid.dart';

import 'cwitter_report_helper.dart';

import 'cwitter_body_text.dart';
import 'cwitter_recweet_confirmation_dialog.dart';
import 'cwitter_reaction_list_sheet.dart';
import 'cwitter_reply_sheet.dart';

import '../../../screens/user_block/block_confirmation_dialog.dart';



class CwitterPostCard extends ConsumerWidget {

  const CwitterPostCard({

    super.key,

    required this.post,

    this.recweet,

  });



  final CwitterPost post;

  final CwitterRecweet? recweet;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.65);

    final uid = ref.watch(currentUserIdProvider);

    final appUser = ref.watch(currentAppUserStreamProvider).valueOrNull;

    final likeOverride = ref.watch(cwitterLikeOverrideProvider)[post.id];

    final isLiked = likeOverride?.isLiked ?? post.isLikedBy(uid);

    final likeCount = likeOverride?.likeCount ?? post.likeCount;

    final recweetOverride = ref.watch(cwitterRecweetOverrideProvider)[post.id];

    final streamIsRecweeted = uid == null
        ? false
        : ref
                .watch(
                  cwitterIsRecweetedProvider(
                    (userId: uid, postId: post.id),
                  ),
                )
                .valueOrNull ??
            false;

    final isRecweeted =
        recweetOverride?.isRecweeted ?? streamIsRecweeted;

    final recweetCount =
        recweetOverride?.recweetCount ?? post.recweetCount;

    final replyOverride = ref.watch(cwitterReplyCountOverrideProvider)[post.id];
    final streamReplyCount =
        ref.watch(cwitterPostReplyCountProvider(post.id)).valueOrNull;
    final replyCount = resolveCwitterReplyCount(
      post: post,
      override: replyOverride,
      streamCount: streamReplyCount,
    );

    ref.listen<AsyncValue<int>>(
      cwitterPostReplyCountProvider(post.id),
      (_, next) {
        next.whenData((count) {
          ref
              .read(cwitterReplyCountOverrideProvider.notifier)
              .syncWithCount(post.id, count);
        });
      },
    );

    final isOwner = uid != null && uid == post.authorId;

    final isAdmin = ref.watch(isAdminProvider);



    return Card(

      margin: const EdgeInsets.only(bottom: 12),

      elevation: 0,

      shape: RoundedRectangleBorder(

        borderRadius: BorderRadius.circular(12),

        side: BorderSide(

          color: colorScheme.outlineVariant.withValues(alpha: 0.5),

        ),

      ),

      child: Padding(

        padding: const EdgeInsets.all(14),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            if (recweet != null) ...[

              _RecweetBanner(recweet: recweet!),

              const SizedBox(height: 10),

            ],

            CwitterAuthorHeader.fromPost(

              post,

              trailing: Row(

                mainAxisSize: MainAxisSize.min,

                children: [

                  Text(

                    formatCommunityRelativeTime(post.createdAt),

                    style: theme.textTheme.bodySmall?.copyWith(

                      color: mutedColor,

                    ),

                  ),

                  CwitterMoreMenu(

                    isOwner: isOwner,

                    onDeletePost: isOwner

                        ? () async {

                            await CwitterService.deletePost(

                              postId: post.id,

                              userId: uid,

                            );

                            ref

                                .read(cwitterFeedProvider.notifier)

                                .removePost(post.id);

                          }

                        : null,

                    onReport: isOwner

                        ? null

                        : () => showCwitterPostReportDialog(

                              context,

                              post: post,

                            ),

                    onBlock: isOwner

                        ? null

                        : () => showBlockConfirmationDialog(

                              context,

                              blockedUserId: post.authorId,

                              blockedUserName: post.displayName,

                              blockedUserCwitterId: post.cwitterId,

                            ),

                    onBan: (!isAdmin || isOwner || uid == null)

                        ? null

                        : () => showAdminBanDialog(

                              context,

                              targetUserId: post.authorId,

                              targetLabel: '@${post.cwitterId}',

                              adminId: uid,

                            ),

                  ),

                ],

              ),

            ),

            if (post.body.isNotEmpty) ...[

              const SizedBox(height: 12),

              CwitterBodyText(
                text: post.body,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),

            ],

            if (post.hasImages) ...[

              SizedBox(height: post.body.isNotEmpty ? 12 : 8),

              CwitterPostImagesGrid(

                imageUrls: post.imageUrls,

                heroTagPrefix: 'cwitterPost_${post.id}',

              ),

            ],

            if (post.hasPoll) ...[

              SizedBox(

                height: post.body.isNotEmpty || post.hasImages ? 12 : 8,

              ),

              CwitterPollWidget(post: post),

            ],

            const SizedBox(height: 10),

            Align(

              alignment: Alignment.centerRight,

              child: Row(

                mainAxisSize: MainAxisSize.min,

                children: [

                  _ActionButton(

                    icon: Icons.chat_bubble_outline,

                    activeIcon: Icons.chat_bubble,

                    count: replyCount,

                    color: mutedColor,

                    activeColor: const Color(0xFF4CAF50),

                    onTap: () => CwitterReplySheet.show(context, post),

                  ),

                  const SizedBox(width: 16),

                  _ActionButton(

                    icon: Icons.repeat,

                    activeIcon: Icons.repeat,

                    count: recweetCount,

                    color: mutedColor,

                    activeColor: const Color(0xFF4CAF50),

                    isActive: isRecweeted,

                    onLongPress: recweetCount > 0

                        ? () => CwitterReactionListSheet.show(

                              context,

                              postId: post.id,

                              kind: CwitterReactionListKind.recweets,

                            )

                        : null,

                    onTap: uid == null ||

                            appUser == null ||

                            !appUser.hasCwitterId

                        ? null

                        : () async {
                            final notifier = ref.read(
                              cwitterRecweetOverrideProvider.notifier,
                            );
                            final nextRecweeted = !isRecweeted;
                            final nextCount = nextRecweeted
                                ? recweetCount + 1
                                : (recweetCount > 0 ? recweetCount - 1 : 0);

                            if (!isRecweeted) {
                              final confirmed =
                                  await showCwitterRecweetConfirmationDialog(
                                context,
                                post: post,
                              );
                              if (!confirmed || !context.mounted) return;
                            }

                            notifier.apply(
                              postId: post.id,
                              isRecweeted: nextRecweeted,
                              recweetCount: nextCount,
                            );

                            try {
                              await CwitterService.toggleRecweet(
                                postId: post.id,
                                userId: uid,
                                displayName: appUser.displayName,
                                cwitterId: appUser.cwitterId!,
                                originalAuthorId: post.authorId,
                                profileImageUrl: appUser.profileImageUrl,
                              );
                            } catch (e) {
                              notifier.revert(post.id);
                              if (!context.mounted) return;
                              if (maybeShowBanNotice(context, e)) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          },

                  ),

                  const SizedBox(width: 16),

                  _ActionButton(

                    icon: Icons.favorite_border,

                    activeIcon: Icons.favorite,

                    count: likeCount,

                    color: mutedColor,

                    activeColor: Colors.pinkAccent,

                    isActive: isLiked,

                    onLongPress: likeCount > 0

                        ? () => CwitterReactionListSheet.show(

                              context,

                              postId: post.id,

                              kind: CwitterReactionListKind.likes,

                            )

                        : null,

                    onTap: uid == null ||

                            appUser == null ||

                            !appUser.hasCwitterId

                        ? null

                        : () async {

                            final notifier =

                                ref.read(cwitterLikeOverrideProvider.notifier);

                            final nextLiked = !isLiked;

                            final nextCount = nextLiked

                                ? likeCount + 1

                                : (likeCount > 0 ? likeCount - 1 : 0);



                            notifier.apply(

                              postId: post.id,

                              isLiked: nextLiked,

                              likeCount: nextCount,

                            );



                            try {

                              await CwitterService.toggleLike(

                                postId: post.id,

                                userId: uid,

                                likerDisplayName: appUser.displayName,

                                likerCwitterId: appUser.cwitterId!,

                              );

                            } catch (e) {

                              notifier.revert(post.id);

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(

                                SnackBar(

                                  content: Text('いいねに失敗しました: $e'),

                                ),

                              );

                            }

                          },

                  ),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }

}



class _RecweetBanner extends ConsumerWidget {

  const _RecweetBanner({required this.recweet});



  final CwitterRecweet recweet;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final theme = Theme.of(context);

    final mutedColor =

        theme.colorScheme.onSurface.withValues(alpha: 0.65);

    final resolvedName = resolveAuthorDisplayName(
      ref.watch(
        authorDisplayNameProvider(
          (authorId: recweet.userId, fallback: recweet.displayName),
        ),
      ),
      recweet.displayName,
    );



    return CwitterAuthorHeader(

      authorId: recweet.userId,

      displayName: recweet.displayName,

      cwitterId: recweet.cwitterId,

      profileImageUrl: recweet.profileImageUrl,

      avatarRadius: 18,

      nameColumn: Text(

        '$resolvedNameさんがrecweetしました',

        style: theme.textTheme.bodySmall?.copyWith(

          color: mutedColor,

          fontWeight: FontWeight.w600,

        ),

        maxLines: 2,

        overflow: TextOverflow.ellipsis,

      ),

      trailing: Text(

        formatCommunityRelativeTime(recweet.recweetedAt),

        style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),

      ),

    );

  }

}



class _ActionButton extends StatelessWidget {

  const _ActionButton({

    required this.icon,

    required this.activeIcon,

    required this.count,

    required this.color,

    required this.activeColor,

    this.isActive = false,

    this.onTap,

    this.onLongPress,

  });



  final IconData icon;

  final IconData activeIcon;

  final int? count;

  final Color color;

  final Color activeColor;

  final bool isActive;

  final VoidCallback? onTap;

  final VoidCallback? onLongPress;



  @override

  Widget build(BuildContext context) {

    final displayColor = isActive ? activeColor : color;



    return Material(

      color: Colors.transparent,

      child: InkWell(

        onTap: onTap,

        onLongPress: onLongPress,

        borderRadius: BorderRadius.circular(20),

        child: Padding(

          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),

          child: Row(

            mainAxisSize: MainAxisSize.min,

            children: [

              Icon(isActive ? activeIcon : icon, size: 20, color: displayColor),

              if (count != null) ...[

                const SizedBox(width: 4),

                Text(

                  '$count',

                  style: TextStyle(fontSize: 13, color: displayColor),

                ),

              ],

            ],

          ),

        ),

      ),

    );

  }

}


