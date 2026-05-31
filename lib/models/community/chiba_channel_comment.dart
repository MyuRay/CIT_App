import 'package:cloud_firestore/cloud_firestore.dart';

/// ちばちゃんねる レス
class ChibaChannelComment {
  const ChibaChannelComment({
    required this.id,
    required this.threadId,
    required this.body,
    required this.commentNumber,
    required this.createdAt,
    required this.authorId,
    required this.anonymousId,
    this.authorEmail,
    this.inReplyToCommentNumber,
    this.inReplyToCommentId,
    this.imageUrls = const [],
    this.isDeleted = false,
  });

  static const String deletedMessage = 'このレスは削除されました';

  final String id;
  final String threadId;
  final String body;
  final int commentNumber;
  final DateTime createdAt;
  final String authorId;
  final String anonymousId;
  final String? authorEmail;
  final int? inReplyToCommentNumber;
  final String? inReplyToCommentId;
  final List<String> imageUrls;
  final bool isDeleted;

  bool get hasImages => !isDeleted && imageUrls.isNotEmpty;

  String get displayName => '名無しさん';

  String get displayIdLabel => 'ID:$anonymousId';

  String get displayBody => isDeleted ? deletedMessage : body;

  factory ChibaChannelComment.fromFirestore(
    String threadId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ChibaChannelComment(
      id: doc.id,
      threadId: threadId,
      body: data['body'] as String? ?? '',
      commentNumber: (data['commentNumber'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      authorId: data['authorId'] as String? ?? '',
      anonymousId: data['anonymousId'] as String? ?? '--------',
      authorEmail: data['authorEmail'] as String?,
      inReplyToCommentNumber:
          (data['inReplyToCommentNumber'] as num?)?.toInt(),
      inReplyToCommentId: data['inReplyToCommentId'] as String?,
      imageUrls: _parseImageUrls(data['imageUrls']),
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }

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
