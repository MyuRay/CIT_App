import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザー投稿の連投防止（1分間に2件まで）
class UserPostRateLimit {
  static const Duration windowDuration = Duration(minutes: 1);
  static const int maxPostsPerWindow = 2;
  static const String usersCollection = 'users';
  static const String rateLimitsCollection = 'rate_limits';

  static const String cwitterPostKey = 'cwitter_post';
  static const String cwitterReplyKey = 'cwitter_reply';
  static const String chibaChannelCommentKey = 'chiba_channel_comment';

  static DocumentReference<Map<String, dynamic>> ref(
    FirebaseFirestore firestore, {
    required String userId,
    required String limitKey,
  }) {
    return firestore
        .collection(usersCollection)
        .doc(userId)
        .collection(rateLimitsCollection)
        .doc(limitKey);
  }

  static Future<void> enforceInTransaction({
    required Transaction transaction,
    required DocumentReference<Map<String, dynamic>> rateLimitRef,
    required DateTime now,
    required Exception rateLimitException,
  }) async {
    final rateSnap = await transaction.get(rateLimitRef);

    var nextCount = 1;
    var nextWindowStart = now;

    if (rateSnap.exists) {
      final rateData = rateSnap.data() ?? <String, dynamic>{};
      final windowStartTs = rateData['windowStart'];
      final currentCount = (rateData['count'] as num?)?.toInt() ?? 0;
      final windowStart = windowStartTs is Timestamp
          ? windowStartTs.toDate()
          : now.subtract(windowDuration);

      if (now.difference(windowStart) < windowDuration) {
        if (currentCount >= maxPostsPerWindow) {
          throw rateLimitException;
        }
        nextCount = currentCount + 1;
        nextWindowStart = windowStart;
      }
    }

    transaction.set(rateLimitRef, {
      'windowStart': Timestamp.fromDate(nextWindowStart),
      'count': nextCount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
