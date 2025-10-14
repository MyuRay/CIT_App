import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/persistent_auth_provider.dart';

class AuthDebugScreen extends ConsumerWidget {
  const AuthDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final persistentAuthState = ref.watch(persistentAuthProvider);
    final authDebugInfo = ref.watch(authDebugInfoProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('認証デバッグ'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(authStateProvider);
              ref.invalidate(persistentAuthProvider);
              ref.invalidate(authDebugInfoProvider);
              ref.read(persistentAuthProvider.notifier).refresh();
            },
            tooltip: 'リフレッシュ',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(authStateProvider);
          ref.invalidate(persistentAuthProvider);
          ref.invalidate(authDebugInfoProvider);
          await ref.read(persistentAuthProvider.notifier).refresh();
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
            
            // 永続化認証状態
            _buildStatusCard(
              '永続化 Auth 状態',
              persistentAuthState.when(
                data: (user) => user != null 
                    ? '✅ ログイン済み\nUID: ${user.uid}\nEmail: ${user.email}'
                    : '❌ 未ログイン',
                loading: () => '⏳ 初期化中...',
                error: (error, _) => '❌ エラー: $error',
              ),
              persistentAuthState.when(
                data: (user) => user != null ? Colors.green : Colors.red,
                loading: () => Colors.orange,
                error: (_, __) => Colors.red,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 詳細デバッグ情報
            authDebugInfo.when(
              data: (info) => _buildDebugInfoCard(info),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('デバッグ情報取得エラー: $error'),
                ),
              ),
            ),
            
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
                    await ref.read(persistentAuthProvider.notifier).forceCheck();
                    ScaffoldMessenger.of(ref.context).showSnackBar(
                      const SnackBar(content: Text('認証状態の強制チェックを実行しました')),
                    );
                  },
                  icon: const Icon(Icons.security, size: 18),
                  label: const Text('認証強制チェック'),
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
                  onPressed: () async {
                    await ref.read(persistentAuthProvider.notifier).refresh();
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
            _buildInfoRow('✅ PersistentAuthProvider', '実装済み'),
            _buildInfoRow('✅ SharedPreferencesバックアップ', '実装済み'),
            _buildInfoRow('✅ Firebase Auth永続化設定', 'LOCAL設定済み'),
            _buildInfoRow('✅ 認証状態強制チェック', '実装済み'),
            _buildInfoRow('✅ 15回 × 800ms 待機', '実装済み'),
            _buildInfoRow('✅ authStateChanges監視', '実装済み'),
            _buildInfoRow('✅ 認証トークン保存', '実装済み'),
            _buildInfoRow('✅ アプリライフサイクル監視', '実装済み'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                'タスクキル後も認証状態を維持する機能が実装されています。\n'
                '問題が続く場合は、アプリを完全に削除して再インストールをお試しください。',
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
            _buildInfoRow('🔄 アプリ再開時', '認証状態自動チェック'),
            _buildInfoRow('⏸️ アプリ一時停止時', '最終アクセス時刻更新'),
            _buildInfoRow('📱 バックグラウンド復帰', '強制認証チェック実行'),
            _buildInfoRow('🔐 認証データ有効期限', '30日間'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Text(
                'アプリがバックグラウンドから復帰するたびに認証状態をチェックし、\n'
                '必要に応じて自動的に復元処理を実行します。',
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