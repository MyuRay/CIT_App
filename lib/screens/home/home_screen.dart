import '../../core/theme/app_colors.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/cafeteria_provider.dart';
import '../../core/providers/cafeteria_review_provider.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/convenience_link_provider.dart';
import '../../core/providers/global_notification_provider.dart';
import '../../core/providers/firebase_menu_provider.dart';
import '../../core/providers/firebase_campus_provider.dart';
import '../../core/providers/bus_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/in_app_ad_provider.dart';
import '../../models/cafeteria/cafeteria_model.dart';
import '../../models/schedule/schedule_model.dart';
import '../../models/schedule/lecture_period_model.dart';
import '../../models/bus/bus_model.dart';
import '../../models/ads/in_app_ad_model.dart';
import '../../widgets/ads/in_app_ad_card.dart';
import '../../widgets/firebase_menu_image_widget.dart';
import '../bus/bus_information_screen.dart';
import '../cafeteria/cafeteria_reviews_screen.dart';
import '../cafeteria/cafeteria_camera_info_screen.dart';
import '../schedule/attendance_qr_reader_screen.dart';
import '../../widgets/campus_map_widget.dart';
import '../../widgets/home/academic_calendar_card.dart';
import '../../widgets/home/campus_weather_card.dart';
import '../../widgets/home/timetable_card_visibility.dart';
import '../../core/providers/assignment_provider.dart';
import '../../widgets/assignments/assignment_list.dart';
import '../../widgets/assignments/assignment_editor.dart';
// 一時非表示: JR津田沼駅発（電車アクセス）カード
// import '../../widgets/home/train_access_home_card.dart';
import '../../widgets/performance/optimized_notification_badge.dart';
import '../../widgets/common/pulsing_dot_badge.dart';
import '../../models/convenience_link/convenience_link_model.dart';
import '../convenience_link/convenience_links_manager_sheet.dart';
import '../notification/unified_notification_screen.dart';
import '../club/club_organizations_screen.dart';
import '../../services/widget/home_widgets_service.dart';
import '../../services/schedule/schedule_service.dart';
import '../../services/schedule/attendance_service.dart';
import '../../widgets/common/interactive_fullscreen_image_viewer.dart';
import '../../widgets/schedule/schedule_class_detail_dialog.dart';
import '../../services/schedule/lecture_period_service.dart';

