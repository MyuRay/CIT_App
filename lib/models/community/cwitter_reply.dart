import 'package:cloud_firestore/cloud_firestore.dart';

class CwitterReply {
  const CwitterReply({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.cwitterId,
    required this.displayName,
    required this.body,
    required this.createdAt,
    this.profileImageUrl,
    this.authorEmail,
    this.inReplyToReplyId,
    this.imageUrls = const [],
  });

  final String id;
  final String postId;
  final String authorId;
  final String cwitterId;
  final String displayName;
  final String? authorEmail;
  final String body;
  final DateTime createdAt;
  final String? profileImageUrl;
  final String? inReplyToReplyId;
  final List<String> imageUrls;

  String get userHandle => '@$cwitterId';
  bool get hasImages => imageUrls.isNotEmpty;

  factory CwitterReply.fromFirestore(
    String postId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CwitterReply(
      id: doc.id,
      postId: postId,
      authorId: data['authorId'] as String? ?? '',
      cwitterId: data['cwitterId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '匿名',
      body: data['body'] as String? ?? '',
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      profileImageUrl: data['profileImageUrl'] as String?,
      authorEmail: data['authorEmail'] as String?,
      inReplyToReplyId: data['inReplyToReplyId'] as String?,
      imageUrls: _parseImageUrls(data['imageUrls']),
    );
  }

  static List<String> parseImageUrls(dynamic raw) => _parseImageUrls(raw);

  static List<String> _parseImageUrls(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((url) => url.isNotEmpty)
        .take(4)
        .toList();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
