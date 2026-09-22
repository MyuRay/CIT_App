import 'package:cit_app/core/utils/logger.dart';
import 'services/widget/home_widget_destination.dart';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'widgets/common/app_system_safe_area.dart';
import 'widgets/common/ui_feedback_listener.dart';
import 'widgets/common/app_update_prompt.dart';
import 'core/config/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/auth_session_provider.dart';
import 'core/providers/analytics_provider.dart';
import 'core/providers/app_update_provider.dart';
import 'core/services/analytics_service.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/performance_monitor.dart';
import 'core/services/cache_service.dart';
import 'core/services/simple_offline_service.dart';
import 'core/services/app_review_service.dart';
import 'services/cafeteria/menu_scheduler_service.dart';
import 'package:home_widget/home_widget.dart';
import 'services/widget/home_widgets_service.dart';
import 'services/notification/notification_service.dart';
import 'services/schedule/schedule_notification_service.dart';
import 'utils/auth_storage_reconciler.dart';

// バックグラウンド通知ハンドラー（トップレベル関数として定義）
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  SecureLogger.debug('🔔 バックグラウンド通知を受信: ${message.messageId}');
  SecureLogger.debug('バックグラウンド通知イベントを受信しました');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    SecureLogger.debug('Uncaught error: $error');
    SecureLogger.debug(stack.toString());
    return false;
  };

  ErrorWidget.builder = (details) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth =
            constraints.hasBoundedWidth
                ? constraints.maxWidth.clamp(0.0, 480.0)
                : 480.0;

        return Material(
          color: Colors.red.shade50,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'エラーが発生しました',
                        style: GoogleFonts.notoSansJp(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        details.exceptionAsString(),
                        style: GoogleFonts.notoSansJp(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  };

  // パフォーマンス監視開始
  final monitor = PerformanceMonitor();
  monitor.startTimer('app_startup');

  // SharedPreferences初期化
  final prefs = await SharedPreferences.getInstance();

  // 非同期初期化を並行実行して起動時間を短縮
  final initializationFutures = <Future>[
    // キャッシュサービス初期化
    CacheService().initialize(),
    // オフラインサービス初期化
    SimpleOfflineService().initialize(),
  ];

  // 並行初期化を開始（Firebase初期化と並行で実行）

  // Firebase初期化
  try {
    SecureLogger.debug('=== Firebase初期化開始 ===');
    SecureLogger.debug('Platform: ${kIsWeb ? "Web" : "Mobile"}');
    SecureLogger.debug('初期化前のFirebase apps数: ${Firebase.apps.length}');

    if (kIsWeb) {
      SecureLogger.debug('Web版Firebase初期化開始');

      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDopjve0NaYSyuRv8DCFSInY-FVPlyqGSg",
          authDomain: "cit-app-2de1c.firebaseapp.com",
          databaseURL: "https://cit-app-2de1c-default-rtdb.firebaseio.com",
          projectId: "cit-app-2de1c",
          storageBucket: "cit-app-2de1c.firebasestorage.app",
          messagingSenderId: "196876028875",
          appId: "1:196876028875:web:b3798c03497fc944a1444e",
          measurementId: "G-21MB6BYBTE",
        ),
      );
      SecureLogger.debug('Web版Firebase初期化完了');
    } else {
      SecureLogger.debug('モバイル版Firebase初期化開始');
      // 既に初期化されている場合はスキップ
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        SecureLogger.debug('モバイル版Firebase初期化完了');
      } else {
        SecureLogger.debug('Firebaseは既に初期化済みです');
      }

      // バックグラウンド通知ハンドラーを設定
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      SecureLogger.debug('🔔 バックグラウンド通知ハンドラーを設定しました');
    }

    // Firebase Auth永続化設定の強化
    final auth = FirebaseAuth.instance;
    try {
      SecureLogger.debug('Firebase Auth永続化設定開始');

      // 認証状態の復元をより確実にするための待機
      SecureLogger.debug('認証状態復元を待機中...');

      // authStateChanges を一度だけ監視して認証状態が安定するまで待つ
      bool authStateResolved = false;
      User? resolvedUser;

      final subscription = auth.authStateChanges().listen((user) {
        if (!authStateResolved) {
          resolvedUser = user;
          authStateResolved = true;
          SecureLogger.debug('認証状態解決: ${user != null ? user.uid : "未ログイン"}');
        }
      });

      // 最大3秒まで認証状態の復元を待つ
      int waitCount = 0;
      while (!authStateResolved && waitCount < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }

      await subscription.cancel();

      if (authStateResolved) {
        SecureLogger.debug(
          'Firebase Auth認証状態復元完了: ${resolvedUser != null ? "ログイン済み" : "未ログイン"}',
        );
      } else {
        SecureLogger.debug('⚠️ Firebase Auth認証状態復元がタイムアウトしました');
      }
    } catch (persistenceError) {
      SecureLogger.debug('Firebase Auth永続化設定警告: $persistenceError');
      // 永続化設定エラーでもアプリは継続
    }

    // SDK の認証状態と食い違う旧アプリ独自のログイン表示キャッシュを整理
    await AuthStorageReconciler.reconcileAfterFirebaseInit();

    // 現在のユーザー状態をログで確認
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      SecureLogger.debug('✅ 既存ユーザーセッション検出: ${currentUser.uid}');
      SecureLogger.debug('✅ ユーザーメール: ${currentUser.email}');
      SecureLogger.debug('✅ メール認証済み: ${currentUser.emailVerified}');

      // ログイン済みユーザーのプッシュ通知を初期化
      try {
        SecureLogger.debug('🔔 プッシュ通知サービス初期化開始');
        await NotificationService.initialize();
        SecureLogger.debug('🔔 プッシュ通知サービス初期化完了');
      } catch (notificationError) {
        SecureLogger.debug('⚠️ プッシュ通知初期化エラー: $notificationError');
        // プッシュ通知エラーでもアプリは継続
      }
    } else {
      SecureLogger.debug('❌ 既存ユーザーセッションなし（未ログイン状態）');
    }

    SecureLogger.debug('Firebase初期化成功');
    SecureLogger.debug('初期化後のFirebase apps数: ${Firebase.apps.length}');
    SecureLogger.debug(
      'Firebase app names: ${Firebase.apps.map((app) => app.name).toList()}',
    );

    // Firebase Analytics初期化と設定
    try {
      final analytics = FirebaseAnalytics.instance;

      // Respect the device's saved preference, including after app restart.
      await analytics.setAnalyticsCollectionEnabled(
        prefs.getBool(analyticsCollectionPreferenceKey) ?? true,
      );

      // デバッグモードでDebug Viewを有効化
      if (kDebugMode) {
        // Android: ADBコマンドで有効化が必要
        // adb shell setprop debug.firebase.analytics.app jp.ac.chibakoudai.citapp
        // iOS: Xcodeのスキーム設定で -FIRDebugEnabled を追加
        SecureLogger.debug('🔍 Firebase Analytics Debug Mode');
        SecureLogger.debug('📱 Android: ADBコマンドを実行してください:');
        SecureLogger.debug(
          '   adb shell setprop debug.firebase.analytics.app jp.ac.chibakoudai.citapp',
        );
        SecureLogger.debug('🍎 iOS: Xcodeのスキーム設定で -FIRDebugEnabled を追加してください');
      }

      // app_open is sent by analyticsSessionSyncProvider after user attributes.
    } catch (analyticsError) {
      SecureLogger.debug('❌ Firebase Analytics ログ送信失敗: $analyticsError');
    }

    // Firebase App Check: Web はビルド時に reCAPTCHA キーが設定された場合のみ有効化する。
    // ローカル開発でダミーキーを渡すと非同期エラーが残り続けるため、未設定時は明示的にスキップする。
    try {
      SecureLogger.debug('Firebase App Check初期化開始');
      var appCheckActivated = false;
      if (kIsWeb) {
        const webRecaptchaSiteKey = String.fromEnvironment(
          'FIREBASE_RECAPTCHA_SITE_KEY',
        );
        if (webRecaptchaSiteKey.isEmpty) {
          SecureLogger.debug(
            'Firebase App Check: FIREBASE_RECAPTCHA_SITE_KEY が未設定のためWebではスキップ',
          );
        } else {
          await FirebaseAppCheck.instance.activate(
            webProvider: ReCaptchaV3Provider(webRecaptchaSiteKey),
          );
          appCheckActivated = true;
        }
      } else {
        await FirebaseAppCheck.instance.activate(
          androidProvider:
              kDebugMode
                  ? AndroidProvider.debug
                  : AndroidProvider.playIntegrity,
          appleProvider:
              kDebugMode
                  ? AppleProvider.debug
                  : AppleProvider.appAttestWithDeviceCheckFallback,
        );
        appCheckActivated = true;
      }
      if (appCheckActivated) {
        SecureLogger.debug('Firebase App Check初期化完了');
      }

      if (kDebugMode && appCheckActivated && !kIsWeb) {
        try {
          final debugToken = await FirebaseAppCheck.instance
              .getToken()
              .timeout(const Duration(seconds: 5));
          if (debugToken != null && debugToken.isNotEmpty) {
            SecureLogger.debug(
              '🔐 App Check debug token（Firebase Console → App Check → デバッグトークン管理）: $debugToken',
            );
          }
        } catch (tokenError) {
          SecureLogger.debug('App Check debug token 取得スキップ: $tokenError');
        }
      }
    } catch (appCheckError) {
      SecureLogger.debug('Firebase App Check初期化警告: $appCheckError');
    }

    // Firebase Storage接続テスト（ネットワーク状況を考慮）
    if (Firebase.apps.isNotEmpty) {
      SecureLogger.debug('Firebase Storage接続テスト実行中...');
      try {
        final storage = FirebaseStorage.instance;
        // ネットワーク接続のタイムアウト設定
        storage.setMaxOperationRetryTime(const Duration(seconds: 10));
        storage.setMaxUploadRetryTime(const Duration(seconds: 10));
        storage.setMaxDownloadRetryTime(const Duration(seconds: 10));

        final testRef = storage.ref().child('test/initialization_test.txt');
        SecureLogger.debug('Firebase Storage テスト参照作成成功: ${testRef.fullPath}');
      } catch (storageError) {
        SecureLogger.debug('Firebase Storage テスト失敗 (ネットワーク問題の可能性): $storageError');
        // ネットワーク接続問題はアプリ起動を阻害しない
      }
    }
  } catch (e, stackTrace) {
    SecureLogger.debug('Firebase初期化失敗: $e');
    SecureLogger.debug('StackTrace: $stackTrace');
    // Firebase未設定でもアプリは動作継続
  }

  // 並行初期化の完了を待つ
  try {
    await Future.wait(initializationFutures);
  } catch (e) {
    SecureLogger.debug('初期化サービスエラー: $e');
    // エラーでもアプリ起動を継続
  }

  // バックグラウンドで遅延初期化を実行（起動時間に影響しない）
  _initializeBackgroundServices();

  // アプリ起動時間を記録
  final startupTime = monitor.stopTimer('app_startup');
  SecureLogger.debug('🚀 アプリ起動完了: ${startupTime}ms');

  // フレームレート監視開始
  if (kDebugMode) {
    monitor.startFrameRateMonitoring();
  }

  // ウィジェットから起動した場合は時間割タブを開く
  String initialRoute = '/home';
  if (!kIsWeb) {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      initialRoute = homeWidgetDestination(uri) ?? initialRoute;
    } catch (_) {}

    // Flutter Engine 経由で渡された defaultRouteName もチェックする
    // (Android のホーム画面ウィジェットから cold start した時、
    //  intent.data の `citapp://schedule` がここに渡るケースがある)
    try {
      final defaultRoute =
          PlatformDispatcher.instance.defaultRouteName.toLowerCase();
      initialRoute = homeWidgetDestination(Uri.tryParse(defaultRoute)) ?? initialRoute;
    } catch (_) {}
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialRouteFromWidgetProvider.overrideWithValue(initialRoute),
      ],
      child: const CITApp(),
    ),
  );
}