const Map<String, String> _campusNavigationOptions = {
  'tsudanuma': '津田沼',
  'narashino': '新習志野',
};

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToSchedule;

  const HomeScreen({super.key, this.onNavigateToSchedule});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const String _homeCardLayoutPrefsKey = 'home_card_layout_v1';
  static const String _timetableAutoShowOverrideKey =
      'timetableAutoShowOverrideOutsideLecturePeriod';
  static const List<String> _defaultHomeCardOrder = [
    'weather',
    'timetable',
    'assignments',
    'cafeteria',
    'bus',
    // 'train_access', // 一時非表示: JR津田沼駅発
    'campus_map',
    'academic_calendar',
    'convenience_links',
  ];

  // ホーム上部のTextMatch広告は非表示にする
  bool _showTextMatchAd = false;
  List<String> _homeCardOrder = List<String>.from(_defaultHomeCardOrder);
  Set<String> _hiddenHomeCards = <String>{};
  bool _alwaysShowAssignments = false;
  bool _timetableAutoShowOverrideOutsideLecturePeriod = false;
  int _selectedRouteIndex = 0; // 選択中の路線インデックス
  bool _busInitialRouteSet = false; // 学バス初期表示の適用有無
  late AnimationController _flipAnimationController;
  late Animation<double> _flipAnimation;
  Timer? _scheduleRefreshTimer;
  final _weatherCardKey = GlobalKey<CampusWeatherCardState>();
  void _invalidateScheduleProviders() {
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      // 家族付きプロバイダのインスタンスを直接無効化して再計算させる
      ref.invalidate(todayScheduleProvider(userId));
      ref.invalidate(todayScheduleByIdProvider);
      ref.invalidate(currentPeriodProvider(userId));
      ref.invalidate(nextClassProvider(userId));
      ref.invalidate(scheduleProvider(userId));
      ref.invalidate(scheduleListProvider(userId));
      // ラッパープロバイダーも一応更新
      ref.invalidate(currentUserTodayScheduleProvider);
      ref.invalidate(currentUserSelectedTodayScheduleProvider);
      ref.invalidate(currentUserCurrentPeriodProvider);
      ref.invalidate(currentUserNextClassProvider);
    }
    ref.invalidate(lecturePeriodSettingsProvider);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _loadAdPreference(); // 広告は常に非表示にするため読み込みを無効化
    _loadHomeCardLayout();

    // フリップアニメーション初期化
    _flipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flipAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // 初回更新はフレーム後に実行してInherited依存を避ける
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _invalidateScheduleProviders();
    });

    // スケジュールのリアルタイム更新タイマー（1分ごと）
    _scheduleRefreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _invalidateScheduleProviders();
      }
    });
  }

  @override
  void dispose() {
    _scheduleRefreshTimer?.cancel();
    _flipAnimationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 画面復帰時にも最新化
      _invalidateScheduleProviders();
    }
  }

  /// 広告表示設定を読み込み
  Future<void> _loadAdPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isAdHidden = prefs.getBool('textmatch_ad_hidden') ?? false;

    if (mounted) {
      setState(() {
        _showTextMatchAd = !isAdHidden;
      });
    }
  }

  /// 広告を非表示に設定して保存
  Future<void> _hideAdPermanently() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('textmatch_ad_hidden', true);

    if (mounted) {
      setState(() {
        _showTextMatchAd = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // グローバルなリフレッシュ通知を監視
    ref.listen<int>(homeRefreshNotifierProvider, (previous, next) {
      if (previous != null && previous != next) {
        print('🔄 ホーム画面のリフレッシュ通知を受信しました');
        _refreshData(ref);
      }
    });

    final homeAdAsync = ref.watch(inAppAdProvider(AdPlacement.homeTop));
    final todayReviewExistsAsync = ref.watch(
      todayCafeteriaReviewExistsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            tooltip: 'ホームカード設定',
            onSelected: (value) {
              if (value == 'edit_home_cards') {
                _showHomeCardLayoutEditor(context);
              }
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem<String>(
                    value: 'edit_home_cards',
                    child: Text('ホームカードを編集'),
                  ),
                ],
          ),
          // 最適化された通知ボタン（未読数バッジ付き）
          OptimizedNotificationBadge(onTap: () => _showNotifications(context)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshData(ref, reloadCampusMaps: true),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              homeAdAsync.when(
                data:
                    (ad) =>
                        ad == null
                            ? const SizedBox.shrink()
                            : Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: InAppAdCard(
                                ad: ad,
                                placement: AdPlacement.homeTop,
                              ),
                            ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              // TextMatch広告バナー
              if (_showTextMatchAd)
                Card(
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => _openTextMatchWebsite(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF2E3B70), Color(0xFF7B6BA8)],
                        ),
                      ),
                      child: Row(
                        children: [
                          // TextMatchロゴ
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                'assets/icons/textmatch_logo .png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.book,
                                      color: Color(0xFF2E3B70),
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // テキスト部分
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        'AD',
                                        style: TextStyle(
                                          color: AppColors.onColor(Colors.orange),
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '教科書の売買',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'TextMatch',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  '送料がかからない教科書フリーマーケット',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _showRemoveAdDialog(context),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white70,
                                size: 14,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_showTextMatchAd) const SizedBox(height: 16),
              ..._buildOrderedHomeCards(context, ref, todayReviewExistsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext context) {
    return CampusWeatherCard(
      key: _weatherCardKey,
      mainCampusKey: ref.watch(preferredBusCampusProvider),
    );
  }
  List<Widget> _buildOrderedHomeCards(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<bool> todayReviewExistsAsync,
  ) {
    final autoHideTimetable = _shouldAutoHideTimetableCardByLecturePeriod();
    final showAssignments = showAssignmentHomeCard(ref.watch(assignmentsProvider), alwaysShow: _alwaysShowAssignments);
    final visibleCardIds =
        _homeCardOrder.where((id) {
          if (_hiddenHomeCards.contains(id)) return false;
          if (id == 'timetable' && autoHideTimetable) return false;
          if (id == 'assignments' && !showAssignments) return false;
          // 一時非表示: JR津田沼駅発（保存済みレイアウトに残っていても出さない）
          if (id == 'train_access') return false;
          return true;
        }).toList();
    if (visibleCardIds.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Text(
            '現在すべてのカードが非表示にされている状態です。表示を変更する場合は右上の≡ボタンから編集をお願いします。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ];
    }
    final widgets = <Widget>[];

    for (int i = 0; i < visibleCardIds.length; i++) {
      widgets.add(
        _buildHomeCardById(
          context,
          ref,
          visibleCardIds[i],
          todayReviewExistsAsync,
        ),
      );
      if (i < visibleCardIds.length - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }
    return widgets;
  }

  Widget _buildHomeCardById(
    BuildContext context,
    WidgetRef ref,
    String cardId,
    AsyncValue<bool> todayReviewExistsAsync,
  ) {
    switch (cardId) {
      case 'weather':
        return _buildWeatherCard(context);
      case 'timetable':
        return _buildTimetableCard(context, ref);
      case 'assignments':
        return const AssignmentHomeCard();
      case 'cafeteria':
        return _buildCafeteriaCard(context, ref, todayReviewExistsAsync);
      case 'bus':
        return _buildBusInfoCard(context, ref);
      // 一時非表示: JR津田沼駅発
      // case 'train_access':
      //   return const TrainAccessHomeCard();
      case 'campus_map':
        return _buildCampusMapCard(context);
      case 'academic_calendar':
        return _buildAcademicCalendarCard(context);
      case 'club_organizations':
        return _buildClubOrganizationsCard(context);
      case 'convenience_links':
        return _buildConvenienceLinksCard(context, ref);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTimetableCard(BuildContext context, WidgetRef ref) {
    final lecturePeriodAsync = ref.watch(lecturePeriodSettingsProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getTodayWeekdayText(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 8),
                lecturePeriodAsync.when(
                  data: (settings) {
                    if (settings == null) return const SizedBox.shrink();
                    return _buildLectureWeekChip(context, settings);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onNavigateToSchedule,
                  child: const Text('詳細を見る'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTodaySchedule(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureWeekChip(
    BuildContext context,
    LecturePeriodSettings settings,
  ) {
    final label = _buildLectureWeekLabel(settings);
    if (label == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String? _buildLectureWeekLabel(LecturePeriodSettings settings) {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);

    String? weekLabel(
      String semesterName,
      DateTime? startRaw,
      DateTime? endRaw,
    ) {
      if (startRaw == null || endRaw == null) return null;
      final start = DateTime(startRaw.year, startRaw.month, startRaw.day);
      final end = DateTime(endRaw.year, endRaw.month, endRaw.day);
      if (day.isBefore(start) || day.isAfter(end)) return null;
      final diffDays = day.difference(start).inDays;
      final week = (diffDays ~/ 7) + 1;
      return '$semesterName 第$week週';
    }

    return weekLabel('前期', settings.springStartDate, settings.springEndDate) ??
        weekLabel('後期', settings.fallStartDate, settings.fallEndDate) ??
        // 旧データ互換
        weekLabel('前期', settings.lectureStartDate, settings.lectureEndDate);
  }

  Widget _buildCafeteriaCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<bool> todayReviewExistsAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.ramen_dining,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getWeeklyMenuTitle(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openCafeteriaWebsite(context),
                  icon: Icon(
                    Icons.open_in_browser,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    '公式サイト',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCafeteriaInfo(context, ref),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _openCafeteriaReviews(context),
                          icon: const Icon(Icons.reviews, size: 16),
                          label: const Text('学食レビュー'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            textStyle: Theme.of(
                              context,
                            ).textTheme.labelMedium?.copyWith(fontSize: 13),
                          ),
                        ),
                      ),
                      todayReviewExistsAsync.when(
                        data:
                            (hasToday) =>
                                hasToday
                                    ? const Positioned(
                                      right: -6,
                                      top: -6,
                                      child: PulsingDotBadge(
                                        size: 10,
                                        tooltipMessage: '今日レビューされています',
                                      ),
                                    )
                                    : const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openCafeteriaCamera(context),
                    icon: const Icon(Icons.videocam, size: 16),
                    label: const Text('食堂カメラ'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor:
                          AppColors.onColor(Theme.of(context).colorScheme.secondary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      textStyle: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampusMapCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'キャンパスマップ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openCampusWebsite(context),
                  icon: Icon(
                    Icons.open_in_browser,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    '詳細',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 12),
            _buildCampusMaps(context),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openClassroomMap(context),
                icon: const Icon(Icons.search, size: 16),
                label: const Text('教室・学内施設を探す'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openClassroomMap(BuildContext context) {
    context.push('/classroom-map');
  }

  Widget _buildAcademicCalendarCard(BuildContext context) {
    return AcademicCalendarCard(
      startsOnSunday:
          ref.watch(calendarWeekStartProvider) == CalendarWeekStart.sunday,
      onOpenAnnualImages: () => _showAcademicYearCalendarImageList(context),
    );
  }

  Future<List<_YearCalendarImageItem>> _fetchYearCalendarImages() async {
    final ref = FirebaseStorage.instance.ref().child('year_calender');
    final result = await ref.listAll();
    final images = <_YearCalendarImageItem>[];
    for (final item in result.items) {
      try {
        final url = await item.getDownloadURL();
        images.add(_YearCalendarImageItem(name: item.name, downloadUrl: url));
      } catch (_) {
        // 取得不可のファイルはスキップ
      }
    }
    images.sort((a, b) => a.name.compareTo(b.name));
    return images;
  }

  Future<void> _showAcademicYearCalendarImageList(BuildContext context) async {
    final imagesFuture = _fetchYearCalendarImages();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.86,
          child: Column(
            children: [
              const ListTile(
                title: Text(
                  '学年暦の年間画像',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<_YearCalendarImageItem>>(
                  future: imagesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          '画像一覧の取得に失敗しました',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }
                    final images =
                        snapshot.data ?? const <_YearCalendarImageItem>[];
                    if (images.isEmpty) {
                      return Center(
                        child: Text(
                          '学年暦の画像はありません',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = images[index];
                        return Semantics(
                          button: true,
                          label: '学年暦の画像 ${index + 1}/${images.length}、タップして拡大',
                          child: InkWell(
                            onTap: () =>
                                showInteractiveFullscreenNetworkImageGallery(
                                  context,
                                  imageUrls: images
                                      .map((image) => image.downloadUrl)
                                      .toList(),
                                  initialIndex: index,
                                  maxScale: 8,
                                ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${index + 1} / ${images.length}',
                                        ),
                                      ),
                                      const Icon(Icons.zoom_in),
                                    ],
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    item.downloadUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(
                                          height: 220,
                                          child: Center(
                                            child: Icon(Icons.broken_image),
                                          ),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showHomeCardLayoutEditor(BuildContext context) async {
    final tempOrder = List<String>.from(_homeCardOrder);
    final tempHidden = Set<String>.from(_hiddenHomeCards);
    var tempAlwaysShowAssignments = _alwaysShowAssignments;
    var tempTimetableAutoShowOverride =
        _timetableAutoShowOverrideOutsideLecturePeriod;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.78,
                child: Column(
                  children: [
                    ListTile(
                      title: const Text(
                        'ホームカードを編集',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('表示/非表示と順序を変更できます'),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder:
                                    (dialogContext) => AlertDialog(
                                      title: const Text('デフォルトに戻す'),
                                      content: const Text(
                                        'カードの表示設定と並び順を初期状態に戻します。よろしいですか？',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                dialogContext,
                                              ).pop(false),
                                          child: const Text('キャンセル'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                dialogContext,
                                              ).pop(true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('戻す'),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirmed != true) return;
                              setState(() {
                                _homeCardOrder = List<String>.from(
                                  _defaultHomeCardOrder,
                                );
                                _hiddenHomeCards = <String>{};
                                _alwaysShowAssignments = false;
                                _timetableAutoShowOverrideOutsideLecturePeriod =
                                    false;
                              });
                              await _saveHomeCardLayout();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            icon: const Icon(Icons.restore),
                            tooltip: 'デフォルトに戻す',
                          ),
                          TextButton(
                            onPressed: () async {
                              setState(() {
                                _homeCardOrder = List<String>.from(tempOrder);
                                _hiddenHomeCards = Set<String>.from(tempHidden);
                                _alwaysShowAssignments = tempAlwaysShowAssignments;
                                _timetableAutoShowOverrideOutsideLecturePeriod =
                                    tempTimetableAutoShowOverride;
                              });
                              await _saveHomeCardLayout();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('保存'),
                          ),
                        ],
                      ),
                    ),
                    // 一時非表示: JR津田沼駅発（キャンパス切替）
                    // const Divider(height: 1),
                    // const TrainHomeCardCampusSetting(),
                    // const Divider(height: 1),
                    Expanded(
                      child: ReorderableListView.builder(
                        itemCount: tempOrder.length,
                        onReorder: (oldIndex, newIndex) {
                          setModalState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = tempOrder.removeAt(oldIndex);
                            tempOrder.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final cardId = tempOrder[index];
                          final isOutsideLecturePeriod =
                              cardId == 'timetable'
                                  ? _isOutsideLecturePeriodForTimetable(
                                    useWatch: false,
                                  )
                                  : false;
                          final isVisible =
                              !tempHidden.contains(cardId) &&
                              (cardId != 'assignments' || showAssignmentHomeCard(ref.read(assignmentsProvider), alwaysShow: tempAlwaysShowAssignments)) &&
                              !(cardId == 'timetable' &&
                                  isOutsideLecturePeriod &&
                                  !tempTimetableAutoShowOverride);
                          return ListTile(
                            key: ValueKey(cardId),
                            leading: const Icon(Icons.drag_handle),
                            title: Text(_homeCardTitle(cardId)),
                            subtitle: Text(
                              cardId == 'timetable' &&
                                      !tempHidden.contains(cardId) &&
                                      !tempTimetableAutoShowOverride
                                  ? isOutsideLecturePeriod
                                      ? '講義期間外のため自動で非表示'
                                      : '講義期間中は自動表示'
                                  : cardId == 'assignments' &&
                                          !tempHidden.contains(cardId) &&
                                          !tempAlwaysShowAssignments
                                      ? '未完了の課題があるときに自動表示'
                                      : isVisible ? '表示中' : '非表示',
                            ),
                            trailing: Switch(
                              value: isVisible,
                              onChanged: (value) {
                                setModalState(() {
                                  if (cardId == 'assignments') {
                                    tempAlwaysShowAssignments = value;
                                  }
                                  if (cardId == 'timetable') {
                                    if (value) {
                                      tempHidden.remove(cardId);
                                      if (isOutsideLecturePeriod) {
                                        tempTimetableAutoShowOverride = true;
                                      }
                                    } else {
                                      tempHidden.add(cardId);
                                      tempTimetableAutoShowOverride = false;
                                    }
                                    return;
                                  }

                                  if (value) {
                                    tempHidden.remove(cardId);
                                  } else {
                                    tempHidden.add(cardId);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _homeCardTitle(String cardId) {
    switch (cardId) {
      case 'weather':
        return '天気';
      case 'timetable':
        return '時間割';
      case 'assignments':
        return '課題';
      case 'cafeteria':
        return '学食情報';
      case 'bus':
        return '学バス情報';
      // case 'train_access':
      //   return trainHomeCardTitle(ref.read(preferredBusCampusProvider));
      case 'campus_map':
        return 'キャンパスマップ';
      case 'academic_calendar':
        return '学年暦';
      case 'club_organizations':
        return 'サークル・部活';
      case 'convenience_links':
        return '便利リンク';
      default:
        return cardId;
    }
  }

  List<String> _normalizeHomeCardOrder(List<dynamic>? rawOrder) {
    final incoming =
        (rawOrder ?? const <dynamic>[])
            .whereType<String>()
            .where((id) => _defaultHomeCardOrder.contains(id))
            .toList();
    final result = List<String>.from(incoming);
    if (!result.contains('weather')) {
      result.insert(0, 'weather');
    }
    if (!result.contains('academic_calendar')) {
      final convenienceIndex = result.indexOf('convenience_links');
      if (convenienceIndex >= 0) {
        result.insert(convenienceIndex, 'academic_calendar');
      } else {
        result.add('academic_calendar');
      }
    }
    // 一時非表示: JR津田沼駅発
    // if (!result.contains('train_access')) {
    //   final busIndex = result.indexOf('bus');
    //   if (busIndex >= 0) {
    //     result.insert(busIndex + 1, 'train_access');
    //   } else {
    //     final campusIndex = result.indexOf('campus_map');
    //     if (campusIndex >= 0) {
    //       result.insert(campusIndex, 'train_access');
    //     } else {
    //       result.add('train_access');
    //     }
    //   }
    // }
    for (final id in _defaultHomeCardOrder) {
      if (!result.contains(id)) {
        result.add(id);
      }
    }
    // Migrate existing layouts by placing the new card below today's timetable.
    if (!incoming.contains('assignments')) {
      result.remove('assignments');
      result.insert(result.indexOf('timetable') + 1, 'assignments');
    }
    return result;
  }

  bool _isOutsideLecturePeriodForTimetable({required bool useWatch}) {
    final lecturePeriodAsync =
        useWatch
            ? ref.watch(lecturePeriodSettingsProvider)
            : ref.read(lecturePeriodSettingsProvider);

    return isOutsideHomeTimetableLecturePeriod(
      settings: lecturePeriodAsync.valueOrNull,
      date: DateTime.now(),
    );
  }

  bool _shouldAutoHideTimetableCardByLecturePeriod() {
    if (_timetableAutoShowOverrideOutsideLecturePeriod) return false;
    return _isOutsideLecturePeriodForTimetable(useWatch: true);
  }

  Future<void> _loadHomeCardLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_homeCardLayoutPrefsKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final order = _normalizeHomeCardOrder(decoded['order'] as List<dynamic>?);
      final hidden =
          ((decoded['hidden'] as List<dynamic>?) ?? const <dynamic>[])
              .whereType<String>()
              .where((id) => _defaultHomeCardOrder.contains(id))
              .toSet();

      if (!mounted) return;
      setState(() {
        _homeCardOrder = order;
        _hiddenHomeCards = hidden;
        _alwaysShowAssignments = decoded['alwaysShowAssignments'] == true;
        _timetableAutoShowOverrideOutsideLecturePeriod =
            decoded[_timetableAutoShowOverrideKey] == true;
      });
    } catch (_) {
      // 設定読み込みエラー時はデフォルト順を使用
    }
  }

  Future<void> _saveHomeCardLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'order': _homeCardOrder,
      'hidden': _hiddenHomeCards.toList(),
      'alwaysShowAssignments': _alwaysShowAssignments,
      _timetableAutoShowOverrideKey:
          _timetableAutoShowOverrideOutsideLecturePeriod,
    };
    await prefs.setString(_homeCardLayoutPrefsKey, jsonEncode(payload));
  }

  // TextMatchのWebサイトを開く
  void _openTextMatchWebsite(BuildContext context) async {
    const url = 'https://text-match.jp';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'URLを開けませんでした';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TextMatchサイトを開けませんでした: $e'),
            action: SnackBarAction(
              label: 'リトライ',
              onPressed: () => _openTextMatchWebsite(context),
            ),
          ),
        );
      }
    }
  }

  // 学食レビュー画面へ遷移
  void _openCafeteriaReviews(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CafeteriaReviewsScreen()),
    );
  }

  // 食堂カメラ情報画面へ遷移
  void _openCafeteriaCamera(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CafeteriaCameraInfoScreen(),
      ),
    );
  }

  // 広告削除確認ダイアログを表示
  void _showRemoveAdDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ヘッダー
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.info,
                        color: AppColors.accent(context, Colors.blue),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '広告を非表示にする',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // メッセージ
                const Text(
                  'TextMatchの広告を非表示にします。以後、この端末では表示されません。',
                  style: TextStyle(fontSize: 14, height: 1.5),
                  textAlign: TextAlign.left,
                ),

                const SizedBox(height: 24),

                // TextMatchボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openTextMatchWebsite(context);
                    },
                    icon: const Icon(Icons.book, size: 20),
                    label: const Text('TextMatchで教科書を売買する'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E3B70),
                      foregroundColor: AppColors.onColor(const Color(0xFF2E3B70)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // アクションボタン
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('キャンセル'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _hideAdPermanently();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('広告を非表示にしました。'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('非表示にする'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCafeteriaInfo(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 今日のメニュー画像
        _buildTodayMenuImage(context, ref),
      ],
    );
  }

  Widget _buildTodayMenuImage(BuildContext context, WidgetRef ref) {
    const campusOptions = {'td': '津田沼', 'sd1': '新習志野1F', 'sd2': '新習志野2F'};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 津田沼キャンパス
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FirebaseMenuImageWidget(
                    campus: 'td',
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                    campusNavigationMap: campusOptions,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '津田沼',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 新習志野キャンパス1F
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FirebaseMenuImageWidget(
                    campus: 'sd1',
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                    campusNavigationMap: campusOptions,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '新習志野1F',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 新習志野キャンパス2F
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FirebaseMenuImageWidget(
                    campus: 'sd2',
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                    campusNavigationMap: campusOptions,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '新習志野2F',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCampusInfo(
    BuildContext context,
    String campusName,
    AsyncValue<CafeteriaMenu?> menuAsync,
    AsyncValue<CafeteriaCongestion?> congestionAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                campusName,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // 混雑状況表示
              congestionAsync.when(
                data: (congestion) {
                  if (congestion == null) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap:
                        congestion.cameraUrl != null
                            ? () => _showCameraDialog(context, congestion)
                            : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(congestion.level.emoji),
                        const SizedBox(width: 4),
                        Text(
                          congestion.level.displayName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (congestion.cameraUrl != null) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.videocam,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  );
                },
                loading:
                    () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                error: (_, __) => const Text('混雑状況取得エラー'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // おすすめメニュー表示
          menuAsync.when(
            data: (menu) {
              if (menu == null || menu.items.isEmpty) {
                return const Text('本日のメニュー情報はありません');
              }
              final topItems = menu.items.take(3).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    topItems
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item.name)),
                                Text(
                                  item.price,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('メニュー取得エラー: $error'),
          ),
        ],
      ),
    );
  }

  void _showCafeteriaDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder:
                (context, scrollController) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '学食詳細メニュー',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            _buildDetailedMenuSection(
                              context,
                              ref,
                              '津田沼キャンパス',
                              'tsudanuma',
                            ),
                            const SizedBox(height: 24),
                            _buildDetailedMenuSection(
                              context,
                              ref,
                              '新習志野キャンパス1F',
                              'narashino1',
                            ),
                            const SizedBox(height: 24),
                            _buildDetailedMenuSection(
                              context,
                              ref,
                              '新習志野キャンパス2F',
                              'narashino2',
                            ),
                            const SizedBox(height: 16), // 最下部にスペース追加
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildDetailedMenuSection(
    BuildContext context,
    WidgetRef ref,
    String campusName,
    String campusKey,
  ) {
    final menuAsync = ref.watch(cafeteriaMenuProvider(campusKey));
    final congestionAsync = ref.watch(cafeteriaCongestionProvider(campusKey));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  campusName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                congestionAsync.when(
                  data: (congestion) {
                    if (congestion == null) return const SizedBox.shrink();
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(congestion.level.emoji),
                        const SizedBox(width: 4),
                        Text(congestion.level.displayName),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('エラー'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BusInformationScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  '詳細',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ),
            menuAsync.when(
              data: (menu) {
                if (menu == null || menu.items.isEmpty) {
                  return const Text('本日のメニューはありません');
                }

                final groupedItems = <String, List<MenuItem>>{};
                for (final item in menu.items) {
                  groupedItems.putIfAbsent(item.category, () => []).add(item);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      groupedItems.entries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...entry.value.map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        bottom: 2,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(child: Text(item.name)),
                                          Text(
                                            item.price,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('エラー: $error'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCameraDialog(BuildContext context, CafeteriaCongestion congestion) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.videocam,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('${congestion.location} 混雑状況'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '現在の状況: ${congestion.level.emoji} ${congestion.level.displayName}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '10秒ごとに更新されるライブカメラで\nリアルタイムの混雑状況を確認できます',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '運用時間: 月〜土 11:00-14:00',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final url = congestion.cameraUrl!;
                  try {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      throw 'URLを開けませんでした';
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('カメラページを開けませんでした: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('カメラを見る'),
              ),
            ],
          ),
    );
  }

  void _openCafeteriaWebsite(BuildContext context) async {
    const url = 'https://www.cit-s.com/dining/';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'URLを開けませんでした';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('学食公式サイトを開けませんでした: $e'),
            action: SnackBarAction(
              label: 'リトライ',
              onPressed: () => _openCafeteriaWebsite(context),
            ),
          ),
        );
      }
    }
  }

  void _openCampusWebsite(BuildContext context) async {
    const url = 'https://chibatech.jp/about/institute/campus/tsudanuma.html';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'URLを開けませんでした';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('キャンパス情報サイトを開けませんでした: $e'),
            action: SnackBarAction(
              label: 'リトライ',
              onPressed: () => _openCampusWebsite(context),
            ),
          ),
        );
      }
    }
  }

  void _showNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UnifiedNotificationScreen(),
      ),
    );
  }

  Widget _buildTodaySchedule(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final selectedScheduleId = ref.watch(selectedScheduleIdProvider);
    final lecturePeriodAsync = ref.watch(lecturePeriodSettingsProvider);
    final scheduleListAsync =
        userId == null
            ? const AsyncValue<List<Schedule>>.loading()
            : ref.watch(scheduleListProvider(userId));
    final todayScheduleAsync = ref.watch(
      currentUserSelectedTodayScheduleProvider,
    );
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final currentPeriodAsync = ref.watch(currentUserCurrentPeriodProvider);
    final isSchoolDay = ref.watch(isSchoolDayProvider);

    if (!isSchoolDay) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.free_breakfast,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              '今日は授業がありません',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return todayScheduleAsync.when(
      data: (todayClasses) {
        return currentPeriodAsync.when(
          data: (currentPeriod) {
            final activeSchedule = scheduleListAsync.maybeWhen(
              data: (schedules) {
                if (schedules.isEmpty) return null;
                if (selectedScheduleId != null &&
                    schedules.any((s) => s.id == selectedScheduleId)) {
                  return schedules.firstWhere(
                    (s) => s.id == selectedScheduleId,
                  );
                }
                return schedules.first;
              },
              orElse: () => null,
            );
            final activeScheduleId = activeSchedule?.id;
            final canUseAttendanceByLecturePeriod =
                _isWithinConfiguredLecturePeriod(
                  settings: lecturePeriodAsync.valueOrNull,
                  semester: activeSchedule?.semester,
                );
            final todayWeekdayKey = _weekdayKeyFromDate(DateTime.now());

            // 今日授業がある科目のみをフィルター
            final scheduledClasses = <int, ScheduleClass>{};
            for (int i = 0; i < todayClasses.length; i++) {
              if (todayClasses[i] != null) {
                scheduledClasses[i + 1] = todayClasses[i]!;
              }
            }

            if (scheduledClasses.isEmpty) {
              return Container(
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_available,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '今日は授業がありません',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            // 連続講義を考慮したクラス表示用のマップを作成
            final displayClasses = <int, ScheduleClass>{};
            final processedIds = <String>{};

            // 時限順でスキャンして、開始セルまたは単独の授業のみを表示対象とする
            for (int period = 1; period <= 10; period++) {
              if (scheduledClasses.containsKey(period)) {
                final scheduleClass = scheduledClasses[period]!;

                // まだ処理されていない授業IDの場合のみ追加
                if (!processedIds.contains(scheduleClass.id)) {
                  displayClasses[period] = scheduleClass;
                  processedIds.add(scheduleClass.id);
                }
              }
            }

            // 今日の全授業を時限順で表示
            final sortedEntries =
                displayClasses.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key));

            return Column(
              children:
                  sortedEntries.map((entry) {
                    final period = entry.key;
                    final scheduleClass = entry.value;
                    final now = DateTime.now();
                    final timeSlot = timeSlotsAsync.firstWhere(
                      (slot) => slot.period == period,
                      orElse:
                          () => TimeSlot(
                            period: period,
                            startTime: '${period + 8}:00',
                            endTime: '${period + 9}:00',
                          ),
                    );

                    // 講義期間内のみ、実時間ベースで現在/次講義を判定
                    final isActive =
                        canUseAttendanceByLecturePeriod &&
                        _isCurrentLectureOverlayVisible(
                          now: now,
                          timeSlot: timeSlot,
                          duration: scheduleClass.duration,
                          timeSlots: timeSlotsAsync,
                        );
                    final isNext =
                        canUseAttendanceByLecturePeriod &&
                        !isActive &&
                        _isNextLectureOverlayVisible(
                          now: now,
                          timeSlot: timeSlot,
                        );
                    final canQuickAttend =
                        canUseAttendanceByLecturePeriod &&
                        activeScheduleId != null &&
                        todayWeekdayKey != null &&
                        _isAttendanceTapAvailableForSlot(
                          now: now,
                          timeSlot: timeSlot,
                        );

                    return GestureDetector(
                      onTap:
                          () => _showClassDetailsDialog(
                            context,
                            scheduleClass,
                            period,
                            timeSlot,
                            timeSlotsAsync,
                            schedule: activeSchedule,
                            canUseAttendanceByLecturePeriod:
                                canUseAttendanceByLecturePeriod,
                          ),
                      child: Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isActive
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.3)
                                      : isNext
                                      ? Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer
                                          .withValues(alpha: 0.3)
                                      : Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  isActive
                                      ? Border.all(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        width: 1,
                                      )
                                      : isNext
                                      ? Border.all(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                        width: 1,
                                      )
                                      : null,
                            ),
                            child: Row(
                              children: [
                                // 時間表示
                                Container(
                                  width: scheduleClass.duration > 1 ? 65 : 50,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(
                                      int.parse(
                                        '0xff${scheduleClass.color.substring(1)}',
                                      ),
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Color(
                                        int.parse(
                                          '0xff${scheduleClass.color.substring(1)}',
                                        ),
                                      ).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        scheduleClass.duration > 1
                                            ? '${timeSlot.period}-${timeSlot.period + scheduleClass.duration - 1}限'
                                            : '${timeSlot.period}限',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall?.copyWith(
                                          color:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              scheduleClass.duration > 1
                                                  ? 10
                                                  : 12,
                                        ),
                                      ),
                                      Text(
                                        scheduleClass.duration > 1
                                            ? '${timeSlot.startTime}-${_getEndTime(timeSlot, scheduleClass.duration, timeSlotsAsync)}'
                                            : timeSlot.startTime,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(
                                          color:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white70
                                                  : Colors.black,
                                          fontSize:
                                              scheduleClass.duration > 1
                                                  ? 8
                                                  : 11,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // 科目情報
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        scheduleClass.subjectName,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Flexible(
                                            flex: 0,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.surface,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).dividerColor,
                                                ),
                                              ),
                                              child: Text(
                                                scheduleClass.classroom,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (scheduleClass
                                              .instructor
                                              .isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.person,
                                              size: 14,
                                              color:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                scheduleClass.instructor,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
                                                  color:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                          if (canQuickAttend) ...[
                                            const SizedBox(width: 8),
                                            FilledButton.icon(
                                              onPressed: () async {
                                                await _openAttendanceQrReaderAndMark(
                                                  context: context,
                                                  scheduleId: activeScheduleId,
                                                  weekdayKey: todayWeekdayKey,
                                                  period: period,
                                                  scheduleClass: scheduleClass,
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.qr_code_scanner,
                                                size: 14,
                                              ),
                                              label: const Text('出席'),
                                              style: FilledButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                minimumSize: const Size(0, 28),
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                textStyle: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (scheduleClass.notes != null &&
                                          scheduleClass.notes!
                                              .trim()
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          scheduleClass.notes!.trim(),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // 色インディケーター
                                Container(
                                  width: 3,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      int.parse(
                                        '0xff${scheduleClass.color.substring(1)}',
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isActive || isNext)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color:
                                        isActive
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.08)
                                            : Theme.of(context)
                                                .colorScheme
                                                .secondary
                                                .withValues(alpha: 0.06),
                                  ),
                                  alignment: Alignment.topRight,
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isActive
                                              ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                              : Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      isActive ? '現在講義中' : '次の講義',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall?.copyWith(
                                        color:
                                            isActive
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary
                                                : Theme.of(
                                                  context,
                                                ).colorScheme.onSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('エラーが発生しました'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('時間割の読み込みに失敗しました'),
    );
  }

  void _showClassDetailsDialog(
    BuildContext hostContext,
    ScheduleClass scheduleClass,
    int period,
    TimeSlot timeSlot,
    List<TimeSlot> timeSlots, {
    Schedule? schedule,
    bool canUseAttendanceByLecturePeriod = true,
  }) {
    final now = DateTime.now();
    final weekdayKey = _weekdayKeyFromDate(now);
    final userId = ref.read(currentUserIdProvider);
    final canEdit =
        schedule != null &&
        weekdayKey != null &&
        userId != null &&
        userId == schedule.userId;
    const weekdayNames = {
      'monday': '月曜日',
      'tuesday': '火曜日',
      'wednesday': '水曜日',
      'thursday': '木曜日',
      'friday': '金曜日',
      'saturday': '土曜日',
    };
    final attendanceSlot =
        schedule?.timeSlots.firstWhere(
          (slot) => slot.period == period,
          orElse: () => timeSlot,
        ) ??
        timeSlot;
    final canTapAttendance =
        canEdit &&
        canUseAttendanceByLecturePeriod &&
        _isAttendanceTapAvailableForSlot(now: now, timeSlot: attendanceSlot);

    void ensureActiveUser() {
      if (!mounted ||
          userId == null ||
          ref.read(currentUserIdProvider) != userId ||
          userId != schedule?.userId) {
        throw StateError('ログイン状態を確認してください');
      }
    }

    showDialog<void>(
      context: hostContext,
      barrierDismissible: false,
      builder: (dialogContext) => ScheduleClassDetailDialog(
        lesson: scheduleClass,
        onAddAssignment: !canEdit ? null : () => showAssignmentEditor(dialogContext, ref, schedule: schedule, lesson: scheduleClass),
        dayLabel: weekdayNames[weekdayKey] ?? '日曜日',
        periodRange: ScheduleUtils.getClassPeriodRange(
          period,
          scheduleClass.duration,
        ),
        timeRange: schedule == null
            ? '${timeSlot.startTime} - ${_getEndTime(timeSlot, scheduleClass.duration, timeSlots)}'
            : ScheduleUtils.getClassTimeRange(
                schedule,
                period,
                scheduleClass.duration,
              ),
        onSaveNotes: !canEdit
            ? null
            : (notes) {
                ensureActiveUser();
                return _saveHomeClassNotesInline(
                  context: hostContext,
                  scheduleId: schedule.id,
                  weekdayKey: weekdayKey,
                  scheduleClass: scheduleClass,
                  notes: notes,
                );
              },
        loadAttendance: !canEdit
            ? null
            : () async {
                ensureActiveUser();
                return _loadAttendanceSummaryForClass(
                  scheduleId: schedule.id,
                  classId: scheduleClass.id,
                  weekdayKey: weekdayKey,
                  startPeriod: period,
                  semester: schedule.semester,
                );
              },
        loadAttendanceSessions: !canEdit
            ? null
            : () async {
                ensureActiveUser();
                final settings =
                    ref.read(lecturePeriodSettingsProvider).valueOrNull ??
                    await LecturePeriodService.getLecturePeriod();
                ensureActiveUser();
                final start = schedule.semester.contains('後期')
                    ? settings?.fallStartDate
                    : settings?.springStartDate;
                if (start == null) return [];
                return AttendanceService.getClassAttendanceSessions(
                  userId: userId,
                  scheduleId: schedule.id,
                  classId: scheduleClass.id,
                  weekdayKey: weekdayKey,
                  startPeriod: period,
                  semesterStartDate: start,
                );
              },
        onSaveAttendance: !canEdit
            ? null
            : (session, status) async {
                ensureActiveUser();
                await AttendanceService.upsertAttendanceStatus(
                  userId: userId,
                  scheduleId: schedule.id,
                  classId: scheduleClass.id,
                  subjectName: scheduleClass.subjectName,
                  weekdayKey: weekdayKey,
                  startPeriod: period,
                  duration: scheduleClass.duration,
                  attendanceDate: session.date,
                  status: status,
                  existingRecordId: session.recordId,
                );
              },
        onAttendance: !canTapAttendance
            ? null
            : () {
                ensureActiveUser();
                return _openAttendanceQrReaderAndMark(
                  context: hostContext,
                  scheduleId: schedule.id,
                  weekdayKey: weekdayKey,
                  period: period,
                  scheduleClass: scheduleClass,
                );
              },
        onOpenRoom: scheduleClass.classroom.trim().isEmpty
            ? null
            : () {
                final uri = Uri(
                  path: '/classroom-map',
                  queryParameters: {'q': scheduleClass.classroom.trim()},
                );
                Navigator.of(dialogContext).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (hostContext.mounted) {
                    GoRouter.of(hostContext).push(uri.toString());
                  }
                });
              },
      ),
    );
  }

  bool _isWithinConfiguredLecturePeriod({
    required LecturePeriodSettings? settings,
    required String? semester,
    DateTime? now,
  }) {
    // 設定未取得/未設定時は従来どおり表示する
    if (settings == null || semester == null || semester.isEmpty) return true;
    final current = now ?? DateTime.now();
    final day = DateTime(current.year, current.month, current.day);

    final isFall = semester.contains('後期');
    final startRaw = isFall ? settings.fallStartDate : settings.springStartDate;
    final endRaw = isFall ? settings.fallEndDate : settings.springEndDate;
    final legacyStart = settings.lectureStartDate;
    final legacyEnd = settings.lectureEndDate;

    final start = startRaw ?? (!isFall ? legacyStart : null);
    final end = endRaw ?? (!isFall ? legacyEnd : null);
    if (start == null || end == null) return true;

    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return !day.isBefore(startDay) && !day.isAfter(endDay);
  }

  Future<bool> _saveHomeClassNotesInline({
    required BuildContext context,
    required String scheduleId,
    required String weekdayKey,
    required ScheduleClass scheduleClass,
    required String? notes,
  }) async {
    try {
      final latest = await ScheduleService.getScheduleById(scheduleId);
      if (latest == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('時間割の取得に失敗しました')));
        }
        return false;
      }

      final updatedTimetable = <String, Map<int, ScheduleClass?>>{};
      for (final dayEntry in latest.timetable.entries) {
        updatedTimetable[dayEntry.key] = <int, ScheduleClass?>{};
        for (final periodEntry in dayEntry.value.entries) {
          final value = periodEntry.value;
          if (dayEntry.key == weekdayKey &&
              value != null &&
              value.id == scheduleClass.id) {
            updatedTimetable[dayEntry.key]![periodEntry.key] = ScheduleClass(
              id: value.id,
              subjectName: value.subjectName,
              classroom: value.classroom,
              instructor: value.instructor,
              color: value.color,
              notes: notes,
              duration: value.duration,
              isStartCell: value.isStartCell,
            );
          } else {
            updatedTimetable[dayEntry.key]![periodEntry.key] = value;
          }
        }
      }

      final updatedSchedule = Schedule(
        id: latest.id,
        userId: latest.userId,
        name: latest.name,
        semester: latest.semester,
        timetable: updatedTimetable,
        timeSlots: latest.timeSlots,
        createdAt: latest.createdAt,
        updatedAt: DateTime.now(),
      );
      await ScheduleService.updateSchedule(updatedSchedule);

      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        ref.invalidate(scheduleListProvider(userId));
        ref.invalidate(scheduleProvider(userId));
        ref.invalidate(todayScheduleProvider(userId));
        ref.invalidate(currentPeriodProvider(userId));
        ref.invalidate(nextClassProvider(userId));
      }
      ref.invalidate(todayScheduleByIdProvider(scheduleId));
      ref.invalidate(currentUserSelectedTodayScheduleProvider);
      ref.invalidate(currentUserTodayScheduleProvider);
      ref.invalidate(currentUserScheduleProvider);
      // ホーム内の他カード含め即時反映
      ref.read(homeRefreshNotifierProvider.notifier).state++;

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('メモを更新しました')));
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('メモ更新に失敗しました: $e')));
      }
      return false;
    }
  }

  Future<void> _markAttendanceFromHome({
    required BuildContext context,
    required String scheduleId,
    required String weekdayKey,
    required int period,
    required ScheduleClass scheduleClass,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ログインが必要です')));
      }
      return;
    }

    final schedule = await ScheduleService.getScheduleById(scheduleId);
    if (schedule == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('時間割の取得に失敗しました')));
      }
      return;
    }

    try {
      final result = await AttendanceService.markAttendanceFromTap(
        userId: userId,
        scheduleId: scheduleId,
        schedule: schedule,
        weekdayKey: weekdayKey,
        startPeriod: period,
        scheduleClass: scheduleClass,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.snackBarSurface(context, result.success ? Colors.green : Colors.orange),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('出欠記録に失敗しました: $e')));
    }
  }

  Future<void> _openAttendanceQrReaderAndMark({
    required BuildContext context,
    required String? scheduleId,
    required String? weekdayKey,
    required int period,
    required ScheduleClass scheduleClass,
  }) async {
    if (scheduleId == null || weekdayKey == null) return;
    String? scannedRaw;
    try {
      scannedRaw = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const AttendanceQrReaderScreen()),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('QRリーダーを起動できませんでした: $e')));
      }
      return;
    }
    if (scannedRaw == null || scannedRaw.trim().isEmpty) return;
    await _openAttendancePortalFromQr(context: context, scannedRaw: scannedRaw);
    if (!context.mounted) return;
    await _markAttendanceFromHome(
      context: context,
      scheduleId: scheduleId,
      weekdayKey: weekdayKey,
      period: period,
      scheduleClass: scheduleClass,
    );
  }

  Future<void> _openAttendancePortalFromQr({
    required BuildContext context,
    required String scannedRaw,
  }) async {
    final raw = scannedRaw.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    final isWeb =
        (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    if (!isWeb) return;
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('出席サイトを開けませんでした')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('出席サイトを開けませんでした: $e')));
    }
  }

  String? _weekdayKeyFromDate(DateTime date) {
    switch (date.weekday) {
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
      default:
        return null;
    }
  }

  bool _isAttendanceTapAvailableForSlot({
    required DateTime now,
    required TimeSlot timeSlot,
  }) {
    final startParts = timeSlot.startTime.split(':');
    final lectureStart = DateTime(
      now.year,
      now.month,
      now.day,
      int.tryParse(startParts[0]) ?? 9,
      int.tryParse(startParts[1]) ?? 0,
    );
    final availableFrom = lectureStart.subtract(const Duration(minutes: 20));
    final availableUntil = lectureStart.add(const Duration(hours: 1));
    return !now.isBefore(availableFrom) && !now.isAfter(availableUntil);
  }

  bool _isCurrentLectureOverlayVisible({
    required DateTime now,
    required TimeSlot timeSlot,
    required int duration,
    required List<TimeSlot> timeSlots,
  }) {
    final range = _classDateTimeRange(
      now: now,
      startTimeSlot: timeSlot,
      duration: duration,
      timeSlots: timeSlots,
    );
    return !now.isBefore(range.start) && now.isBefore(range.end);
  }

  bool _isNextLectureOverlayVisible({
    required DateTime now,
    required TimeSlot timeSlot,
  }) {
    final start = _timeOnDate(now: now, hhmm: timeSlot.startTime);
    final from = start.subtract(const Duration(minutes: 20));
    return !now.isBefore(from) && now.isBefore(start);
  }

  DateTimeRange _classDateTimeRange({
    required DateTime now,
    required TimeSlot startTimeSlot,
    required int duration,
    required List<TimeSlot> timeSlots,
  }) {
    final endPeriod = startTimeSlot.period + duration - 1;
    final endTimeSlot = timeSlots.firstWhere(
      (slot) => slot.period == endPeriod,
      orElse:
          () => TimeSlot(
            period: endPeriod,
            startTime: '${endPeriod + 8}:00',
            endTime: '${endPeriod + 9}:00',
          ),
    );
    return DateTimeRange(
      start: _timeOnDate(now: now, hhmm: startTimeSlot.startTime),
      end: _timeOnDate(now: now, hhmm: endTimeSlot.endTime),
    );
  }

  DateTime _timeOnDate({required DateTime now, required String hhmm}) {
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts.first) ?? 9;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  Future<AttendanceClassSummary> _loadAttendanceSummaryForClass({
    required String scheduleId,
    required String classId,
    required String weekdayKey,
    required int startPeriod,
    required String? semester,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return const AttendanceClassSummary(
        presentCount: 0,
        lateCount: 0,
        absentCount: 0,
      );
    }
    final settings = ref.read(lecturePeriodSettingsProvider).valueOrNull;
    final window = _attendanceSummaryWindowForSemester(
      settings: settings,
      semester: semester,
    );
    if (window == null || weekdayKey.isEmpty) {
      return AttendanceService.getClassAttendanceSummary(
        userId: userId,
        scheduleId: scheduleId,
        classId: classId,
      );
    }
    return AttendanceService.getClassAttendanceSummaryForRange(
      userId: userId,
      scheduleId: scheduleId,
      classId: classId,
      weekdayKey: weekdayKey,
      startPeriod: startPeriod,
      startDate: window.start,
      endDate: window.end,
    );
  }

  DateTimeRange? _attendanceSummaryWindowForSemester({
    required LecturePeriodSettings? settings,
    required String? semester,
  }) {
    if (settings == null || semester == null || semester.isEmpty) return null;
    final isFall = semester.contains('後期');
    final startRaw = isFall ? settings.fallStartDate : settings.springStartDate;
    final endRaw = isFall ? settings.fallEndDate : settings.springEndDate;
    final legacyStart = settings.lectureStartDate;
    final legacyEnd = settings.lectureEndDate;

    final start = startRaw ?? (!isFall ? legacyStart : null);
    final end = endRaw ?? (!isFall ? legacyEnd : null);
    if (start == null || end == null) return null;

    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return DateTimeRange(start: startDay, end: endDay);
  }

  String _getEndTime(
    TimeSlot startTimeSlot,
    int duration,
    List<TimeSlot> timeSlots,
  ) {
    final endPeriod = startTimeSlot.period + duration - 1;
    final endTimeSlot = timeSlots.firstWhere(
      (slot) => slot.period == endPeriod,
      orElse:
          () => TimeSlot(
            period: endPeriod,
            startTime: '${endPeriod + 8}:00',
            endTime: '${endPeriod + 9}:00',
          ),
    );
    return endTimeSlot.endTime;
  }

  Widget _buildCampusMaps(BuildContext context) {
    return Row(
      children: [
        // 津田沼キャンパス
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CampusMapWidget(
                campus: 'tsudanuma',
                height: 100,
                showTitle: false,
                campusNavigationMap: _campusNavigationOptions,
              ),
              const SizedBox(height: 4),
              Text(
                '津田沼',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // 新習志野キャンパス
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CampusMapWidget(
                campus: 'narashino',
                height: 100,
                showTitle: false,
              ),
              const SizedBox(height: 4),
              Text(
                '新習志野',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCampusMapDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder:
                (context, scrollController) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'キャンパスマップ',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            const CampusMapWidget(
                              campus: 'tsudanuma',
                              height: 200,
                            ),
                            const SizedBox(height: 24),
                            const CampusMapWidget(
                              campus: 'narashino',
                              height: 200,
                              campusNavigationMap: _campusNavigationOptions,
                            ),
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'アクセス情報',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('津田沼キャンパス：JR総武線「津田沼駅」徒歩3分'),
                                    const Text('新習志野キャンパス：JR京葉線「新習志野駅」徒歩6分'),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        const url =
                                            'https://www.cit.ac.jp/guide/campus/';
                                        try {
                                          final uri = Uri.parse(url);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri);
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('公式サイトを開けませんでした'),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.open_in_browser),
                                      label: const Text('公式サイトで詳細を見る'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16), // 最下部にスペース追加
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  // 学バス情報カードを構築
  Widget _buildBusInfoCard(BuildContext context, WidgetRef ref) {
    final busInfo = ref.watch(busInformationStreamProvider);
    final hasEnabledBusTimetable = busInfo.when(
      data: _hasEnabledBusTimetable,
      loading: () => false,
      error: (_, __) => false,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_bus,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('学バス情報', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (hasEnabledBusTimetable)
                  TextButton.icon(
                    onPressed: () => _showBusTimetableImage(context),
                    icon: Icon(
                      Icons.schedule,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      'ダイヤ一覧',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 28),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            busInfo.when(
              data:
                  (data) =>
                      data == null
                          ? _buildNoBusDataState(context)
                          : Column(
                            children: [
                              _buildInteractiveBusInfoContent(context, data),
                              if (data.description.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _buildBusTimetableNote(
                                  context,
                                  data.description,
                                ),
                              ],
                            ],
                          ),
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error: (error, _) => _buildBusErrorState(context, error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusTimetableNote(BuildContext context, String note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(note, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  bool _hasEnabledBusTimetable(BusInformation? data) {
    if (data == null) return false;
    return data.activeRoutes.any(
      (route) => route.timeEntries.any((entry) => entry.isActive),
    );
  }

  Widget _buildNoBusDataState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_bus_filled_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            '学バス情報が設定されていません',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusErrorState(BuildContext context, dynamic error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.tintedSurface(context, Colors.red),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 40, color: AppColors.accent(context, Colors.red.shade400)),
          const SizedBox(height: 8),
          Text(
            '学バス情報の読み込みに失敗しました',
            style: TextStyle(color: AppColors.accent(context, Colors.red.shade600)),
          ),
        ],
      ),
    );
  }

  // インタラクティブな学バス情報コンテンツ
  Widget _buildInteractiveBusInfoContent(
    BuildContext context,
    BusInformation busInfo,
  ) {
    final isOperating = busInfo.isCurrentlyOperating;
    final activeRoutes =
        busInfo.operatingRoutes
            .where((route) => route.activeTimeEntries.isNotEmpty)
            .toList();

    // ホームウィジェット（学バス）を更新
    try {
      final preferred = ref.read(preferredBusCampusProvider);
      HomeWidgetsService.updateBusRealtime(busInfo, preferredCampus: preferred);
    } catch (_) {}

    // 初回のみ、設定に基づき優先キャンパスの路線を先頭表示にする
    if (!_busInitialRouteSet && activeRoutes.isNotEmpty) {
      final preferred = ref.read(preferredBusCampusProvider);
      int? preferredIndex;
      if (preferred == 'narashino') {
        preferredIndex = activeRoutes.indexWhere((r) {
          final name = r.name;
          final idxArrow = name.indexOf('→');
          final idxNarashino = name.indexOf('新習志野');
          return idxNarashino >= 0 && (idxArrow < 0 || idxNarashino < idxArrow);
        });
      } else {
        // default tsudanuma
        preferredIndex = activeRoutes.indexWhere((r) {
          final name = r.name;
          final idxArrow = name.indexOf('→');
          final idxTsudanuma = name.indexOf('津田沼');
          return idxTsudanuma >= 0 && (idxArrow < 0 || idxTsudanuma < idxArrow);
        });
      }
      if (preferredIndex >= 0) {
        _selectedRouteIndex = preferredIndex;
      }
      _busInitialRouteSet = true;
    }

    if (!isOperating || activeRoutes.isEmpty) {
      return _buildStaticBusStatus(
        context,
        busInfo,
        noActiveRoutes: activeRoutes.isEmpty,
      );
    }

    // 当日の次の便が無ければ、本日の運行終了表示
    final hasNextBusToday = activeRoutes.any(
      (route) => _hasNextBusToday(route),
    );
    if (!hasNextBusToday) {
      return _buildServiceEndedStatus(context);
    }

    return Column(
      children: [
        // フリップ可能な路線カード
        AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            return GestureDetector(
              onTap: _flipToNextRoute,
              onHorizontalDragEnd: (details) {
                // 左スワイプ（次の路線へ）
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < -300) {
                  _flipToNextRoute();
                }
                // 右スワイプ（前の路線へ）
                else if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 300) {
                  _flipToPreviousRoute();
                }
              },
              child: Transform(
                alignment: Alignment.center,
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(_flipAnimation.value * 3.14159),
                child:
                    _flipAnimation.value <= 0.5
                        ? _buildFlippableRouteCard(
                          context,
                          activeRoutes[_selectedRouteIndex %
                              activeRoutes.length],
                          false,
                        )
                        : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(3.14159),
                          child: _buildFlippableRouteCard(
                            context,
                            activeRoutes[(_selectedRouteIndex + 1) %
                                activeRoutes.length],
                            true,
                          ),
                        ),
              ),
            );
          },
        ),

        // 路線インディケーター
        if (activeRoutes.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              activeRoutes.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color:
                      index == (_selectedRouteIndex % activeRoutes.length)
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'タップまたはスワイプで切り替え',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // 静的な運行状況表示（運行していない場合）
  Widget _buildStaticBusStatus(
    BuildContext context,
    BusInformation busInfo, {
    bool noActiveRoutes = false,
  }) {
    final isOperating = busInfo.isCurrentlyOperating;
    final showNotOperating = !isOperating || noActiveRoutes;
    final currentPeriod = busInfo.currentOperationPeriod;

    // 学バスウィジェットも空データ含め更新
    try {
      final preferred = ref.read(preferredBusCampusProvider);
      HomeWidgetsService.updateBusRealtime(busInfo, preferredCampus: preferred);
    } catch (_) {}

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: showNotOperating ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              showNotOperating ? Colors.orange.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            showNotOperating ? Icons.cancel : Icons.check_circle,
            color:
                showNotOperating
                    ? Colors.orange.shade600
                    : Colors.green.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showNotOperating ? '現在運行しておりません' : '運行中（運行時刻外）',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        showNotOperating
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                  ),
                ),
                if (currentPeriod != null && !showNotOperating) ...[
                  const SizedBox(height: 2),
                  Text(
                    '期間: ${currentPeriod.name}',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          showNotOperating
                              ? Colors.orange.shade600
                              : Colors.green.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 本日の運行終了状況表示
  Widget _buildServiceEndedStatus(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.bedtime, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 40),
          const SizedBox(height: 8),
          Text(
            '本日の運行は終了しました',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '明日の時刻表をご確認ください',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // 当日に次の便があるかチェック
  bool _hasNextBusToday(BusRoute route) {
    final now = DateTime.now();
    final activeEntries = route.activeTimeEntries;

    for (final entry in activeEntries) {
      final entryTime = DateTime(
        now.year,
        now.month,
        now.day,
        entry.hour,
        entry.minute,
      );
      if (entryTime.isAfter(now)) {
        return true;
      }
    }
    return false;
  }

  // フリップ可能な路線カード
  Widget _buildFlippableRouteCard(
    BuildContext context,
    BusRoute route,
    bool isFlipped,
  ) {
    final baseColor = _parseRouteHexColor(route.color);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final routeLabelBgColor =
        isDarkMode
            ? Colors.black.withValues(alpha: 0.82)
            : Colors.white.withValues(alpha: 0.90);
    final routeLabelTextColor = isDarkMode ? Colors.white : Colors.black;
    final routeColorHsl = HSLColor.fromColor(baseColor);
    final cardColorStart =
        routeColorHsl
            .withLightness((routeColorHsl.lightness + 0.30).clamp(0.0, 1.0))
            .toColor();
    final cardColorEnd =
        routeColorHsl
            .withLightness((routeColorHsl.lightness + 0.40).clamp(0.0, 1.0))
            .toColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardColorStart, cardColorEnd],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 路線名（背景色の影響を受けないよう白背景上に固定）
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: routeLabelBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.route, color: routeLabelTextColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: routeLabelTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 次の便とカウントダウン（当日分のみ）
          _buildCountdownSection(context, route),
        ],
      ),
    );
  }

  Color _parseRouteHexColor(String? hex) {
    final normalized = (hex ?? '').trim();
    final sanitized =
        normalized.startsWith('#') ? normalized.substring(1) : normalized;
    if (RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(sanitized)) {
      return Color(int.parse('FF$sanitized', radix: 16));
    }
    return Theme.of(context).colorScheme.primary;
  }

  // カウントダウンセクション
  Widget _buildCountdownSection(BuildContext context, BusRoute route) {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      builder: (context, snapshot) {
        final now = DateTime.now();
        // 現在時刻基準で都度「次の便」を再計算（当日分のみ）
        final dynamicNext = route.getNextBusTime();

        if (dynamicNext == null) {
          // 本日の便が全て終了
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '本日の運行は終了しました',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        final nextBusTime = DateTime(
          now.year,
          now.month,
          now.day,
          dynamicNext.hour,
          dynamicNext.minute,
        );
        final timeUntilBus = nextBusTime.difference(now);
        final nextNextBus = route.getNextNextBusTime();
        return _buildTimeDisplay(
          context,
          route,
          dynamicNext,
          timeUntilBus,
          nextNextBus,
        );
      },
    );
  }

  // 時刻表示ウィジェット
  Widget _buildTimeDisplay(
    BuildContext context,
    BusRoute route,
    BusTimeEntry nextBus,
    Duration timeUntil,
    BusTimeEntry? nextNextBus, {
    bool isTomorrow = false,
  }) {
    final hours = timeUntil.inHours;
    final minutes = timeUntil.inMinutes % 60;
    final seconds = timeUntil.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            '次の便: ${nextBus.timeString}${isTomorrow ? ' (明日)' : ''}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (nextNextBus != null)
                        TextSpan(
                          text: ' (その次の便: ${nextNextBus.timeString})',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (nextBus.note != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    nextBus.note!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // カウントダウン表示
          Row(
            children: [
              _buildTimeUnit(context, hours.toString().padLeft(2, '0'), '時間'),
              const SizedBox(width: 8),
              _buildTimeUnit(context, minutes.toString().padLeft(2, '0'), '分'),
              const SizedBox(width: 8),
              _buildTimeUnit(context, seconds.toString().padLeft(2, '0'), '秒'),
              const Spacer(),
              Icon(
                Icons.timer,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 時間単位表示
  Widget _buildTimeUnit(BuildContext context, String value, String unit) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.onColor(Theme.of(context).colorScheme.primary),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }

  // 路線切り替えアニメーション（次へ）
  void _flipToNextRoute() async {
    final busInfo = ref.read(busInformationStreamProvider).valueOrNull;
    if (busInfo == null) return;

    final activeRoutes =
        busInfo.operatingRoutes
            .where((route) => route.activeTimeEntries.isNotEmpty)
            .toList();

    if (activeRoutes.length <= 1) return;

    // アニメーション中の場合は処理をスキップ
    if (_flipAnimationController.isAnimating) return;

    // 半回転で次の路線に切り替え
    _flipAnimationController.forward().then((_) {
      setState(() {
        _selectedRouteIndex = (_selectedRouteIndex + 1) % activeRoutes.length;
      });
      _flipAnimationController.reset();
    });
  }

  // 路線切り替えアニメーション（前へ）
  void _flipToPreviousRoute() async {
    final busInfo = ref.read(busInformationStreamProvider).valueOrNull;
    if (busInfo == null) return;

    final activeRoutes =
        busInfo.operatingRoutes
            .where((route) => route.activeTimeEntries.isNotEmpty)
            .toList();

    if (activeRoutes.length <= 1) return;

    // アニメーション中の場合は処理をスキップ
    if (_flipAnimationController.isAnimating) return;

    // 半回転で前の路線に切り替え
    _flipAnimationController.forward().then((_) {
      setState(() {
        _selectedRouteIndex =
            (_selectedRouteIndex - 1 + activeRoutes.length) %
            activeRoutes.length;
      });
      _flipAnimationController.reset();
    });
  }

  // バスダイヤ画像を一発でフルスクリーン表示
  void _showBusTimetableImage(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: false,
      builder:
          (dialogContext) => Consumer(
            builder: (context, ref, child) {
              final imageUrlAsync = ref.watch(firebaseBusTimetableProvider);

              return imageUrlAsync.when(
                data: (imageUrl) {
                  if (imageUrl != null && imageUrl.isNotEmpty) {
                    return interactiveFullscreenNetworkImageDialog(
                      imageUrl: imageUrl,
                      title: '学バス時刻表',
                      maxScale: 5.0,
                      fallbackAssetPath: 'assets/images/bus_timetable.png',
                      errorMessage: 'バス時刻表の読み込みに失敗しました',
                    );
                  }
                  return interactiveFullscreenAssetImageDialog(
                    assetPath: 'assets/images/bus_timetable.png',
                    title: '学バス時刻表（オフライン版）',
                    maxScale: 5.0,
                    errorMessage: 'バス時刻表の読み込みに失敗しました',
                  );
                },
                loading:
                    () => Dialog.fullscreen(
                      backgroundColor: Colors.black87,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                error:
                    (error, _) => interactiveFullscreenAssetImageDialog(
                      assetPath: 'assets/images/bus_timetable.png',
                      title: '学バス時刻表（オフライン版）',
                      maxScale: 5.0,
                      errorMessage: 'バス時刻表の読み込みに失敗しました',
                    ),
              );
            },
          ),
    );
  }

  Widget _buildRouteCard(BuildContext context, BusRoute route) {
    final nextBus = route.getNextBusTime();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final routeTextColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, size: 16, color: routeTextColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  route.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: routeTextColor,
                  ),
                ),
              ),
            ],
          ),
          if (route.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              route.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (nextBus != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '次の便: ${nextBus.timeString}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (nextBus.note != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${nextBus.note})',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClubOrganizationsCard(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openClubOrganizations(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.groups_2_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'サークル・部活一覧',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '体育会加盟団体をカテゴリ別で確認できます',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _openClubOrganizations(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClubOrganizationsScreen()),
    );
  }

  // 便利リンクカードを構築
  Widget _buildConvenienceLinksCard(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(enabledConvenienceLinksProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.link_outlined,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('便利リンク', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  onPressed: () => _showConvenienceLinksManager(context, ref),
                  icon: const Icon(Icons.settings),
                  iconSize: 20,
                  tooltip: 'リンクを管理',
                ),
              ],
            ),
            const SizedBox(height: 12),
            linksAsync.when(
              data: (links) {
                if (links.isEmpty) {
                  return _buildEmptyLinksState(context, ref);
                }
                return _buildLinksGrid(context, links);
              },
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error:
                  (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, color: AppColors.accent(context, Colors.red[400])),
                          const SizedBox(height: 8),
                          Text(
                            'リンクの読み込みに失敗しました',
                            style: TextStyle(color: AppColors.accent(context, Colors.red[600])),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // リンクが空の場合の表示
  Widget _buildEmptyLinksState(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.link_off,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'リンクが設定されていません',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showConvenienceLinksManager(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('リンクを追加'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36)),
          ),
        ],
      ),
    );
  }

  // リンクグリッドを構築
  Widget _buildLinksGrid(BuildContext context, List<ConvenienceLink> links) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 常に2列
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.5, // 横長のタイル
      ),
      itemCount: links.length,
      itemBuilder: (context, index) => _buildLinkTile(context, links[index]),
    );
  }

  // 個別のリンクタイルを構築
  Widget _buildLinkTile(BuildContext context, ConvenienceLink link) {
    return InkWell(
      onTap: () => _openLink(context, link),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: LinkColors.getColor(link.color).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: LinkColors.getColor(link.color).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: LinkColors.getColor(link.color),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                LinkIcons.getIcon(link.iconName),
                color: Theme.of(context).colorScheme.surface,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Uri.parse(link.url).host,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // リンクを開く
  Future<void> _openLink(BuildContext context, ConvenienceLink link) async {
    try {
      final uri = Uri.parse(link.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'URLを開けませんでした';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${link.title}」を開けませんでした: $e'),
            action: SnackBarAction(
              label: '再試行',
              onPressed: () => _openLink(context, link),
            ),
          ),
        );
      }
    }
  }

  // 便利リンク管理画面を表示
  void _showConvenienceLinksManager(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => ConvenienceLinksManagerSheet(
                  scrollController: scrollController,
                ),
          ),
    );
  }

  // 今日の曜日を取得する
  String _getTodayWeekdayText() {
    final now = DateTime.now();
    const weekdays = [
      '', // 0は未使用
      '月曜日の時間割',
      '火曜日の時間割',
      '水曜日の時間割',
      '木曜日の時間割',
      '金曜日の時間割',
      '土曜日の時間割',
      '日曜日の時間割',
    ];

    return weekdays[now.weekday];
  }

  // プルツーリフレッシュでデータを更新
  Future<void> _refreshData(WidgetRef ref, {bool reloadCampusMaps = false}) async {
    try {
      // Start independently so other refresh failures do not prevent map retries.
      final mapRefresh = reloadCampusMaps
          ? ref.read(refreshCampusMapsProvider)().catchError((Object error) {
              debugPrint('キャンパスマップの再読み込みに失敗しました: $error');
            })
          : Future<void>.value();
      final weatherRefresh = _weatherCardKey.currentState?.refresh();
      // 各プロバイダーを無効化して再取得
      _invalidateScheduleProviders();
      ref.invalidate(cafeteriaMenuProvider);
      ref.invalidate(cafeteriaCongestionProvider);
      ref.invalidate(enabledConvenienceLinksProvider);
      ref.invalidate(currentUserConvenienceLinksProvider);
      ref.invalidate(unreadNotificationCountProvider);
      ref.invalidate(globalNotificationsProvider);
      ref.invalidate(unviewedNotificationsProvider);
      ref.invalidate(busInformationProvider);
      ref.invalidate(busInformationStreamProvider);
      ref.invalidate(firebaseBusTimetableProvider);

      // 強制リフレッシュフラグを設定
      ref.read(forceRefreshProvider.notifier).state = true;

      // Firebase画像プロバイダーも無効化して再取得
      ref.invalidate(firebaseTodayMenuProvider);
      ref.invalidate(firebaseWeeklyMenuProvider);
      ref.invalidate(firebaseTsudanumaTodayMenuProvider);
      ref.invalidate(firebaseNarashinoTodayMenuProvider);
      ref.invalidate(firebaseTsudanumaWeeklyMenuProvider);
      ref.invalidate(firebaseNarashinoWeeklyMenuProvider);

      // キャッシュもクリアしてFirebaseから強制再取得
      await _clearFirebaseImageCache();

      // 少し待機してからフラグをリセット
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          ref.read(forceRefreshProvider.notifier).state = false;
        }
      });

      if (weatherRefresh != null) await weatherRefresh;
      await mapRefresh;

      // 少し待機してデータ更新を完了させる
      await Future.delayed(const Duration(milliseconds: 800));

      print('🔄 ホーム画面リフレッシュ完了（Firebase画像含む）');
    } catch (e) {
      // エラーハンドリング
      print('リフレッシュエラー: $e');
    }
  }

  /// Firebase画像のキャッシュをクリア
  Future<void> _clearFirebaseImageCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Firebase画像URLのキャッシュキーを特定して削除
      final keys =
          prefs
              .getKeys()
              .where(
                (key) =>
                    key.startsWith('cache_firebase_today_menu_') ||
                    key.startsWith('cache_firebase_weekly_menu_'),
              )
              .toList();

      for (final key in keys) {
        await prefs.remove(key);
      }

      print('🧹 Firebase画像キャッシュをクリアしました (${keys.length}件)');
    } catch (e) {
      print('⚠️ Firebase画像キャッシュクリアエラー: $e');
    }
  }

  // ウィジェット機能は削除済み

  // 今週の日付を含む学食情報タイトルを生成
  String _getWeeklyMenuTitle() {
    final now = DateTime.now();

    // 今週の月曜日を取得
    final monday = now.subtract(Duration(days: now.weekday - 1));

    // 今週の日曜日を取得
    final sunday = monday.add(const Duration(days: 6));

    // 月と日を取得
    final mondayMonth = monday.month;
    final mondayDay = monday.day;
    final sundayMonth = sunday.month;
    final sundayDay = sunday.day;

    // 同じ月の場合とまたがる場合で表示を分ける
    if (mondayMonth == sundayMonth) {
      return '今週($mondayMonth/$mondayDay-$sundayDay)の学食情報';
    } else {
      return '今週($mondayMonth/$mondayDay-$sundayMonth/$sundayDay)の学食情報';
    }
  }
}

class _YearCalendarImageItem {
  final String name;
  final String downloadUrl;

  const _YearCalendarImageItem({required this.name, required this.downloadUrl});
}
