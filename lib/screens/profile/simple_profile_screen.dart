import '../../core/theme/app_colors.dart';
import 'package:cit_app/core/utils/logger.dart';


import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../services/user/user_service.dart';
import '../../services/user/profile_image_service.dart';
import '../../widgets/profile/user_avatar.dart';
import '../../core/providers/cwitter_provider.dart';
import '../contact/contact_form_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../core/providers/admin_provider.dart';
import '../contact/user_contact_list_screen.dart';
import '../legal/terms_of_service_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../cafeteria/cafeteria_my_screen.dart';
import 'cit_app_recruitment_screen.dart';
import 'account_deletion_screen.dart';
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
    SecureLogger.debug('🔧 SimpleProfileScreen build開始');

    final themeMode = ref.watch(themeModeProvider);
    final themeModeNotifier = ref.read(themeModeProvider.notifier);
    final preferredBusCampus = ref.watch(preferredBusCampusProvider);
    final appFontSize = ref.watch(appFontSizeProvider);
    final analyticsEnabled = ref.watch(analyticsCollectionEnabledProvider);
    final calendarWeekStart = ref.watch(calendarWeekStartProvider);
    final profileAdAsync = ref.watch(inAppAdProvider(AdPlacement.profileTop));

    SecureLogger.debug('🔧 テーマモード取得成功: $themeMode');

    // Firestore ユーザーをリアルタイム監視して表示名・アイコン変更を即時反映
    final authUserAsync = ref.watch(authStateProvider);
    final currentUser = authUserAsync.when(
      data: (u) => u ?? FirebaseAuth.instance.currentUser,
      loading: () => FirebaseAuth.instance.currentUser,
      error: (_, __) => FirebaseAuth.instance.currentUser,
    );
    SecureLogger.debug('🔧 現在のユーザー: ${currentUser?.email ?? "ゲスト"}');

    final appUserAsync =
        currentUser != null ? ref.watch(currentAppUserStreamProvider) : null;

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
    final profileImageUrl = appUserAsync?.maybeWhen(
      skipLoadingOnReload: true,
      skipError: true,
      data: (appUser) =>
          appUser?.uid == currentUser?.uid
              ? appUser?.profileImageUrl
              : currentUser?.photoURL,
      orElse: () => currentUser?.photoURL,
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
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        UserAvatar(
                          imageUrl: profileImageUrl,
                          displayName: effectiveDisplayName,
                          colorSeed: currentUser?.uid,
                          radius: 40,
                          initialTextStyle: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (currentUser != null)
                          Material(
                            color: Theme.of(context).colorScheme.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap:
                                  () => _showAvatarEditSheet(
                                    context,
                                    ref,
                                    uid: currentUser.uid,
                                    profileImageUrl: profileImageUrl,
                                  ),
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: AppColors.onColor(Theme.of(context).colorScheme.primary),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (currentUser != null)
                      TextButton(
                        onPressed:
                            () => _showAvatarEditSheet(
                              context,
                              ref,
                              uid: currentUser.uid,
                              profileImageUrl: profileImageUrl,
                            ),
                        child: const Text('表示アイコンを変更'),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      effectiveDisplayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentUser?.email ?? 'ログインして全機能をご利用ください',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                    if (currentUser != null &&
                        AppConstants.shouldShowEmailChangeButton(
                          currentUser.email,
                        )) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/change-email'),
                        icon: const Icon(Icons.alternate_email, size: 16),
                        label: const Text('メールアドレスを変更'),
                      ),
                    ],
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
                      SecureLogger.debug('🔧 テーマ設定タップ');
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

                  // 学年暦
                  ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: const Text('学年暦'),
                    subtitle: Text('カレンダー: ${calendarWeekStart.displayName}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap:
                        () => _showCalendarWeekStartDialog(
                          context,
                          ref,
                          calendarWeekStart,
                        ),
                  ),

                  const Divider(height: 1),

                  // タブチュートリアル再表示
                  ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: const Text('チュートリアルを確認'),
                    subtitle: const Text('操作の見本をタップして、各タブの使い方を確認'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final prefs = ref.read(sharedPreferencesProvider);
                      await prefs.remove(_tabTutorialSeenVersionKey);
                      ref
                          .read(tabTutorialReplaySignalProvider.notifier)
                          .state++;
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
                      leading: Icon(
                        Icons.help_center,
                        color: AppColors.accent(context, Colors.blue),
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
                      leading: Icon(Icons.history, color: AppColors.accent(context, Colors.green)),
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
                      leading: Icon(Icons.block, color: AppColors.accent(context, Colors.red)),
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
                      leading: Icon(Icons.logout, color: AppColors.accent(context, Colors.red)),
                      title: const Text('ログアウト'),
                      onTap: () => _showLogoutDialog(context, ref),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.delete_forever,
                        color: AppColors.accent(context, Colors.red),
                      ),
                      title: const Text('アカウント削除'),
                      subtitle: const Text('アカウントと関連データを削除'),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const AccountDeletionScreen(),
                      )),
                    ),
                  ] else ...[
                    ListTile(
                      leading: Icon(Icons.login, color: AppColors.accent(context, Colors.blue)),
                      title: const Text('ログイン'),
                      onTap: () {
                        Navigator.of(context).pushNamed('/login');
                      },
                    ),
                  ],

                  const Divider(height: 1),

                  // 利用状況の分析
                  SwitchListTile(
                    secondary: const Icon(Icons.insights_outlined),
                    title: const Text('利用状況の分析'),
                    subtitle: const Text(
                      '画面の利用状況や設定を改善に役立てます。氏名・メール・投稿内容は送信しません。この端末でオフにできます。',
                    ),
                    value: analyticsEnabled,
                    onChanged: (enabled) async {
                      try {
                        await ref
                            .read(analyticsCollectionEnabledProvider.notifier)
                            .setEnabled(enabled);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('設定を保存できませんでした。もう一度お試しください。'),
                            ),
                          );
                        }
                      }
                    },
                  ),
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

  Widget _buildAdminSection(BuildContext context, WidgetRef ref, User? currentUser) {
    if (currentUser == null) return const SizedBox.shrink();
    return ref.watch(currentUserAdminProvider).when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      data: (permissions) => permissions?.isAdmin == true
          ? Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Card(child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Icon(Icons.admin_panel_settings_outlined, color: Theme.of(context).colorScheme.primary),
                title: const Text('管理センター', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('対応待ちの確認・配信・キャンパス運営'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AdminDashboardScreen())),
              )),
            )
          : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('バージョン'),
            subtitle: Text(AppConstants.appVersion),
          ),

          const Divider(height: 1),

          const _AppDescriptionListTile(),

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
    SecureLogger.debug('🔧 テーマ選択ダイアログ表示');
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

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                 Icon(Icons.construction, color: AppColors.accent(context, Colors.orange)),
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

  void _showAvatarEditSheet(
    BuildContext context,
    WidgetRef ref, {
    required String uid,
    String? profileImageUrl,
  }) {
    final hasImage =
        profileImageUrl != null && profileImageUrl.trim().isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '表示アイコン',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('ライブラリから選ぶ'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _updateAvatar(context, ref, uid, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('カメラで撮影'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _updateAvatar(context, ref, uid, ImageSource.camera);
                  },
                ),
                if (hasImage)
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: AppColors.accent(context, Colors.red),
                    ),
                    title: Text(
                      'アイコンを削除',
                      style: TextStyle(color: AppColors.accent(context, Colors.red)),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _removeAvatar(context, ref, uid);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  Future<void> _updateAvatar(
    BuildContext context,
    WidgetRef ref,
    String uid,
    ImageSource source,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ProfileImageService.pickAndUpload(uid: uid, source: source);
      ref.invalidate(userProvider(uid));
      ref.invalidate(authStateProvider);
      ref.invalidate(currentAppUserStreamProvider);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('表示アイコンを更新しました')));
    } on ProfileImageCancelledException {
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('アイコンの更新に失敗しました: $e')));
      }
    }
  }

  Future<void> _removeAvatar(
    BuildContext context,
    WidgetRef ref,
    String uid,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ProfileImageService.removeProfileImage(uid);
      ref.invalidate(userProvider(uid));
      ref.invalidate(authStateProvider);
      ref.invalidate(currentAppUserStreamProvider);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('表示アイコンを削除しました')));
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('アイコンの削除に失敗しました: $e')));
      }
    }
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
                    await UserService.updateUserProfile(
                      uid: user.uid,
                      displayName: newName,
                    );
                    ref.invalidate(authStateProvider);
                    ref.invalidate(currentAppUserStreamProvider);
                    ref.invalidate(userProvider(user.uid));
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

  void _showCalendarWeekStartDialog(
    BuildContext context,
    WidgetRef ref,
    CalendarWeekStart current,
  ) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.calendar_month),
                SizedBox(width: 8),
                Text('学年暦カレンダー'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  CalendarWeekStart.values
                      .map(
                        (option) => RadioListTile<CalendarWeekStart>(
                          title: Text(option.displayName),
                          value: option,
                          groupValue: current,
                          onChanged: (value) async {
                            if (value == null) return;
                            await ref.read(setCalendarWeekStartProvider)(value);
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);
    final errorBackground = AppColors.snackBarSurface(context, Colors.red);
    final authService = ref.read(authServiceProvider);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: AppColors.accent(context, Colors.orange)),
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
                    await authService.signOut();
                  } catch (e) {
                    if (messenger.mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('通知の解除に失敗しました。通信を確認して、もう一度ログアウトしてください。'),
                          backgroundColor: errorBackground,
                        ),
                      );
                    }
                    return;
                  }
                  // The auth router redirects after sign-out completes.
                },
                child: Text('ログアウト', style: TextStyle(color: AppColors.accent(context, Colors.red))),
              ),
            ],
          ),
    );
  }

}

class _AppDescriptionListTile extends StatefulWidget {
  const _AppDescriptionListTile();

  @override
  State<_AppDescriptionListTile> createState() =>
      _AppDescriptionListTileState();
}

class _AppDescriptionListTileState extends State<_AppDescriptionListTile> {
  int _tapCount = 0;

  void _handleTap() {
    _tapCount++;
    if (_tapCount < AppConstants.developerRecruitmentTapThreshold) return;

    _tapCount = 0;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CitAppRecruitmentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.school),
      title: const Text(AppConstants.appDescriptionTitle),
      subtitle: Text(
        AppConstants.appDescriptionSubtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: _handleTap,
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
