import 'dart:async';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../models/user/user_model.dart';
import '../../services/user/user_service.dart';
import '../admin/notification_management_screen.dart';
import '../admin/user_management_screen.dart';
import '../admin/contact_management_screen.dart';
import '../admin/admin_management_screen.dart';
import '../admin/bulletin_management_screen.dart';
import '../admin/bus_admin_screen.dart';
import '../admin/in_app_ad_management_screen.dart';
import '../admin/lecture_period_settings_screen.dart';
import '../admin/academic_calendar_settings_screen.dart';
import '../contact/contact_form_screen.dart';
import '../reports/report_management_screen.dart';
import '../contact/user_contact_list_screen.dart';
import '../legal/terms_of_service_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../cafeteria/cafeteria_my_screen.dart';
import '../../core/providers/settings_provider.dart';
import '../user_block/blocked_user_list_screen.dart';
import '../../core/providers/in_app_ad_provider.dart';
import '../../models/ads/in_app_ad_model.dart';
import '../../widgets/ads/in_app_ad_card.dart';

class SimpleProfileScreen extends ConsumerWidget {
  const SimpleProfileScreen({super.key});
  static const String _tabTutorialSeenVersionKey = 'tab_tutorial_seen_version';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🔧 SimpleProfileScreen build開始');

    final themeMode = ref.watch(themeModeProvider);
    final themeModeNotifier = ref.read(themeModeProvider.notifier);
    final preferredBusCampus = ref.watch(preferredBusCampusProvider);
    final preferredTrainDirection = ref.watch(
      preferredTrainDirectionProvider(preferredBusCampus),
    );
    final appFontSize = ref.watch(appFontSizeProvider);
    final profileAdAsync = ref.watch(inAppAdProvider(AdPlacement.profileTop));

    print('🔧 テーマモード取得成功: $themeMode');

    // 認証プロバイダーを監視して、表示名変更をリアルタイム反映
    final authUserAsync = ref.watch(authStateProvider);
    final currentUser = authUserAsync.when(
      data: (u) => u ?? FirebaseAuth.instance.currentUser,
      loading: () => FirebaseAuth.instance.currentUser,
      error: (_, __) => FirebaseAuth.instance.currentUser,
    );
    print('🔧 現在のユーザー: ${currentUser?.email ?? "ゲスト"}');

    AsyncValue<AppUser?>? appUserAsync;
    if (currentUser != null) {
      appUserAsync = ref.watch(userProvider(currentUser.uid));
    }

    final firestoreDisplayName = appUserAsync?.maybeWhen(
      data: (appUser) => appUser?.displayName,
      orElse: () => null,
    );
    final firebaseDisplayName = currentUser?.displayName;
    final effectiveDisplayName = _resolveDisplayName(
      primary: firestoreDisplayName,
      secondary: firebaseDisplayName,
      isLoggedIn: currentUser != null,
    );
    final avatarInitial = _computeAvatarInitial(
      effectiveDisplayName,
      isLoggedIn: currentUser != null,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('マイページ'), actions: const []),
      body: SingleChildScrollView(
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
                        avatarInitial,
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      effectiveDisplayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentUser?.email ?? 'ログインして全機能をご利用ください',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed:
                          () => _showEditCommentNameDialog(
                            context,
                            ref,
                            effectiveDisplayName,
                          ),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('表示名を編集'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            profileAdAsync.when(
              data:
                  (ad) =>
                      ad == null
                          ? const SizedBox.shrink()
                          : Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: InAppAdCard(
                              ad: ad,
                              placement: AdPlacement.profileTop,
                            ),
                          ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

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

                  // 電車優先方面設定
                  ListTile(
                    leading: const Icon(Icons.train),
                    title: const Text('電車の優先方面を設定'),
                    subtitle: Text(
                      preferredTrainDirection == 'down' ? '下りを優先表示' : '上りを優先表示',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap:
                        () => _showPreferredTrainDirectionDialog(
                          context,
                          ref,
                          preferredBusCampus,
                          preferredTrainDirection,
                        ),
                  ),

                  const Divider(height: 1),

                  // テーマ設定
                  ListTile(
                    leading: Icon(
                      themeModeNotifier.isDarkMode(context)
                          ? Icons.dark_mode
                          : Icons.light_mode,
                    ),
                    title: const Text('テーマ設定'),
                    subtitle: Text(themeModeNotifier.currentThemeDisplayName),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      print('🔧 テーマ設定タップ');
                      _showThemeSelectionDialog(
                        context,
                        themeModeNotifier,
                        themeMode,
                      );
                    },
                  ),

                  const Divider(height: 1),

                  // メインキャンパス設定
                  ListTile(
                    leading: const Icon(Icons.school),
                    title: const Text('メインキャンパスを設定'),
                    subtitle: Text(
                      preferredBusCampus == 'narashino'
                          ? '新習志野キャンパス'
                          : '津田沼キャンパス',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap:
                        () => _showPreferredBusCampusDialog(
                          context,
                          ref,
                          preferredBusCampus,
                        ),
                  ),

                  const Divider(height: 1),

                  // 文字サイズ設定
                  ListTile(
                    leading: const Icon(Icons.format_size),
                    title: const Text('文字サイズ'),
                    subtitle: Text(appFontSize.displayName),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showFontSizeDialog(context, ref, appFontSize),
                  ),

                  const Divider(height: 1),

                  // タブチュートリアル再表示
                  ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: const Text('チュートリアルを確認'),
                    subtitle: const Text('各タブの使い方ガイドを再表示'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final prefs = ref.read(sharedPreferencesProvider);
                      await prefs.remove(_tabTutorialSeenVersionKey);
                      ref.read(tabTutorialReplaySignalProvider.notifier).state++;
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('チュートリアルを再表示します')),
                        );
                      }
                    },
                  ),

