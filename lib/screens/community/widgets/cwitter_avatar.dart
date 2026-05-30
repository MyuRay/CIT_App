import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../widgets/profile/author_avatar.dart';
import '../../../widgets/profile/user_avatar.dart';

/// Cwitter 用のアカウントアイコン（作者の最新プロフィール画像を優先表示）
class CwitterAvatar extends ConsumerWidget {
  const CwitterAvatar({
    super.key,
    required this.displayName,
    this.cwitterId,
    this.authorId,
    this.profileImageUrl,
    this.radius = 22,
  });

  final String displayName;
  final String? cwitterId;
  final String? authorId;
  final String? profileImageUrl;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = authorId?.trim();
    if (uid != null && uid.isNotEmpty) {
      return AuthorAvatar(
        authorId: uid,
        displayName: displayName,
        colorSeed: cwitterId,
        fallbackImageUrl: profileImageUrl,
        radius: radius,
      );
    }

    return UserAvatar(
      imageUrl: profileImageUrl,
      displayName: displayName,
      colorSeed: cwitterId,
      radius: radius,
    );
  }
}
