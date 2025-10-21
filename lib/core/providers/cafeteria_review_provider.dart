import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/cafeteria/cafeteria_review_model.dart';
import '../../services/cafeteria/cafeteria_review_service.dart';
import '../../services/user/user_service.dart';

// 一覧取得（ストリーム）
final cafeteriaReviewsProvider = StreamProvider.family<List<CafeteriaReview>, String>((ref, cafeteriaId) {
  return CafeteriaReviewService.streamReviews(cafeteriaId);
});

// 投稿用アクション
class CafeteriaReviewActions {
  Future<void> create({
    required String cafeteriaId,
    String? menuName,
    required int taste,
    required int volume,
    required int recommend,
    String? comment,
    String? userName,
    String? volumeGender,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('ログインが必要です');
    }
    final review = CafeteriaReview(
      id: '',
      cafeteriaId: cafeteriaId,
      menuName: menuName,
      taste: taste,
      volume: volume,
      recommend: recommend,
      volumeGender: volumeGender,
      comment: comment,
      userId: user.uid,
      userName: (userName != null && userName.trim().isNotEmpty)
          ? userName.trim()
          : (user.displayName ?? (user.email ?? '匿名')),
      createdAt: DateTime.now(),
      likeCount: 0,
      likedBy: const {},
    );
    await CafeteriaReviewService.addReview(review);
    await UserService.incrementReviewCount(user.uid);
  }

  Future<void> update({
    required String reviewId,
    required int taste,
    required int volume,
    required int recommend,
    String? comment,
    String? userName,
    String? volumeGender,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('ログインが必要です');

    // reviewIdの検証
    if (reviewId.isEmpty) {
      throw Exception('レビューIDが無効です');
    }

    final data = <String, dynamic>{
      'taste': taste,
      'volume': volume,
      'recommend': recommend,
      'comment': comment,
      'userName': (userName != null && userName.trim().isNotEmpty)
          ? userName.trim()
          : (user.displayName ?? (user.email ?? '匿名')),
      'volumeGender': volumeGender,
      'userId': user.uid,
    }..removeWhere((k, v) => v == null);

    try {
      await CafeteriaReviewService.updateReview(reviewId, data);
    } catch (e) {
      throw Exception('レビューの更新に失敗しました: $e');
    }
  }

  Future<void> delete(String reviewId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('ログインが必要です');

    if (reviewId.isEmpty) {
      throw Exception('レビューIDが無効です');
    }

    try {
      await CafeteriaReviewService.deleteReview(reviewId);
    } catch (e) {
      throw Exception('レビューの削除に失敗しました: $e');
    }
  }

  Future<void> like(String reviewId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('ログインが必要です');
    }
    final docRef = FirebaseFirestore.instance.collection('cafeteria_reviews').doc(reviewId);
    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(docRef);
      if (!snap.exists) {
        throw Exception('レビューが見つかりません');
      }
      final data = snap.data() as Map<String, dynamic>;
      final currentCount = (data['likeCount'] as int?) ?? 0;
      final currentLikedBy = Map<String, dynamic>.from(data['likedBy'] as Map<String, dynamic>? ?? {});
      if (currentLikedBy[uid] == true) {
        return;
      }
      currentLikedBy[uid] = true;
      txn.update(docRef, {
        'likedBy': currentLikedBy,
        'likeCount': currentCount + 1,
      });
    });
  }

  Future<void> unlike(String reviewId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('ログインが必要です');
    }
    final docRef = FirebaseFirestore.instance.collection('cafeteria_reviews').doc(reviewId);
    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(docRef);
      if (!snap.exists) {
        throw Exception('レビューが見つかりません');
      }
      final data = snap.data() as Map<String, dynamic>;
      final currentCount = (data['likeCount'] as int?) ?? 0;
      final currentLikedBy = Map<String, dynamic>.from(data['likedBy'] as Map<String, dynamic>? ?? {});
      if (currentLikedBy[uid] == true) {
        currentLikedBy[uid] = false;
        txn.update(docRef, {
          'likedBy': currentLikedBy,
          'likeCount': currentCount > 0 ? currentCount - 1 : 0,
        });
      }
    });
  }

}

final cafeteriaReviewActionsProvider = Provider<CafeteriaReviewActions>((ref) {
  return CafeteriaReviewActions();
});
