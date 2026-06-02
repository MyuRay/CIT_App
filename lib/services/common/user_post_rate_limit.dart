import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザー投稿の連投防止
class UserPostRateLimit {
  static const Duration windowDuration = Duration(minutes: 1);
  static const int defaultMaxPostsPerWindow = 2;
  static const int chibaChannelMaxPostsPerWindow = 3;
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

  /// 読み取りフェーズ。制限超過時は [rateLimitException] を投げ、
  /// それ以外は書き込みフェーズで使用するデータを返す。
  ///
  /// Firestore トランザクションは「全ての読み取りを全ての書き込みより前に」
  /// 実行する必要があるため、この関数では一切書き込みを行わない。
  static Future<Map<String, dynamic>> evaluate({
    required Transaction transaction,
    required DocumentReference<Map<String, dynamic>> rateLimitRef,
    required DateTime now,
    required Exception rateLimitException,
    int maxPostsPerWindow = defaultMaxPostsPerWindow,
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

    return <String, dynamic>{
      'windowStart': Timestamp.fromDate(nextWindowStart),
      'count': nextCount,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// 書き込みフェーズ。[evaluate] が返したデータを保存する。
  static void commit({
    required Transaction transaction,
    required DocumentReference<Map<String, dynamic>> rateLimitRef,
    required Map<String, dynamic> data,
  }) {
    transaction.set(rateLimitRef, data);
  }

  /// 後続の読み取りが無いトランザクション向けの簡易版（読み取り→書き込み）。
  static Future<void> enforceInTransaction({
    required Transaction transaction,
    required DocumentReference<Map<String, dynamic>> rateLimitRef,
    required DateTime now,
    required Exception rateLimitException,
    int maxPostsPerWindow = defaultMaxPostsPerWindow,
  }) async {
    final data = await evaluate(
      transaction: transaction,
      rateLimitRef: rateLimitRef,
      now: now,
      rateLimitException: rateLimitException,
      maxPostsPerWindow: maxPostsPerWindow,
    );
    commit(
      transaction: transaction,
      rateLimitRef: rateLimitRef,
      data: data,
    );
  }
}
