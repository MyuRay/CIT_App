import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_management/user_management_model.dart';
import '../../models/admin/admin_model.dart';

class UserManagementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _usersCollection = 'users';
  static const String _adminPermissionsCollection = 'admin_permissions';
  static const String _userActivityCollection = 'user_activities';

  // ユーザー一覧を取得
  static Stream<List<AppUser>> getAllUsers({
    int? limit,
    bool? isActiveFilter,
    String? searchQuery,
  }) {
    Query query = _firestore.collection(_usersCollection)
        .orderBy('createdAt', descending: true);

    if (isActiveFilter != null) {
      query = query.where('isActive', isEqualTo: isActiveFilter);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      var users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id; // ドキュメントIDをuidとして使用
        return AppUser.fromJson(data);
      }).toList();

      // 検索フィルタリング（クライアントサイド）
      if (searchQuery?.isNotEmpty == true) {
        final query = searchQuery!.toLowerCase();
        users = users.where((user) {
          return user.email.toLowerCase().contains(query) ||
                 user.displayDisplayName.toLowerCase().contains(query) ||
                 user.uid.toLowerCase().contains(query);
        }).toList();
      }

      return users;
    });
  }

  // 特定ユーザーの詳細情報を取得
  static Future<AppUser?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['uid'] = doc.id;
        return AppUser.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ ユーザー詳細取得エラー: $e');
      rethrow;
    }
  }

  // ユーザー情報を更新
  static Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update(updates);
      print('✅ ユーザー情報を更新しました: $uid');
      
      // アクティビティログを記録
      await _logUserActivity(
        uid: _auth.currentUser?.uid ?? 'system',
        action: 'user_updated',
        details: 'Updated user: $uid',
      );
    } catch (e) {
      print('❌ ユーザー更新エラー: $e');
      rethrow;
    }
  }

  // ユーザーを無効化
  static Future<void> deactivateUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'isActive': false,
        'deactivatedAt': Timestamp.now(),
        'deactivatedBy': _auth.currentUser?.uid,
      });
      
      print('✅ ユーザーを無効化しました: $uid');
      
      await _logUserActivity(
        uid: _auth.currentUser?.uid ?? 'system',
        action: 'user_deactivated',
        details: 'Deactivated user: $uid',
      );
    } catch (e) {
      print('❌ ユーザー無効化エラー: $e');
      rethrow;
    }
  }

  // ユーザーを有効化
  static Future<void> activateUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'isActive': true,
        'reactivatedAt': Timestamp.now(),
        'reactivatedBy': _auth.currentUser?.uid,
      });
      
      print('✅ ユーザーを有効化しました: $uid');
      
      await _logUserActivity(
        uid: _auth.currentUser?.uid ?? 'system',
        action: 'user_activated',
        details: 'Activated user: $uid',
      );
    } catch (e) {
      print('❌ ユーザー有効化エラー: $e');
      rethrow;
    }
  }

  // 管理者権限を付与
  static Future<void> grantAdminPermission(String uid, {
    bool canManagePosts = false,
    bool canViewContacts = false,
    bool canManageUsers = false,
    bool canManageCategories = false,
  }) async {
    try {
      final adminPermission = AdminPermissions(
        userId: uid,
        isAdmin: true,
        canManagePosts: canManagePosts,
        canViewContacts: canViewContacts,
        canManageUsers: canManageUsers,
        canManageCategories: canManageCategories,
        grantedAt: DateTime.now(),
        grantedBy: _auth.currentUser?.uid ?? 'system',
      );

      await _firestore
          .collection(_adminPermissionsCollection)
          .doc(uid)
          .set(adminPermission.toJson());
      
      print('✅ 管理者権限を付与しました: $uid');
      
      await _logUserActivity(
        uid: _auth.currentUser?.uid ?? 'system',
        action: 'admin_granted',
        details: 'Granted admin to: $uid',
      );
    } catch (e) {
      print('❌ 管理者権限付与エラー: $e');
      rethrow;
    }
  }

  // 管理者権限を取り消し
  static Future<void> revokeAdminPermission(String uid) async {
    try {
      await _firestore
          .collection(_adminPermissionsCollection)
          .doc(uid)
          .delete();
      
      print('✅ 管理者権限を取り消しました: $uid');
      
      await _logUserActivity(
        uid: _auth.currentUser?.uid ?? 'system',
        action: 'admin_revoked',
        details: 'Revoked admin from: $uid',
      );
    } catch (e) {
      print('❌ 管理者権限取り消しエラー: $e');
      rethrow;
    }
  }

  // 管理者権限を更新
  static Future<void> updateAdminPermissions(String uid, AdminPermissions permissions) async {
    try {
      await _firestore
          .collection(_adminPermissionsCollection)
          .doc(uid)
          .update(permissions.toJson());
      
      print('✅ 管理者権限を更新しました: $uid');
      
      await _logUserActivity(
        uid: _auth.currentUser?.uid ?? 'system',
        action: 'admin_updated',
        details: 'Updated admin permissions for: $uid',
      );
    } catch (e) {
      print('❌ 管理者権限更新エラー: $e');
      rethrow;
    }
  }

  // ユーザーの管理者権限を取得
  static Future<AdminPermissions?> getUserAdminPermissions(String uid) async {
    try {
      final doc = await _firestore
          .collection(_adminPermissionsCollection)
          .doc(uid)
          .get();
      
      if (doc.exists) {
        return AdminPermissions.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ 管理者権限取得エラー: $e');
      rethrow;
    }
  }

  // ユーザー統計を取得
  static Future<UserStats> getUserStats() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);

      // 全ユーザー数
      final totalUsersSnapshot = await _firestore.collection(_usersCollection).get();
      final totalUsers = totalUsersSnapshot.size;

      // アクティブユーザー数
      final activeUsersSnapshot = await _firestore
          .collection(_usersCollection)
          .where('isActive', isEqualTo: true)
          .get();
      final activeUsers = activeUsersSnapshot.size;

      // 非アクティブユーザー数
      final inactiveUsers = totalUsers - activeUsers;

      // 今日の新規登録数
      final todayRegistrationsSnapshot = await _firestore
          .collection(_usersCollection)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .get();
      final todayRegistrations = todayRegistrationsSnapshot.size;

      // 今月の新規登録数
      final monthlyRegistrationsSnapshot = await _firestore
          .collection(_usersCollection)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .get();
      final monthlyRegistrations = monthlyRegistrationsSnapshot.size;

      return UserStats(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        inactiveUsers: inactiveUsers,
        todayRegistrations: todayRegistrations,
        monthlyRegistrations: monthlyRegistrations,
      );
    } catch (e) {
      print('❌ ユーザー統計取得エラー: $e');
      rethrow;
    }
  }

  // ユーザーアクティビティログを記録
  static Future<void> _logUserActivity({
    required String uid,
    required String action,
    String? details,
  }) async {
    try {
      final activity = UserActivity(
        uid: uid,
        action: action,
        timestamp: DateTime.now(),
        details: details,
      );

      await _firestore
          .collection(_userActivityCollection)
          .add(activity.toJson());
    } catch (e) {
      print('❌ アクティビティログ記録エラー: $e');
      // ログ記録の失敗は主処理には影響させない
    }
  }

  // ユーザーアクティビティ履歴を取得
  static Stream<List<UserActivity>> getUserActivities({
    String? uid,
    int? limit = 50,
  }) {
    Query query = _firestore
        .collection(_userActivityCollection)
        .orderBy('timestamp', descending: true);

    if (uid != null) {
      query = query.where('uid', isEqualTo: uid);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserActivity.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // ユーザーを検索
  static Future<List<AppUser>> searchUsers(String searchQuery) async {
    try {
      // Firestoreは複雑な文字列検索をサポートしていないため、
      // 全ユーザーを取得してクライアントサイドで検索
      final snapshot = await _firestore
          .collection(_usersCollection)
          .limit(1000) // 制限を設ける
          .get();

      final query = searchQuery.toLowerCase();
      final users = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['uid'] = doc.id;
            return AppUser.fromJson(data);
          })
          .where((user) {
            return user.email.toLowerCase().contains(query) ||
                   user.displayDisplayName.toLowerCase().contains(query) ||
                   user.uid.toLowerCase().contains(query);
          })
          .toList();

      return users;
    } catch (e) {
      print('❌ ユーザー検索エラー: $e');
      rethrow;
    }
  }
}