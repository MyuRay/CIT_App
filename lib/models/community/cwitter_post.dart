import 'package:cloud_firestore/cloud_firestore.dart';

import 'cwitter_poll.dart';

class CwitterPost {
  const CwitterPost({
    required this.id,
    required this.authorId,
    required this.cwitterId,
    required this.displayName,
    required this.body,
    required this.createdAt,
    this.replyCount = 0,
    this.likeCount = 0,
    this.recweetCount = 0,
    this.likedBy = const {},
    this.profileImageUrl,
    this.authorEmail,
    this.imageUrls = const [],
    this.poll,
  });

  final String id;
  final String authorId;
  final String cwitterId;
  final String displayName;
  /// 投稿時点の登録メールアドレス（管理者・モデレーション用）
  final String? authorEmail;
  final String body;
  final DateTime createdAt;
  final int replyCount;
  final int likeCount;
  final int recweetCount;
  final Map<String, dynamic> likedBy;
  final String? profileImageUrl;
  final List<String> imageUrls;
  final CwitterPoll? poll;

  String get userHandle => '@$cwitterId';

  bool get hasImages => imageUrls.isNotEmpty;
  bool get hasPoll => poll?.hasPoll ?? false;

  bool isLikedBy(String? uid) =>
      uid != null && likedBy[uid] == true;

  factory CwitterPost.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CwitterPost(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      cwitterId: data['cwitterId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '匿名',
      body: data['body'] as String? ?? '',
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      replyCount: (data['replyCount'] as num?)?.toInt() ?? 0,
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      recweetCount: (data['recweetCount'] as num?)?.toInt() ?? 0,
      likedBy: data['likedBy'] is Map
          ? Map<String, dynamic>.from(data['likedBy'] as Map)
          : {},
      profileImageUrl: data['profileImageUrl'] as String?,
      authorEmail: data['authorEmail'] as String?,
      imageUrls: _parseImageUrls(data['imageUrls']),
      poll: _parsePoll(data['poll']),
    );
  }

  static CwitterPoll? _parsePoll(dynamic raw) {
    if (raw is! Map) return null;
    final poll = CwitterPoll.fromMap(Map<String, dynamic>.from(raw));
    return poll.hasPoll ? poll : null;
  }

  static List<String> _parseImageUrls(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((url) => url.isNotEmpty)
        .take(4)
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'authorId': authorId,
      'cwitterId': cwitterId,
      'displayName': displayName,
      if (authorEmail != null) 'authorEmail': authorEmail,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'replyCount': replyCount,
      'likeCount': likeCount,
      'recweetCount': recweetCount,
      'likedBy': likedBy,
      if (imageUrls.isNotEmpty) 'imageUrls': imageUrls,
      if (poll != null) 'poll': poll!.toMap(),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
