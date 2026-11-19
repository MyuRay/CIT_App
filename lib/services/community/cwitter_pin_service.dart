import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/community/cwitter_post.dart';
import '../auth/session_work_guard.dart';

/// A single post reference per profile; the original post remains authoritative.
class CwitterPinService {
  CwitterPinService({required this.firestore, required this.auth});

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  static const field = 'cwitterPinnedPostId';

  static String? parsePostId(Object? value) =>
      value is String && RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(value)
          ? value
          : null;

  Stream<String?> watchPinnedPostId(String userId) => firestore
      .collection(auth.currentUser?.uid == userId ? 'users' : 'public_profiles')
      .doc(userId)
      .snapshots()
      .map(
        (doc) =>
            doc.data()?['isActive'] == false
                ? null
                : parsePostId(doc.data()?[field]),
      );

  Stream<CwitterPost?> watchPost(String postId) => firestore
      .collection('cwitter_posts')
      .doc(postId)
      .snapshots()
      .map((doc) => doc.exists ? CwitterPost.fromFirestore(doc) : null);

  Future<void> setPinned({
    required String userId,
    required String postId,
    required bool pinned,
  }) async {
    final generation = SessionWorkGuard.generation;
    void requireCurrentUser() {
      if (!SessionWorkGuard.isCurrent(generation) ||
          auth.currentUser?.uid != userId ||
          auth.currentUser?.emailVerified != true) {
        throw StateError('ログイン状態を確認してください');
      }
    }

    requireCurrentUser();
    if (parsePostId(postId) == null) throw StateError('Cweetが見つかりません');
    final profileRef = firestore.collection('users').doc(userId);
    await firestore.runTransaction((transaction) async {
      final profile = await transaction.get(profileRef);
      if (!profile.exists || profile.data()?['isActive'] == false) {
        throw StateError('プロフィールが見つかりません');
      }
      if (pinned) {
        final post = await transaction.get(
          firestore.collection('cwitter_posts').doc(postId),
        );
        if (!post.exists) throw StateError('このCweetは削除されています');
        if (post.data()?['authorId'] != userId) {
          throw StateError('固定できるのは自分のCweetだけです');
        }
      } else if (profile.data()?[field] != postId) {
        // An old menu must not unpin a different post selected on another device.
        return;
      }
      requireCurrentUser();
      transaction.update(profileRef, {
        field: pinned ? postId : FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
