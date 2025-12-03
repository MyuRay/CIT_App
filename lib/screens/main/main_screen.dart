import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../home/home_screen.dart';
import '../schedule/schedule_screen.dart';
import '../bulletin/bulletin_post_form_screen.dart';
import '../bulletin/bulletin_post_detail_screen.dart';
import '../bulletin/bulletin_screen.dart';
import '../../widgets/common/animated_image_placeholder.dart';
import '../profile/profile_screen.dart';
import '../profile/debug_profile_screen.dart';
import '../profile/minimal_profile_screen.dart';
import '../profile/simple_profile_screen.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/bulletin_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/providers/comment_provider.dart';
import '../../services/bulletin/bulletin_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../models/admin/admin_model.dart';
import '../admin/admin_management_screen.dart';

// モック画像の背景パターンを描画するCustomPainter
class MockImagePainter extends CustomPainter {
  final Color color;

  MockImagePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    // 格子パターンを描画
    const gridSize = 30.0;

    // 縦線
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // 横線
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  // 安全なcurrentIndexゲッター
  int get safeCurrentIndex =>
      (_currentIndex > 3 || _currentIndex < 0) ? 0 : _currentIndex;

  @override
  void initState() {
    super.initState();
    // 強制的に0にリセット（シラバス削除後の対応）
    _currentIndex = 0;

    // 次のフレームでも確実にリセット
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _currentIndex > 3) {
        setState(() {
          _currentIndex = 0;
        });
      }
    });
  }

  void _navigateToSchedule() {
    setState(() {
      _currentIndex = 1; // 時間割タブのインデックス
    });
  }

  List<Widget> get _screens {
    print('🔧 _screens getter呼び出し');
    return [
      HomeScreen(onNavigateToSchedule: _navigateToSchedule),
      const ScheduleScreen(),
      const BulletinScreen(),
      const SimpleProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    print('🔧 MainScreen build - 現在のタブ: $_currentIndex');

    // 認証状態を確認
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // ユーザーが未認証の場合は空のコンテナ（ルーターがリダイレクトを処理）
          return const Scaffold(body: Center(child: Text('リダイレクト中...')));
        }
        return _buildMainContent();
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
                  const Icon(Icons.error, size: 64, color: Colors.red),
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
    final screens = _screens;
    print('🔧 screens配列取得完了 - 長さ: ${screens.length}');

    // 掲示板の最新投稿日と最終既読時刻からバッジ表示を判定
    final prefs = ref.watch(sharedPreferencesProvider);
    final lastSeenMs = prefs.getInt('bulletin_last_seen_at') ?? 0;
    final latestPostsAsync = ref.watch(bulletinPostsProvider);
    int latestMs = 0;
    latestPostsAsync.when(
      data: (posts) {
        if (posts.isNotEmpty) {
          latestMs = posts
              .map((p) => p.createdAt.millisecondsSinceEpoch)
              .reduce((a, b) => a > b ? a : b);
        }
      },
      loading: () {},
      error: (_, __) {},
    );
    final hasNewBulletin = latestMs > lastSeenMs;

    Widget currentScreen;
    switch (safeCurrentIndex) {
      case 0:
        currentScreen = HomeScreen(onNavigateToSchedule: _navigateToSchedule);
        break;
      case 1:
        currentScreen = const ScheduleScreen();
        break;
      case 2:
        currentScreen = const BulletinScreen();
        break;
      case 3:
        print('🔧 SimpleProfileScreenを直接表示します');
        currentScreen = const SimpleProfileScreen();
        break;
      default:
        // インデックスが範囲外の場合はホームに戻す
        _currentIndex = 0;
        currentScreen = HomeScreen(onNavigateToSchedule: _navigateToSchedule);
    }

    print('🔧 現在のスクリーン: ${currentScreen.runtimeType}');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        // ホーム画面以外の場合はホームに戻る
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
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
        body: currentScreen,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: safeCurrentIndex,
          onTap: (index) {
            print('🔧 タブ ${index} がタップされました');
            // インデックス範囲チェック（0-3の4つのタブ）
            if (index >= 0 && index <= 3) {
              setState(() {
                _currentIndex = index;
              });
              print('🔧 _currentIndex を ${index} に設定しました');
              // 掲示板タブを開いたら既読時刻を更新
              if (index == 2) {
                prefs.setInt(
                  'bulletin_last_seen_at',
                  DateTime.now().millisecondsSinceEpoch,
                );
              }
            } else {
              print('🔧 無効なインデックス: ${index}, ホームに戻します');
              setState(() {
                _currentIndex = 0;
              });
            }
          },
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
            const BottomNavigationBarItem(
              icon: Icon(Icons.schedule),
              label: '時間割',
            ),
            BottomNavigationBarItem(
              icon: _bulletinIcon(hasNewBulletin),
              activeIcon: _bulletinIcon(hasNewBulletin),
              label: '掲示板',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'マイページ',
            ),
          ],
        ),
      ),
    );
  }

  static Widget _bulletinIcon(bool hasNew) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.campaign),
        if (hasNew)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
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
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知')),
      body: const Center(child: Text('通知機能は開発中です')),
    );
  }
}

