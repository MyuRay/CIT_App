import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザーが recweet した Cweet
class CwitterRecweet {
  const CwitterRecweet({
    required this.userId,
    required this.postId,
    required this.displayName,
    required this.cwitterId,
    required this.originalAuthorId,
    required this.recweetedAt,
    this.profileImageUrl,
  });

  final String userId;
  final String postId;
  final String displayName;
  final String cwitterId;
  final String? profileImageUrl;
  final String originalAuthorId;
  final DateTime recweetedAt;

  String get userHandle => '@$cwitterId';

  factory CwitterRecweet.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final userId = doc.reference.parent.parent?.id ?? '';
    return CwitterRecweet(
      userId: userId,
      postId: data['postId'] as String? ?? doc.id,
      displayName: data['displayName'] as String? ?? 'Unknown',
      cwitterId: data['cwitterId'] as String? ?? '',
      profileImageUrl: data['profileImageUrl'] as String?,
      originalAuthorId: data['originalAuthorId'] as String? ?? '',
      recweetedAt: _parseDateTime(data['recweetedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
