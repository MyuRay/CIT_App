import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/community/cwitter_post.dart';
import '../common/user_post_rate_limit.dart';

class CwitterQuoteUnavailableException implements Exception {
  const CwitterQuoteUnavailableException();

  @override
  String toString() => '元のCweetを引用できません。削除や公開状態をご確認ください。';
}

/// 引用先の存在確認と連投制限を、投稿の保存と同じトランザクションで行う。
Future<void> writeCwitterPost({
  required FirebaseFirestore firestore,
  required DocumentReference<Map<String, dynamic>> postRef,
  required Map<String, dynamic> data,
  required DateTime now,
  required Exception rateLimitException,
  String? quotedAuthorId,
}) async {
  final rateLimitRef = UserPostRateLimit.ref(
    firestore,
    userId: data['authorId'] as String,
    limitKey: UserPostRateLimit.cwitterPostKey,
  );
  await firestore.runTransaction((transaction) async {
    if (data.containsKey('quotedPostId')) {
      final quoteId = parseCwitterQuotedPostId(data['quotedPostId']);
      if (quoteId == null || quoteId == postRef.id) {
        throw const CwitterQuoteUnavailableException();
      }
      final source = await transaction.get(
        firestore.collection('cwitter_posts').doc(quoteId),
      );
      if (!source.exists ||
          quotedAuthorId == null ||
          source.data()?['authorId'] != quotedAuthorId) {
        throw const CwitterQuoteUnavailableException();
      }
    }
    await UserPostRateLimit.enforceInTransaction(
      transaction: transaction,
      rateLimitRef: rateLimitRef,
      now: now,
      rateLimitException: rateLimitException,
    );
    transaction.set(postRef, data);
  });
}
