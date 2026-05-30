import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/user_provider.dart';
import '../../../core/providers/schedule_provider.dart';
import '../../../models/community/cwitter_post.dart';
import '../../../models/community/cwitter_profile_user.dart';
import 'cwitter_avatar.dart';
import 'cwitter_author_name_row.dart';
import 'cwitter_handle_text.dart';
import 'cwitter_profile_screen.dart';
import '../../../core/providers/cwitter_provider.dart';

/// 投稿者アイコン・名前タップでプロフィール（投稿一覧）を開く
class CwitterAuthorHeader extends ConsumerWidget {
  const CwitterAuthorHeader({
    super.key,
    required this.authorId,
    required this.displayName,
    required this.cwitterId,
    this.profileImageUrl,
    this.avatarRadius = 22,
    this.nameColumn,
    this.trailing,
  });

  final String authorId;
  final String displayName;
  final String cwitterId;
  final String? profileImageUrl;
  final double avatarRadius;
  final Widget? nameColumn;
  final Widget? trailing;

  factory CwitterAuthorHeader.fromPost(
    CwitterPost post, {
    Key? key,
    double avatarRadius = 22,
    Widget? trailing,
  }) {
    return CwitterAuthorHeader(
      key: key,
      authorId: post.authorId,
      displayName: post.displayName,
      cwitterId: post.cwitterId,
      profileImageUrl: post.profileImageUrl,
      avatarRadius: avatarRadius,
      trailing: trailing,
    );
  }

  void _openProfile(BuildContext context, WidgetRef ref) {
    final currentUid = ref.read(currentUserIdProvider);
    final tags =
        ref.read(cwitterUserTagsProvider(authorId)).valueOrNull ?? const [];
    final resolvedName = resolveAuthorDisplayName(
      ref.read(
        authorDisplayNameProvider((authorId: authorId, fallback: displayName)),
      ),
      displayName,
    );
    if (currentUid != null && currentUid == authorId) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const CwitterProfileScreen(),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CwitterProfileScreen(
          user: CwitterProfileUser(
            authorId: authorId,
            displayName: resolvedName,
            cwitterId: cwitterId,
            profileImageUrl: profileImageUrl,
            tags: tags,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mutedColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final tags = ref.watch(cwitterUserTagsProvider(authorId)).valueOrNull ??
        const <String>[];
    final resolvedName = resolveAuthorDisplayName(
      ref.watch(
        authorDisplayNameProvider((authorId: authorId, fallback: displayName)),
      ),
      displayName,
    );

    final defaultNameColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CwitterAuthorNameRow(
          displayName: resolvedName,
          cwitterId: cwitterId,
          tags: tags,
          compact: true,
        ),
        CwitterHandleText(
          cwitterId: cwitterId,
          showOfficialTag: false,
          style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openProfile(context, ref),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CwitterAvatar(
                authorId: authorId,
                displayName: resolvedName,
                cwitterId: cwitterId,
                profileImageUrl: profileImageUrl,
                radius: avatarRadius,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: nameColumn ?? defaultNameColumn),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
