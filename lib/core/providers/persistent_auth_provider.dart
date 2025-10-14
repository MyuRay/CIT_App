import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// 永続化を強化した認証プロバイダー
/// タスクキル後の認証状態復元を確実にする
class PersistentAuthNotifier extends StateNotifier<AsyncValue<User?>> {
  PersistentAuthNotifier() : super(const AsyncValue.loading()) {
    _initializeAuth();
  }

  StreamSubscription<User?>? _authSubscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const String _keyUserLoggedIn = 'user_logged_in';
  static const String _keyUserUID = 'user_uid';
  static const String _keyUserEmail = 'user_email';
  static const String _keyLastAuthTime = 'last_auth_time';
  static const String _keyLastAccessTime = 'last_access_time';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRememberMe = 'remember_me';
  static const Duration _maxAuthAge = Duration(days: 30); // 30日間有効

  Future<void> _initializeAuth() async {
    try {
      print('🔐 PersistentAuth: 認証初期化開始');
      
      // Firebase Authの永続化設定を確認・強化
      await _configurePersistence();
      
      // SharedPreferencesから永続化データを確認
      final prefs = await SharedPreferences.getInstance();
      bool wasLoggedIn = prefs.getBool(_keyUserLoggedIn) ?? false;
      final lastAuthTime = prefs.getString(_keyLastAuthTime);
      final savedUID = prefs.getString(_keyUserUID);
      final savedEmail = prefs.getString(_keyUserEmail);
      
      print('🔐 SharedPreferences状態:');
      print('  - wasLoggedIn: $wasLoggedIn');
      print('  - savedUID: $savedUID');
      print('  - savedEmail: $savedEmail');
      
      if (lastAuthTime != null) {
        final lastAuth = DateTime.parse(lastAuthTime);
        final timeSinceLastAuth = DateTime.now().difference(lastAuth);
        print('  - 前回認証からの経過時間: ${timeSinceLastAuth.inMinutes}分');
        
        // 認証データが古すぎる場合はクリア
        if (timeSinceLastAuth > _maxAuthAge) {
          print('⚠️ 認証データが古すぎるためクリア (${timeSinceLastAuth.inDays}日経過)');
          await _clearPersistentData();
          wasLoggedIn = false;
        }
      }
      
      // Firebase Authの現在のユーザーを確認
      final currentUser = FirebaseAuth.instance.currentUser;
      print('🔐 Firebase Auth currentUser: ${currentUser?.uid ?? "null"}');
      
      // より長い待機時間でFirebase Authの初期化を待つ
      if (currentUser == null && wasLoggedIn) {
        print('⏳ Firebase Auth初期化をより長く待機中...');
        
        for (int i = 0; i < 15; i++) {
          await Future.delayed(const Duration(milliseconds: 800));
          final retryUser = FirebaseAuth.instance.currentUser;
          if (retryUser != null) {
            print('✅ Firebase Auth遅延初期化成功 (${(i + 1) * 800}ms後)');
            await _updatePersistentData(retryUser, true);
            state = AsyncValue.data(retryUser);
            _startAuthStateMonitoring();
            return;
          }
          print('  ⏳ 待機中... ${i + 1}/15');
        }
        
        // 最後の試行でauthStateChangesストリームから確認
        print('⏳ authStateChangesストリームから確認中...');
        final streamUser = await FirebaseAuth.instance.authStateChanges().first.timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );
        
        if (streamUser != null) {
          print('✅ authStateChangesストリームから認証復元成功');
          await _updatePersistentData(streamUser, true);
          state = AsyncValue.data(streamUser);
          _startAuthStateMonitoring();
          return;
        }
      }
      
      // 認証状態ストリームの監視を開始
      _startAuthStateMonitoring();
      
      // 初期状態の設定
      if (currentUser != null) {
        print('✅ 既存の認証セッション検出');
        await _updatePersistentData(currentUser, true);
        state = AsyncValue.data(currentUser);
      } else if (wasLoggedIn) {
        print('⚠️ 認証状態復元に時間がかかっています（端末依存の初期化遅延の可能性）');
        print('⚠️ いったん待機（loading）としてストリームの更新を待ちます');
        // ここではクリアしない。authStateChanges からの復帰を待つ
        state = const AsyncValue.loading();
      } else {
        print('ℹ️ 未認証状態で開始');
        state = const AsyncValue.data(null);
      }
      
    } catch (e, stackTrace) {
      print('❌ PersistentAuth初期化エラー: $e');
      print('❌ StackTrace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Firebase Auth永続化設定を強化
  Future<void> _configurePersistence() async {
    try {
      print('🔧 Firebase Auth永続化設定を確認中...');
      
      // Firebase Authインスタンスの設定確認
      final auth = FirebaseAuth.instance;
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_keyRememberMe) ?? true;
      
      // アプリの永続化設定をユーザー選択に合わせて設定（Web）
      try {
        await auth.setPersistence(rememberMe ? Persistence.LOCAL : Persistence.SESSION);
        print('✅ Firebase Auth永続化を ${rememberMe ? 'LOCAL' : 'SESSION'} に設定');
      } catch (e) {
        // モバイルでは未対応のため継続
        print('ℹ️ setPersistence未対応プラットフォーム（継続）: $e');
      }
      
      // 追加の設定: authDomain や他の設定を確認
      print('🔧 Firebase App設定確認:');
      print('  - App名: ${auth.app.name}');
      print('  - Project ID: ${auth.app.options.projectId}');
      
      // セッション維持のための追加設定
      await auth.setSettings(
        appVerificationDisabledForTesting: false,
        userAccessGroup: null, // iOSでのキーチェーン共有（nullで既定値）
      );
      print('✅ Firebase Auth追加設定完了');
      
    } catch (e) {
      print('⚠️ 永続化設定エラー（継続）: $e');
    }
  }

  /// 詳細な認証状態をログ出力
  Future<void> _logDetailedAuthState() async {
    try {
      final auth = FirebaseAuth.instance;
      final prefs = await SharedPreferences.getInstance();
      
      print('🔍 詳細認証状態デバッグ:');
      print('  - Firebase App初期化済み: ${auth.app.name}');
      print('  - currentUser null: ${auth.currentUser == null}');
      
      // SharedPreferencesの全認証関連キーを確認
      final allKeys = prefs.getKeys().where((key) => 
        key.contains('user_') || key.contains('auth_') || key.contains('firebase_')).toList();
      print('  - SharedPreferences認証関連キー: $allKeys');
      
      for (final key in allKeys) {
        final value = prefs.get(key);
        print('    $key: $value');
      }
      
    } catch (e) {
      print('⚠️ デバッグ情報取得エラー: $e');
    }
  }

  void _startAuthStateMonitoring() {
    _authSubscription?.cancel();
    
    _authSubscription = FirebaseAuth.instance
        .authStateChanges()
        .distinct() // 重複する状態変更を無視
        .listen(
      (user) async {
        print('🔐 Auth状態変更検出: ${user?.uid ?? "ログアウト"}');
        
        // 再接続の試行をリセット
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();
        
        if (user != null) {
          print('✅ ユーザー認証確認済み: ${user.email}');
          await _updatePersistentData(user, true);
          state = AsyncValue.data(user);
        } else {
          print('❌ ユーザーログアウト検出');
          await _updatePersistentData(null, false);
          state = const AsyncValue.data(null);
        }
      },
      onError: (error) async {
        print('❌ Auth状態監視エラー: $error');
        state = AsyncValue.error(error, StackTrace.current);
        
        // エラー発生時は再接続を試行
        _scheduleReconnect();
      },
    );
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ 最大再接続試行回数に達しました');
      return;
    }
    
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2); // 指数バックオフ
    