                  const Divider(height: 1),

                  // My食堂
                  ListTile(
                    leading: const Icon(Icons.favorite),
                    title: const Text('My食堂'),
                    subtitle: const Text('自分のレビュー履歴とお気に入りを確認'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MyCafeteriaScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 1),

                  // お問い合わせフォーム（ログインユーザー向け）
                  if (currentUser != null) ...[
                    ListTile(
                      leading: const Icon(
                        Icons.help_center,
                        color: Colors.blue,
                      ),
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

                    // お問い合わせ履歴
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const BlockedUserListScreen(),
                          ),
                        );
                      },
                    ),

                    const Divider(height: 1),
                  ],

                  // ログアウト（ユーザーがログインしている場合のみ）
                  if (currentUser != null) ...[
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('ログアウト'),
                      onTap: () => _showLogoutDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('アカウント削除'),
                      subtitle: const Text('アカウントとすべてのデータを削除'),
                      onTap: () => _showDeleteAccountDialog(context, ref),
                    ),
                  ] else ...[
                    ListTile(
                      leading: const Icon(Icons.login, color: Colors.blue),
                      title: const Text('ログイン'),
                      onTap: () {
                        Navigator.of(context).pushNamed('/login');
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 管理者セクション（管理者のみ表示）
            _buildAdminSection(context, ref, currentUser),

            // アプリ情報
            _buildAppInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSection(
    BuildContext context,
    WidgetRef ref,
    User? currentUser,
  ) {
    print('🔧 管理者セクション構築開始');

    // ログインチェック
    if (currentUser == null) {
      print('🔧 未ログインのため管理者セクション非表示');
      return const SizedBox.shrink(); // 未ログイン時は非表示
    }

    // 直接Firestoreアクセス（プロバイダーの問題により一時的に使用）
    return FutureBuilder<bool>(
      future: _checkAdminStatusDirectly(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('🔧 管理者権限確認中...');
          return const SizedBox.shrink(); // ローディング中は非表示
        }

        if (snapshot.hasError) {
          print('🔧 管理者権限確認エラー: ${snapshot.error}');
          return const SizedBox.shrink(); // エラー時は非表示
        }

        final isAdmin = snapshot.data ?? false;
        print('🔧 管理者権限チェック結果: $isAdmin');

        if (isAdmin) {
          return Column(
            children: [_buildAdminCard(context), const SizedBox(height: 24)],
          );
        } else {
          return const SizedBox.shrink(); // 非管理者は非表示
        }
      },
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),

          const ListTile(
            leading: Icon(Icons.info),
            title: Text('バージョン'),
            subtitle: Text('2.0.0'),
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

          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('利用規約'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),

          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showThemeSelectionDialog(
    BuildContext context,
    ThemeModeNotifier themeModeNotifier,
    ThemeMode currentThemeMode,
  ) {
    print('🔧 テーマ選択ダイアログ表示');
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('テーマ設定'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('ライトモード(推奨)'),
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

  Widget _buildAdminCard(BuildContext context) {
    return Column(
      children: [
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '管理者機能',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 通知管理
              ListTile(
                leading: const Icon(Icons.campaign, color: Colors.blue),
                title: const Text('通知管理'),
                subtitle: const Text('アプリアップデート・お知らせの配信'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => const NotificationManagementScreen(),
                    ),
                  );
                },
              ),

              const Divider(height: 1),

              // 掲示板管理
              ListTile(
                leading: const Icon(Icons.forum, color: Colors.green),
                title: const Text('掲示板管理'),
                subtitle: const Text('投稿の管理・削除'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BulletinManagementScreen(),
                    ),
                  );
                },
              ),

              const Divider(height: 1),

              // 通報管理
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.red),
                title: const Text('通報管理'),
                subtitle: const Text('ユーザーからの通報対応'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ReportManagementScreen(),
                    ),
                  );
                },
              ),

              const Divider(height: 1),

              // お問い合わせ管理
              ListTile(
                leading: const Icon(Icons.help_center, color: Colors.orange),
                title: const Text('お問い合わせ管理'),
                subtitle: const Text('ユーザーからの問い合わせ対応'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ContactManagementScreen(),
                    ),
                  );
                },
              ),

              const Divider(height: 1),

              // ユーザー管理
              ListTile(
                leading: const Icon(Icons.people, color: Colors.purple),
                title: const Text('ユーザー管理'),
                subtitle: const Text('権限管理・アカウント管理'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UserManagementScreen(),
                    ),
                  );
                },
              ),

              const Divider(height: 1),

              ListTile(
                leading: const Icon(
                  Icons.campaign_outlined,
                  color: Colors.teal,
                ),
                title: const Text('広告管理'),
                subtitle: const Text('アプリ内広告の作成・編集・削除'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const InAppAdManagementScreen(),
                    ),
                  );
                },
              ),

              const Divider(height: 1),

              // 講義期間設定
              ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.indigo),
                title: const Text('講義期間設定'),
                subtitle: const Text('前期・後期の開始日/終了日を設定'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LecturePeriodSettingsScreen(),
                    ),
                  );
                },
              ),

              const Divider(height: 1),

              // 学年暦予定管理
              ListTile(
                leading: const Icon(Icons.event_note, color: Colors.deepOrange),
                title: const Text('学年暦予定管理'),
                subtitle: const Text('ホームの学年暦予定を編集'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AcademicCalendarSettingsScreen(),
                    ),
                  );
                },
              ),

              const Divider(height: 1),

              // 学バス管理
              ListTile(
                leading: const Icon(Icons.directions_bus, color: Colors.green),
                title: const Text('学バス管理'),
                subtitle: const Text('バス路線・運行期間の管理'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  print('🔧 学バス管理ボタンがタップされました（管理者機能）');
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BusAdminScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<bool> _checkAdminStatusDirectly(String userId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('admin_permissions')
              .doc(userId)
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        return data['isAdmin'] as bool? ?? false;
      } else {
        return false; // ドキュメントが存在しない場合は非管理者
      }
    } catch (e) {
      return false; // エラー時は非管理者として扱う
    }
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.construction, color: Colors.orange),
                const SizedBox(width: 8),
                Text('$feature（開発中）'),
              ],
            ),
            content: const Text('この機能は現在開発中です。\n近日中に実装予定です。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showEditCommentNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentDisplayName,
  ) {
    final current = FirebaseAuth.instance.currentUser;
    String initial = currentDisplayName.trim();
    if (initial.isEmpty || initial == 'ユーザー' || initial == 'ゲストユーザー') {
      final firebaseName = current?.displayName?.trim() ?? '';
      if (firebaseName.isNotEmpty) {
        initial = firebaseName;
      } else {
        initial = current?.email?.split('@').first ?? '';
      }
    }
    final controller = TextEditingController(text: initial);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('コメント表示名を編集'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: '表示名'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('表示名を入力してください')),
                    );
                    return;
                  }
                  try {
                    final auth = FirebaseAuth.instance;
                    final user = auth.currentUser;
                    if (user == null) {
                      throw Exception('ログインが必要です');
                    }
                    await user.updateDisplayName(newName);
                    await user.reload();
                    // Firestoreプロフィールも更新（存在しない場合は無視）
                    try {
                      await UserService.updateUserProfile(
                        uid: user.uid,
                        displayName: newName,
                      );
                    } catch (_) {}
                    // 表示を即時反映
                    ref.invalidate(authStateProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
                    }
                  } finally {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('表示名を更新しました')),
                      );
                    }
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
    );
  }

  void _showPreferredBusCampusDialog(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.school),
                SizedBox(width: 8),
                Text('メインキャンパスを設定'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('津田沼キャンパス'),
                  value: 'tsudanuma',
                  groupValue: current,
                  onChanged: (v) async {
                    if (v == null) return;
                    await ref.read(setPreferredBusCampusProvider)(v);
                    if (context.mounted) Navigator.of(context).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('メインキャンパスを「津田沼」に設定しました')),
                      );
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('新習志野キャンパス'),
                  value: 'narashino',
                  groupValue: current,
                  onChanged: (v) async {
                    if (v == null) return;
                    await ref.read(setPreferredBusCampusProvider)(v);
                    if (context.mounted) Navigator.of(context).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('メインキャンパスを「新習志野」に設定しました')),
                      );
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
    );
  }

  void _showPreferredTrainDirectionDialog(
    BuildContext context,
    WidgetRef ref,
    String campus,
    String currentDirection,
  ) {
    final campusLabel = campus == 'narashino' ? '新習志野キャンパス' : '津田沼キャンパス';
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.train),
                const SizedBox(width: 8),
                Expanded(child: Text('$campusLabelの優先方面')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('上り'),
                  value: 'up',
                  groupValue: currentDirection,
                  onChanged: (v) async {
                    if (v == null) return;
                    await ref.read(setPreferredTrainDirectionProvider)(campus, v);
                    if (context.mounted) Navigator.of(context).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('優先方面を上りに設定しました')));
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('下り'),
                  value: 'down',
                  groupValue: currentDirection,
                  onChanged: (v) async {
                    if (v == null) return;
                    await ref.read(setPreferredTrainDirectionProvider)(campus, v);
                    if (context.mounted) Navigator.of(context).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('優先方面を下りに設定しました')));
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
    );
  }

  void _showFontSizeDialog(
    BuildContext context,
    WidgetRef ref,
    AppFontSizeOption current,
  ) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.format_size),
                SizedBox(width: 8),
                Text('文字サイズ'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  AppFontSizeOption.values
                      .map(
                        (option) => RadioListTile<AppFontSizeOption>(
                          title: Text(option.displayName),
                          value: option,
                          groupValue: current,
                          onChanged: (value) async {
                            if (value == null) return;
                            await ref.read(setAppFontSizeProvider)(value);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          },
                        ),
                      )
                      .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                  // サインアウト自体のみを監視
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
                  // ナビゲーションは別処理（エラーでも失敗メッセージは出さない）
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
                child: const Text('ログアウト', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('アカウント削除'),
          ],
        ),
        content: const Text(
          'アカウントを削除すると、すべてのデータが完全に削除されます。\n\nこの操作は取り消せません。本当に削除しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDeleteAccountConfirmationDialog(context, ref);
            },
            child: const Text(
              'アカウント削除',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('最終確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '本当にアカウントを削除しますか？\n\n確認のため「削除する」と入力してください。',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: '「削除する」と入力',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (confirmController.text.trim() != '削除する') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('「削除する」と正確に入力してください'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.of(context).pop();

              // ローディング表示
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              bool isAccountDeleted = false;
              String? completedWithWarning;
              String? errorMessage;

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) throw Exception('ログインが必要です');

                // Firestore削除は失敗してもAuth削除は継続し、退会不能を避ける
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .delete()
                      .timeout(const Duration(seconds: 12));
                } on TimeoutException {
                  completedWithWarning = 'ユーザーデータ削除がタイムアウトしました（アカウント削除は継続）';
                } catch (_) {
                  completedWithWarning = '一部データの削除に失敗しましたが、アカウント削除は継続します';
                }

                // Firebase Authenticationのアカウントを削除
                await user.delete().timeout(const Duration(seconds: 12));
                isAccountDeleted = true;
              } on FirebaseAuthException catch (e) {
                if (e.code == 'requires-recent-login') {
                  errorMessage = 'セキュリティ保護のため、再ログイン後にもう一度お試しください';
                } else {
                  errorMessage = e.message ?? '認証アカウントの削除に失敗しました';
                }
              } on TimeoutException {
                errorMessage = '通信がタイムアウトしました。ネットワークをご確認のうえ再試行してください';
              } catch (e) {
                errorMessage = 'アカウント削除に失敗しました: $e';
              } finally {
                if (context.mounted) {
                  Navigator.of(context).pop(); // ローディングを閉じる
                }
              }

              if (!context.mounted) return;

              if (isAccountDeleted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(completedWithWarning ?? 'アカウントを削除しました'),
                    backgroundColor:
                        completedWithWarning == null ? Colors.green : Colors.orange,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage ?? 'アカウント削除に失敗しました'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('削除する'),
          ),
        ],
      ),
    );
  }
}

String _resolveDisplayName({
  String? primary,
  String? secondary,
  required bool isLoggedIn,
}) {
  if (primary != null && primary.trim().isNotEmpty) {
    return primary.trim();
  }
  if (secondary != null && secondary.trim().isNotEmpty) {
    return secondary.trim();
  }
  return isLoggedIn ? 'ユーザー' : 'ゲストユーザー';
}

String _computeAvatarInitial(String displayName, {required bool isLoggedIn}) {
  final trimmed = displayName.trim();
  if (trimmed.isNotEmpty) {
    final first = trimmed.characters.first;
    return first.toUpperCase();
  }
  return isLoggedIn ? 'U' : 'G';
}