/// バックグラウンドサービスの遅延初期化
void _initializeBackgroundServices() {
  // 遅延実行でアプリ起動に影響しないように
  Future.delayed(const Duration(seconds: 2), () async {
    try {
      // メニュー自動更新（端末側タイマー）は MenuSchedulerService.scheduledUpdatesEnabled で制御
      MenuSchedulerService.startScheduledUpdates();

      if (!kIsWeb) {
        // ホームウィジェットとローカル講義通知はモバイル専用。
        await HomeWidgetsService.initialize();
        await ScheduleNotificationService.initialize();
      }

      SecureLogger.debug('✅ バックグラウンドサービス初期化完了');
    } catch (e) {
      SecureLogger.debug('⚠️ バックグラウンドサービス初期化エラー: $e');
    }
  });
}

/// ストアレビュー管理：起動回数をカウントし、条件を満たしたらレビューを促す
void _handleAppReview() {
  // 遅延実行でアプリ起動に影響しないように
  Future.delayed(const Duration(seconds: 3), () async {
    try {
      // 起動回数をカウント
      await AppReviewService.incrementLaunchCount();

      // レビューを促すべきかチェック
      final shouldRequest = await AppReviewService.shouldRequestReview();
      if (shouldRequest) {
        // レビューを表示
        await AppReviewService.requestReview();
      }
    } catch (e) {
      SecureLogger.debug('⚠️ ストアレビュー処理エラー: $e');
    }
  });
}