    print('🔄 Auth再接続を${delay.inSeconds}秒後に試行 (${_reconnectAttempts}/$_maxReconnectAttempts)');
    
    _reconnectTimer = Timer(delay, () {
      print('🔄 Auth再接続試行中...');
      _startAuthStateMonitoring();
    });
  }

  Future<void> _updatePersistentData(User? user, bool isLoggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (isLoggedIn && user != null) {
        final now = DateTime.now();
        
        await prefs.setBool(_keyUserLoggedIn, true);
        await prefs.setString(_keyUserUID, user.uid);
        await prefs.setString(_keyUserEmail, user.email ?? '');
        await prefs.setString(_keyLastAuthTime, now.toIso8601String());
        await prefs.setString(_keyLastAccessTime, now.toIso8601String());
        
        // 認証トークンも保存（可能であれば）
        try {
          final token = await user.getIdToken();
          if (token != null && token.isNotEmpty) {
            await prefs.setString(_keyAuthToken, token);
            print('✅ 認証トークンを保存');
          }
        } catch (tokenError) {
          print('⚠️ トークン保存エラー: $tokenError');
        }
        
        print('✅ 認証データをSharedPreferencesに保存');
        print('  - UID: ${user.uid}');
        print('  - Email: ${user.email}');
        print('  - 保存時刻: ${now.toIso8601String()}');
      } else {
        await _clearPersistentData();
        print('✅ 認証データをSharedPreferencesから削除');
      }
    } catch (e) {
      print('⚠️ SharedPreferences更新エラー: $e');
    }
  }

  Future<void> _clearPersistentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserLoggedIn);
      await prefs.remove(_keyUserUID);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyLastAuthTime);
      await prefs.remove(_keyLastAccessTime);
      await prefs.remove(_keyAuthToken);
      print('✅ 全認証データをSharedPreferencesからクリア');
    } catch (e) {
      print('⚠️ SharedPreferencesクリアエラー: $e');
    }
  }

  /// 手動でリフレッシュ（デバッグ用）
  Future<void> refresh() async {
    print('🔄 手動認証リフレッシュ');
    state = const AsyncValue.loading();
    await _initializeAuth();
  }
  
  /// 最後のアクセス時刻を更新（アプリアクティブ時に呼び出し）
  Future<void> updateLastAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyUserLoggedIn) ?? false;
      
      if (isLoggedIn) {
        await prefs.setString(_keyLastAccessTime, DateTime.now().toIso8601String());
        print('🔄 最終アクセス時刻を更新');
      }
    } catch (e) {
      print('⚠️ 最終アクセス時刻更新エラー: $e');
    }
  }

  /// 認証状態の強制チェック
  Future<void> forceCheck() async {
    print('🔍 認証状態強制チェック');
    
    try {
      // Firebase Auth の現在のユーザーを取得
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        try {
          // 強制リフレッシュは行わず、通常のトークン取得で状態を確認
          await currentUser.getIdToken().timeout(const Duration(seconds: 5));
          print('✅ 認証トークン有効');
          await _updatePersistentData(currentUser, true);
          state = AsyncValue.data(currentUser);
        } on FirebaseAuthException catch (e) {
          final transientCodes = {
            'network-request-failed',
            'internal-error',
            'too-many-requests',
            'unknown',
            'app-check-token-validation-failed',
            'app-check-too-many-requests',
            'app-check-unexpected-error',
            'app-check-network-error',
          };
          final isAppCheckRelated = e.code.startsWith('app-check') || e.code == 'invalid-app-check-token';

          if (transientCodes.contains(e.code) || isAppCheckRelated) {
            print('⚠️ 一時的な認証／AppCheckエラー(${e.code})のためサインアウトはしません');
            _scheduleReconnect();
            return;
          }

          if (e.code == 'user-token-expired' || e.code == 'user-disabled' || e.code == 'user-not-found') {
            print('⚠️ トークンリロードを試行 (${e.code})');
            try {
              await currentUser.reload();
              final refreshedUser = FirebaseAuth.instance.currentUser;
              if (refreshedUser != null) {
                print('✅ トークン再取得成功');
                await _updatePersistentData(refreshedUser, true);
                state = AsyncValue.data(refreshedUser);
                return;
              }
            } catch (reloadError) {
              print('⚠️ トークン再取得に失敗: $reloadError');
            }

            print('❌ 致命的な認証エラーのためサインアウトします (${e.code})');
            await FirebaseAuth.instance.signOut();
            return;
          }

          print('⚠️ 想定外のトークンエラー(${e.code})。サインアウトせず再試行を予約');
          _scheduleReconnect();
          return;
        } on TimeoutException {
          print('⚠️ トークン取得タイムアウト。サインアウトは行わず再試行を予約');
          _scheduleReconnect();
          return;
        } catch (tokenError) {
          print('⚠️ 予期せぬトークン取得エラー（サインアウトせず保持）: $tokenError');
          _scheduleReconnect();
          return;
        }
      } else {
        print('ℹ️ 未認証状態');
        // ここで即クリアはしない（端末依存の初期化遅延に配慮）
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      print('❌ 強制チェックエラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _reconnectTimer?.cancel();
    super.dispose();
  }
}

/// 永続化された認証プロバイダー
final persistentAuthProvider = StateNotifierProvider<PersistentAuthNotifier, AsyncValue<User?>>((ref) {
  return PersistentAuthNotifier();
});

/// 認証状態確認用プロバイダー
final isLoggedInPersistentProvider = Provider<bool?>((ref) {
  final authState = ref.watch(persistentAuthProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => null,
    error: (_, __) => false,
  );
});

/// デバッグ用認証情報プロバイダー
final authDebugInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final firebaseUser = FirebaseAuth.instance.currentUser;
  
  return {
    'firebase_user_uid': firebaseUser?.uid,
    'firebase_user_email': firebaseUser?.email,
    'firebase_user_verified': firebaseUser?.emailVerified,
    'prefs_logged_in': prefs.getBool('user_logged_in') ?? false,
    'prefs_uid': prefs.getString('user_uid') ?? '',
    'prefs_email': prefs.getString('user_email') ?? '',
    'prefs_last_auth': prefs.getString('last_auth_time') ?? '',
    'prefs_last_access': prefs.getString('last_access_time') ?? '',
    'prefs_has_token': prefs.getString('auth_token')?.isNotEmpty ?? false,
  };
});

