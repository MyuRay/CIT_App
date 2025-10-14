import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user/user_model.dart';

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
    );
  }

  /// 現在のユーザー情報を取得（存在しない場合は作成）
  static Future<AppUser?> getCurrentUserOrCreate() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;

    // 既存ユーザー情報を取得
    AppUser? existingUser = await getUser(firebaseUser.uid);
    
    if (existingUser != null) {
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
    String? department,
    String? studentId,
    int? graduationYear,
  }) async {
    try {
      final existingUser = await getUser(uid);
      if (existingUser == null) {
        throw Exception('ユーザーが見つかりません');
      }

      final updatedUser = existingUser.copyWith(
        displayName: displayName,
        department: department,
        studentId: studentId,
        graduationYear: graduationYear,
        updatedAt: DateTime.now(),
      );

      await updateUser(updatedUser);
    } catch (e) {
      print('❌ プロフィール更新エラー: $e');
      rethrow;
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
}