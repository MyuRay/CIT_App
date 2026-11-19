import '../../core/providers/assignment_notification_provider.dart';
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import 'package:cit_app/core/utils/logger.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/providers/assignment_provider.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/providers/admin_navigation_provider.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../core/services/analytics_service.dart';
import '../../core/providers/bulletin_provider.dart';
import '../../core/providers/community_tab_provider.dart';
import '../../core/providers/cwitter_composer_back_provider.dart';
import '../../core/providers/cwitter_provider.dart';
import '../../core/providers/legal_consent_provider.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/providers/home_feature_intro_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../models/schedule/schedule_model.dart';
import '../../services/schedule/attendance_availability.dart';
import '../../services/auth/tab_tutorial_progress.dart';
import '../../services/auth/my_page_relocation_progress.dart';
import '../../widgets/home/my_page_relocation_guide.dart';
import '../../services/schedule/attendance_service.dart';
import '../../services/schedule/class_notification_payload.dart';
import '../../services/schedule/schedule_notification_service.dart';
import '../../services/schedule/schedule_service.dart';
import '../../services/notification/notification_service.dart';
import '../../services/notification/notification_target.dart';
import '../../services/notification/notification_navigation.dart';
import '../../widgets/auth/legacy_email_migration_dialog.dart';
import '../../widgets/common/ui_feedback_listener.dart';
import '../bulletin/bulletin_screen.dart';
import '../community/community_screen.dart';
import '../home/home_screen.dart';
import '../legal/community_legal_update_consent_gate.dart';
import '../schedule/attendance_qr_reader_screen.dart';
import '../schedule/schedule_screen.dart';
import 'widgets/main_navigation_bar.dart';
import 'widgets/visual_tab_tutorial.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final Set<int> _visitedTabIndices = <int>{};
  bool _didCheckTabTutorial = false;
  String? _tutorialUserId;
  bool _isTabTutorialShowing = false;
  int _lastTutorialReplaySignal = 0;
  bool _didCheckEmailMigrationPrompt = false;
  bool _isEmailMigrationPromptShowing = false;
  final _profileAvatarAnchorKey = GlobalKey(debugLabel: 'homeMyPageAvatar');
  final _homeMenuAnchorKey = GlobalKey(debugLabel: 'homeMenu');
  int _communityGuideIndex = 0;
  final _controlGuideKeys = {
    for (final name in ['semester', 'assignment', 'attendance', 'scheduleEdit',
      'share', 'saturday', 'excelImport', 'communitySwitch', 'chibaTab', 'communitySearch', 'categories', 'bulletinPost'])
      name: GlobalKey(debugLabel: name),
  };
  final _navigationGuideKeys = List.generate(MainNavigation.destinationCount,
      (index) => GlobalKey(debugLabel: 'navigationGuide$index'));
  final _myPageGuideShownUsers = <String>{};
  Timer? _myPageGuideTimer;
  bool _isMyPageGuideShowing = false;

  StreamSubscription<String>? _notificationTapSub;
  StreamSubscription<void>? _pushTapSub;
  bool _handlingNotificationTap = false;
  bool _didBootstrapScheduleNotifications = false;

  int get safeCurrentIndex => _currentIndex == MainNavigation.adminIndex &&
      ref.read(currentUserAdminProvider).valueOrNull?.isAdmin == true
          ? MainNavigation.adminIndex : MainNavigation.normalizeIndex(_currentIndex);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = MainNavigation.normalizeIndex(widget.initialTabIndex);
    _visitedTabIndices.add(_currentIndex);
    _pushTapSub = NotificationService.taps.changes.listen((_) => _consumePushTap());

    // 講義通知タップを購読
    _notificationTapSub = ScheduleNotificationService.onNotificationTap.listen((
      payload,
    ) {
      _handleScheduleNotificationPayload(
        ScheduleNotificationService.consumePendingLaunchPayload() ?? payload,
      );
    });

    // アプリが完全終了状態から通知タップで起動された場合に拾う
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(analyticsServiceProvider).showMainTab(safeCurrentIndex));
      if (safeCurrentIndex == MainNavigation.homeIndex) {
        ref.read(homeTabVisitSignalProvider.notifier).update((s) => s + 1);
      }
      final pending = ScheduleNotificationService.consumePendingLaunchPayload();
      if (pending != null) {
        _handleScheduleNotificationPayload(pending);
      }
      _consumePushTap();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _myPageGuideTimer?.cancel();
    _notificationTapSub?.cancel();
    _pushTapSub?.cancel();
    _notificationTapSub = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex == widget.initialTabIndex) return;

    _currentIndex = MainNavigation.normalizeIndex(widget.initialTabIndex);
    _visitedTabIndices.add(_currentIndex);
    unawaited(ref.read(analyticsServiceProvider).showMainTab(safeCurrentIndex));
  }

  void _consumePushTap() {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (!mounted || user == null || !user.emailVerified) return;
    final target = NotificationService.taps.consume(user.uid);
    if (target != null) NotificationNavigation.open(context, target);
  }

  /// 通知タップ時の payload を処理する。
  ///
  /// payload は [ClassNotificationPayload] が JSON 文字列にエンコードしたもの。
  /// type が `class_attendance` 以外、または parse 失敗時は何もせずに無視する。
  Future<void> _handleScheduleNotificationPayload(String payload) async {
    try {
      final value = jsonDecode(payload);
      if (value is Map && value['kind'] == 'assignment_reminder') {
        if (mounted && value['userId'] == ref.read(authStateProvider).valueOrNull?.uid) {
          ref.read(assignmentViewOpenProvider.notifier).state = true;
          _selectTab(MainNavigation.scheduleIndex);
        }
        return;
      }
    } catch (_) {}
    final pushTarget = NotificationTarget.tryParse(payload);
    if (pushTarget != null) {
      NotificationService.taps.add(pushTarget);
      return;
    }
    if (_handlingNotificationTap) return;
    _handlingNotificationTap = true;
    try {
      final parsed = ClassNotificationPayload.tryParse(payload);
      if (parsed == null) {
        SecureLogger.debug('⚠️ 通知 payload 解析失敗 or class_attendance 以外: $payload');
        return;
      }

      // 時間割タブに切り替え
      if (mounted && safeCurrentIndex != MainNavigation.scheduleIndex) {
        _selectTab(MainNavigation.scheduleIndex);
        // 1フレーム待ってタブ切り替えを反映させる
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (!mounted) return;

      // 出席可能時間判定は payload の startDateTime を基準に「今」で判定する。
      // 通知が届いた時刻ではなく、ユーザーが実際にタップした瞬間で判定するため。
      final now = DateTime.now();
      final inWindow = AttendanceAvailability.isWithinWindow(
        now: now,
        startDateTime: parsed.startDateTime,
      );

      if (!inWindow) {
        await _showOutOfAttendanceWindowDialog(
          subjectName: parsed.subjectName,
          startDateTime: parsed.startDateTime,
        );
        return;
      }

      // 出席可能時間内: 出席記録に必要な Schedule / ScheduleClass をロードする。
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        SecureLogger.debug('⚠️ 通知タップ時 userId が null。出席記録はスキップして QR のみ起動。');
      }

      Schedule? schedule;
      ScheduleClass? scheduleClass;
      String? weekdayKey;
      if (userId != null) {
        try {
          final schedules = await ScheduleService.getAllSchedulesByUserId(
            userId,
          );
          if (schedules.isNotEmpty) {
            schedule =
                schedules.where((s) => s.id == parsed.scheduleId).firstOrNull;
            schedule ??= schedules.first;
            weekdayKey = _weekdayKeyFromInt(parsed.weekday);
            if (weekdayKey != null) {
              scheduleClass = schedule.timetable[weekdayKey]?[parsed.period];
            }
          }
        } catch (e) {
          SecureLogger.debug('⚠️ 通知タップ時の時間割ロード失敗: $e');
        }
      }

      if (!mounted) return;

      // 既存の QR リーダー画面を起動（既存ルート/画面をそのまま再利用）
      String? scannedRaw;
      try {
        scannedRaw = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => const AttendanceQrReaderScreen()),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('QRリーダーを起動できませんでした: $e')));
        return;
      }
      if (scannedRaw == null || scannedRaw.trim().isEmpty) return;

      // 出席ポータルを外部ブラウザで開く（既存挙動を踏襲）
      await _openAttendancePortalFromQr(scannedRaw);
      if (!mounted) return;

      // 出席記録（必要情報が揃っているときだけ）
      if (userId == null ||
          schedule == null ||
          scheduleClass == null ||
          weekdayKey == null) {
        return;
      }

      try {
        final result = await AttendanceService.markAttendanceFromTap(
          userId: userId,
          scheduleId: schedule.id,
          schedule: schedule,
          weekdayKey: weekdayKey,
          startPeriod: parsed.period,
          scheduleClass: scheduleClass,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.snackBarSurface(context, result.success ? Colors.green : Colors.orange),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('出欠記録に失敗しました: $e')));
      }
    } finally {
      _handlingNotificationTap = false;
    }
  }

  /// アプリ起動時に通知 ON のユーザーへ、最新の時間割をもとに通知を再予約する。
  /// 講義期間設定がある場合は、講義期間終了日までの通知を一度に予約する。
  Future<void> _bootstrapScheduleNotifications() async {
    try {
      final notificationEnabled = ref.read(scheduleNotificationEnabledProvider);
      if (!notificationEnabled) return;

      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      // 通知サービス初期化が main.dart の遅延処理で実行されるため、少しだけ待つ。
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted ||
          ref.read(currentUserIdProvider) != userId ||
          !ref.read(scheduleNotificationEnabledProvider)) {
        return;
      }

      final schedule = await ScheduleService.getSelectedScheduleByUserId(
        userId,
        selectedScheduleId: ref.read(selectedScheduleIdProvider),
      );
      if (!mounted ||
          schedule == null ||
          ref.read(currentUserIdProvider) != userId ||
          !ref.read(scheduleNotificationEnabledProvider)) {
        return;
      }
      await ScheduleNotificationService.scheduleWeeklyNotifications(schedule);
      SecureLogger.debug('🔁 起動時の授業通知再予約 完了 (scheduleId=${schedule.id})');
    } catch (e) {
      SecureLogger.debug('⚠️ 起動時の授業通知再予約に失敗: $e');
    }
  }

  String? _weekdayKeyFromInt(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
      default:
        return null;
    }
  }

  Future<void> _showOutOfAttendanceWindowDialog({
    required String subjectName,
    required DateTime startDateTime,
  }) async {
    final timeText =
        '${startDateTime.month}/${startDateTime.day} ${startDateTime.hour}:${startDateTime.minute.toString().padLeft(2, '0')}';
    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.schedule, color: AppColors.accent(context, Colors.orange)),
                SizedBox(width: 8),
                Text('出席可能時間外です'),
              ],
            ),
            content: Text(
              'この授業の出席受付時間外です。\n'
              '対象: ${subjectName.isNotEmpty ? subjectName : "対象の授業"}（開始 $timeText）\n'
              '受付: 開始${AttendanceAvailability.beforeMinutes}分前〜開始${AttendanceAvailability.afterMinutes}分後',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _openAttendancePortalFromQr(String scannedRaw) async {
    final raw = scannedRaw.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    final isWeb =
        (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    if (!isWeb) return;
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('出席サイトを開けませんでした')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('出席サイトを開けませんでした: $e')));
    }
  }

  void _navigateToSchedule() {
    _selectTab(MainNavigation.scheduleIndex);
  }

  void _selectTab(int index) {
    final nextIndex = index == MainNavigation.adminIndex &&
        ref.read(currentUserAdminProvider).valueOrNull?.isAdmin == true
            ? MainNavigation.adminIndex : MainNavigation.normalizeIndex(index);
    if (_currentIndex == nextIndex && _visitedTabIndices.contains(nextIndex)) {
      return;
    }
    setState(() {
      _currentIndex = nextIndex;
      _visitedTabIndices.add(nextIndex);
    });
    unawaited(ref.read(analyticsServiceProvider).showMainTab(nextIndex));
    if (nextIndex == MainNavigation.homeIndex) {
      ref.read(homeTabVisitSignalProvider.notifier).update((s) => s + 1);
    }
  }

  Widget _buildTabScreen(int index) {
    if (!_visitedTabIndices.contains(index)) {
      return const SizedBox.shrink();
    }

    final screen = switch (index) {
      MainNavigation.homeIndex => HomeScreen(
        onNavigateToSchedule: _navigateToSchedule,
        profileAvatarAnchorKey: _profileAvatarAnchorKey,
        homeMenuAnchorKey: _homeMenuAnchorKey,
      ),
      MainNavigation.scheduleIndex => ScheduleScreen(
        semesterAnchorKey: _controlGuideKeys['semester'],
        assignmentAnchorKey: _controlGuideKeys['assignment'],
        attendanceAnchorKey: _controlGuideKeys['attendance'],
        editAnchorKey: _controlGuideKeys['scheduleEdit'],
        shareAnchorKey: _controlGuideKeys['share'],
        saturdayAnchorKey: _controlGuideKeys['saturday'],
        excelImportAnchorKey: _controlGuideKeys['excelImport'],
      ),
      MainNavigation.communityIndex => CommunityScreen(
        tutorialActive: _isTabTutorialShowing,
        guideTabIndex: _isTabTutorialShowing ? _communityGuideIndex : null,
        chibaAnchorKey: _controlGuideKeys['chibaTab'],
        switchAnchorKey: _controlGuideKeys['communitySwitch'],
        searchAnchorKey: _controlGuideKeys['communitySearch'],
      ),
      MainNavigation.bulletinIndex => BulletinScreen(
        categoriesAnchorKey: _controlGuideKeys['categories'],
        postAnchorKey: _controlGuideKeys['bulletinPost'],
      ),
      MainNavigation.adminIndex => const AdminDashboardScreen(),
      _ => const SizedBox.shrink(),
    };

    return KeyedSubtree(
      key: PageStorageKey<String>('main-tab-$index'),
      child: screen,
    );
  }

  Widget _buildTabStack() {
    return IndexedStack(
      index: safeCurrentIndex,
      children: List<Widget>.generate(
        MainNavigation.destinationCount + 1,
        _buildTabScreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(assignmentReminderSyncProvider);
    // 認証状態を確認
    final authState = ref.watch(authStateProvider);
    final tutorialReplaySignal = ref.watch(tabTutorialReplaySignalProvider);
    // 利用規約同意ポップアップと被らないよう、同意完了後にチュートリアルを開始する
    final hasLegalConsent = ref.watch(hasAcceptedCurrentLegalConsentProvider);

    return authState.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: (user) {
        if (user == null) {
          // ユーザーが未認証の場合は空のコンテナ（ルーターがリダイレクトを処理）
          return const Scaffold(body: Center(child: Text('リダイレクト中...')));
        }
        // 利用規約同意が済んでからチュートリアルを開始（ポップアップの重なり防止）
        if (_tutorialUserId != user.uid) {
          _tutorialUserId = user.uid;
          _didCheckTabTutorial = false;
          _didCheckEmailMigrationPrompt = false;
        }
        ref.listen<bool>(hasAcceptedCurrentLegalConsentProvider, (prev, next) {
          if (prev == false && next == true) {
            _scheduleTabTutorialIfNeeded();
          }
        });
        if (hasLegalConsent) {
          _scheduleTabTutorialIfNeeded();
          _scheduleMyPageRelocationGuide();
        }
        if (!_didBootstrapScheduleNotifications) {
          _didBootstrapScheduleNotifications = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _bootstrapScheduleNotifications();
          });
        }
        // メール移行プロンプトも同意完了後に表示
        if (hasLegalConsent && !_didCheckEmailMigrationPrompt) {
          _didCheckEmailMigrationPrompt = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeShowLegacyEmailMigrationPrompt(user.uid, user.email);
          });
        }
        if (tutorialReplaySignal != _lastTutorialReplaySignal) {
          _lastTutorialReplaySignal = tutorialReplaySignal;
          if (hasLegalConsent) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _maybeStartTabTutorial(force: true);
            });
          }
        }
        return CommunityLegalUpdateConsentGate(child: _buildMainContent());
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.error, size: 64, color: AppColors.accent(context, Colors.red)),
                  const SizedBox(height: 16),
                  Text('認証エラー: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // 認証プロバイダーを再読み込み
                      ref.invalidate(authStateProvider);
                    },
                    child: const Text('再試行'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMainContent() {
    // 掲示板の最新投稿日と最終既読時刻からバッジ表示を判定
    final prefs = ref.watch(sharedPreferencesProvider);
    final managementVisible = ref.watch(currentUserAdminProvider).valueOrNull?.isAdmin == true &&
        ref.watch(adminTabVisibleProvider);
    ref.listen<bool>(adminTabVisibleProvider, (_, visible) {
      if (!visible && _currentIndex == MainNavigation.adminIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _selectTab(MainNavigation.homeIndex);
        });
      }
    });
    final lastSeenMs = prefs.getInt('bulletin_last_seen_at') ?? 0;
    final latestCreatedAt =
        ref.watch(bulletinLatestPostCreatedAtProvider).valueOrNull;
    final latestMs = latestCreatedAt?.millisecondsSinceEpoch ?? 0;
    final hasNewBulletin = latestMs > lastSeenMs;
    final hasNewCwitter = ref.watch(hasNewCwitterPostsProvider);
    final showCommunityNew =
        hasNewCwitter && safeCurrentIndex != MainNavigation.communityIndex;
    final showBulletinNew =
        hasNewBulletin && safeCurrentIndex != MainNavigation.bulletinIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        final composerGate = ref.read(cwitterComposerBackGateProvider);
        if (composerGate.shouldIntercept && composerGate.handleBack != null) {
          await composerGate.handleBack!();
          return;
        }

        if (_currentIndex == MainNavigation.scheduleIndex && ref.read(scheduleEditingProvider)) {
          ref.read(scheduleEditingProvider.notifier).state = false;
          return;
        }
        // ホーム画面以外の場合はホームに戻る
        if (_currentIndex == MainNavigation.scheduleIndex &&
            ref.read(assignmentViewOpenProvider)) {
          ref.read(assignmentViewOpenProvider.notifier).state = false;
          return;
        }
        if (_currentIndex != MainNavigation.homeIndex) {
          _selectTab(MainNavigation.homeIndex);
          return;
        }

        // ホーム画面の場合は確認ダイアログを表示
        final bool shouldExit = await _showExitDialog();
        if (shouldExit) {
          // アプリを終了
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: _buildTabStack(),
        bottomNavigationBar: MainNavigationBar(
          tutorialAnchorKeys: _navigationGuideKeys,
          showAdminTab: managementVisible,
          selectedIndex: safeCurrentIndex,
          hasNewCommunityPosts: showCommunityNew,
          hasNewBulletinPosts: showBulletinNew,
          onDestinationSelected: uiFeedbackTabIndexHandler((index) async {
            if (index == MainNavigation.scheduleIndex &&
                safeCurrentIndex == MainNavigation.scheduleIndex) {
              final assignments = ref.read(assignmentViewOpenProvider.notifier);
              assignments.state = !assignments.state;
              return;
            }
            // 交流タブを開いている状態で再タップしたら Cwitter / ちばちゃんねる を切り替える
            if (index == MainNavigation.communityIndex &&
                safeCurrentIndex == MainNavigation.communityIndex) {
              ref.read(communityTabReselectSignalProvider.notifier).state++;
              return;
            }
            // 交流タブから離れる際、Cwitter入力中なら破棄確認を出す
            if (safeCurrentIndex == MainNavigation.communityIndex &&
                index != MainNavigation.communityIndex) {
              final gate = ref.read(cwitterComposerBackGateProvider);
              if (gate.shouldIntercept && gate.handleBack != null) {
                final proceed = await gate.handleBack!();
                if (!proceed || !mounted) return;
              }
            }
            _selectTab(index);
            // 掲示板タブを開いたら既読時刻を更新
            if (index == MainNavigation.bulletinIndex) {
              await prefs.setInt(
                'bulletin_last_seen_at',
                DateTime.now().millisecondsSinceEpoch,
              );
            }
          }),
        ),
      ),
    );
  }

  /// アプリ終了確認ダイアログ
  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('アプリを終了しますか？'),
                content: const Text('CIT Appを終了してよろしいですか？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('終了'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleMyPageRelocationGuide();
      ref.invalidate(assignmentReminderSyncProvider);
      if (ref.read(scheduleNotificationEnabledProvider)) unawaited(_bootstrapScheduleNotifications());
    } else {
      _myPageGuideTimer?.cancel();
      _myPageGuideTimer = null;
    }
  }

  void _scheduleMyPageRelocationGuide() {
    if (!mounted || _myPageGuideTimer != null || _isMyPageGuideShowing) return;
    if (safeCurrentIndex != MainNavigation.homeIndex) return;
    if (!ref.read(hasAcceptedCurrentLegalConsentProvider)) return;
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null || _myPageGuideShownUsers.contains(uid)) return;
    final progress = MyPageRelocationProgress(ref.read(sharedPreferencesProvider));
    if (!progress.shouldShow(uid)) return;

    _myPageGuideTimer = Timer(const Duration(milliseconds: 550), () async {
      _myPageGuideTimer = null;
      if (!mounted) return;
      if (ref.read(authStateProvider).valueOrNull?.uid != uid) {
        _scheduleMyPageRelocationGuide();
        return;
      }
      if (safeCurrentIndex != MainNavigation.homeIndex ||
          !ref.read(hasAcceptedCurrentLegalConsentProvider)) {
        return;
      }
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
      if (_isTabTutorialShowing || _isEmailMigrationPromptShowing ||
          ModalRoute.of(context)?.isCurrent != true) {
        _scheduleMyPageRelocationGuide();
        return;
      }

      _isMyPageGuideShowing = true;
      _myPageGuideShownUsers.add(uid);
      try {
        final acknowledged = await showMyPageRelocationGuide(
          context,
          avatarKey: _profileAvatarAnchorKey,
        );
        if (acknowledged) {
          await progress.markSeen(uid);
        } else {
          _myPageGuideShownUsers.remove(uid);
        }
      } catch (_) {
        SecureLogger.warning('マイページの移動案内を完了できませんでした');
      } finally {
        _isMyPageGuideShowing = false;
      }
    });
  }

  Future<void> _maybeShowLegacyEmailMigrationPrompt(
    String uid,
    String? email,
  ) async {
    if (!mounted || _isEmailMigrationPromptShowing || _tutorialUserId != uid) {
      return;
    }
    if (!LegacyEmailMigrationDialog.shouldShow(email)) return;

    _isEmailMigrationPromptShowing = true;
    try {
      await LegacyEmailMigrationDialog.showIfNeeded(
        context,
        uid: uid,
        email: email,
        preferences: ref.read(sharedPreferencesProvider),
      );
    } finally {
      _isEmailMigrationPromptShowing = false;
      if (mounted && _didCheckTabTutorial) {
        await _maybeStartTabTutorial();
      }
    }
  }

  /// 利用規約同意ポップアップが閉じた後にチュートリアルを開始する。
  /// 同意UIと AlertDialog が同時に出ないよう、短い遅延を挟む。
  void _scheduleTabTutorialIfNeeded() {
    if (_didCheckTabTutorial || !mounted) return;
    if (!ref.read(hasAcceptedCurrentLegalConsentProvider)) return;

    _didCheckTabTutorial = true;
    final uid = _tutorialUserId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      if (_tutorialUserId != uid) return;
      if (!ref.read(hasAcceptedCurrentLegalConsentProvider)) return;
      await _maybeStartTabTutorial();
    });
  }

  Future<void> _maybeStartTabTutorial({bool force = false}) async {
    if (!mounted || _isTabTutorialShowing || _isEmailMigrationPromptShowing || _isMyPageGuideShowing) return;
    if (!ref.read(hasAcceptedCurrentLegalConsentProvider)) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    final progress = TabTutorialProgress(ref.read(sharedPreferencesProvider));
    if (!force && !progress.shouldShow(uid)) return;

    _isTabTutorialShowing = true;
    final previousTab = safeCurrentIndex;
    final previousEditing = ref.read(scheduleEditingProvider);
    final previousAssignments = ref.read(assignmentViewOpenProvider);
    var explainedMyPage = false;
    ControlTutorialStep step(int tab, GlobalKey anchor, String title, String description, {int communityTab = 0, bool scheduleEditing = false}) =>
      ControlTutorialStep(anchor: anchor, title: title, description: description,
        onEnter: () async {
          if (mounted && ref.read(authStateProvider).valueOrNull?.uid == uid) {
            if (tab == MainNavigation.communityIndex) setState(() => _communityGuideIndex = communityTab);
            if (tab == MainNavigation.scheduleIndex) {
              ref.read(assignmentViewOpenProvider.notifier).state = false;
              ref.read(scheduleEditingProvider.notifier).state = scheduleEditing;
            }
            _selectTab(tab);
          }
        });
    try {
      final completed = await showVisualTabTutorial(
        context,
        isCurrentSession: () => mounted && ref.read(authStateProvider).valueOrNull?.uid == uid,
        onStepShown: (step) {
          if (identical(step.anchor, _profileAvatarAnchorKey)) explainedMyPage = true;
        },
        closingStep: step(
          MainNavigation.homeIndex,
          _profileAvatarAnchorKey,
          'チュートリアルの確認方法',
          'このチュートリアルはマイページからいつでも確認可能です',
        ),
        steps: [
          step(MainNavigation.homeIndex, _navigationGuideKeys[MainNavigation.homeIndex],
            'ホーム', '天気・時間割・課題・学バスなど、大学生活に必要な情報をまとめて確認できます。'),
          step(MainNavigation.homeIndex, _homeMenuAnchorKey,
            'ホームをカスタマイズ', '右上のメニューから「ホームカードを編集」を開くと、カードの表示や並び順を変更できます。'),
          step(MainNavigation.scheduleIndex, _navigationGuideKeys[MainNavigation.scheduleIndex],
            '時間割・課題管理', 'このタブで時間割と課題を管理します。タブをダブルタップしても、時間割と課題管理を切り替えられます。'),
          step(MainNavigation.scheduleIndex, _controlGuideKeys['semester']!,
            '時間割を追加・切り替え', 'ここから時間割を追加したり、登録済みの時間割へ切り替えられます。年度・前期後期を設定すると、出欠管理に対応した日付が表示されます。'),
          step(MainNavigation.scheduleIndex, _controlGuideKeys['scheduleEdit']!,
            '講義を登録・編集', '鉛筆ボタンで編集モードを開き、空いているマスに講義を登録できます。講義の変更や、時限の拡張・削除も編集モードから行えます。'),
          step(MainNavigation.scheduleIndex, _controlGuideKeys['saturday']!,
            '土曜日の表示・非表示', '編集モードでは、このボタンで時間割の土曜日を表示・非表示にできます。土曜日の講義データは、非表示にしても残ります。', scheduleEditing: true),
          step(MainNavigation.scheduleIndex, _controlGuideKeys['excelImport']!,
            'Excelから時間割をインポート', '編集モードのこのボタンから、大学の学生時間割表のExcelファイルを取り込めます。ファイルを選び、学期と保存先を指定し、プレビューで内容を確認してから適用します。', scheduleEditing: true),
          step(MainNavigation.scheduleIndex, _controlGuideKeys['assignment']!,
            '課題を管理', '「課題」で課題一覧を開き、提出期限や完了状況を管理できます。「時間割」を押すと元の表示に戻ります。'),
          step(MainNavigation.scheduleIndex, _controlGuideKeys['attendance']!,
            '出欠を記録', '講義ごとの出席・欠席・遅刻を記録できます。年度・前期後期に合わせた講義期間を選び、日付ごとに確認できます。'),
          step(MainNavigation.scheduleIndex, _controlGuideKeys['share']!,
            '時間割を保存・共有', '共有ボタンから時間割を画像として保存したり、友だちに共有できます。'),
          step(MainNavigation.communityIndex, _controlGuideKeys['communitySwitch']!,
            'Cwitterとちばちゃんねる', '上のタブで切り替えます。下の交流ボタンをダブルタップしても切り替えられます。CwitterはCweetIDをあとで設定して投稿を読むこともでき、投稿・いいねなどの操作時に登録を案内します。'),
          step(MainNavigation.communityIndex, _controlGuideKeys['communitySearch']!,
            'Cwitterを検索', '虫眼鏡から投稿やユーザーを検索できます。気になる話題や友だちを探してみてください。'),
          step(MainNavigation.communityIndex, _controlGuideKeys['chibaTab']!,
            'ちばちゃんねる', '匿名で大学生活の話題を相談・交流できます。スレッドを開いて内容や返信を確認し、ご利用についての案内を読んでから投稿してください。', communityTab: 1),
          step(MainNavigation.bulletinIndex, _controlGuideKeys['categories']!,
            '掲示板で情報を探す', 'カテゴリを選ぶと、お知らせ・募集などを絞り込めます。投稿を開くと詳しい内容やコメントを確認できます。'),
          step(MainNavigation.bulletinIndex, _controlGuideKeys['bulletinPost']!,
            '掲示板への掲載を申請', '右上の投稿ボタンから掲載を申請できます。イベントやメンバーの募集、卒業論文のアンケート集めにもご利用いただけます。'),
          step(MainNavigation.homeIndex, _profileAvatarAnchorKey,
            'マイページとお問い合わせ', 'ホーム左上のアイコンから開けます。「便利な機能・カスタマイズ」でテーマやTipsの表示を設定でき、使い方ガイドも見直せます。運営への連絡は「お問い合わせ」からどうぞ。'),
        ],
      );
      if (completed && mounted && ref.read(authStateProvider).valueOrNull?.uid == uid) {
        await progress.markSeen(uid);
        if (explainedMyPage) {
          _myPageGuideShownUsers.add(uid);
          await MyPageRelocationProgress(progress.preferences).markSeen(uid);
        }
      }
    } finally {
      _isTabTutorialShowing = false;
      if (mounted && ref.read(authStateProvider).valueOrNull?.uid == uid) {
        ref.read(scheduleEditingProvider.notifier).state = previousEditing;
        ref.read(assignmentViewOpenProvider.notifier).state = previousAssignments;
        _selectTab(previousTab);
      }
    }
  }
}
