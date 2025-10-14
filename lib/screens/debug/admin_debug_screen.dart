import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/admin_setup_helper.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../debug/firestore_rules_test.dart';

class AdminDebugScreen extends ConsumerStatefulWidget {
  const AdminDebugScreen({super.key});

  @override
  ConsumerState<AdminDebugScreen> createState() => _AdminDebugScreenState();
}

class _AdminDebugScreenState extends ConsumerState<AdminDebugScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String _result = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final adminPermissions = ref.watch(currentUserAdminProvider);
    final debugStatus = ref.watch(debugAdminStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理者デバッグ画面'),
        backgroundColor: Colors.orange.shade50,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 現在の状態表示
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '現在の状態',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text('デバッグ情報: $debugStatus'),
                    const SizedBox(height: 8),
                    authState.when(
                      data: (user) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('認証状態: ${user != null ? "ログイン済み" : "未ログイン"}'),
                          if (user != null) ...[
                            Text('ユーザーID: ${user.uid}'),
                            Text('メールアドレス: ${user.email ?? "なし"}'),
                            Text('表示名: ${user.displayName ?? "なし"}'),
                          ],
                        ],
                      ),
                      loading: () => const Text('認証状態: 確認中...'),
                      error: (error, _) => Text('認証エラー: $error'),
                    ),
                    const SizedBox(height: 8),
                    adminPermissions.when(
                      data: (permissions) => Text(
                        '管理者権限: ${permissions?.isAdmin == true ? "あり" : "なし"}',
                        style: TextStyle(
                          color: permissions?.isAdmin == true ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => const Text('管理者権限: 確認中...'),
                      error: (error, _) => Text('管理者権限エラー: $error'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 管理者作成ツール
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '管理者作成ツール',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // 現在のユーザーを管理者にする
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _makeCurrentUserAdmin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('現在のユーザーを管理者にする'),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // メールアドレスで管理者作成
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'メールアドレス',
                        hintText: 'admin@s.chibakoudai.jp',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _makeUserAdminByEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('メールアドレスで管理者作成'),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 管理者一覧表示
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _listAdmins,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('管理者一覧表示'),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 状態更新
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _refreshState,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('状態を更新'),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Firestore Rules テスト
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const FirestoreRulesTestScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Firestore Rules テスト'),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Firebase Console直接アクセス
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _showFirebaseInstructions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Firebase Rules修正手順'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 結果表示
            if (_result.isNotEmpty)
              Card(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '実行結果',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _result = ''),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _result,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _makeCurrentUserAdmin() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      setState(() {
        _result = '🔄 管理者権限作成を開始しています...\n';
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('ユーザーが認証されていません');
      }

      setState(() {
        _result += '✅ Firebase認証済み: ${currentUser.uid}\n';
        _result += '📧 メールアドレス: ${currentUser.email}\n';
        _result += '🔄 Firestoreに権限ドキュメントを作成中...\n';
      });

      await AdminSetupHelper.makeCurrentUserAdmin();
      
      setState(() {
        _result += '✅ 管理者権限の作成が完了しました！\n';
        _result += '🔄 リアルタイム更新により自動反映されます...\n';
      });
      
      // StreamProviderは自動でリアルタイム更新されるため、invalidateは不要
      // しかし念のため実行（StreamProviderでは効果は限定的）
      ref.invalidate(currentUserAdminProvider);
      ref.invalidate(adminPermissionsProvider);
      
      setState(() {
        _result += '✅ 完了！マイページに戻って管理者メニューが自動表示されるはずです。';
      });
      
    } catch (e) {
      setState(() {
        _result += '❌ エラー発生: $e\n\n';
        _result += '🛠️ 解決方法:\n';
        _result += '1. Firebase Consoleにアクセス\n';
        _result += '2. Firestore Database → Rules\n';
        _result += '3. 以下のルールを追加:\n\n';
        _result += 'match /admin_permissions/{document} {\n';
        _result += '  allow read, write: if request.auth != null;\n';
        _result += '}\n\n';
        _result += '4. 「公開」ボタンをクリック\n';
        _result += '5. このボタンを再度試行';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makeUserAdminByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メールアドレスを入力してください')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      await AdminSetupHelper.makeUserAdminByEmail(email);
      setState(() {
        _result = '✅ $email に管理者権限を付与しました（リアルタイム更新されます）';
      });
      _emailController.clear();
      
      // StreamProviderは自動でリアルタイム更新されるため、invalidateは不要
      ref.invalidate(currentUserAdminProvider);
      ref.invalidate(adminPermissionsProvider);
      
    } catch (e) {
      setState(() {
        _result = '❌ エラー: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _listAdmins() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      // コンソール出力をキャプチャするため、独自実装
      final result = StringBuffer();
      
      await AdminSetupHelper.listAdmins();
      setState(() {
        _result = '管理者一覧をコンソールに出力しました。\nFlutter DevToolsのコンソールを確認してください。';
      });
    } catch (e) {
      setState(() {
        _result = '❌ エラー: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _refreshState() {
    setState(() {
      _result = '🔄 状態を更新中...';
    });
    
    // 全ての関連プロバイダーを更新
    ref.invalidate(currentUserAdminProvider);
    ref.invalidate(adminPermissionsProvider);
    ref.invalidate(authStateProvider);
    ref.invalidate(debugAdminStatusProvider);
    
    setState(() {
      _result = '✅ 状態を更新しました';
    });
  }

  void _showFirebaseInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Firebase Rules修正が必要'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'permission deniedエラーを解決するため、以下の手順でFirestoreルールを修正してください：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('1. Firebase Consoleにアクセス'),
              const Text('   https://console.firebase.google.com/'),
              const SizedBox(height: 8),
              const Text('2. プロジェクト「cit-app-2de1c」を選択'),
              const SizedBox(height: 8),
              const Text('3. Firestore Database → Rules をクリック'),
              const SizedBox(height: 8),
              const Text('4. 既存のルールに以下を追加:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'match /admin_permissions/{document} {\n'
                  '  allow read, write: if request.auth != null;\n'
                  '}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('5. 「公開」ボタンをクリック'),
              const SizedBox(height: 8),
              const Text('6. このアプリに戻って再試行'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // クリップボードにルールをコピー
              setState(() {
                _result = '📋 以下のルールをFirebase Consoleに追加してください:\n\n'
                    'match /admin_permissions/{document} {\n'
                    '  allow read, write: if request.auth != null;\n'
                    '}';
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('ルールをコピー', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}