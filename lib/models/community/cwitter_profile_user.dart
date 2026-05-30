/// Cwitter プロフィール表示用のユーザー情報（投稿データから組み立て）
class CwitterProfileUser {
  const CwitterProfileUser({
    required this.authorId,
    required this.displayName,
    required this.cwitterId,
    this.profileImageUrl,
    this.bio,
    this.tags = const [],
  });

  final String authorId;
  final String displayName;
  final String cwitterId;
  final String? profileImageUrl;
  final String? bio;
  final List<String> tags;

  String get handle => '@$cwitterId';
}
