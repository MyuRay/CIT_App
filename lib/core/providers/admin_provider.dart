import 'package:cit_app/core/utils/logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/admin/admin_model.dart';
import 'auth_provider.dart';

// 管理者権限プロバイダー（特定ユーザーID用）- StreamProvider に変更してリアルタイム監視
final adminPermissionsProvider = StreamProvider.autoDispose
    .family<AdminPermissions?, String>((ref, userId) {
      // 空のユーザーIDは無効
      if (userId.isEmpty) {
        SecureLogger.debug('⚠️ 管理者権限チェック: 空のユーザーID');
        return Stream.value(null);
      }

      SecureLogger.debug('🔍 管理者権限リアルタイム監視開始: $userId');

      return FirebaseFirestore.instance
          .collection('admin_permissions')
          .doc(userId)
          .snapshots()
          .map((doc) {
            if (doc.exists) {
              final data = {...doc.data()!, 'userId': userId};
              try {
                final permissions = AdminPermissions.fromJson(data);
                SecureLogger.debug(
                  '✅ 管理者権限発見: $userId -> isAdmin: ${permissions.isAdmin}',
                );
                return permissions;
              } catch (e) {
                if (data['isAdmin'] == true) {
                  return AdminPermissions.fromJson({
                    ...data,
                    'userId': data['userId'] ?? userId,
                    'grantedAt': data['grantedAt'] ?? Timestamp.now(),
                    'grantedBy': data['grantedBy'] ?? '',
                  });
                }
                return null;
              }
            }

            SecureLogger.debug('❌ 管理者権限なし: $userId');
            return null;
          });
    });

// Rebuild on authentication changes; an infinite Firestore stream must not block logout.
final currentUserAdminProvider = StreamProvider<AdminPermissions?>((ref) {
  return ref
      .watch(authStateProvider)
      .when(
        skipLoadingOnRefresh: false,
        skipLoadingOnReload: false,
        data: (user) {
          if (user == null) return Stream.value(null);
          return ref
              .watch(adminPermissionsProvider(user.uid))
              .when(
                skipLoadingOnRefresh: false,
                skipLoadingOnReload: false,
                data: (permissions) => Stream.value(permissions),
                loading: () => const Stream<AdminPermissions?>.empty(),
                error:
                    (error, stack) =>
                        Stream<AdminPermissions?>.error(error, stack),
              );
        },
        loading: () => const Stream<AdminPermissions?>.empty(),
        error: (error, stack) => Stream<AdminPermissions?>.error(error, stack),
      );
});
// 管理者かどうかの判定プロバイダー
final isAdminProvider = Provider<bool>((ref) {
  final adminPermissions = ref.watch(currentUserAdminProvider);
  return adminPermissions.when(
    data: (permissions) {
      final isAdmin = permissions?.isAdmin ?? false;
      SecureLogger.debug('🔍 isAdminProvider結果: $isAdmin');
      return isAdmin;
    },
    loading: () {
      SecureLogger.debug('🔄 isAdminProvider: ローディング中');
      return false;
    },
    error: (error, _) {
      SecureLogger.debug('❌ isAdminProvider エラー: $error');
      return false;
    },
  );
});

// デバッグ用：現在の認証状態と管理者権限を詳細表示
final debugAdminStatusProvider = Provider<String>((ref) {
  final authState = ref.watch(authStateProvider);
  final adminPermissions = ref.watch(currentUserAdminProvider);

  final authStatus = authState.when(
    data: (user) => user != null ? 'ログイン済み: ${user.uid}' : '未ログイン',
    loading: () => '認証確認中...',
    error: (error, _) => '認証エラー: $error',
  );

  final adminStatus = adminPermissions.when(
    data:
        (permissions) =>
            permissions != null
                ? '管理者権限: ${permissions.isAdmin ? "あり" : "なし"}'
                : '管理者権限: なし',
    loading: () => '管理者権限確認中...',
    error: (error, _) => '管理者権限エラー: $error',
  );

  return '$authStatus | $adminStatus';
});

// 各種権限チェック用プロバイダー
final canManagePostsProvider = Provider<bool>((ref) {
  final adminPermissions = ref.watch(currentUserAdminProvider);
  return adminPermissions.when(
    data: (permissions) => permissions?.canManagePosts ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

final canViewContactsProvider = Provider<bool>((ref) {
  final adminPermissions = ref.watch(currentUserAdminProvider);
  return adminPermissions.when(
    data: (permissions) => permissions?.canAccessContactManagement ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

final canManageUsersProvider = Provider<bool>((ref) {
  final adminPermissions = ref.watch(currentUserAdminProvider);
  return adminPermissions.when(
    data: (permissions) => permissions?.canManageUsers ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

// お問い合わせ一覧プロバイダー（管理者専用）
final contactFormsProvider = FutureProvider<List<ContactForm>>((ref) async {
  final canView = ref.watch(canViewContactsProvider);
  if (!canView) {
    throw Exception('お問い合わせ一覧を表示する権限がありません');
  }

  try {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('contact_forms')
            .orderBy('createdAt', descending: true)
            .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ContactForm.fromJson(data);
    }).toList();
  } catch (e) {
    SecureLogger.debug('お問い合わせ一覧取得エラー: $e');
    rethrow;
  }
});

// お問い合わせステータス更新サービス
class ContactFormService {
  static Future<void> updateStatus(String contactId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('contact_forms')
          .doc(contactId)
          .update({'status': newStatus, 'updatedAt': Timestamp.now()});
      SecureLogger.debug('お問い合わせステータス更新完了: $contactId -> $newStatus');
    } catch (e) {
      SecureLogger.debug('お問い合わせステータス更新エラー: $e');
      rethrow;
    }
  }

  static Future<void> addResponse(
    String contactId,
    String response,
    String adminId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('contact_forms')
          .doc(contactId)
          .update({
            'response': response,
            'respondedAt': Timestamp.now(),
            'respondedBy': adminId,
            'status': 'resolved',
          });
      SecureLogger.debug('お問い合わせ返信完了: $contactId');
    } catch (e) {
      SecureLogger.debug('お問い合わせ返信エラー: $e');
      rethrow;
    }
  }
}
