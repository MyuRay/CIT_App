import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/simple_auth_provider.dart';
import '../services/analytics_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/main/main_screen.dart';
import '../../screens/legal/terms_of_service_screen.dart';
import '../../screens/legal/privacy_policy_screen.dart';
import '../../screens/user_block/blocked_user_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // シンプルな認証プロバイダーを使用
  final isLoggedIn = ref.watch(isLoggedInSimpleProvider);
  final analyticsObserver = ref.watch(firebaseAnalyticsObserverProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      // 認証画面（ログイン/サインアップ等）と、誰でも見られる公開画面（規約/ポリシー）を分けて扱う
      final authPages = ['/login', '/signup', '/forgot-password'];
      final publicPages = ['/terms', '/privacy'];

      final loc = state.matchedLocation;
      final goingAuth = authPages.contains(loc);
      final goingPublic = publicPages.contains(loc);

      // 認証状態がまだ判定中（null）の場合
      if (isLoggedIn == null) {
        // 公開ページと認証ページへのアクセスは許可
        if (goingAuth || goingPublic) {
          return null;
        }
        // それ以外の場合は、初回起動時なのでリダイレクトしない
        // （認証状態が確定するまで待つ）
        return null;
      }

      // ログイン済みが認証画面へ行こうとしたらホームへ
      if (isLoggedIn && goingAuth) return '/home';

      // 未ログイン時は公開画面と認証画面のみ許可し、その他はサインアップへ
      if (!isLoggedIn && !(goingAuth || goingPublic)) return '/signup';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/terms',
        name: 'terms',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/blocked-users',
        name: 'blocked-users',
        builder: (context, state) => const BlockedUserListScreen(),
      ),
    ],
    observers: [analyticsObserver],
    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: const Text('エラー')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'ページが見つかりません',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(state.error.toString()),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('ホームに戻る'),
                ),
              ],
            ),
          ),
        ),
  );
});
