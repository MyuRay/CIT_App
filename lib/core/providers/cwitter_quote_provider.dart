import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/community/cwitter_post.dart';
import '../../models/user/user_model.dart';
import '../../services/community/cwitter_service.dart';
import 'schedule_provider.dart';
import 'user_block_provider.dart';

final cwitterQuotedPostProvider = StreamProvider.autoDispose
    .family<CwitterPost?, String>((ref, postId) {
      if (ref.watch(currentUserIdProvider) == null ||
          parseCwitterQuotedPostId(postId) == null) {
        return Stream.value(null);
      }
      return FirebaseFirestore.instance
          .collection('cwitter_posts')
          .doc(postId)
          .snapshots()
          .map((doc) => doc.exists ? CwitterPost.fromFirestore(doc) : null);
    });

/// ブロック状態の取得前・取得失敗時も、引用経由では内容を表示しない。
final visibleCwitterQuotedPostProvider = Provider.autoDispose
    .family<AsyncValue<CwitterPost?>, String>((ref, postId) {
      final hidden = ref.watch(hiddenUserIdsProvider);
      if (hidden.hasError) {
        return AsyncValue.error(hidden.error!, hidden.stackTrace!);
      }
      if (hidden.isLoading) return const AsyncValue.loading();
      return ref
          .watch(cwitterQuotedPostProvider(postId))
          .whenData(
            (post) =>
                post != null && !hidden.requireValue.contains(post.authorId)
                    ? post
                    : null,
          );
    });

typedef SubmitCwitterQuote =
    Future<void> Function(AppUser author, String quotedPostId, String body);

final submitCwitterQuoteProvider = Provider<SubmitCwitterQuote>((ref) {
  return (author, quotedPostId, body) => CwitterService.createPost(
    authorId: author.uid,
    authorEmail: author.email,
    cwitterId: author.cwitterId!,
    displayName: author.displayName,
    profileImageUrl: author.profileImageUrl,
    body: body,
    quotedPostId: quotedPostId,
  );
});
