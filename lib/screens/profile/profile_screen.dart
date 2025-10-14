import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/providers/user_provider.dart';
import '../admin/admin_management_screen.dart';
import '../debug/admin_debug_screen.dart';
import '../contact/user_contact_list_screen.dart';
import '../contact/contact_form_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../debug/auth_debug_screen.dart';
import '../admin/bus_management_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🔧 ProfileScreen build開始');
    print('🔧 ProfileScreen widget初期化完了');
    
    try {
      final user = ref.watch(authStateProvider);
      final themeMode = ref.watch(themeModeProvider);
      final themeModeNotifier = ref.read(themeModeProvider.notifier);
      
      print('🔧 テーマモード: $themeMode');
      print('🔧 authStateProvider状態: ${user.runtimeType}');
      
      return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        actions: [],
      ),
      body: user.when(
        data: (user) {
          print('🔧 ユーザーデータ取得: ${user?.email ?? "null"}');
          return _buildProfileContent(context, ref, user, themeMode, themeModeNotifier);
        },
        loading: () {
          print('🔧 ユーザー読み込み中...');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          print('❌ ユーザー取得エラー: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('エラーが発生しました: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // とりあえずテーマ設定だけ表示
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('テーマ設定'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('ライトモード'),
                              onTap: () {
                                themeModeNotifier.setLightMode();
                                Navigator.of(context).pop();
                              },
                            ),
                            ListTile(
                              title: const Text('ダークモード'),
                              onTap: () {
                                themeModeNotifier.setDarkMode();
                                Navigator.of(context).pop();
                              },
                            ),
                            ListTile(
                              title: const Text('システム設定'),
                              onTap: () {
                                themeModeNotifier.setSystemMode();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('テーマ設定を開く'),
                ),
              ],
            ),
          );
        },
      ),
    );
    } catch (e, stack) {
      print('❌ ProfileScreen build内でエラー: $e');
      print('❌ スタックトレース: $stack');
      return Scaffold(
        appBar: AppBar(title: const Text('マイページ（エラー）')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('ビルドエラー: $e'),
              const SizedBox(height: 16),
              const Text('デバッグ版に切り替えてください'),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    User? user,
    ThemeMode themeMode,
    ThemeModeNotifier themeModeNotifier,
  ) {
    print('🔧 _buildProfileContent開始, user: ${user?.email ?? "null"}');
    print('🔧 テーマモード: $themeMode');
    
    // ログインしていない場合でもテーマ設定は表示する
    if (user == null) {
      print('🔧 ゲストユーザー用UI構築');
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ログイン案内カード
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      child: Icon(
                        Icons.person_off,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ゲストユーザー',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ログインして全機能をご利用ください',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/login');
                      },
                      child: const Text('ログイン'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // テーマ設定（ログインしていなくても利用可能）
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '設定',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  
                  // ダークモード設定
                  Builder(
                    builder: (context) {
                      print('🔧 テーマ設定ListTile構築中（ゲスト用）');
                      return ListTile(
                        leading: Icon(
                          themeModeNotifier.isDarkMode(context) 
                              ? Icons.dark_mode 
                              : Icons.light_mode,
                        ),
                        title: const Text('テーマ設定'),
                        subtitle: Text(themeModeNotifier.currentThemeDisplayName),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          print('🔧 テーマ設定タップ（ゲスト用）');
                          _showThemeSelectionDialog(context, themeModeNotifier, themeMode);
                        },
                      );
                    },
                  ),
                  
                  const Divider(height: 1),
                  
                  // プライバシーポリシー（ゲスト用）
                  ListTile(
                    leading: const Icon(Icons.privacy_tip, color: Colors.teal),
                    title: const Text('プライバシーポリシー'),
                    subtitle: const Text('データの取り扱いについて'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const Divider(height: 1),
                  
                  // 認証デバッグ画面（ゲスト用）
                  ListTile(
                    leading: const Icon(Icons.security, color: Colors.blue),
                    title: const Text('認証デバッグ'),
                    subtitle: const Text('ログイン状態・認証トークンの確認'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      print('🔧 認証デバッグボタンがタップされました（ゲスト用）');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AuthDebugScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const Divider(height: 1),
                  
                  // 管理者デバッグ画面（ゲスト用）
                  ListTile(
                    leading: const Icon(Icons.bug_report, color: Colors.purple),
                    title: const Text('管理者デバッグ'),
                    subtitle: const Text('管理者権限のデバッグ・設定'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      print('🔧 管理者デバッグボタンがタップされました（ゲスト用）');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AdminDebugScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // アプリ情報
            _buildAppInfoCard(context),
          ],
        ),
      );
    }

    final adminPermissionsAsync = ref.watch(currentUserAdminProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ユーザー情報カード
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      user.displayName?.isNotEmpty == true
                          ? user.displayName![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName ?? 'ユーザー',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 詳細ユーザー情報（Firestoreから取得）
          _buildDetailedUserInfo(ref, user.uid),
          
          const SizedBox(height: 16),
          
          // 設定セクション
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '設定',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                
                // ダークモード設定
                ListTile(
                  leading: Icon(
                    themeModeNotifier.isDarkMode(context) 
                        ? Icons.dark_mode 
                        : Icons.light_mode,
                  ),
                  title: const Text('テーマ設定'),
                  subtitle: Text(themeModeNotifier.currentThemeDisplayName),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showThemeSelectionDialog(context, themeModeNotifier, themeMode),
                ),
                
                const Divider(height: 1),
                
                // 学バス管理メニュー
                ListTile(
                  leading: const Icon(Icons.directions_bus, color: Colors.green),
                  title: const Text('学バス管理'),
                  subtitle: const Text('バス路線・運行期間の管理'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    print('🔧 学バス管理ボタンがタップされました');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BusManagementScreen(),
                      ),
                    );
                  },
                ),
                
                const Divider(height: 1),
                
                // お問い合わせメニュー
                ListTile(
                  leading: const Icon(Icons.help_center, color: Colors.blue),
                  title: const Text('お問い合わせ'),
                  subtitle: const Text('質問・要望・不具合報告'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ContactFormScreen(),
                      ),
                    );
                  },
                ),
                
                const Divider(height: 1),
                
                // お問い合わせ履歴メニュー
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.green),
                  title: const Text('お問い合わせ履歴'),
                  subtitle: const Text('過去のお問い合わせと返信'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UserContactListScreen(),
                      ),
                    );
                  },
                ),
                
                const Divider(height: 1),

                // ブロック済みユーザー管理
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('ブロック済みユーザー'),
                  subtitle: const Text('ブロックしたユーザーの管理'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).pushNamed('/blocked-users');
                  },
                ),

                const Divider(height: 1),

                // プライバシーポリシー
                ListTile(
                  leading: const Icon(Icons.privacy_tip, color: Colors.teal),
                  title: const Text('プライバシーポリシー'),
                  subtitle: const Text('データの取り扱いについて'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
                
                const Divider(height: 1),
                
                // 認証デバッグ（ログインユーザー用）
                ListTile(
                  leading: const Icon(Icons.security, color: Colors.blue),
                  title: const Text('認証デバッグ'),
                  subtitle: const Text('ログイン状態・認証トークンの確認'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AuthDebugScreen(),
                      ),
                    );
                  },
                ),
                
                const Divider(height: 1),
                
                // 管理者メニュー（管理者のみ表示）
                adminPermissionsAsync.when(
                  data: (permissions) {
                    print('🔧 管理者権限チェック: ${permissions?.toString()}');
                    print('🔧 isAdmin: ${permissions?.isAdmin}');
                    if (permissions?.isAdmin == true) {
                      return Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.admin_panel_settings, color: Colors.orange),
                            title: const Text('管理者メニュー'),
                            subtitle: const Text('投稿管理・ユーザー管理'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const AdminManagementScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () {
                    print('🔧 管理者権限読み込み中');
                    return const SizedBox.shrink();
                  },
                  error: (error, stack) {
                    print('🔧 管理者権限エラー: $error');
                    return const SizedBox.shrink();
                  },
                ),
                
                
                // ログアウト
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('ログアウト'),
                  onTap: () => _showLogoutDialog(context, ref),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // アプリ情報
          _buildAppInfoCard(context),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'アプリ情報',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('バージョン'),
            subtitle: Text('1.11.0+23'),
          ),
          
          const Divider(height: 1),
          
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('千葉工業大学 学生支援アプリ'),
            subtitle: Text(
              '時間割・掲示板・学食情報などを提供',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeSelectionDialog(BuildContext context, ThemeModeNotifier themeModeNotifier, ThemeMode currentThemeMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テーマ設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('ライトモード'),
              subtitle: const Text('明るいテーマ'),
              value: ThemeMode.light,
              groupValue: currentThemeMode,
              onChanged: (value) {
                if (value != null) {
                  themeModeNotifier.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('ダークモード'),
              subtitle: const Text('暗いテーマ'),
              value: ThemeMode.dark,
              groupValue: currentThemeMode,
              onChanged: (value) {
                if (value != null) {
                  themeModeNotifier.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('システム設定に従う'),
              subtitle: const Text('端末の設定に連動'),
              value: ThemeMode.system,
              groupValue: currentThemeMode,
              onChanged: (value) {
                if (value != null) {
                  themeModeNotifier.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('ログアウト'),
          ],
        ),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // サインアウトの成否のみでメッセージを出す
              try {
                await FirebaseAuth.instance.signOut();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ログアウトに失敗しました: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text('ログアウト', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedUserInfo(WidgetRef ref, String uid) {
    final userAsync = ref.watch(userProvider(uid));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '詳細情報',
                  style: Theme.of(ref.context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 編集ボタン（将来的に実装）
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    // TODO: プロフィール編集画面に遷移
                    ScaffoldMessenger.of(ref.context).showSnackBar(
                      const SnackBar(content: Text('プロフィール編集機能は今後実装予定です')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            userAsync.when(
              data: (appUser) {
                if (appUser == null) {
                  return const Text(
                    '詳細情報を読み込めませんでした',
                    style: TextStyle(color: Colors.grey),
                  );
                }

                return Column(
                  children: [
                    _buildInfoRow('ユーザーID', appUser.uid),
                    if (appUser.department != null)
                      _buildInfoRow('学部・学科', appUser.department!),
                    if (appUser.studentId != null)
                      _buildInfoRow('学籍番号', appUser.studentId!),
                    if (appUser.graduationYear != null)
                      _buildInfoRow('卒業年度', '${appUser.graduationYear}年'),
                    _buildInfoRow('登録日', _formatDate(appUser.createdAt)),
                    if (appUser.updatedAt != null)
                      _buildInfoRow('最終更新', _formatDate(appUser.updatedAt!)),
                    _buildInfoRow(
                      'アカウント状態', 
                      appUser.isActive ? 'アクティブ' : '無効',
                      valueColor: appUser.isActive ? Colors.green : Colors.red,
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Column(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'エラー: $error',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.refresh(userProvider(uid)),
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
