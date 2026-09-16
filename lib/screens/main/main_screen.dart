import '../../core/theme/app_colors.dart';
import 'package:cit_app/core/utils/logger.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/services/analytics_service.dart';
import '../../core/providers/bulletin_provider.dart';
import '../../core/providers/community_tab_provider.dart';
import '../../core/providers/cwitter_composer_back_provider.dart';
import '../../core/providers/cwitter_provider.dart';
import '../../core/providers/legal_consent_provider.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../models/schedule/schedule_model.dart';
import '../../services/schedule/attendance_availability.dart';
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
import '../profile/simple_profile_screen.dart';
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

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  final Set<int> _visitedTabIndices = <int>{};
  bool _didCheckTabTutorial = false;
  bool _isTabTutorialShowing = false;
  int _lastTutorialReplaySignal = 0;
  bool _didCheckEmailMigrationPrompt = false;
  bool _isEmailMigrationPromptShowing = false;

  StreamSubscription<String>? _notificationTapSub;
  StreamSubscription<void>? _pushTapSub;
  bool _handlingNotificationTap = false;
  bool _didBootstrapScheduleNotifications = false;

  static const String _tabTutorialSeenVersionKey = 'tab_tutorial_seen_version';
  static const String _tabTutorialCurrentVersion = '2.0.0';

  int get safeCurrentIndex => MainNavigation.normalizeIndex(_currentIndex);

  @override
  void initState() {
    super.initState();
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
      final pending = ScheduleNotificationService.consumePendingLaunchPayload();
      if (pending != null) {
        _handleScheduleNotificationPayload(pending);
      }
      _consumePushTap();
    });
  }

  @override
  void dispose() {
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
      if (!mounted) return;

      final schedules = await ScheduleService.getAllSchedulesByUserId(userId);
      if (schedules.isEmpty) return;
      final selectedId = ref.read(selectedScheduleIdProvider);
      final schedule =
          (selectedId != null
              ? schedules.where((s) => s.id == selectedId).firstOrNull
              : null) ??
          schedules.first;
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
    final nextIndex = MainNavigation.normalizeIndex(index);
    if (_currentIndex == nextIndex && _visitedTabIndices.contains(nextIndex)) {
      return;
    }
    setState(() {
      _currentIndex = nextIndex;
      _visitedTabIndices.add(nextIndex);
    });
    unawaited(ref.read(analyticsServiceProvider).showMainTab(nextIndex));
  }

  Widget _buildTabScreen(int index) {
    if (!_visitedTabIndices.contains(index)) {
      return const SizedBox.shrink();
    }

    final screen = switch (index) {
      MainNavigation.homeIndex => HomeScreen(
        onNavigateToSchedule: _navigateToSchedule,
      ),
      MainNavigation.scheduleIndex => const ScheduleScreen(),
      MainNavigation.communityIndex => const CommunityScreen(),
      MainNavigation.bulletinIndex => const BulletinScreen(),
      MainNavigation.profileIndex => const SimpleProfileScreen(),
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
        MainNavigation.destinationCount,
        _buildTabScreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 認証状態を確認
    final authState = ref.watch(authStateProvider);
    final tutorialReplaySignal = ref.watch(tabTutorialReplaySignalProvider);
    // 利用規約同意ポップアップと被らないよう、同意完了後にチュートリアルを開始する
    final hasLegalConsent = ref.watch(hasAcceptedCurrentLegalConsentProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // ユーザーが未認証の場合は空のコンテナ（ルーターがリダイレクトを処理）
          return const Scaffold(body: Center(child: Text('リダイレクト中...')));
        }
        // 利用規約同意が済んでからチュートリアルを開始（ポップアップの重なり防止）
        ref.listen<bool>(hasAcceptedCurrentLegalConsentProvider, (prev, next) {
          if (prev == false && next == true) {
            _scheduleTabTutorialIfNeeded();
          }
        });
        if (hasLegalConsent) {
          _scheduleTabTutorialIfNeeded();
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
            _maybeShowLegacyEmailMigrationPrompt(user.email);
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

        // ホーム画面以外の場合はホームに戻る
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
          selectedIndex: safeCurrentIndex,
          hasNewCommunityPosts: showCommunityNew,
          hasNewBulletinPosts: showBulletinNew,
          onDestinationSelected: uiFeedbackTabIndexHandler((index) async {
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

  Future<void> _maybeShowLegacyEmailMigrationPrompt(String? email) async {
    if (!mounted || _isEmailMigrationPromptShowing) return;
    if (!LegacyEmailMigrationDialog.shouldShow(email)) return;

    _isEmailMigrationPromptShowing = true;
    try {
      await LegacyEmailMigrationDialog.showIfNeeded(context, email: email);
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      if (!ref.read(hasAcceptedCurrentLegalConsentProvider)) return;
      await _maybeStartTabTutorial();
    });
  }

  Future<void> _maybeStartTabTutorial({bool force = false}) async {
    if (!mounted || _isTabTutorialShowing || _isEmailMigrationPromptShowing) return;
    if (!ref.read(hasAcceptedCurrentLegalConsentProvider)) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final seenVersion = prefs.getString(_tabTutorialSeenVersionKey);
    if (!force && seenVersion == _tabTutorialCurrentVersion) return;

    _isTabTutorialShowing = true;
    try {
      final destination = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (_) => VisualTabTutorial(
          initialCampus: ref.read(preferredBusCampusProvider),
          onSaveCampus: ref.read(setPreferredBusCampusProvider),
        ),
      );
      if (!mounted) return;
      await prefs.setString(
        _tabTutorialSeenVersionKey,
        _tabTutorialCurrentVersion,
      );
      if (mounted && destination != null) _selectTab(destination);
    } finally {
      _isTabTutorialShowing = false;
    }
  }
}
