import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/user_management/user_management_model.dart';
import '../../models/admin/admin_model.dart';
import '../../services/user_management/user_management_service.dart';

// ユーザー一覧プロバイダー
final allUsersProvider = StreamProvider.family<List<AppUser>, UserListFilter>((ref, filter) {
  return UserManagementService.getAllUsers(
    limit: filter.limit,
    isActiveFilter: filter.isActiveFilter,
    searchQuery: filter.searchQuery,
  );
});

// ユーザー統計プロバイダー
final userStatsProvider = FutureProvider<UserStats>((ref) {
  return UserManagementService.getUserStats();
});

// 特定ユーザー詳細プロバイダー
final userDetailProvider = FutureProvider.family<AppUser?, String>((ref, uid) {
  return UserManagementService.getUserById(uid);
});

// ユーザーの管理者権限プロバイダー
final userAdminPermissionsProvider = FutureProvider.family<AdminPermissions?, String>((ref, uid) {
  return UserManagementService.getUserAdminPermissions(uid);
});

// ユーザーアクティビティプロバイダー
final userActivitiesProvider = StreamProvider.family<List<UserActivity>, String?>((ref, uid) {
  return UserManagementService.getUserActivities(uid: uid);
});

// ユーザー管理アクションプロバイダー
final userManagementActionsProvider = Provider<UserManagementActions>((ref) {
  return UserManagementActions(ref);
});

// ユーザーリストフィルター
class UserListFilter {
  final int? limit;
  final bool? isActiveFilter;
  final String? searchQuery;

  const UserListFilter({
    this.limit,
    this.isActiveFilter,
    this.searchQuery,
  });

  UserListFilter copyWith({
    int? limit,
    bool? isActiveFilter,
    String? searchQuery,
  }) {
    return UserListFilter(
      limit: limit ?? this.limit,
      isActiveFilter: isActiveFilter ?? this.isActiveFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ユーザー管理アクション
class UserManagementActions {
  final ProviderRef ref;

  UserManagementActions(this.ref);

  // ユーザーを更新
  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    await UserManagementService.updateUser(uid, updates);
    // 関連プロバイダーを更新
    ref.invalidate(userDetailProvider(uid));
    ref.invalidate(allUsersProvider);
    ref.invalidate(userStatsProvider);
  }

  // ユーザーを無効化
  Future<void> deactivateUser(String uid) async {
    await UserManagementService.deactivateUser(uid);
    // 関連プロバイダーを更新
    ref.invalidate(userDetailProvider(uid));
    ref.invalidate(allUsersProvider);
    ref.invalidate(userStatsProvider);
  }

  // ユーザーを有効化
  Future<void> activateUser(String uid) async {
    await UserManagementService.activateUser(uid);
    // 関連プロバイダーを更新
    ref.invalidate(userDetailProvider(uid));
    ref.invalidate(allUsersProvider);
    ref.invalidate(userStatsProvider);
  }

  // 管理者権限を付与
  Future<void> grantAdminPermission(String uid, {
    bool canManagePosts = false,
    bool canViewContacts = false,
    bool canManageUsers = false,
    bool canManageCategories = false,
  }) async {
    await UserManagementService.grantAdminPermission(
      uid,
      canManagePosts: canManagePosts,
      canViewContacts: canViewContacts,
      canManageUsers: canManageUsers,
      canManageCategories: canManageCategories,
    );
    // 関連プロバイダーを更新
    ref.invalidate(userAdminPermissionsProvider(uid));
    ref.invalidate(userDetailProvider(uid));
    ref.invalidate(allUsersProvider);
  }

  // 管理者権限を取り消し
  Future<void> revokeAdminPermission(String uid) async {
    await UserManagementService.revokeAdminPermission(uid);
    // 関連プロバイダーを更新
    ref.invalidate(userAdminPermissionsProvider(uid));
    ref.invalidate(userDetailProvider(uid));
    ref.invalidate(allUsersProvider);
  }

  // 管理者権限を更新
  Future<void> updateAdminPermissions(String uid, AdminPermissions permissions) async {
    await UserManagementService.updateAdminPermissions(uid, permissions);
    // 関連プロバイダーを更新
    ref.invalidate(userAdminPermissionsProvider(uid));
    ref.invalidate(userDetailProvider(uid));
  }

  // ユーザーを検索
  Future<List<AppUser>> searchUsers(String searchQuery) async {
    return await UserManagementService.searchUsers(searchQuery);
  }
}

// デフォルトのフィルター（全ユーザーを表示）
const defaultUserListFilter = UserListFilter();