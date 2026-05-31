import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/admin/admin_model.dart';
import 'auth_provider.dart';

// 管理者権限プロバイダー（特定ユーザーID用）- StreamProvider に変更してリアルタイム監視
final adminPermissionsProvider = StreamProvider.family<AdminPermissions?, String>((ref, userId) {
  // 空のユーザーIDは無効
  if (userId.isEmpty) {
    print('⚠️ 管理者権限チェック: 空のユーザーID');
    return Stream.value(null);
  }
  
  print('🔍 管理者権限リアルタイム監視開始: $userId');
  
  return FirebaseFirestore.instance
      .collection('admin_permissions')
      .doc(userId)
      .snapshots()
      .map((doc) {
    if (doc.exists) {
      final data = doc.data()!;
      try {
        final permissions = AdminPermissions.fromJson(data);
        print('✅ 管理者権限発見: $userId -> isAdmin: ${permissions.isAdmin}');
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
    
    print('❌ 管理者権限なし: $userId');
    return null;
  }).handleError((e) {
    print('❌ 管理者権限取得エラー: $userId -> $e');
    return null;
  });
});

// 現在ユーザーの管理者権限プロバイダー - Firebase Authから直接ストリームを作成
final currentUserAdminProvider = StreamProvider<AdminPermissions?>((ref) {
  // Firebase Authの認証状態を直接監視
  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) {
      print('🔐 ユーザー未認証: 管理者権限なし');
      return Stream.value(null);
    }
    
    print('🔐 認証済みユーザー: ${user.uid}');
    // Firestoreから管理者権限をリアルタイム監視
    return FirebaseFirestore.instance
        .collection('admin_permissions')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        print('🔍 プロバイダー取得データ: $data');
        
        try {
          final permissions = AdminPermissions.fromJson(data);
          print('✅ 現在ユーザー管理者権限パース成功: ${user.uid} -> isAdmin: ${permissions.isAdmin}');
          return permissions;
        } catch (parseError) {
          print('❌ AdminPermissions.fromJsonパースエラー: $parseError');
          print('❌ 問題のあるデータ: $data');
          if (data['isAdmin'] == true) {
            return AdminPermissions.fromJson({
              ...data,
              'userId': data['userId'] ?? user.uid,
              'grantedAt': data['grantedAt'] ?? Timestamp.now(),
              'grantedBy': data['grantedBy'] ?? '',
            });
          }
          return null;
        }
      }
      print('❌ 現在ユーザー管理者権限なし: ${user.uid}');
      return null;
    }).handleError((e) {
      print('❌ 現在ユーザー管理者権限ストリームエラー: ${user.uid} -> $e');
      return null;
    });
  });
});

// 管理者かどうかの判定プロバイダー
final isAdminProvider = Provider<bool>((ref) {
  final adminPermissions = ref.watch(currentUserAdminProvider);
  return adminPermissions.when(
    data: (permissions) {
      final isAdmin = permissions?.isAdmin ?? false;
      print('🔍 isAdminProvider結果: $isAdmin');
      return isAdmin;
    },
    loading: () {
      print('🔄 isAdminProvider: ローディング中');
      return false;
    },
    error: (error, _) {
      print('❌ isAdminProvider エラー: $error');
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
    data: (permissions) => permissions != null 
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
    final querySnapshot = await FirebaseFirestore.instance
        .collection('contact_forms')
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ContactForm.fromJson(data);
    }).toList();
  } catch (e) {
    print('お問い合わせ一覧取得エラー: $e');
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
          .update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });
      print('お問い合わせステータス更新完了: $contactId -> $newStatus');
    } catch (e) {
      print('お問い合わせステータス更新エラー: $e');
      rethrow;
    }
  }

  static Future<void> addResponse(String contactId, String response, String adminId) async {
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
      print('お問い合わせ返信完了: $contactId');
    } catch (e) {
      print('お問い合わせ返信エラー: $e');
      rethrow;
    }
  }
}