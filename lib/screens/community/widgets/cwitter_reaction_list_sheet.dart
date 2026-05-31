import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/cwitter_provider.dart';
import '../../../core/providers/schedule_provider.dart';
import '../../../models/community/cwitter_follow_user.dart';
import 'cwitter_avatar.dart';
import 'cwitter_handle_text.dart';
import 'cwitter_profile_screen.dart';

enum CwitterReactionListKind {
  likes('いいね'),
  recweets('recweet');

  const CwitterReactionListKind(this.title);
  final String title;
}

/// recweet / いいねしたユーザー一覧（長押しで表示）
class CwitterReactionListSheet extends ConsumerWidget {
  const CwitterReactionListSheet({
    super.key,
    required this.postId,
    required this.kind,
    this.scrollController,
  });

  final String postId;
  final CwitterReactionListKind kind;
  final ScrollController? scrollController;

  static Future<void> show(
    BuildContext context, {
    required String postId,
    required CwitterReactionListKind kind,
  }) {
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
          return CwitterReactionListSheet(
            postId: postId,
            kind: kind,
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUid = ref.watch(currentUserIdProvider);
    final usersAsync = kind == CwitterReactionListKind.likes
        ? ref.watch(filteredCwitterPostLikersProvider(postId))
        : ref.watch(filteredCwitterPostRecweetersProvider(postId));

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            kind.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('読み込みに失敗しました: $error'),
              ),
            ),
            data: (users) {
              if (users.isEmpty) {
                return Center(
                  child: Text(
                    kind == CwitterReactionListKind.likes
                        ? 'まだいいねはありません'
                        : 'まだrecweetはありません',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                );
              }

              return ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _ReactionUserTile(
                    user: users[index],
                    currentUid: currentUid,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReactionUserTile extends StatelessWidget {
  const _ReactionUserTile({
    required this.user,
    required this.currentUid,
  });

  final CwitterFollowUser user;
  final String? currentUid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).pop();
          if (currentUid != null && currentUid == user.authorId) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CwitterProfileScreen(),
              ),
            );
            return;
          }

          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CwitterProfileScreen(user: user.toProfileUser()),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CwitterAvatar(
                authorId: user.authorId,
                displayName: user.displayName,
                cwitterId: user.cwitterId,
                profileImageUrl: user.profileImageUrl,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    CwitterHandleText(
                      cwitterId: user.cwitterId,
                      showOfficialTag: false,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