class BulletinScreen extends ConsumerStatefulWidget {
  const BulletinScreen({super.key});

  @override
  ConsumerState<BulletinScreen> createState() => _BulletinScreenState();
}

class _BulletinScreenState extends ConsumerState<BulletinScreen> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('掲示板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPostDialog(context),
            tooltip: '投稿する',
          ),
        ],
      ),
      body: Column(
        children: [
          // カテゴリフィルター
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chipWidth = (constraints.maxWidth - 16) / 3; // 3列表示
                return Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children:
                      BulletinCategories.all
                          .map(
                            (category) => SizedBox(
                              width: chipWidth,
                              child: _buildCategoryChip(
                                category.id,
                                category.name,
                                _getCategoryIcon(category.icon),
                              ),
                            ),
                          )
                          .toList(),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // 投稿一覧
          Expanded(child: _buildAllPostsTab()),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String categoryId, String label, IconData icon) {
    final isSelected = _selectedCategoryId == categoryId;

    return SizedBox(
      width: double.infinity,
      child: FilterChip(
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategoryId = isSelected ? null : categoryId;
          });
        },
        avatar: Icon(
          icon,
          size: 14,
          color: isSelected ? Colors.white : Colors.grey[600],
        ),
        label: SizedBox(
          width: double.infinity,
          child: Text(label, textAlign: TextAlign.center),
        ),
        selectedColor: Theme.of(context).colorScheme.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildAllPostsTab() {
    final postsAsync = ref.watch(
      bulletinPostsByCategoryProvider(_selectedCategoryId),
    );

    return postsAsync.when(
      data: (posts) => _buildPostsList(posts),
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'エラーが発生しました',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$error',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(bulletinPostsProvider);
                      ref.invalidate(bulletinPostsByCategoryProvider);
                    },
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildPinnedPostsTab() {
    final postsAsync = ref.watch(pinnedBulletinPostsProvider);

    return postsAsync.when(
      data: (posts) => _buildPostsList(posts),
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'エラーが発生しました',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$error',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(bulletinPostsProvider);
                      ref.invalidate(bulletinPostsByCategoryProvider);
                    },
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildPostsList(List<BulletinPost> posts) {
    if (posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.announcement, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('投稿がありません', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text(
              'まだ掲示板への投稿がありません。\n右上の+ボタンから投稿してください。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(bulletinPostsProvider);
        ref.invalidate(bulletinPostsByCategoryProvider);
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          // 少し横長にしてカードの高さを抑える
          childAspectRatio: 0.82,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  Widget _buildPostCard(BulletinPost post) {
    final categoryColor = Color(
      int.parse('0xff${post.category.color.substring(1)}'),
    );
    final canManagePosts = ref.watch(canManagePostsProvider);

    return Card(
      child: InkWell(
        onTap: () => _showPostDetail(post),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像部分（常に表示）
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: AspectRatio(
                // 画像部分もやや横長にして縦寸を抑制
                aspectRatio: 16 / 8.5,
                child:
                    post.imageUrl.isNotEmpty
                        ? (kIsWeb
                            ? Image.network(
                              post.imageUrl,
                              fit: BoxFit.cover,
                              alignment: Alignment(
                                post.thumbAlignX,
                                post.thumbAlignY,
                              ),
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return const AnimatedImagePlaceholder(
                                  borderRadius: 0,
                                  borderColor: Colors.transparent,
                                );
                              },
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      _buildMockImage(post.category),
                            )
                            : CachedNetworkImage(
                              imageUrl: post.imageUrl,
                              fit: BoxFit.cover,
                              alignment: Alignment(
                                post.thumbAlignX,
                                post.thumbAlignY,
                              ),
                              placeholder:
                                  (context, url) =>
                                      const AnimatedImagePlaceholder(
                                        borderRadius: 0,
                                        borderColor: Colors.transparent,
                                      ),
                              errorWidget:
                                  (context, url, error) =>
                                      _buildMockImage(post.category),
                            ))
                        : _buildMockImage(post.category),
              ),
            ),

            Padding(
              // 縦方向の余白を少しだけ縮小
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー行
                  Row(
                    children: [
                      // ピン留めのテキストラベルは非表示（右側のピンアイコンのみ表示）
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: categoryColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(post.category.icon),
                                size: 14,
                                color: categoryColor,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  post.category.name,
                                  style: TextStyle(
                                    color: categoryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (post.isPinned) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.push_pin,
                          size: 14,
                          color: Colors.orange[700],
                        ),
                      ],
                      // カード部分では三点リーダーメニューを表示しない
                      // if (canManagePosts) ...[
                      //   const SizedBox(width: 4),
                      //   PopupMenuButton<String>(
                      //     icon: Icon(
                      //       Icons.more_vert,
                      //       size: 16,
                      //       color: Colors.grey[600],
                      //     ),
                      //     onSelected: (value) {
                      //       if (value == 'edit') {
                      //         _showPostEditDialog(post);
                      //       } else if (value == 'delete') {
                      //         _showDeleteConfirmDialog(post);
                      //       }
                      //     },
                      //     itemBuilder: (context) => [
                      //       const PopupMenuItem(
                      //         value: 'edit',
                      //         child: Row(
                      //           children: [
                      //             Icon(Icons.edit, size: 16),
                      //             SizedBox(width: 8),
                      //             Text('編集'),
                      //           ],
                      //         ),
                      //       ),
                      //       const PopupMenuItem(
                      //         value: 'delete',
                      //         child: Row(
                      //           children: [
                      //             Icon(Icons.delete, size: 16, color: Colors.red),
                      //             SizedBox(width: 8),
                      //             Text('削除', style: TextStyle(color: Colors.red)),
                      //           ],
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // タイトル
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // フッター
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              post.authorName,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${post.viewCount}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (post.allowComments) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.comment,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 2),
                                Consumer(
                                  builder: (context, ref, child) {
                                    final commentStats = ref.watch(
                                      commentStatsProvider(post.id),
                                    );
                                    return commentStats.when(
                                      data:
                                          (stats) => Text(
                                            '${stats.totalComments}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      loading:
                                          () => Text(
                                            '0',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      error:
                                          (_, __) => Text(
                                            '0',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                          Flexible(
                            child: Text(
                              _formatDate(post.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // カテゴリに応じたモック画像を生成
  Widget _buildMockImage(BulletinCategory category) {
    IconData iconData;
    Color backgroundColor;
    Color iconColor;
    String categoryText;

    switch (category.id) {
      case 'event':
        iconData = Icons.event;
        backgroundColor = const Color(0xFF2196F3).withOpacity(0.1);
        iconColor = const Color(0xFF2196F3);
        categoryText = 'イベント';
        break;
      case 'club':
        iconData = Icons.group;
        backgroundColor = const Color(0xFFFF9800).withOpacity(0.1);
        iconColor = const Color(0xFFFF9800);
        categoryText = 'サークル・部活';
        break;
      case 'announcement':
        iconData = Icons.announcement;
        backgroundColor = const Color(0xFFF44336).withOpacity(0.1);
        iconColor = const Color(0xFFF44336);
        categoryText = 'お知らせ';
        break;
      case 'job':
        iconData = Icons.work;
        backgroundColor = const Color(0xFF9C27B0).withOpacity(0.1);
        iconColor = const Color(0xFF9C27B0);
        categoryText = '求人・就職';
        break;
      case 'coupon':
        iconData = Icons.local_offer;
        backgroundColor = const Color(0xFFE91E63).withOpacity(0.1);
        iconColor = const Color(0xFFE91E63);
        categoryText = 'クーポン';
        break;
      default:
        iconData = Icons.article;
        backgroundColor = const Color(0xFF607D8B).withOpacity(0.1);
        iconColor = const Color(0xFF607D8B);
        categoryText = 'その他';
        break;
    }

    return Container(
      width: double.infinity,
      color: backgroundColor,
      child: Stack(
        children: [
          // 背景パターン
          Positioned.fill(
            child: CustomPaint(
              painter: MockImagePainter(iconColor.withOpacity(0.05)),
            ),
          ),
          // メインコンテンツ
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(iconData, size: 48, color: iconColor.withOpacity(0.8)),
                const SizedBox(height: 8),
                Text(
                  categoryText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _useCoupon(BulletinPost post) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ログインが必要です')));
      return;
    }

    // 既に使用済みかチェック
    if (post.couponUsedBy?.containsKey(currentUser.uid) == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('このクーポンは既に使用済みです')));
      return;
    }

    // 使用回数上限チェック
    if (post.couponMaxUses != null &&
        post.couponUsedCount >= post.couponMaxUses!) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('クーポンの使用回数上限に達しています')));
      return;
    }

    // クーポン使用確認ダイアログ
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('クーポン使用確認'),
            content: Text('「${post.title}」のクーポンを使用しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('使用する'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // クーポン使用処理をサービスに委任
        await BulletinService.useCoupon(post.id, currentUser.uid);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('クーポンを使用しました'),
            backgroundColor: Colors.green,
          ),
        );

        // プロバイダーを更新
        ref.invalidate(bulletinPostsProvider);
        ref.invalidate(bulletinPostsByCategoryProvider);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('クーポン使用に失敗しました: $e')));
      }
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'event':
        return Icons.event;
      case 'group':
        return Icons.group;
      case 'school':
        return Icons.school;
      case 'announcement':
        return Icons.announcement;
      case 'work':
        return Icons.work;
      case 'more_horiz':
        return Icons.more_horiz;
      case 'local_offer':
        return Icons.local_offer;
      default:
        return Icons.circle;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  void _showPostDetail(BulletinPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BulletinPostDetailScreen(post: post),
      ),
    );
  }

  void _showAddPostDialog(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const BulletinPostFormScreen()),
    );

    // 投稿が成功した場合、掲示板データを更新
    if (result == true) {
      ref.invalidate(bulletinPostsProvider);
      ref.invalidate(pinnedBulletinPostsProvider);
      ref.invalidate(popularBulletinPostsProvider);
      // 全てのカテゴリフィルターも無効化
      ref.invalidate(bulletinPostsByCategoryProvider);
    }
  }

  void _showPostEditDialog(BulletinPost post) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => BulletinPostEditScreen(post: post),
          ),
        )
        .then((result) {
          if (result == true) {
            // 投稿が更新された場合、掲示板データを更新
            ref.invalidate(bulletinPostsProvider);
            ref.invalidate(pinnedBulletinPostsProvider);
            ref.invalidate(popularBulletinPostsProvider);
            ref.invalidate(bulletinPostsByCategoryProvider);
          }
        });
  }

  void _showDeleteConfirmDialog(BulletinPost post) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('投稿を削除'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('この投稿を削除しますか？この操作は元に戻せません。'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '投稿者: ${post.authorName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
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
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _deletePost(post);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('削除'),
              ),
            ],
          ),
    );
  }

  Future<void> _deletePost(BulletinPost post) async {
    try {
      // Firestoreから投稿を削除
      await FirebaseFirestore.instance
          .collection('bulletin_posts')
          .doc(post.id)
          .delete();

      // 画像がある場合は削除
      if (post.imageUrl.isNotEmpty) {
        try {
          final imageRef = FirebaseStorage.instance.refFromURL(post.imageUrl);
          await imageRef.delete();
        } catch (e) {
          print('画像削除エラー（続行）: $e');
        }
      }

      // データを更新
      ref.invalidate(bulletinPostsProvider);
      ref.invalidate(pinnedBulletinPostsProvider);
      ref.invalidate(popularBulletinPostsProvider);
      ref.invalidate(bulletinPostsByCategoryProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('投稿を削除しました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      final isAdmin = ref.watch(isAdminProvider);
      final canViewContacts = ref.watch(canViewContactsProvider);

      return Scaffold(
        appBar: AppBar(title: const Text('マイページ')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ユーザー情報',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('メールアドレス: ${user?.email ?? 'デバッグモード'}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // お問い合わせボタン
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.contact_support,
                    color: Colors.blue,
                  ),
                  title: const Text('お問い合わせ'),
                  subtitle: const Text('アプリに関するご質問・ご要望'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showContactForm(context),
                ),
              ),
              const SizedBox(height: 16),

              // 管理者専用セクション
              if (isAdmin) ...[
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '管理者メニュー',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // お問い合わせ一覧
                        if (canViewContacts)
                          ListTile(
                            leading: const Icon(
                              Icons.contact_support,
                              color: Colors.blue,
                            ),
                            title: const Text('お問い合わせ一覧'),
                            subtitle: const Text('ユーザーからのお問い合わせを管理'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showContactList(context),
                          ),

                        // 管理者権限管理（最高管理者のみ）
                        ListTile(
                          leading: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.red,
                          ),
                          title: const Text('管理者権限管理'),
                          subtitle: const Text('新しい管理者の追加・削除'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showAdminManagement(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (user != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await authService.signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('ログアウト'),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'デバッグモード',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Firebase設定完了後に認証機能が利用できます',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Scaffold(
        appBar: AppBar(title: const Text('マイページ')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text('デバッグモード', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Firebase設定完了後に認証機能が利用できます'),
            ],
          ),
        ),
      );
    }
  }

  void _showContactForm(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ContactFormScreen()));
  }

  void _showContactList(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ContactListScreen()));
  }

  void _showAdminManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AdminManagementScreen()),
    );
  }
}

