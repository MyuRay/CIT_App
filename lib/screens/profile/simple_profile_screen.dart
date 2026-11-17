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
import '../admin/admin_dashboard_screen.dart';
import '../../core/providers/admin_provider.dart';
import '../contact/user_contact_list_screen.dart';
import '../legal/terms_of_service_screen.dart';
import '../legal/privacy_policy_screen.dart';
import 'cit_app_recruitment_screen.dart';
import 'profile_avatar_setup_screen.dart';
import 'account_deletion_screen.dart';
import '../../core/providers/settings_provider.dart';
import '../user_block/blocked_user_list_screen.dart';
import '../../core/providers/in_app_ad_provider.dart';
import '../../models/ads/in_app_ad_model.dart';
import '../../widgets/ads/in_app_ad_card.dart';
import '../../widgets/profile/profile_feature_shortcuts_card.dart';
import '../../widgets/profile/profile_highlight_badge.dart';

class SimpleProfileScreen extends ConsumerWidget {
  const SimpleProfileScreen({super.key});
  static const String _tabTutorialSeenVersionKey = 'tab_tutorial_seen_version';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SecureLogger.debug('🔧 SimpleProfileScreen build開始');

    final themeMode = ref.watch(themeModeProvider);
    final themeModeNotifier = ref.read(themeModeProvider.notifier);
    final storedMainCampus = ref.watch(preferredBusCampusStoredProvider);
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
    final mainCampusLabel =
        storedMainCampus == null
            ? '未設定'
            : storedMainCampus == 'narashino'
            ? '新習志野キャンパス'
            : '津田沼キャンパス';
    final mainCampusNameStyle =
        storedMainCampus == null
            ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )
            : Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            UserAvatar(
                              imageUrl: profileImageUrl,
                              displayName: effectiveDisplayName,
                              colorSeed: currentUser?.uid,
                              radius: 36,
                              initialTextStyle: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (currentUser != null)
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Material(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: const CircleBorder(),
                                  elevation: 1,
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
                                      padding: const EdgeInsets.all(5),
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: AppColors.onColor(
                                          Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap:
                                    () => _showEditCommentNameDialog(
                                      context,
                                      ref,
                                      effectiveDisplayName,
                                    ),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          effectiveDisplayName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.edit,
                                        size: 16,
                                        color:
                                            Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Material(
                                    color:
                                        Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(10),
                                    child: InkWell(
                                      onTap:
                                          () => _showPreferredBusCampusDialog(
                                            context,
                                            ref,
                                            storedMainCampus,
                                          ),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'メインキャンパス',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                        ),
                                                  ),
                                                  Text(
                                                    mainCampusLabel,
                                                    style: mainCampusNameStyle,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (storedMainCampus == null)
                                    const Positioned(
                                      top: -4,
                                      right: -4,
                                      child: ProfileHighlightBadge(),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _ProfileEmailTapZone(
                                email: currentUser?.email,
                                fallbackLabel: 'ログインして全機能をご利用ください',
                              ),
                              if (currentUser != null &&
                                  AppConstants.shouldShowEmailChangeButton(
                                    currentUser.email,
                                  )) ...[
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () => context.push('/change-email'),
                                    child: const Text('メールアドレスを変更'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
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

            ProfileFeatureShortcutsCard(
              themeModeNotifier: themeModeNotifier,
              themeMode: themeMode,
              appFontSize: appFontSize,
              calendarWeekStart: calendarWeekStart,
              onThemeDialog:
                  () => _showThemeSelectionDialog(
                    context,
                    themeModeNotifier,
                    themeMode,
                  ),
              onFontSizeDialog:
                  () => _showFontSizeDialog(context, ref, appFontSize),
              onCalendarDialog:
                  () => _showCalendarWeekStartDialog(
                    context,
                    ref,
                    calendarWeekStart,
                  ),
            ),

            const SizedBox(height: 16),

            // 設定セクション
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '設定',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _ProfileMenuTile(
                    icon: Icons.play_circle_outline,
                    title: '使い方ガイド',
                    subtitle: '各タブの操作見本を確認',
                    onTap: () => _replayTabTutorial(context, ref),
                  ),
                  if (currentUser != null) ...[
                    _ProfileMenuTile(
                      icon: Icons.history,
                      iconColor: AppColors.accent(context, Colors.green),
                      title: 'お問い合わせ履歴',
                      subtitle: '過去のお問い合わせと返信',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const UserContactListScreen(),
                          ),
                        );
                      },
                    ),
                    _ProfileMenuTile(
                      icon: Icons.block,
                      iconColor: AppColors.accent(context, Colors.red),
                      title: 'ブロック済みユーザー',
                      subtitle: 'ブロックしたユーザーの管理',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const BlockedUserListScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  if (currentUser != null) ...[
                    _ProfileMenuTile(
                      icon: Icons.logout,
                      iconColor: AppColors.accent(context, Colors.red),
                      title: 'ログアウト',
                      showChevron: false,
                      onTap: () => _showLogoutDialog(context, ref),
                    ),
                    _ProfileMenuTile(
                      icon: Icons.delete_forever,
                      iconColor: AppColors.accent(context, Colors.red),
                      title: 'アカウント削除',
                      subtitle: 'アカウントと関連データを削除',
                      showChevron: false,
                      onTap:
                          () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AccountDeletionScreen(),
                            ),
                          ),
                    ),
                  ] else
                    _ProfileMenuTile(
                      icon: Icons.login,
                      iconColor: AppColors.accent(context, Colors.blue),
                      title: 'ログイン',
                      showChevron: false,
                      onTap: () => Navigator.of(context).pushNamed('/login'),
                    ),
                  const SizedBox(height: 4),
                  _ProfileSwitchTile(
                    icon: Icons.insights_outlined,
                    title: '利用状況の分析',
                    subtitle:
                        '画面の利用状況や設定を改善に役立てます。氏名・メール・投稿内容は送信しません。この端末でオフにできます。',
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
                  const SizedBox(height: 8),
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

  Future<void> _replayTabTutorial(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_tabTutorialSeenVersionKey);
    ref.read(tabTutorialReplaySignalProvider.notifier).state++;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('チュートリアルを再表示します')),
      );
    }
  }

  Widget _buildAdminSection(BuildContext context, WidgetRef ref, User? currentUser) {
    if (currentUser == null) return const SizedBox.shrink();
    return ref.watch(currentUserAdminProvider).when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      data: (permissions) => permissions?.isAdmin == true
          ? Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: _ProfileMenuTile(
                  icon: Icons.admin_panel_settings_outlined,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: '管理センター',
                  subtitle: '対応待ちの確認・配信・キャンパス運営',
                  onTap:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminDashboardScreen(),
                        ),
                      ),
                ),
              ),
            )
          : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'アプリ情報',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          _ProfileMenuTile(
            icon: Icons.info_outline,
            title: 'バージョン',
            subtitle: AppConstants.appVersion,
            showChevron: false,
          ),
          const _AppDescriptionListTile(),
          _ProfileMenuTile(
            icon: Icons.description_outlined,
            title: '利用規約',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
          _ProfileMenuTile(
            icon: Icons.privacy_tip_outlined,
            title: 'プライバシーポリシー',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
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
    try {
      final picked = await ProfileImageService.pickAvatarImage(source: source);
      if (!context.mounted) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder:
              (_) => ProfileAvatarSetupScreen(uid: uid, imageFile: picked),
        ),
      );
      if (saved != true || !context.mounted) return;
      ref.invalidate(userProvider(uid));
      ref.invalidate(authStateProvider);
      ref.invalidate(currentAppUserStreamProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('表示アイコンを更新しました')),
      );
    } on ProfileImageCancelledException {
      return;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アイコンの更新に失敗しました: $e')),
        );
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
    String? current,
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
    return _ProfileMenuTile(
      icon: Icons.school_outlined,
      title: AppConstants.appDescriptionTitle,
      subtitle: AppConstants.appDescriptionSubtitle,
      showChevron: false,
      onTap: _handleTap,
    );
  }
}

