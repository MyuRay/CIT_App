import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user/user_model.dart';

/// メール変更完了チェックの結果
enum EmailChangeCheckResult {
  /// まだ Firebase Auth 上で新メールに切り替わっていない
  notCompleted,

  /// 変更完了（セッション有効・Firestore 同期済みまたは試行済み）
  completed,

  /// 変更完了したがセッションが無効化されたため再ログインが必要
  completedRequiresReauth,
}

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'users';

  /// ユーザー情報を作成
  static Future<void> createUser(AppUser user) async {
    try {
      print('👤 ユーザー情報作成開始: ${user.email}');
      
      await _firestore
          .collection(_collection)
          .doc(user.uid)
          .set(user.toJson());
      
      print('✅ ユーザー情報を作成しました: ${user.uid}');
    } catch (e) {
      print('❌ ユーザー情報作成エラー: $e');
      rethrow;
    }
  }

  /// ユーザー情報を取得
  static Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return AppUser.fromJson(doc.data()!);
      }
      
      return null;
    } catch (e) {
      print('❌ ユーザー情報取得エラー: $e');
      return null;
    }
  }

  /// ユーザー情報を更新
  static Future<void> updateUser(AppUser user) async {
    try {
      final updatedUser = user.copyWith(updatedAt: DateTime.now());
      
      await _firestore
          .collection(_collection)
          .doc(user.uid)
          .set(updatedUser.toJson());
      
      print('✅ ユーザー情報を更新しました: ${user.uid}');
    } catch (e) {
      print('❌ ユーザー情報更新エラー: $e');
      rethrow;
    }
  }

  /// Firebase Authユーザーからアプリユーザーを作成
  static AppUser createAppUserFromFirebaseUser(User firebaseUser) {
    // メールアドレスから表示名を生成（メールの@より前の部分）
    String displayName = firebaseUser.displayName ?? 
                        firebaseUser.email?.split('@').first ?? 
                        '匿名ユーザー';

    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: displayName,
      profileImageUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
      isActive: true,
      reviewCount: 0,
      emailVerified: firebaseUser.emailVerified,
    );
  }

  /// 現在のユーザー情報を取得（存在しない場合は作成）
  static Future<AppUser?> getCurrentUserOrCreate() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;

    // 既存ユーザー情報を取得
    AppUser? existingUser = await getUser(firebaseUser.uid);
    
    if (existingUser != null) {
      await syncEmailFromFirebaseAuth(firebaseUser);
      return existingUser;
    }

    // 存在しない場合は新規作成
    final newUser = createAppUserFromFirebaseUser(firebaseUser);
    await createUser(newUser);
    return newUser;
  }

  /// ユーザープロフィールを更新
  static Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? profileImageUrl,
    bool clearProfileImageUrl = false,
    String? department,
    String? studentId,
    int? graduationYear,
  }) async {
    try {
      var existingUser = await getUser(uid);
      final previousDisplayName = existingUser?.displayName;

      if (existingUser == null) {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser == null || firebaseUser.uid != uid) {
          throw Exception('ユーザーが見つかりません');
        }
        existingUser = createAppUserFromFirebaseUser(firebaseUser);
      }

      final updatedUser = existingUser.copyWith(
        displayName: displayName ?? existingUser.displayName,
        profileImageUrl: clearProfileImageUrl
            ? null
            : (profileImageUrl ?? existingUser.profileImageUrl),
        department: department,
        studentId: studentId,
        graduationYear: graduationYear,
        updatedAt: DateTime.now(),
      );

      await updateUser(updatedUser);

      if (displayName != null &&
          displayName.trim().isNotEmpty &&
          displayName.trim() != previousDisplayName?.trim()) {
        unawaited(
          propagateDisplayNameToBulletinComments(
            uid: uid,
            displayName: displayName.trim(),
          ),
        );
      }
    } catch (e) {
      print('❌ プロフィール更新エラー: $e');
      rethrow;
    }
  }

  /// 掲示板コメントに保存されている表示名を最新に同期
  static Future<void> propagateDisplayNameToBulletinComments({
    required String uid,
    required String displayName,
  }) async {
    try {
      const batchLimit = 400;
      final snapshot = await _firestore
          .collection('bulletin_comments')
          .where('authorId', isEqualTo: uid)
          .get();

      for (var i = 0; i < snapshot.docs.length; i += batchLimit) {
        final batch = _firestore.batch();
        final chunk = snapshot.docs.skip(i).take(batchLimit);
        for (final doc in chunk) {
          batch.update(doc.reference, {'authorName': displayName});
        }
        await batch.commit();
      }
    } catch (e) {
      print('⚠️ 掲示板コメントの表示名同期エラー: $e');
    }
  }

  /// アカウントを無効化（論理削除）
  static Future<void> deactivateUser(String uid) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(uid)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
      
      print('✅ ユーザーを無効化しました: $uid');
    } catch (e) {
      print('❌ ユーザー無効化エラー: $e');
      rethrow;
    }
  }

  static Future<void> incrementReviewCount(String uid) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'reviewCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('❌ レビュー数更新エラー: $e');
      // ドキュメントが存在しない場合などは呼び出し側での処理を継続
    }
  }

  /// 最終ログイン時刻を更新
  static Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'lastLoginAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      print('✅ 最終ログイン時刻を更新しました: $uid');
    } catch (e) {
      print('⚠️ 最終ログイン時刻更新エラー: $e');
      // エラーが発生してもログインは継続
    }
  }

  /// メール認証状態をFirestoreに同期
  static Future<void> syncEmailVerificationStatus(String uid, bool emailVerified) async {
    try {
      final docRef = _firestore.collection(_collection).doc(uid);
      final snapshot = await docRef.get();
      final data = snapshot.data() ?? <String, dynamic>{};
      final alreadyVerified =
          (data['emailVerified'] == true) || (data['isEmailVerified'] == true);
      final effectiveVerified = alreadyVerified || emailVerified;

      await docRef.update({
        'emailVerified': effectiveVerified,
        'isEmailVerified': effectiveVerified,
        'updatedAt': Timestamp.now(),
      });
      print('✅ メール認証状態を同期しました: $uid -> $effectiveVerified');
    } catch (e) {
      print('⚠️ メール認証状態同期エラー: $e');
      // エラーが発生しても処理は継続
    }
  }

  /// 現在のユーザーのメール認証状態をFirebase Authから取得してFirestoreに同期
  static Future<bool> syncCurrentUserEmailVerification() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;

      // Firebase Authの状態を再読み込み
      await firebaseUser.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser == null) return false;

      final authVerified = refreshedUser.emailVerified;
      final doc = await _firestore.collection(_collection).doc(refreshedUser.uid).get();
      final existingData = doc.data() ?? <String, dynamic>{};
      final storedVerified =
          (existingData['emailVerified'] == true) ||
          (existingData['isEmailVerified'] == true);
      final effectiveVerified = authVerified || storedVerified;
      
      // Firestoreに同期
      await syncEmailVerificationStatus(refreshedUser.uid, effectiveVerified);
      await syncEmailFromFirebaseAuth(refreshedUser);
      
      return effectiveVerified;
    } catch (e) {
      print('⚠️ メール認証状態確認エラー: $e');
      return false;
    }
  }

  /// Firebase Auth のメールアドレスを Firestore に反映する
  static Future<bool> syncEmailFromFirebaseAuth(User firebaseUser) async {
    try {
      final authEmail = firebaseUser.email?.trim();
      if (authEmail == null || authEmail.isEmpty) return false;

      final existingUser = await getUser(firebaseUser.uid);
      if (existingUser == null) return false;

      if (existingUser.email.trim().toLowerCase() == authEmail.toLowerCase()) {
        return false;
      }

      final updatedUser = existingUser.copyWith(
        email: authEmail,
        emailVerified: firebaseUser.emailVerified,
        updatedAt: DateTime.now(),
      );
      await updateUser(updatedUser);
      print('✅ Firestoreのメールアドレスを同期しました: $authEmail');
      return true;
    } catch (e) {
      print('⚠️ メールアドレス同期エラー: $e');
      return false;
    }
  }

  static bool _isSessionInvalidatedAfterEmailChange(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-token-expired':
      case 'invalid-user-token':
      case 'user-not-found':
        return true;
      default:
        return false;
    }
  }

  static Future<void> _syncAfterEmailChange(User firebaseUser) async {
    try {
      await syncEmailFromFirebaseAuth(firebaseUser);
      await syncEmailVerificationStatus(
        firebaseUser.uid,
        firebaseUser.emailVerified,
      );
    } catch (e) {
      print('⚠️ メール変更後の Firestore 同期エラー（再ログイン後に再試行）: $e');
    }
  }

  /// メール変更が完了したかを確認する。
  ///
  /// メール変更直後は Firebase Auth のセッションが無効化されることがあり、
  /// その場合は [EmailChangeCheckResult.completedRequiresReauth] を返す。
  static Future<EmailChangeCheckResult> checkEmailChangeCompletion(
    String expectedEmail,
  ) async {
    final expected = expectedEmail.trim().toLowerCase();
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return EmailChangeCheckResult.completedRequiresReauth;
    }

    try {
      await firebaseUser.reload();
    } on FirebaseAuthException catch (e) {
      if (_isSessionInvalidatedAfterEmailChange(e)) {
        return EmailChangeCheckResult.completedRequiresReauth;
      }
      rethrow;
    }

    final refreshedUser = FirebaseAuth.instance.currentUser;
    if (refreshedUser == null) {
      return EmailChangeCheckResult.completedRequiresReauth;
    }

    final current = refreshedUser.email?.trim().toLowerCase();
    if (current == null || current != expected) {
      return EmailChangeCheckResult.notCompleted;
    }

    await _syncAfterEmailChange(refreshedUser);
    return EmailChangeCheckResult.completed;
  }

  /// ユーザードキュメントをリアルタイム監視するストリーム
  static Stream<AppUser?> watchUser(String uid) {
    return _firestore
        .collection(_collection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        try {
          return AppUser.fromJson(doc.data()!);
        } catch (e) {
          print('❌ ユーザー情報パースエラー: $e');
          return null;
        }
      }
      return null;
    });
  }
}
