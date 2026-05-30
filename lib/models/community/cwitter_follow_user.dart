import 'cwitter_profile_user.dart';

/// フォロー / フォロワー一覧表示用
class CwitterFollowUser {
  const CwitterFollowUser({
    required this.authorId,
    required this.displayName,
    required this.cwitterId,
    this.profileImageUrl,
    this.bio,
    this.tags = const [],
    this.followedAt,
  });

  final String authorId;
  final String displayName;
  final String cwitterId;
  final String? profileImageUrl;
  final String? bio;
  final List<String> tags;
  final DateTime? followedAt;

  String get handle => '@$cwitterId';

  CwitterProfileUser toProfileUser() {
    return CwitterProfileUser(
      authorId: authorId,
      displayName: displayName,
      cwitterId: cwitterId,
      profileImageUrl: profileImageUrl,
      bio: bio,
      tags: tags,
    );
  }
}

enum CwitterFollowListKind {
  following('フォロー中'),
  followers('フォロワー');

  const CwitterFollowListKind(this.title);
  final String title;
}

enum CwitterFeedTab {
  everyone,
  following,
}