class ContactFormScreen extends ConsumerStatefulWidget {
  const ContactFormScreen({super.key});

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedCategory = 'general';
  bool _isLoading = false;

  final Map<String, String> _categories = {
    'general': '一般的な質問',
    'bug': 'バグ報告',
    'feature': '機能リクエスト',
    'schedule': '時間割に関して',
    'bulletin': '掲示板に関して',
    'other': 'その他',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('お問い合わせ')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // カテゴリ選択
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'お問い合わせ種別',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items:
                          _categories.entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // お名前
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'お名前',
                hintText: '氏名またはニックネーム',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'お名前を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // メールアドレス
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                hintText: 'your.email@example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
                helperText: '返信先として使用されます',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'メールアドレスを入力してください';
                }
                if (!RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                ).hasMatch(value.trim())) {
                  return '正しいメールアドレスを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 件名
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: '件名',
                hintText: 'お問い合わせの概要',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.subject),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '件名を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // メッセージ
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'お問い合わせ内容',
                hintText: '詳細な内容をご記入ください',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              maxLength: 1000,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'お問い合わせ内容を入力してください';
                }
                if (value.trim().length < 10) {
                  return '10文字以上で入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // 注意事項
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'お問い合わせについて',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• 通常、2〜3営業日以内にご返信いたします\n'
                      '• 緊急の問題の場合は、件名に【緊急】と記載してください\n'
                      '• 個人情報の取り扱いには十分注意してください\n'
                      '• バグ報告の際は、発生した手順も詳しく記載してください',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 送信ボタン
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitContactForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          '送信',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitContactForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🚀 お問い合わせ送信処理開始...');

      // お問い合わせデータを作成
      final contactData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'category': _selectedCategory,
        'categoryName': _categories[_selectedCategory],
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'createdAt': Timestamp.now(),
        'status': 'pending', // pending, in_progress, resolved
        'userId': 'current_user', // TODO: 実際のユーザーIDを使用
      };

      print('📝 Firestoreにお問い合わせを保存中...');
      print('データ: ${contactData.toString()}');

      // Firebase Firestoreに保存
      await FirebaseFirestore.instance
          .collection('contact_forms')
          .add(contactData);

      print('✅ お問い合わせ保存完了');

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('お問い合わせを送信しました。ご返信まで少々お待ちください。'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ お問い合わせ送信エラー: $e');
      print('スタックトレース: $stackTrace');

      String errorMessage = 'お問い合わせの送信に失敗しました';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'アクセス権限が不足しています';
      } else if (e.toString().contains('network')) {
        errorMessage = 'ネットワークエラーが発生しました。接続を確認してください。';
      } else if (e.toString().contains('unavailable')) {
        errorMessage = 'サーバーに接続できません。';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage\n\n詳細: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '再試行',
              textColor: Colors.white,
              onPressed: () => _submitContactForm(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// お問い合わせ一覧画面（管理者専用）
class ContactListScreen extends ConsumerWidget {
  const ContactListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactFormsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('お問い合わせ一覧'),
        backgroundColor: Colors.orange.shade50,
      ),
      body: contactsAsync.when(
        data: (contacts) => _buildContactsList(context, ref, contacts),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('エラーが発生しました: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(contactFormsProvider),
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildContactsList(
    BuildContext context,
    WidgetRef ref,
    List<ContactForm> contacts,
  ) {
    if (contacts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contact_support, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('お問い合わせはありません'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(contactFormsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return _buildContactCard(context, contact);
        },
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, ContactForm contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showContactDetail(context, contact),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー行
              Row(
                children: [
                  Text(
                    contact.categoryIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      contact.subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: contact.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: contact.statusColor),
                    ),
                    child: Text(
                      contact.statusDisplayName,
                      style: TextStyle(
                        color: contact.statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // カテゴリと送信者
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      contact.categoryName,
                      style: const TextStyle(color: Colors.blue, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    contact.name ?? '匿名',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(contact.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // メッセージプレビュー
              Text(
                contact.message,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactDetail(BuildContext context, ContactForm contact) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContactDetailScreen(contact: contact),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

// お問い合わせ詳細画面
class ContactDetailScreen extends ConsumerStatefulWidget {
  final ContactForm contact;

  const ContactDetailScreen({super.key, required this.contact});

  @override
  ConsumerState<ContactDetailScreen> createState() =>
      _ContactDetailScreenState();
}

class _ContactDetailScreenState extends ConsumerState<ContactDetailScreen> {
  final _responseController = TextEditingController();
  String _selectedStatus = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.contact.status;
    if (widget.contact.response != null) {
      _responseController.text = widget.contact.response!;
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お問い合わせ詳細'),
        backgroundColor: Colors.orange.shade50,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'update_status') {
                await _showStatusDialog();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'update_status',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('ステータス変更'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ステータスカード
            Card(
              color: widget.contact.statusColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: widget.contact.statusColor),
                    const SizedBox(width: 8),
                    Text(
                      'ステータス: ${widget.contact.statusDisplayName}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.contact.statusColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.contact.categoryIcon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 基本情報
            _buildInfoCard('基本情報', [
              _buildInfoRow('件名', widget.contact.subject),
              _buildInfoRow('カテゴリ', widget.contact.categoryName),
              _buildInfoRow('送信者', widget.contact.name ?? '匿名'),
              _buildInfoRow('メールアドレス', widget.contact.email ?? '未入力'),
              _buildInfoRow(
                '送信日時',
                '${widget.contact.createdAt.year}/${widget.contact.createdAt.month.toString().padLeft(2, '0')}/${widget.contact.createdAt.day.toString().padLeft(2, '0')} ${widget.contact.createdAt.hour.toString().padLeft(2, '0')}:${widget.contact.createdAt.minute.toString().padLeft(2, '0')}',
              ),
            ]),
            const SizedBox(height: 16),

            // お問い合わせ内容
            _buildInfoCard('お問い合わせ内容', [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.contact.message,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // 返信フォーム
            _buildResponseCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildResponseCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '管理者返信',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (widget.contact.response != null) ...[
              Text(
                '返信日時: ${widget.contact.respondedAt != null ? "${widget.contact.respondedAt!.year}/${widget.contact.respondedAt!.month.toString().padLeft(2, '0')}/${widget.contact.respondedAt!.day.toString().padLeft(2, '0')} ${widget.contact.respondedAt!.hour.toString().padLeft(2, '0')}:${widget.contact.respondedAt!.minute.toString().padLeft(2, '0')}" : "未設定"}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
            ],

            TextFormField(
              controller: _responseController,
              decoration: const InputDecoration(
                labelText: '返信内容',
                hintText: '返信メッセージを入力してください',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              maxLength: 1000,
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitResponse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text('返信して解決済みにする'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStatusDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ステータス変更'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile(
                  title: const Text('未対応'),
                  value: 'pending',
                  groupValue: _selectedStatus,
                  onChanged:
                      (value) => setState(() => _selectedStatus = value!),
                ),
                RadioListTile(
                  title: const Text('対応中'),
                  value: 'in_progress',
                  groupValue: _selectedStatus,
                  onChanged:
                      (value) => setState(() => _selectedStatus = value!),
                ),
                RadioListTile(
                  title: const Text('解決済み'),
                  value: 'resolved',
                  groupValue: _selectedStatus,
                  onChanged:
                      (value) => setState(() => _selectedStatus = value!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_selectedStatus),
                child: const Text('更新'),
              ),
            ],
          ),
    );

    if (result != null && result != widget.contact.status) {
      await _updateStatus(result);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);

    try {
      await ContactFormService.updateStatus(widget.contact.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ステータスを更新しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ステータス更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitResponse() async {
    if (_responseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('返信内容を入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ContactFormService.addResponse(
        widget.contact.id,
        _responseController.text.trim(),
        'current_admin', // TODO: 実際の管理者IDを使用
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('返信を送信し、解決済みにしました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('返信送信に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
