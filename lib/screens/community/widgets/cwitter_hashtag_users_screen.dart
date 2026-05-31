import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/cwitter_provider.dart';
import '../../../core/providers/schedule_provider.dart';
import '../../../core/providers/user_block_provider.dart';
import '../../../models/community/cwitter_follow_user.dart';
import '../../../services/community/cwitter_service.dart';
import 'cwitter_avatar.dart';
import 'cwitter_follow_button.dart';
import 'cwitter_handle_text.dart';
import 'cwitter_profile_screen.dart';
import 'cwitter_tags_row.dart';

/// 指定ハッシュタグを設定しているユーザー一覧
class CwitterHashtagUsersScreen extends ConsumerStatefulWidget {
  const CwitterHashtagUsersScreen({
    super.key,
    required this.tag,
  });

  final String tag;

  @override
  ConsumerState<CwitterHashtagUsersScreen> createState() =>
      _CwitterHashtagUsersScreenState();
}

class _CwitterHashtagUsersScreenState
    extends ConsumerState<CwitterHashtagUsersScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<CwitterFollowUser> _users = const [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hiddenUserIds =
          ref.read(hiddenUserIdsProvider).valueOrNull ?? const {};
      final users = (await CwitterService.fetchUsersWithHashtag(widget.tag))
          .where((user) => !hiddenUserIds.contains(user.authorId))
          .toList();

      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUid = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('#${widget.tag}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('読み込みに失敗しました: $_errorMessage'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadUsers,
                          child: const Text('再読み込み'),
                        ),
                      ],
                    ),
                  ),
                )
              : _users.isEmpty
                  ? Center(
                      child: Text(
                        'このタグを設定しているユーザーはいません',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _HashtagUserTile(
                          user: _users[index],
                          currentUid: currentUid,
                        );
                      },
                    ),
    );
  }
}

class _HashtagUserTile extends ConsumerWidget {
  const _HashtagUserTile({
    required this.user,
    required this.currentUid,
  });

  final CwitterFollowUser user;
  final String? currentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelf = currentUid != null && currentUid == user.authorId;
    final showFollowButton = !isSelf && currentUid != null;
    final tags =
        ref.watch(cwitterUserTagsProvider(user.authorId)).valueOrNull ??
            user.tags;

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
          if (isSelf) {
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
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      CwitterTagsRow(tags: tags, compact: true),
                    ],
                  ],
                ),
              ),
              if (showFollowButton) ...[
                const SizedBox(width: 8),
                CwitterFollowButton(
                  followerId: currentUid!,
                  followeeId: user.authorId,
                  compact: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