class CITApp extends ConsumerStatefulWidget {
  const CITApp({super.key});

  @override
  ConsumerState<CITApp> createState() => _CITAppState();
}

class _CITAppState extends ConsumerState<CITApp> with WidgetsBindingObserver {
  StreamSubscription<Uri?>? _homeWidgetClickSubscription;

  @override
  void initState() {
    super.initState();
    // アプリライフサイクル監視を開始
    WidgetsBinding.instance.addObserver(this);
    // ウィジェットタップ時（アプリ起動中）に時間割タブへ遷移
    if (!kIsWeb) {
      _homeWidgetClickSubscription = HomeWidget.widgetClicked.listen((uri) {
        final destination = homeWidgetDestination(uri);
        if (destination != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(routerProvider).go(destination);
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _homeWidgetClickSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        SecureLogger.debug('🔄 アプリ再開: 認証状態を確認中...');
        // アプリが再開された時に認証状態を強制チェック
        _checkAuthenticationOnResume();
        break;
      case AppLifecycleState.paused:
        SecureLogger.debug('⏸️ アプリ一時停止: 最終アクセス時刻を更新');
        // アプリが一時停止された時に最終アクセス時刻を更新
        _updateLastAccessOnPause();
        break;
      case AppLifecycleState.detached:
        SecureLogger.debug('🔚 アプリ終了');
        break;
      case AppLifecycleState.inactive:
        SecureLogger.debug('😴 アプリ非アクティブ');
        break;
      case AppLifecycleState.hidden:
        SecureLogger.debug('👁️‍🗨️ アプリ非表示');
        break;
    }
  }

  /// アプリ再開時の認証状態確認
  void _checkAuthenticationOnResume() {
    try {
      // Firebase Auth が自動的に認証状態を復元するため、特別な処理は不要
      SecureLogger.debug('✅ アプリ再開: Firebase Auth による自動復元を待機');

      // ログイン中なら FCM トークンを再登録しておく。
      // 端末側でトークンが更新されてもアプリ起動中でないと
      // onTokenRefresh を取りこぼし、サーバーが古いトークンに送って
      // 「通知が来ない」状態になるのを防ぐ。
      if (FirebaseAuth.instance.currentUser != null) {
        NotificationService.refreshTokenRegistration();
      }
    } catch (e) {
      SecureLogger.debug('⚠️ アプリ再開時認証チェックエラー: $e');
    }
  }

  /// アプリ一時停止時の処理
  void _updateLastAccessOnPause() {
    try {
      // Firebase Auth が自動的に状態を保存するため、特別な処理は不要
      SecureLogger.debug('✅ アプリ一時停止: Firebase Auth による自動保存');
    } catch (e) {
      SecureLogger.debug('⚠️ アプリ一時停止処理エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authSessionSyncProvider);
    ref.watch(analyticsSessionSyncProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appFontSize = ref.watch(appFontSizeProvider);
    final navigatorKey = ref.watch(appNavigatorKeyProvider);
    final updateObserver = ref.watch(appUpdateObserverProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final theme = Theme.of(context);
        final defaultTextStyle =
            theme.textTheme.bodyMedium ?? const TextStyle();
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(appFontSize.textScale),
          ),
          child: DefaultTextStyle(
            style: defaultTextStyle,
            child: AppSystemSafeArea(
              child: AppUpdatePromptHost(
                navigatorKey: navigatorKey,
                observer: updateObserver,
                checkForUpdate: () => ref.read(appUpdateCheckProvider.future),
                onNoUpdate: _handleAppReview,
                child: UiFeedbackListener(child: child ?? const SizedBox.shrink()),
              ),
            ),
          ),
        );
      },
    );
  }
}
