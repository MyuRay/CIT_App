import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../services/user/user_service.dart';
import '../../models/user/user_model.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  Timer? _checkTimer;
  StreamSubscription<AppUser?>? _userSubscription;

  @override
  void initState() {
    super.initState();
    // 画面表示時に即座に認証状態をチェック
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVerificationStatus();
      _startWatchingUser();
    });
    // 5秒ごとに認証状態をチェック（Firebase Authとの同期）
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkVerificationStatus();
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }

  // Firestoreのユーザードキュメントをリアルタイム監視
  void _startWatchingUser() {
    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return;

    _userSubscription?.cancel();
    _userSubscription = UserService.watchUser(user.uid).listen((appUser) {
      if (appUser != null && appUser.emailVerified && mounted) {
        print('✅ Firestoreでメール認証完了を検知: ${appUser.uid}');
        // 認証完了したらホーム画面へ強制遷移
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go('/home');
          }
        });
      }
    }, onError: (error) {
      print('❌ ユーザー監視エラー: $error');
    });
  }

  Future<void> _checkVerificationStatus() async {
    if (_isChecking) return;
    
    setState(() => _isChecking = true);
    
    try {
      // Firebase Authの状態を確認してFirestoreに同期
      final isVerified = await UserService.syncCurrentUserEmailVerification();
      
      if (isVerified && mounted) {
        print('✅ Firebase Authでメール認証完了を検知');
        // 認証完了したらホーム画面へ
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go('/home');
          }
        });
      }
    } catch (e) {
      print('❌ 認証状態チェックエラー: $e');
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResending) return;
    
    setState(() => _isResending = true);
    
    try {
      final authService = ref.read(authServiceProvider);
      await authService.resendVerificationEmail();
      
      // メール認証状態をFirestoreに同期（再送信後も確認）
      await UserService.syncCurrentUserEmailVerification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('認証メールを再送信しました。メールボックスを確認してください。'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? '認証メールの再送信に失敗しました'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      // ユーザーがログインしていない場合はログイン画面へ
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // メール認証済みの場合はホームへ遷移（画面表示時にもチェック）
    if (user.emailVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/home');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('メール認証'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // アイコン
              Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              // タイトル
              Text(
                'メール認証が必要です',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              // 説明文
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '登録されたメールアドレスに認証メールを送信しました。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '以下の手順で認証を完了してください：',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _buildStep('1', 'メールボックスを確認してください'),
                    _buildStep('2', '認証メール内のリンクをクリック'),
                    _buildStep('3', '認証完了後、この画面が自動的に更新されます'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // メールアドレス表示
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '送信先メールアドレス',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email ?? 'メールアドレス未設定',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // 認証状態をチェックボタン
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isChecking ? null : _checkVerificationStatus,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_isChecking ? '確認中...' : '認証状態を確認'),
                ),
              ),
              const SizedBox(height: 12),
              // 再送信ボタン
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isResending ? null : _resendVerificationEmail,
                  icon: _isResending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isResending ? '送信中...' : '認証メールを再送信'),
                ),
              ),
              const SizedBox(height: 24),
              // 注意事項
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '認証が完了するまで、アプリの機能を使用できません。\nメールが届かない場合は、迷惑メールフォルダも確認してください。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // ログアウトボタン
              TextButton(
                onPressed: () async {
                  final authService = ref.read(authServiceProvider);
                  await authService.signOut();
                  if (mounted) {
                    context.go('/login');
                  }
                },
                child: const Text('別のアカウントでログイン'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

