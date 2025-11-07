import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/simple_auth_provider.dart';

class AuthDebugScreen extends ConsumerWidget {
  const AuthDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final simpleAuthState = ref.watch(simpleAuthStateProvider);
    final currentUser = ref.watch(currentUserSimpleProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('認証デバッグ'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(authStateProvider);
              ref.invalidate(simpleAuthStateProvider);
            },
            tooltip: 'リフレッシュ',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(authStateProvider);
          ref.invalidate(simpleAuthStateProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // タスクキル対応状況カード
            _buildTaskKillInfoCard(context, ref),
            
            const SizedBox(height: 16),
            
            // アプリライフサイクル監視状況
            _buildLifecycleInfoCard(),
            
            const SizedBox(height: 16),
            
            // 現在の認証状態
            _buildStatusCard(
              'Firebase Auth 状態',
              authState.when(
                data: (user) => user != null 
                    ? '✅ ログイン済み\nUID: ${user.uid}\nEmail: ${user.email}'
                    : '❌ 未ログイン',
                loading: () => '⏳ 読み込み中...',
                error: (error, _) => '❌ エラー: $error',
              ),
              authState.when(
                data: (user) => user != null ? Colors.green : Colors.red,
                loading: () => Colors.orange,
                error: (_, __) => Colors.red,
              ),
            ),
            
            const SizedBox(height: 16),

            // シンプル認証状態
            _buildStatusCard(
              'シンプル Auth 状態',
              simpleAuthState.when(
                data: (user) => user != null
                    ? '✅ ログイン済み\nUID: ${user.uid}\nEmail: ${user.email}'
                    : '❌ 未ログイン',
                loading: () => '⏳ 初期化中...',
                error: (error, _) => '❌ エラー: $error',
              ),
              simpleAuthState.when(
                data: (user) => user != null ? Colors.green : Colors.red,
                loading: () => Colors.orange,
                error: (_, __) => Colors.red,
              ),
            ),

            const SizedBox(height: 16),

            // 現在のユーザー情報
            _buildCurrentUserCard(currentUser),
            
            const SizedBox(height: 16),
            
            // アクションボタン
            _buildActionButtons(ref),
            
            const SizedBox(height: 16),
            
            // ログ表示
            _buildLogSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String content, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentUserCard(User? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👤 現在のユーザー情報',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (user != null) ...[
              _buildInfoRow('UID', user.uid),
              _buildInfoRow('Email', user.email ?? 'なし'),
              _buildInfoRow('表示名', user.displayName ?? 'なし'),
              _buildInfoRow('メール認証', user.emailVerified ? '✅ 済み' : '❌ 未認証'),
              _buildInfoRow('匿名ユーザー', user.isAnonymous ? 'はい' : 'いいえ'),
              _buildInfoRow('作成日時', user.metadata.creationTime?.toString() ?? 'なし'),
              _buildInfoRow('最終ログイン', user.metadata.lastSignInTime?.toString() ?? 'なし'),
            ] else ...[
              const Text(
                '未ログイン',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDebugInfoCard(Map<String, dynamic> info) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔍 詳細デバッグ情報',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...info.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value?.toString() ?? 'null',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🛠️ デバッグアクション',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.currentUser?.reload();
                      ref.invalidate(simpleAuthStateProvider);
                      ScaffoldMessenger.of(ref.context).showSnackBar(
                        const SnackBar(content: Text('ユーザー情報を再読み込みしました')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(ref.context).showSnackBar(
                        SnackBar(
                          content: Text('再読み込みエラー: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.security, size: 18),
                  label: const Text('ユーザー再読み込み'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
                      ScaffoldMessenger.of(ref.context).showSnackBar(
                        SnackBar(
                          content: Text(token != null ? 'トークン更新成功' : 'ユーザーが未ログイン'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(ref.context).showSnackBar(
                        SnackBar(
                          content: Text('トークン更新エラー: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.token, size: 18),
                  label: const Text('トークン更新'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(simpleAuthStateProvider);
                    ref.invalidate(authStateProvider);
                    ScaffoldMessenger.of(ref.context).showSnackBar(
                      const SnackBar(content: Text('プロバイダーをリフレッシュしました')),
                    );
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('プロバイダーリフレッシュ'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 認証ログの確認',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '認証関連のログは開発者コンソールで確認してください。\n'
                'Android Studio: Run タブ\n'
                'VS Code: Debug Console\n'
                '\n'
                '主要なログキーワード:\n'
                '• 🔐 PersistentAuth\n'
                '• ✅ 認証復元\n'
                '• ❌ 認証エラー\n'
                '• 🔄 再接続試行',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskKillInfoCard(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.task_alt, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'タスクキル対応状況',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('✅ SimpleAuthProvider', '実装済み'),
            _buildInfoRow('✅ Firebase Auth標準永続化', '使用中'),
            _buildInfoRow('✅ authStateChanges監視', '実装済み'),
            _buildInfoRow('✅ シンプルな認証フロー', '実装済み'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                'Firebase Authの標準永続化機能を使用しています。\n'
                '複雑なロジックを排除し、Firebaseのネイティブ動作に任せることで、\n'
                'より安定した認証状態の維持を実現しています。',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLifecycleInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sync, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'アプリライフサイクル監視',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('🔄 アプリ再開時', 'Firebase自動復元'),
            _buildInfoRow('⏸️ アプリ一時停止時', 'Firebase自動保存'),
            _buildInfoRow('📱 バックグラウンド復帰', 'Firebase自動同期'),
            _buildInfoRow('🔐 認証データ', 'Firebaseが管理'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Text(
                'Firebase Authが自動的に認証状態を管理します。\n'
                '独自の復元処理は行わず、Firebaseのネイティブ動作に任せています。',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}