import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/simple_auth_provider.dart';
import 'core/services/performance_monitor.dart';
import 'core/services/cache_service.dart';
import 'core/services/simple_offline_service.dart';
import 'core/services/app_review_service.dart';
import 'services/cafeteria/menu_scheduler_service.dart';
import 'package:home_widget/home_widget.dart';
import 'services/widget/home_widgets_service.dart';
import 'services/notification/notification_service.dart';
import 'services/schedule/schedule_notification_service.dart';
import 'services/firebase/firebase_menu_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

// バックグラウンド通知ハンドラー（トップレベル関数として定義）
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 バックグラウンド通知を受信: ${message.messageId}');
  debugPrint('🔔 タイトル: ${message.notification?.title}');
  debugPrint('🔔 本文: ${message.notification?.body}');
  debugPrint('🔔 データ: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrint(stack.toString());
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
                      const Text(
                        'エラーが発生しました',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        details.exceptionAsString(),
                        style: const TextStyle(
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
    debugPrint('=== Firebase初期化開始 ===');
    debugPrint('Platform: ${kIsWeb ? "Web" : "Mobile"}');
    debugPrint('初期化前のFirebase apps数: ${Firebase.apps.length}');

    if (kIsWeb) {
      debugPrint('Web版Firebase初期化開始');

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
      debugPrint('Web版Firebase初期化完了');
    } else {
      debugPrint('モバイル版Firebase初期化開始');
      // 既に初期化されている場合はスキップ
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        debugPrint('モバイル版Firebase初期化完了');
      } else {
        debugPrint('Firebaseは既に初期化済みです');
      }

      // バックグラウンド通知ハンドラーを設定
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      debugPrint('🔔 バックグラウンド通知ハンドラーを設定しました');
    }

    // Firebase Auth永続化設定の強化
    final auth = FirebaseAuth.instance;
    try {
      debugPrint('Firebase Auth永続化設定開始');

      // 認証状態の復元をより確実にするための待機
      debugPrint('認証状態復元を待機中...');

      // authStateChanges を一度だけ監視して認証状態が安定するまで待つ
      bool authStateResolved = false;
      User? resolvedUser;

      final subscription = auth.authStateChanges().listen((user) {
        if (!authStateResolved) {
          resolvedUser = user;
          authStateResolved = true;
          debugPrint('認証状態解決: ${user != null ? user.uid : "未ログイン"}');
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
        debugPrint(
          'Firebase Auth認証状態復元完了: ${resolvedUser != null ? "ログイン済み" : "未ログイン"}',
        );
      } else {
        debugPrint('⚠️ Firebase Auth認証状態復元がタイムアウトしました');
      }
    } catch (persistenceError) {
      debugPrint('Firebase Auth永続化設定警告: $persistenceError');
      // 永続化設定エラーでもアプリは継続
    }

    // 現在のユーザー状態をログで確認
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      debugPrint('✅ 既存ユーザーセッション検出: ${currentUser.uid}');
      debugPrint('✅ ユーザーメール: ${currentUser.email}');
      debugPrint('✅ メール認証済み: ${currentUser.emailVerified}');

      // ログイン済みユーザーのプッシュ通知を初期化
      try {
        debugPrint('🔔 プッシュ通知サービス初期化開始');
        await NotificationService.initialize();
        debugPrint('🔔 プッシュ通知サービス初期化完了');
      } catch (notificationError) {
        debugPrint('⚠️ プッシュ通知初期化エラー: $notificationError');
        // プッシュ通知エラーでもアプリは継続
      }
    } else {
      debugPrint('❌ 既存ユーザーセッションなし（未ログイン状態）');
    }

    debugPrint('Firebase初期化成功');
    debugPrint('初期化後のFirebase apps数: ${Firebase.apps.length}');
    debugPrint(
      'Firebase app names: ${Firebase.apps.map((app) => app.name).toList()}',
    );

    // Firebase Analytics初期化と設定
    try {
      final analytics = FirebaseAnalytics.instance;
      
      // Analyticsの収集を明示的に有効化（デフォルトで有効ですが、念のため）
      await analytics.setAnalyticsCollectionEnabled(true);
      debugPrint('✅ Firebase Analytics収集を有効化しました');
      
      // デバッグモードでDebug Viewを有効化
      if (kDebugMode) {
        // Android: ADBコマンドで有効化が必要
        // adb shell setprop debug.firebase.analytics.app jp.ac.chibakoudai.citapp
        // iOS: Xcodeのスキーム設定で -FIRDebugEnabled を追加
        debugPrint('🔍 Firebase Analytics Debug Mode');
        debugPrint('📱 Android: ADBコマンドを実行してください:');
        debugPrint('   adb shell setprop debug.firebase.analytics.app jp.ac.chibakoudai.citapp');
        debugPrint('🍎 iOS: Xcodeのスキーム設定で -FIRDebugEnabled を追加してください');
      }
      
      // アプリオープンイベントを記録
      await analytics.logAppOpen();
      debugPrint('✅ Firebase Analytics app_open logged');
    } catch (analyticsError) {
      debugPrint('❌ Firebase Analytics ログ送信失敗: $analyticsError');
    }

    // Firebase App Check初期化
    try {
      debugPrint('Firebase App Check初期化開始');
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider:
            kDebugMode
                ? AppleProvider.debug
                : AppleProvider.appAttestWithDeviceCheckFallback,
      );
      debugPrint('Firebase App Check初期化完了');
    } catch (appCheckError) {
      debugPrint('Firebase App Check初期化警告: $appCheckError');
      // App Checkは必須ではないため、エラーでもアプリ継続
    }

    // Firebase Storage接続テスト（ネットワーク状況を考慮）
    if (Firebase.apps.isNotEmpty) {
      debugPrint('Firebase Storage接続テスト実行中...');
      try {
        final storage = FirebaseStorage.instance;
        // ネットワーク接続のタイムアウト設定
        storage.setMaxOperationRetryTime(const Duration(seconds: 10));
        storage.setMaxUploadRetryTime(const Duration(seconds: 10));
        storage.setMaxDownloadRetryTime(const Duration(seconds: 10));

        final testRef = storage.ref().child('test/initialization_test.txt');
        debugPrint('Firebase Storage テスト参照作成成功: ${testRef.fullPath}');
      } catch (storageError) {
        debugPrint('Firebase Storage テスト失敗 (ネットワーク問題の可能性): $storageError');
        // ネットワーク接続問題はアプリ起動を阻害しない
      }
    }
  } catch (e, stackTrace) {
    debugPrint('Firebase初期化失敗: $e');
    debugPrint('StackTrace: $stackTrace');
    // Firebase未設定でもアプリは動作継続
  }

  // 並行初期化の完了を待つ
  try {
    await Future.wait(initializationFutures);
  } catch (e) {
    debugPrint('初期化サービスエラー: $e');
    // エラーでもアプリ起動を継続
  }

  // バックグラウンドで遅延初期化を実行（起動時間に影響しない）
  _initializeBackgroundServices();

  // ストアレビュー管理：起動回数をカウント
  _handleAppReview();

  // アプリ起動時間を記録
  final startupTime = monitor.stopTimer('app_startup');
  debugPrint('🚀 アプリ起動完了: ${startupTime}ms');

  // フレームレート監視開始
  if (kDebugMode) {
    monitor.startFrameRateMonitoring();
  }

  // ウィジェットから起動した場合は時間割タブを開く
  String initialRoute = '/home';
  if (!kIsWeb) {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (uri != null && uri.toString().contains('schedule')) {
        initialRoute = '/home?tab=schedule';
      }
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
      // メニュー自動更新スケジューラーを開始
      MenuSchedulerService.startScheduledUpdates();

      // ホームウィジェット初期化
      await HomeWidgetsService.initialize();

      // 講義通知サービスを初期化
      await ScheduleNotificationService.initialize();

      debugPrint('✅ バックグラウンドサービス初期化完了');
    } catch (e) {
      debugPrint('⚠️ バックグラウンドサービス初期化エラー: $e');
    }
  });
}

