import 'package:cit_app/core/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin/admin_model.dart';

/// 管理者設定ヘルパー（開発用）
/// 本番環境では使用しないでください
class AdminSetupHelper {
  /// 現在のユーザーを管理者に設定（開発用）
  static Future<void> makeCurrentUserAdmin() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('ユーザーが認証されていません');
      }

      // 既に管理者権限があるかチェック
      final existingDoc =
          await FirebaseFirestore.instance
              .collection('admin_permissions')
              .doc(currentUser.uid)
              .get();

      if (existingDoc.exists) {
        final data = existingDoc.data()!;
        if (data['isAdmin'] == true) {
          SecureLogger.debug('✅ 既に管理者権限があります: ${currentUser.uid}');
          return;
        }
      }

      // 管理者権限を作成
      final adminPermissions = AdminPermissions(
        userId: currentUser.uid,
        isAdmin: true,
        canManagePosts: true,
        canManageUsers: true,
        canViewContacts: true,
        canManageCategories: true,
        grantedAt: DateTime.now(),
        grantedBy: 'system_setup',
      );

      await FirebaseFirestore.instance
          .collection('admin_permissions')
          .doc(currentUser.uid)
          .set(adminPermissions.toJson());

      SecureLogger.debug('✅ 管理者権限を付与しました: ${currentUser.uid}');
      SecureLogger.debug('📧 メールアドレス: ${currentUser.email}');
      SecureLogger.debug('👤 表示名: ${currentUser.displayName ?? "未設定"}');
    } catch (e) {
      SecureLogger.debug('❌ 管理者権限付与エラー: $e');
      rethrow;
    }
  }

  /// 指定したメールアドレスのユーザーを管理者に設定
  static Future<void> makeUserAdminByEmail(String email) async {
    try {
      // usersコレクションからメールアドレスでユーザーを検索
      final userQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('指定されたメールアドレスのユーザーが見つかりません: $email');
      }

      final userDoc = userQuery.docs.first;
      final userId = userDoc.id;
      final userData = userDoc.data();

      // 既に管理者権限があるかチェック
      final existingAdmin =
          await FirebaseFirestore.instance
              .collection('admin_permissions')
              .doc(userId)
              .get();

      if (existingAdmin.exists) {
        final data = existingAdmin.data()!;
        if (data['isAdmin'] == true) {
          SecureLogger.debug('✅ 既に管理者権限があります: $email ($userId)');
          return;
        }
      }

      // 現在のユーザーを実行者として設定
      final currentUser = FirebaseAuth.instance.currentUser;
      final grantedBy = currentUser?.uid ?? 'system_setup';

      // 管理者権限を作成
      final adminPermissions = AdminPermissions(
        userId: userId,
        isAdmin: true,
        canManagePosts: true,
        canManageUsers: true,
        canViewContacts: true,
        canManageCategories: true,
        grantedAt: DateTime.now(),
        grantedBy: grantedBy,
      );

      await FirebaseFirestore.instance
          .collection('admin_permissions')
          .doc(userId)
          .set(adminPermissions.toJson());

      SecureLogger.debug('✅ 管理者権限を付与しました:');
      SecureLogger.debug('  📧 メールアドレス: $email');
      SecureLogger.debug('  🆔 ユーザーID: $userId');
      SecureLogger.debug('  👤 表示名: ${userData['displayName'] ?? "未設定"}');
    } catch (e) {
      SecureLogger.debug('❌ 管理者権限付与エラー: $e');
      rethrow;
    }
  }

  /// 管理者一覧を表示
  static Future<void> listAdmins() async {
    try {
      final adminQuery =
          await FirebaseFirestore.instance
              .collection('admin_permissions')
              .where('isAdmin', isEqualTo: true)
              .get();

      if (adminQuery.docs.isEmpty) {
        SecureLogger.debug('📋 管理者が登録されていません');
        return;
      }

      SecureLogger.debug('📋 現在の管理者一覧:');
      SecureLogger.debug('=' * 50);

      for (final doc in adminQuery.docs) {
        final admin = AdminPermissions.fromJson(doc.data());

        // ユーザー詳細情報を取得
        try {
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(admin.userId)
                  .get();

          final userData =
              userDoc.exists ? userDoc.data()! : <String, dynamic>{};

          SecureLogger.debug('👤 ${userData['displayName'] ?? "名前未設定"}');
          SecureLogger.debug('  📧 ${userData['email'] ?? "メール未設定"}');
          SecureLogger.debug('  🆔 ${admin.userId}');
          SecureLogger.debug(
            '  📅 付与日: ${admin.grantedAt.year}/${admin.grantedAt.month.toString().padLeft(2, '0')}/${admin.grantedAt.day.toString().padLeft(2, '0')}',
          );
          SecureLogger.debug('  👨‍💼 付与者: ${admin.grantedBy}');
          SecureLogger.debug(
            '  ✅ 権限: 投稿管理(${admin.canManagePosts}) ユーザー管理(${admin.canManageUsers}) お問い合わせ(${admin.canViewContacts})',
          );
          SecureLogger.debug('-' * 30);
        } catch (e) {
          SecureLogger.debug('👤 ユーザーID: ${admin.userId}');
          SecureLogger.debug('  ⚠️ ユーザー詳細取得エラー: $e');
          SecureLogger.debug('-' * 30);
        }
      }
    } catch (e) {
      SecureLogger.debug('❌ 管理者一覧取得エラー: $e');
      rethrow;
    }
  }

  /// 管理者権限を削除
  static Future<void> removeAdminPermissions(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('admin_permissions')
          .doc(userId)
          .delete();

      SecureLogger.debug('✅ 管理者権限を削除しました: $userId');
    } catch (e) {
      SecureLogger.debug('❌ 管理者権限削除エラー: $e');
      rethrow;
    }
  }
}

/// デバッグ用管理者セットアップ
///
/// 使用例:
/// ```dart
/// // 現在のユーザーを管理者にする
/// await AdminSetupHelper.makeCurrentUserAdmin();
///
/// // メールアドレスで管理者を作成
/// await AdminSetupHelper.makeUserAdminByEmail('admin@s.chibakoudai.jp');
///
/// // 管理者一覧表示
/// await AdminSetupHelper.listAdmins();
/// ```
class DebugAdminSetup {
  /// デバッグコンソールでの使用例を表示
  static void showUsageExample() {
    SecureLogger.debug('🔧 管理者セットアップヘルパー - 使用例');
    SecureLogger.debug('=' * 50);
    SecureLogger.debug('// 現在のユーザーを管理者にする');
    SecureLogger.debug('await AdminSetupHelper.makeCurrentUserAdmin();');
    SecureLogger.debug('');
    SecureLogger.debug('// メールアドレスで管理者を作成');
    SecureLogger.debug(
      'await AdminSetupHelper.makeUserAdminByEmail("admin@s.chibakoudai.jp");',
    );
    SecureLogger.debug('');
    SecureLogger.debug('// 管理者一覧表示');
    SecureLogger.debug('await AdminSetupHelper.listAdmins();');
    SecureLogger.debug('');
    SecureLogger.debug('// 管理者権限削除');
    SecureLogger.debug('await AdminSetupHelper.removeAdminPermissions("user_id");');
    SecureLogger.debug('=' * 50);
  }
}