class _ProfileIconBadge extends StatelessWidget {
  const _ProfileIconBadge({
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.size = 44,
    this.iconSize = 24,
  });

  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.primaryContainer.withValues(alpha: 0.55);
    final fg = iconColor ?? scheme.onPrimaryContainer;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, size: iconSize, color: fg),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.backgroundColor,
    this.showChevron = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _ProfileIconBadge(
        icon: icon,
        iconColor: iconColor,
        backgroundColor: backgroundColor,
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle:
          subtitle == null
              ? null
              : Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
      trailing:
          showChevron && onTap != null
              ? Icon(Icons.chevron_right, color: scheme.outline)
              : null,
      onTap: onTap,
    );
  }
}

class _ProfileSwitchTile extends StatelessWidget {
  const _ProfileSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileIconBadge(icon: icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// 管理者のみ: メール表示部を15回タップでマイページ設定を初期化。
class _ProfileEmailTapZone extends ConsumerStatefulWidget {
  const _ProfileEmailTapZone({this.email, required this.fallbackLabel});

  final String? email;
  final String fallbackLabel;

  @override
  ConsumerState<_ProfileEmailTapZone> createState() =>
      _ProfileEmailTapZoneState();
}

class _ProfileEmailTapZoneState extends ConsumerState<_ProfileEmailTapZone> {
  static const int _requiredTaps = 15;
  static const Duration _tapResetGap = Duration(seconds: 3);

  int _tapCount = 0;
  DateTime? _lastTapAt;

  Future<void> _onTap() async {
    final isAdmin = ref.read(currentUserAdminProvider).valueOrNull?.isAdmin;
    if (isAdmin != true) return;

    final now = DateTime.now();
    if (_lastTapAt != null && now.difference(_lastTapAt!) > _tapResetGap) {
      _tapCount = 0;
    }
    _lastTapAt = now;
    _tapCount++;

    if (_tapCount < _requiredTaps) return;
    _tapCount = 0;

    try {
      await ref.read(resetMyPageDefaultsProvider)();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('マイページ設定を初期状態に戻しました')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('設定のリセットに失敗しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.email ?? widget.fallbackLabel;
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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
