import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/cwitter_provider.dart';
import '../../../core/providers/schedule_provider.dart';
import '../../../models/community/cwitter_follow_user.dart';
import 'cwitter_avatar.dart';
import 'cwitter_handle_text.dart';
import 'cwitter_profile_screen.dart';

class CwitterFollowListScreen extends ConsumerWidget {
  const CwitterFollowListScreen({
    super.key,
    required this.userId,
    required this.userDisplayName,
    required this.kind,
  });

  final String userId;
  final String userDisplayName;
  final CwitterFollowListKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUid = ref.watch(currentUserIdProvider);
    final usersAsync = kind == CwitterFollowListKind.following
        ? ref.watch(filteredCwitterFollowingUsersProvider(userId))
        : ref.watch(filteredCwitterFollowerUsersProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text('${userDisplayName}の${kind.title}'),
      ),
      body: usersAsync.when(
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
                kind == CwitterFollowListKind.following
                    ? 'フォロー中のユーザーはいません'
                    : 'フォロワーはいません',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = users[index];
              return _FollowUserTile(
                user: user,
                currentUid: currentUid,
              );
            },
          );
        },
      ),
    );
  }
}

class _FollowUserTile extends StatelessWidget {
  const _FollowUserTile({
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
