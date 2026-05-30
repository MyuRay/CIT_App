import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/user_provider.dart';
import 'user_avatar.dart';

/// 作者の最新プロフィール画像を表示するアバター
class AuthorAvatar extends ConsumerWidget {
  const AuthorAvatar({
    super.key,
    required this.authorId,
    required this.displayName,
    this.colorSeed,
    this.fallbackImageUrl,
    this.radius = 20,
  });

  final String authorId;
  final String displayName;
  final String? colorSeed;
  final String? fallbackImageUrl;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(authorProfileImageUrlProvider(authorId));
    final imageUrl = profileAsync.when(
      data: (url) => url,
      loading: () => fallbackImageUrl,
      error: (_, __) => fallbackImageUrl,
    );
    final nameAsync = ref.watch(
      authorDisplayNameProvider((authorId: authorId, fallback: displayName)),
    );
    final resolvedName = resolveAuthorDisplayName(nameAsync, displayName);

    return UserAvatar(
      imageUrl: imageUrl,
      displayName: resolvedName,
      colorSeed: colorSeed ?? authorId,
      radius: radius,
    );
  }
}
