import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/cafeteria_provider.dart';
import '../../core/providers/cafeteria_review_provider.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/convenience_link_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/global_notification_provider.dart';
import '../../core/providers/firebase_menu_provider.dart';
import '../../core/providers/bus_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/in_app_ad_provider.dart';
import '../../models/cafeteria/cafeteria_model.dart';
import '../../models/schedule/schedule_model.dart';
import '../../models/bus/bus_model.dart';
import '../../models/ads/in_app_ad_model.dart';
import '../../widgets/ads/in_app_ad_card.dart';
import '../../widgets/firebase_menu_image_widget.dart';
import '../../widgets/firebase_bus_timetable_widget.dart';
import '../bus/bus_information_screen.dart';
import '../cafeteria/cafeteria_reviews_screen.dart';
import '../cafeteria/cafeteria_my_screen.dart';
import '../cafeteria/cafeteria_camera_info_screen.dart';
import '../../widgets/campus_map_widget.dart';
import '../../widgets/performance/optimized_notification_badge.dart';
import '../../widgets/common/pulsing_dot_badge.dart';
import '../../models/convenience_link/convenience_link_model.dart';
import '../notification/notification_list_screen.dart';
import '../convenience_link/convenience_link_edit_screen.dart';
import '../notification/unified_notification_screen.dart';
import '../../services/widget/home_widgets_service.dart';

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
  // ホーム上部のTextMatch広告は非表示にする
  bool _showTextMatchAd = false;
  int _selectedRouteIndex = 0; // 選択中の路線インデックス
  bool _busInitialRouteSet = false; // 学バス初期表示の適用有無
  late AnimationController _flipAnimationController;
  late Animation<double> _flipAnimation;
  Timer? _scheduleRefreshTimer;
  void _invalidateScheduleProviders() {
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      // 家族付きプロバイダのインスタンスを直接無効化して再計算させる
      ref.invalidate(todayScheduleProvider(userId));
      ref.invalidate(currentPeriodProvider(userId));
      ref.invalidate(nextClassProvider(userId));
      // ラッパープロバイダーも一応更新
      ref.invalidate(currentUserTodayScheduleProvider);
      ref.invalidate(currentUserCurrentPeriodProvider);
      ref.invalidate(currentUserNextClassProvider);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _loadAdPreference(); // 広告は常に非表示にするため読み込みを無効化

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
          // 最適化された通知ボタン（未読数バッジ付き）
          OptimizedNotificationBadge(onTap: () => _showNotifications(context)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshData(ref),
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
                                "cit_app\assets\icons\textmatch_logo .png",
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
                                      child: const Text(
                                        'AD',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '教科書売ってください！',
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
                                        color: Colors.white.withOpacity(0.2),
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
              Card(
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
                          const Spacer(),
                          TextButton(
                            onPressed: widget.onNavigateToSchedule,
                            child: const Text('詳細を見る'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTodaySchedule(context, ref),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade700),
                        ),
                        child: Text(
                          '(テスト用)ビルド番号3',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 学食情報カード
              Card(
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
                      // 学食レビュー / My食堂 / 食堂カメラボタン
                      Row(
                        children: [
                          Expanded(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                FilledButton.icon(
                                  onPressed: () => _openCafeteriaReviews(context),
                                  icon: const Icon(Icons.reviews, size: 16),
                                  label: const Text('学食レビュー'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    textStyle: const TextStyle(fontSize: 13),
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
                              onPressed: () => _openMyCafeteria(context),
                              icon: const Icon(Icons.favorite, size: 16),
                              label: const Text('My食堂'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _openCafeteriaCamera(context),
                              icon: const Icon(Icons.videocam, size: 16),
                              label: const Text('食堂カメラ'),
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onSecondary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 学バス情報カード
              _buildBusInfoCard(context, ref),
              const SizedBox(height: 16),
              Card(
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 便利リンクカード
              _buildConvenienceLinksCard(context, ref),
            ],
          ),
        ),
      ),
    );
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

  // My食堂画面へ遷移
  void _openMyCafeteria(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MyCafeteriaScreen()),
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
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.info,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'CIT Appの制作者です！',
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
                  '広告が表示を邪魔してごめんなさい泣\n'
                  '少しだけ読んでいただけると嬉しいです。\n\n'
                  'CIT Appの開発と運営に時間とお金が結構かかってます・・・。\n'
                  '直接寄付はお願いしません。\n\n'
                  '本当に消すボタンを押したらもうこの広告は出てこないので、どうか教科書を買う時と売る時はTextMatchを思い出してぜひ活用・ご支援をお願いいたします。',
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
                      foregroundColor: Colors.white,
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
                                content: Text('広告を非表示にしました。ご理解いただきありがとうございます。'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('本当に消す'),
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
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
    final todayScheduleAsync = ref.watch(currentUserTodayScheduleProvider);
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
                    final timeSlot = timeSlotsAsync.firstWhere(
                      (slot) => slot.period == period,
                      orElse:
                          () => TimeSlot(
                            period: period,
                            startTime: '${period + 8}:00',
                            endTime: '${period + 9}:00',
                          ),
                    );

                    // 現在の授業かどうかをチェック
                    bool isActive = false;
                    if (currentPeriod != null) {
                      isActive =
                          period <= currentPeriod &&
                          currentPeriod < period + scheduleClass.duration;
                    }

                    // 次の授業かどうかをチェック
                    bool isNext = false;
                    if (currentPeriod != null && !isActive) {
                      final futurePeriods =
                          displayClasses.keys
                              .where((p) => p > currentPeriod)
                              .toList();
                      if (futurePeriods.isNotEmpty) {
                        futurePeriods.sort();
                        isNext = period == futurePeriods.first;
                      }
                    }

                    return GestureDetector(
                      onTap:
                          () => _showClassDetailsDialog(
                            context,
                            scheduleClass,
                            period,
                            timeSlot,
                            timeSlotsAsync,
                          ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isActive
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(0.3)
                                  : isNext
                                  ? Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                      .withOpacity(0.3)
                                  : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              isActive
                                  ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 1,
                                  )
                                  : isNext
                                  ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    width: 1,
                                  )
                                  : null,
                        ),
                        child: Row(
                          children: [
                            // 時間表示
                            Container(
                              width: scheduleClass.duration > 1 ? 65 : 50,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(
                                    '0xff${scheduleClass.color.substring(1)}',
                                  ),
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Color(
                                    int.parse(
                                      '0xff${scheduleClass.color.substring(1)}',
                                    ),
                                  ).withOpacity(0.3),
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
                                      color: Color(
                                        int.parse(
                                          '0xff${scheduleClass.color.substring(1)}',
                                        ),
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          scheduleClass.duration > 1 ? 10 : 12,
                                    ),
                                  ),
                                  Text(
                                    scheduleClass.duration > 1
                                        ? '${timeSlot.startTime}-${_getEndTime(timeSlot, scheduleClass.duration, timeSlotsAsync)}'
                                        : timeSlot.startTime,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color: Color(
                                        int.parse(
                                          '0xff${scheduleClass.color.substring(1)}',
                                        ),
                                      ),
                                      fontSize:
                                          scheduleClass.duration > 1 ? 8 : 11,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isActive) ...[
                                        Text(
                                          '現在の授業',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.play_circle_filled,
                                          size: 16,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                      ] else if (isNext) ...[
                                        Text(
                                          '次の授業',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.secondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.schedule,
                                          size: 16,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (isActive || isNext)
                                    const SizedBox(height: 2),
                                  Text(
                                    scheduleClass.subjectName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        flex: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
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
                                    ],
                                  ),
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
    BuildContext context,
    ScheduleClass scheduleClass,
    int period,
    TimeSlot timeSlot,
    List<TimeSlot> timeSlots,
  ) {
    final now = DateTime.now();
    final weekday = Weekday.values[now.weekday - 1];
    final weekdayNames = {
      Weekday.monday: '月曜日',
      Weekday.tuesday: '火曜日',
      Weekday.wednesday: '水曜日',
      Weekday.thursday: '木曜日',
      Weekday.friday: '金曜日',
      Weekday.saturday: '土曜日',
    };

    final timeRange =
        scheduleClass.duration > 1
            ? '${timeSlot.startTime}-${_getEndTime(timeSlot, scheduleClass.duration, timeSlots)}'
            : timeSlot.startTime;
    final periodRange =
        scheduleClass.duration > 1
            ? '$period-${period + scheduleClass.duration - 1}限'
            : '$period限';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse('0xff${scheduleClass.color.substring(1)}'),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scheduleClass.subjectName,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  context,
                  Icons.schedule,
                  '時間',
                  '${weekdayNames[weekday] ?? ''} $periodRange\n$timeRange',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  context,
                  Icons.location_on,
                  '教室',
                  scheduleClass.classroom,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  context,
                  Icons.person,
                  '担当教員',
                  scheduleClass.instructor,
                ),
                if (scheduleClass.duration > 1) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    Icons.timer,
                    '講義時間',
                    '${scheduleClass.duration}時間連続',
                  ),
                ],
                if (scheduleClass.notes != null &&
                    scheduleClass.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRowLinkified(
                    context,
                    Icons.note,
                    'メモ',
                    scheduleClass.notes!,
                  ),
                ],
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

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildDetailRowLinkified(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: _linkifyText(context, value),
            ),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _linkifyText(BuildContext context, String text) {
    final spans = <TextSpan>[];
    final urlRegex = RegExp(r'(https?:\/\/[^\s)]+)');
    int start = 0;
    for (final m in urlRegex.allMatches(text)) {
      if (m.start > start) {
        spans.add(TextSpan(text: text.substring(start, m.start)));
      }
      final url = text.substring(m.start, m.end);
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
          recognizer:
              (TapGestureRecognizer()
                ..onTap = () async {
                  final uri = Uri.tryParse(url);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }),
        ),
      );
      start = m.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
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
    final busInfo = ref.watch(busInformationProvider);

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
                                _buildBusTimetableNote(context, data.description),
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
            child: Text(
              note,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
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
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
          const SizedBox(height: 8),
          Text(
            '学バス情報の読み込みに失敗しました',
            style: TextStyle(color: Colors.red.shade600),
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
        busInfo.activeRoutes
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
      if (preferredIndex != null && preferredIndex >= 0) {
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
                          ).colorScheme.onSurface.withOpacity(0.3),
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
                if (currentPeriod != null) ...[
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
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.bedtime, color: Colors.grey.shade600, size: 40),
          const SizedBox(height: 8),
          Text(
            '本日の運行は終了しました',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '明日の時刻表をご確認ください',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
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
    // 新習志野→津田沼のパターンを正確に判定
    final isNarashinoToTsudanuma =
        route.name.contains('新習志野') &&
        route.name.contains('→') &&
        route.name.contains('津田沼') &&
        route.name.indexOf('新習志野') < route.name.indexOf('津田沼');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isNarashinoToTsudanuma
                  ? [Colors.green.shade100, Colors.green.shade50]
                  : [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withOpacity(0.7),
                  ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isNarashinoToTsudanuma
                  ? Colors.green.withOpacity(0.3)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color:
                isNarashinoToTsudanuma
                    ? Colors.green.withOpacity(0.1)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 路線名
          Row(
            children: [
              Icon(
                Icons.route,
                color:
                    isNarashinoToTsudanuma
                        ? Colors.green.shade700
                        : Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  route.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        isNarashinoToTsudanuma
                            ? Colors.green.shade800
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 次の便とカウントダウン（当日分のみ）
          _buildCountdownSection(context, route),
        ],
      ),
    );
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
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
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
        return _buildTimeDisplay(context, route, dynamicNext, timeUntilBus, nextNextBus);
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
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
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
                        text: '次の便: ${nextBus.timeString}${isTomorrow ? ' (明日)' : ''}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (nextNextBus != null)
                        TextSpan(
                          text: ' (その次の便: ${nextNextBus.timeString})',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
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
            style: const TextStyle(
              color: Colors.white,
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
    final busInfo = ref.read(busInformationProvider).valueOrNull;
    if (busInfo == null) return;

    final activeRoutes =
        busInfo.activeRoutes
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
    final busInfo = ref.read(busInformationProvider).valueOrNull;
    if (busInfo == null) return;

    final activeRoutes =
        busInfo.activeRoutes
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
      barrierColor: Colors.black87,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, child) {
          final imageUrlAsync = ref.watch(firebaseBusTimetableProvider);
          
          return imageUrlAsync.when(
            data: (imageUrl) {
              // データが取得できたら画像を表示
              if (imageUrl != null && imageUrl.isNotEmpty) {
                return _buildFullScreenImageDialog(context, imageUrl, dialogContext);
              } else {
                return _buildFullScreenAssetImageDialog(context, dialogContext);
              }
            },
            loading: () {
              // 読み込み中はローディング表示
              return Dialog.fullscreen(
                backgroundColor: Colors.black87,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              );
            },
            error: (error, _) {
              // エラー時はアセット画像を表示
              return _buildFullScreenAssetImageDialog(context, dialogContext);
            },
          );
        },
      ),
    );
  }

  // フルスクリーン画像ダイアログを構築
  Widget _buildFullScreenImageDialog(BuildContext context, String imageUrl, BuildContext dialogContext) {
    return _HomeScreenImageViewer(
      imageUrl: imageUrl,
      isAsset: false,
      title: '学バス時刻表',
    );
  }

  // フルスクリーンアセット画像ダイアログを構築
  Widget _buildFullScreenAssetImageDialog(BuildContext context, BuildContext dialogContext) {
    return _HomeScreenImageViewer(
      imageUrl: 'assets/images/bus_timetable.png',
      isAsset: true,
      title: '学バス時刻表（オフライン版）',
    );
  }

  // Firebaseからの画像をフルスクリーン表示
  void _showFullScreenFirebaseImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _HomeScreenImageViewer(
        imageUrl: imageUrl,
        isAsset: false,
        title: '学バス時刻表',
      ),
    );
  }

  // ローディング画面をフルスクリーン表示
  void _showFullScreenLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: false,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black87,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // アセット画像をフルスクリーン表示
  void _showFullScreenAssetImage(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _HomeScreenImageViewer(
        imageUrl: 'assets/images/bus_timetable.png',
        isAsset: true,
        title: '学バス時刻表（オフライン版）',
      ),
    );
  }

  // フルスクリーンのコントロール（共通）
  Widget _buildFullScreenControls(BuildContext context, String title) {
    return Stack(
      children: [
        // 閉じるボタン
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        // タイトル
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // ピンチアウトのヒント（下部）
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ピンチで拡大・縮小、ドラッグで移動できます',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteCard(BuildContext context, BusRoute route) {
    final nextBus = route.getNextBusTime();

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
              Icon(
                Icons.route,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  route.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                          Icon(Icons.error_outline, color: Colors.red[400]),
                          const SizedBox(height: 8),
                          Text(
                            'リンクの読み込みに失敗しました',
                            style: TextStyle(color: Colors.red[600]),
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
          color: LinkColors.getColor(link.color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: LinkColors.getColor(link.color).withOpacity(0.3),
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
                (context, scrollController) =>
                    _buildLinksManagerSheet(context, ref, scrollController),
          ),
    );
  }

  // リンク管理シートを構築
  Widget _buildLinksManagerSheet(
    BuildContext context,
    WidgetRef ref,
    ScrollController scrollController,
  ) {
    final linksAsync = ref.watch(currentUserConvenienceLinksProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ハンドル
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ヘッダー
          Row(
            children: [
              Icon(
                Icons.link_outlined,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('リンク管理', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                onPressed: () => _resetToDefaults(context, ref),
                icon: const Icon(Icons.restore),
                tooltip: 'デフォルトにリセット',
              ),
              IconButton(
                onPressed: () => _addNewLink(context, ref),
                icon: const Icon(Icons.add),
                tooltip: '新しいリンクを追加',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // リンク一覧
          Expanded(
            child: linksAsync.when(
              data: (links) {
                if (links.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.link_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'リンクがありません',
                          style: TextStyle(
                            fontSize: 18,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _addNewLink(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('最初のリンクを追加'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: links.length,
                  itemBuilder: (context, index) {
                    final link = links[index];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: LinkColors.getColor(link.color),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            LinkIcons.getIcon(link.iconName),
                            color: Theme.of(context).colorScheme.surface,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          link.title,
                          style: TextStyle(
                            decoration:
                                link.isEnabled
                                    ? null
                                    : TextDecoration.lineThrough,
                            color:
                                link.isEnabled
                                    ? null
                                    : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        subtitle: Text(
                          Uri.parse(link.url).host,
                          style: TextStyle(
                            color:
                                link.isEnabled
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant
                                    : Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: link.isEnabled,
                              onChanged:
                                  (value) =>
                                      _toggleLinkEnabled(context, ref, link.id),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            IconButton(
                              onPressed: () => _editLink(context, ref, link),
                              icon: const Icon(Icons.edit),
                              iconSize: 20,
                            ),
                          ],
                        ),
                        onTap: () => _editLink(context, ref, link),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text('エラーが発生しました: $error'),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // 新しいリンクを追加
  Future<void> _addNewLink(BuildContext context, WidgetRef ref) async {
    final authService = ref.read(authServiceProvider);
    final currentUser = authService.currentUser;

    if (currentUser?.email == null) return;

    final userId = currentUser!.email!.split('@').first;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ConvenienceLinkEditScreen(userId: userId),
      ),
    );

    if (result == true) {
      ref.invalidate(currentUserConvenienceLinksProvider);
    }
  }

  // リンクを編集
  Future<void> _editLink(
    BuildContext context,
    WidgetRef ref,
    ConvenienceLink link,
  ) async {
    final authService = ref.read(authServiceProvider);
    final currentUser = authService.currentUser;

    if (currentUser?.email == null) return;

    final userId = currentUser!.email!.split('@').first;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (context) =>
                ConvenienceLinkEditScreen(initialLink: link, userId: userId),
      ),
    );

    if (result == true) {
      ref.invalidate(currentUserConvenienceLinksProvider);
    }
  }

  // リンクの有効/無効を切り替え
  Future<void> _toggleLinkEnabled(
    BuildContext context,
    WidgetRef ref,
    String linkId,
  ) async {
    final authService = ref.read(authServiceProvider);
    final currentUser = authService.currentUser;

    if (currentUser?.uid.isEmpty != false) return;

    final userId = currentUser!.uid;
    final userEmail = currentUser.email;

    try {
      final notifier = ref.read(
        convenienceLinkProvider((
          userId: userId,
          userEmail: userEmail,
        )).notifier,
      );
      await notifier.toggleLinkEnabled(linkId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('設定の変更に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // デフォルトにリセット
  Future<void> _resetToDefaults(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('デフォルトにリセット'),
        content: const Text('すべてのリンクをデフォルトの状態にリセットしますか？\nカスタムリンクは削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('リセット'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authService = ref.read(authServiceProvider);
    final currentUser = authService.currentUser;

    if (currentUser?.uid.isEmpty != false) return;

    final userId = currentUser!.uid;
    final userEmail = currentUser.email;

    try {
      final notifier = ref.read(
        convenienceLinkProvider((
          userId: userId,
          userEmail: userEmail,
        )).notifier,
      );
      await notifier.resetToDefaults();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('デフォルトにリセットしました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('リセットに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
  Future<void> _refreshData(WidgetRef ref) async {
    try {
      // 各プロバイダーを無効化して再取得
      ref.invalidate(currentUserTodayScheduleProvider);
      ref.invalidate(currentUserCurrentPeriodProvider);
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
      return '今週(${mondayMonth}/${mondayDay}-${sundayDay})の学食情報';
    } else {
      return '今週(${mondayMonth}/${mondayDay}-${sundayMonth}/${sundayDay})の学食情報';
    }
  }
}

class _HomeScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final bool isAsset;
  final String title;

  const _HomeScreenImageViewer({
    required this.imageUrl,
    required this.isAsset,
    required this.title,
  });

  @override
  State<_HomeScreenImageViewer> createState() => _HomeScreenImageViewerState();
}

class _HomeScreenImageViewerState extends State<_HomeScreenImageViewer> {
  late final TransformationController _transformationController;
  static const double _zoomedScale = 2.5;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final isCurrentlyZoomed = scale > 1.1;

    if (isCurrentlyZoomed) {
      // 拡大中の場合、元のサイズに戻す
      _transformationController.value = Matrix4.identity();
    } else {
      // 縮小時の場合、タップ位置を中心に拡大
      final screenSize = MediaQuery.of(context).size;
      final screenCenterX = screenSize.width / 2;
      final screenCenterY = screenSize.height / 2;

      // タップ位置をローカル座標から取得
      final tapPosition = details.localPosition;
      
      // 画面中心からのオフセットを計算
      final offsetX = tapPosition.dx - screenCenterX;
      final offsetY = tapPosition.dy - screenCenterY;

      final newScale = _zoomedScale;
      
      // タップ位置が画面中心に来るように変換行列を計算
      final translateX = -offsetX * (newScale - 1) / newScale;
      final translateY = -offsetY * (newScale - 1) / newScale;
      
      // スケールを先に適用してから平行移動を適用するため、Matrix4を直接構築
      final matrix = Matrix4.identity()
        ..scale(newScale)
        ..translate(translateX / newScale, translateY / newScale);
      
      _transformationController.value = matrix;
    }
  }

  Widget _buildFullScreenControls(BuildContext context, String title) {
    return Stack(
      children: [
        // 閉じるボタン
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        // タイトル
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // ピンチアウトのヒント（下部）
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ダブルタップで拡大・縮小、ピンチで拡大・縮小、ドラッグで移動できます',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black87,
      child: Stack(
        children: [
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTapDown: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 5.0,
                child: widget.isAsset
                    ? Image.asset(
                        widget.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.white, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  'バス時刻表の読み込みに失敗しました',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : (kIsWeb
                        ? Image.network(
                            widget.imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/bus_timetable.png',
                                fit: BoxFit.contain,
                              );
                            },
                          )
                        : Image.network(
                            widget.imageUrl,
                            fit: BoxFit.contain,
                            cacheWidth: null,
                            cacheHeight: null,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/bus_timetable.png',
                                fit: BoxFit.contain,
                              );
                            },
                          )),
              ),
            ),
          ),
          _buildFullScreenControls(context, widget.title),
        ],
      ),
    );
  }
}