/// 学バス情報のダイヤ一覧画像を事前読み込み
void _preloadBusTimetableImage() {
  // バックグラウンドで非同期実行（アプリ起動をブロックしない）
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      debugPrint('🚌 学バス情報のダイヤ一覧画像を事前読み込み開始');
      
      // Firebase Storageから直接画像URLを取得
      final url = await FirebaseMenuService.getBusTimetableImageUrl();
      
      if (url != null) {
        // HTTPリクエストで画像をダウンロードしてキャッシュに保存
        // CachedNetworkImageは自動的にキャッシュするので、事前にダウンロードしておく
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          // 画像をダウンロードしたので、次回表示時にキャッシュから読み込まれる
          debugPrint('✅ 学バス情報のダイヤ一覧画像の事前読み込み完了: $url');
        } else {
          debugPrint('⚠️ 学バス情報のダイヤ一覧画像のダウンロード失敗: ${response.statusCode}');
        }
      } else {
        debugPrint('ℹ️ 学バス情報のダイヤ一覧画像URLが取得できませんでした（アセット画像を使用）');
      }
    } catch (e) {
      debugPrint('⚠️ 学バス情報のダイヤ一覧画像の事前読み込みエラー（無視）: $e');
      // エラーは無視（フォールバックはアセット画像）
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
      debugPrint('⚠️ ストアレビュー処理エラー: $e');
    }
  });
}

