import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/bulletin/bulletin_model.dart';

class BulletinService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 掲示板投稿を作成
  static Future<void> createPost({
    required String title,
    required String description,
    File? imageFile,
    required BulletinCategory category,
    required String authorName,
    required String authorId,
    DateTime? expiresAt,
    bool isPinned = false,
  }) async {
    try {
      // 画像をStorageにアップロード（画像がある場合のみ）
      String imageUrl = '';
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile);
      }

      // 投稿データを作成
      final BulletinPost post = BulletinPost(
        id: '', // Firestoreで自動生成
        title: title,
        description: description,
        imageUrl: imageUrl,
        category: category,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        authorId: authorId,
        authorName: authorName,
        viewCount: 0,
        isPinned: isPinned,
        isActive: true,
      );

      // Firestoreに保存
      await _firestore.collection('bulletin_posts').add(post.toJson());
    } catch (e) {
      throw Exception('投稿の作成に失敗しました: $e');
    }
  }

  /// 画像をFirebase Storageにアップロード
  static Future<String> _uploadImage(File imageFile) async {
    try {
      // 認証ユーザーIDを取得
      final String userId = _getCurrentUserId();
      
      // ファイル名を生成（タイムスタンプ + 元ファイル名）
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      
      // 新しいパス構造: /bulletin_images/{userId}/{imageId}
      final Reference ref = _storage
          .ref()
          .child('bulletin_images')
          .child(userId)
          .child(fileName);
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('画像のアップロードに失敗しました: $e');
    }
  }

  /// 現在のユーザーIDを取得
  static String _getCurrentUserId() {
    // Firebase Authから現在のユーザーを取得
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('ユーザーが認証されていません');
    }
    return user.uid;
  }

  /// 投稿を取得（ページネーション対応）
  static Future<List<BulletinPost>> getPosts({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? categoryId,
    bool? isPinned,
  }) async {
    try {
      Query query = _firestore
          .collection('bulletin_posts')
          .where('isActive', isEqualTo: true);

      // カテゴリでフィルタリング
      if (categoryId != null) {
        query = query.where('category.id', isEqualTo: categoryId);
      }

      // ピン留めでフィルタリング
      if (isPinned != null) {
        query = query.where('isPinned', isEqualTo: isPinned);
      }

      final QuerySnapshot snapshot = await query.get();
      
      List<BulletinPost> posts = snapshot.docs
          .map((doc) => BulletinPost.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();

      // ピン留め投稿を優先してソート
      posts.sort((a, b) {
        // まずピン留めステータスで比較
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        
        // ピン留めステータスが同じ場合は作成日時で比較
        return b.createdAt.compareTo(a.createdAt);
      });

      // ページネーション処理（ソート後に適用）
      if (lastDocument != null) {
        // 既存のlastDocumentの位置を見つけて、その後からlimit分を返す
        int startIndex = 0;
        for (int i = 0; i < posts.length; i++) {
          if (posts[i].id == lastDocument.id) {
            startIndex = i + 1;
            break;
          }
        }
        posts = posts.skip(startIndex).take(limit).toList();
      } else {
        posts = posts.take(limit).toList();
      }
      
      return posts;
    } catch (e) {
      throw Exception('投稿の取得に失敗しました: $e');
    }
  }

  /// 投稿の閲覧数を増加
  static Future<void> incrementViewCount(String postId) async {
    try {
      await _firestore.collection('bulletin_posts').doc(postId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      // エラーが発生してもUIには影響させない
      print('閲覧数の更新に失敗: $e');
    }
  }

  /// 投稿を削除（論理削除）
  static Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('bulletin_posts').doc(postId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('投稿の削除に失敗しました: $e');
    }
  }

  /// 期限切れの投稿を自動的に無効化
  static Future<void> deactivateExpiredPosts() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('bulletin_posts')
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isLessThan: Timestamp.now())
          .get();

      final WriteBatch batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      await batch.commit();
    } catch (e) {
      print('期限切れ投稿の処理に失敗: $e');
    }
  }

  /// 投稿統計を取得
  static Future<Map<String, int>> getPostStatistics() async {
    try {
      final QuerySnapshot allPosts = await _firestore
          .collection('bulletin_posts')
          .where('isActive', isEqualTo: true)
          .get();

      final QuerySnapshot pinnedPosts = await _firestore
          .collection('bulletin_posts')
          .where('isActive', isEqualTo: true)
          .where('isPinned', isEqualTo: true)
          .get();

      return {
        'total': allPosts.docs.length,
        'pinned': pinnedPosts.docs.length,
      };
    } catch (e) {
      return {'total': 0, 'pinned': 0};
    }
  }

  /// クーポンを使用
  /// 注意: Discord通知はFirebase FunctionsのonDocumentUpdatedトリガーで自動的に送信されます
  static Future<void> useCoupon(String postId, String userId) async {
    try {
      print('🎫 useCoupon start: postId=$postId, userId=$userId');
      await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('bulletin_posts').doc(postId);
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw Exception('投稿が見つかりません');
        }
        
        final raw = postDoc.data()!;
        final post = BulletinPost.fromJson({
          'id': postDoc.id,
          ...raw,
        });
        // 事前ログ
        final rawIsCoupon = raw['isCoupon'];
        final rawMax = raw['couponMaxUses'];
        final rawUsedCount = raw['couponUsedCount'];
        final rawUsedBy = (raw['couponUsedBy'] is Map) ? Map<String, dynamic>.from(raw['couponUsedBy'] as Map) : <String, dynamic>{};
        final currentUserUsage = (rawUsedBy[userId] is num) ? (rawUsedBy[userId] as num).toInt() : 0;
        print('🎫 current resource: isCoupon=$rawIsCoupon, couponMaxUses=$rawMax, couponUsedCount=$rawUsedCount');
        print('🎫 current userUsage[$userId]=$currentUserUsage, usedBy.size=${rawUsedBy.length}');
        
        // クーポン投稿でない場合はエラー
        if (!post.isCoupon) {
          throw Exception('この投稿はクーポンではありません');
        }
        
        // ユーザーごとの使用回数上限チェック
        final usedBy = post.couponUsedBy ?? <String, int>{};
        final currentUserUsageCount = usedBy[userId] ?? 0;
        
        if (post.couponMaxUses != null && currentUserUsageCount >= post.couponMaxUses!) {
          throw Exception('あなたはこのクーポンの使用回数上限に達しています');
        }
        
        // 使用記録を更新（ユーザーごとの使用回数）
        final updatedUsedBy = Map<String, int>.from(usedBy);
        updatedUsedBy[userId] = currentUserUsageCount + 1;
        final newTotal = post.couponUsedCount + 1;
        print('🎫 update payload: couponUsedCount: ${post.couponUsedCount} -> $newTotal, '
              'couponUsedBy[$userId]: $currentUserUsageCount -> ${updatedUsedBy[userId]}');
        
        transaction.update(postRef, {
          'couponUsedCount': newTotal,
          'couponUsedBy': updatedUsedBy,
        });
        print('🎫 transaction.update called with only couponUsedCount & couponUsedBy');
      });
      
      // 反映確認ログ（任意）
      try {
        final after = await _firestore.collection('bulletin_posts').doc(postId).get();
        final a = after.data();
        final afterCount = a?['couponUsedCount'];
        final afterUser = (a?['couponUsedBy'] is Map) ? (a?['couponUsedBy'][userId]) : null;
        print('🎫 after update: couponUsedCount=$afterCount, couponUsedBy[$userId]=$afterUser');
      } catch (e) {
        print('⚠️ post-update fetch failed (ignored): $e');
      }
    } catch (e) {
      print('❌ クーポン使用エラー: $e');
      if (e is FirebaseException) {
        print('❌ FirebaseException(code=${e.code}, message=${e.message})');
      }
      print('❌ Hint: Ensure only couponUsedCount/couponUsedBy are being updated and user is CIT domain.');
      rethrow;
    }
  }
}
