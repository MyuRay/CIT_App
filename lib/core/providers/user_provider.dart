import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/user/user_model.dart';
import '../../services/user/user_service.dart';
import 'auth_provider.dart';

// 現在のユーザー情報プロバイダー
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (firebaseUser) async {
      if (firebaseUser == null) return null;
      return await UserService.getCurrentUserOrCreate();
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// 特定ユーザー情報プロバイダー（ファミリー）
final userProvider = FutureProvider.family<AppUser?, String>((ref, uid) async {
  return await UserService.getUser(uid);
});

// ユーザー情報管理のStateNotifier
class UserNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  UserNotifier() : super(const AsyncValue.loading());

  /// ユーザー情報を読み込み
  Future<void> loadCurrentUser() async {
    try {
      state = const AsyncValue.loading();
      final user = await UserService.getCurrentUserOrCreate();
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// プロフィールを更新
  Future<void> updateProfile({
    String? displayName,
    String? department,
    String? studentId,
    int? graduationYear,
  }) async {
    try {
      final currentUser = state.value;
      if (currentUser == null) {
        throw Exception('ユーザー情報が読み込まれていません');
      }

      await UserService.updateUserProfile(
        uid: currentUser.uid,
        displayName: displayName,
        department: department,
        studentId: studentId,
        graduationYear: graduationYear,
      );

      // 更新後のユーザー情報を再読み込み
      await loadCurrentUser();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// ユーザー情報を再読み込み
  Future<void> refresh() async {
    await loadCurrentUser();
  }
}

// UserNotifierプロバイダー
final userNotifierProvider = StateNotifierProvider<UserNotifier, AsyncValue<AppUser?>>((ref) {
  return UserNotifier();
});