class CITApp extends ConsumerStatefulWidget {
  const CITApp({super.key});

  @override
  ConsumerState<CITApp> createState() => _CITAppState();
}

class _CITAppState extends ConsumerState<CITApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // アプリライフサイクル監視を開始
    WidgetsBinding.instance.addObserver(this);
    // ウィジェットタップ時（アプリ起動中）に時間割タブへ遷移
    if (!kIsWeb) {
      HomeWidget.widgetClicked.listen((uri) {
        if (uri != null && uri.toString().contains('schedule')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(routerProvider).go('/home?tab=schedule');
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('🔄 アプリ再開: 認証状態を確認中...');
        // アプリが再開された時に認証状態を強制チェック
        _checkAuthenticationOnResume();
        break;
      case AppLifecycleState.paused:
        debugPrint('⏸️ アプリ一時停止: 最終アクセス時刻を更新');
        // アプリが一時停止された時に最終アクセス時刻を更新
        _updateLastAccessOnPause();
        break;
      case AppLifecycleState.detached:
        debugPrint('🔚 アプリ終了');
        break;
      case AppLifecycleState.inactive:
        debugPrint('😴 アプリ非アクティブ');
        break;
      case AppLifecycleState.hidden:
        debugPrint('👁️‍🗨️ アプリ非表示');
        break;
    }
  }

  /// アプリ再開時の認証状態確認
  void _checkAuthenticationOnResume() {
    try {
      // Firebase Auth が自動的に認証状態を復元するため、特別な処理は不要
      debugPrint('✅ アプリ再開: Firebase Auth による自動復元を待機');
    } catch (e) {
      debugPrint('⚠️ アプリ再開時認証チェックエラー: $e');
    }
  }

  /// アプリ一時停止時の処理
  void _updateLastAccessOnPause() {
    try {
      // Firebase Auth が自動的に状態を保存するため、特別な処理は不要
      debugPrint('✅ アプリ一時停止: Firebase Auth による自動保存');
    } catch (e) {
      debugPrint('⚠️ アプリ一時停止処理エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appFontSize = ref.watch(appFontSizeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(appFontSize.textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
