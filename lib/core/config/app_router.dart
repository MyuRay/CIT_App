import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/simple_auth_provider.dart';
import '../services/analytics_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/email_verification_screen.dart';
import '../../screens/profile/change_email_screen.dart';
import '../../screens/profile/change_email_verification_screen.dart';
import '../../screens/main/main_screen.dart';
import '../../screens/legal/terms_of_service_screen.dart';
import '../../screens/legal/privacy_policy_screen.dart';
import '../../screens/user_block/blocked_user_list_screen.dart';
import '../../screens/classroom_map/classroom_map_calibration_screen.dart';
import '../../screens/classroom_map/classroom_map_screen.dart';

/// ウィジェットから起動時の初期ルート（override用）
final initialRouteFromWidgetProvider = Provider<String>((ref) => '/home');

final routerProvider = Provider<GoRouter>((ref) {
  // シンプルな認証プロバイダーを使用
  final isLoggedIn = ref.watch(isLoggedInSimpleProvider);
  final isEmailVerified = ref.watch(isEmailVerifiedSyncProvider);
  final currentUser = ref.watch(currentUserSimpleProvider);
  final analyticsObserver = ref.watch(firebaseAnalyticsObserverProvider);
  final initialRoute = ref.watch(initialRouteFromWidgetProvider);

  return GoRouter(
    initialLocation: initialRoute,
    redirect: (context, state) {
      // 認証画面（ログイン/サインアップ等）と、誰でも見られる公開画面（規約/ポリシー）を分けて扱う
      final authPages = ['/login', '/signup', '/forgot-password'];
      final publicPages = ['/terms', '/privacy'];
      final verificationPage = '/email-verification';
      final changeEmailPages = ['/change-email', '/change-email-verification'];

      final loc = state.matchedLocation;
      final goingAuth = authPages.contains(loc);
      final goingPublic = publicPages.contains(loc);
      final goingVerification = loc == verificationPage;
      final goingChangeEmail = changeEmailPages.contains(loc);

      // Android のホーム画面ウィジェットや citapp:// スキームから
      // 渡される時間割系ディープリンクを正規化する。
      // (例) `citapp://schedule`, `/schedule`, `schedule://...`
      final fullLocation = state.uri.toString();
      final lowerFull = fullLocation.toLowerCase();
      final lowerLoc = loc.toLowerCase();
      final isScheduleDeepLink =
          lowerLoc == '/schedule' ||
          lowerFull.startsWith('citapp://schedule') ||
          lowerFull.startsWith('schedule://') ||
          lowerFull.contains('://schedule');
      if (isScheduleDeepLink && loc != '/home') {
        return '/home?tab=schedule';
      }

      // 認証状態がまだ判定中（null）の場合
      if (isLoggedIn == null || isEmailVerified == null) {
        // 公開ページと認証ページへのアクセスは許可
        if (goingAuth || goingPublic || goingVerification || goingChangeEmail) {
          return null;
        }
        // それ以外の場合は、初回起動時なのでリダイレクトしない
        // （認証状態が確定するまで待つ）
        return null;
      }

      // ログイン済みの場合
      if (isLoggedIn) {
        // メール認証が未完了の場合
        if (!isEmailVerified && currentUser != null) {
          // 認証待ち画面以外にアクセスしようとしたら認証待ち画面へ
          if (!goingVerification && !goingPublic) {
            return verificationPage;
          }
        } else {
          // メール認証済みの場合、認証画面や認証待ち画面へ行こうとしたらホームへ
          if (goingAuth || goingVerification) {
            return '/home';
          }
          // メール変更画面は旧ドメイン等のユーザーのみ（新ドメインは不要）
          if (goingChangeEmail) {
            if (AppConstants.hasChibatechEmailDomain(currentUser?.email)) {
              return '/home';
            }
            return null;
          }
        }
      }

      // 未ログイン時は公開画面と認証画面のみ許可
      if (!isLoggedIn) {
        if (goingAuth || goingPublic) return null;
        // メール変更フロー中にセッションが切れた場合はログインへ
        if (goingChangeEmail) return '/login';
        return '/signup';
      }

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
        path: '/email-verification',
        name: 'email-verification',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/change-email',
        name: 'change-email',
        builder: (context, state) => const ChangeEmailScreen(),
      ),
      GoRoute(
        path: '/change-email-verification',
        name: 'change-email-verification',
        builder: (context, state) => const ChangeEmailVerificationScreen(),
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
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          final initialTabIndex = switch (tab) {
            'schedule' => 1,
            'community' => 2,
            _ => 0,
          };
          return MainScreen(initialTabIndex: initialTabIndex);
        },
      ),
      // ホーム画面ウィジェット (今日の時間割) からのディープリンク
      // `citapp://schedule` や `/schedule` を時間割タブに誘導する
      GoRoute(
        path: '/schedule',
        name: 'schedule-shortcut',
        redirect: (context, state) => '/home?tab=schedule',
      ),
      GoRoute(
        path: '/blocked-users',
        name: 'blocked-users',
        builder: (context, state) => const BlockedUserListScreen(),
      ),
      GoRoute(
        path: '/classroom-map',
        name: 'classroom-map',
        builder: (context, state) {
          final campus = state.uri.queryParameters['campus'];
          final rawQ = state.uri.queryParameters['q'];
          final trimmedQ =
              rawQ == null ? null : rawQ.trim().isEmpty ? null : rawQ.trim();
          return ClassroomMapScreen(
            initialCampusId: campus,
            initialSearchQuery: trimmedQ,
          );
        },
      ),
      if (kDebugMode)
        GoRoute(
          path: '/debug/classroom-map-calibration',
          name: 'debug-classroom-map-calibration',
          builder: (context, state) => const ClassroomMapCalibrationScreen(),
        ),
    ],
    observers: [analyticsObserver],
    errorBuilder: (context, state) {
      // 想定外のディープリンクで到達した場合は、可能な限り意味のあるタブへ
      // 自動フォールバックする。特にホーム画面ウィジェット由来の
      // `citapp://schedule` 等を「ページが見つかりません」で止めない。
      final raw = state.uri.toString().toLowerCase();
      final fallback = raw.contains('schedule') ? '/home?tab=schedule' : '/home';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(fallback);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    },
  );
});
