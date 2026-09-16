import 'dart:io';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cit_app/core/providers/bulletin_provider.dart';
import 'package:cit_app/core/providers/comment_provider.dart';
import 'package:cit_app/core/providers/filtered_bulletin_provider.dart';
import 'package:cit_app/core/providers/schedule_provider.dart';
import 'package:cit_app/models/bulletin/bulletin_model.dart';
import 'package:cit_app/models/comment/comment_model.dart';
import 'package:cit_app/screens/bulletin/bulletin_screen.dart';
import 'package:cit_app/screens/main/widgets/main_navigation_bar.dart';
import 'package:cit_app/widgets/bulletin/bulletin_feed_card.dart';
import 'package:cit_app/widgets/bulletin/bulletin_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../support/theme_test_fonts.dart';

const photoUrl = 'https://example.com/bulletin-ui-fixture.png';
BulletinPost fixture(
  String id, {
  BulletinCategory category = BulletinCategories.event,
  bool photo = false,
  bool sponsored = false,
  bool pinned = false,
  bool comments = false,
  String? title,
  String? description,
}) => BulletinPost(
  id: id,
  title:
      title ??
      (photo
          ? '秋のキャンパス交流会を開催します'
          : sponsored
          ? '学生限定・ドリンク100円引き'
          : '新しい仲間と、好きなことを。'),
  description:
      description ??
      (photo
          ? '学年や学科を越えて、気軽に交流できるイベントです。友達と一緒の参加も大歓迎！'
          : sponsored
          ? '授業の合間にほっとひと息。学生証の提示でドリンクがお得になります。'
          : 'サークル見学・体験会の参加者を募集中です。初めての方もお気軽にどうぞ。'),
  imageUrl: photo ? photoUrl : '',
  imageUrls: photo ? const [photoUrl, 'second'] : const [],
  category: category,
  createdAt: DateTime(2026, 9, 16),
  expiresAt: null,
  authorId: 'owner',
  authorName: sponsored ? '津田沼カフェ' : '学生スタッフ',
  isSponsored: sponsored,
  sponsorName: sponsored ? '津田沼カフェ' : '',
  isPinned: pinned,
  viewCount: 128,
  allowComments: comments,
);

class _Feed extends BulletinFeedNotifier {
  _Feed(super.ref, BulletinFeedState initial) {
    state = initial;
  }
  int refreshes = 0;
  int loads = 0;
  @override
  Future<void> refresh() async {
    refreshes++;
    state = const BulletinFeedState(hasMore: false);
  }

  @override
  Future<void> loadMore() async {
    loads++;
    state = state.copyWith(hasMore: false, clearError: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  late ui.Image poster;
  late _Feed feed;
  final boundary = GlobalKey();
  setUpAll(() async {
    themes = await loadTestThemes();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1200, 675),
      Paint()..color = const Color(0xFF164D61),
    );
    canvas.drawCircle(
      const Offset(1060, 50),
      270,
      Paint()..color = const Color(0xFFECBC68),
    );
    canvas.drawCircle(
      const Offset(1120, 650),
      300,
      Paint()..color = const Color(0xFF3F8290),
    );
    final text = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: 'CAMPUS\nMEETUP',
        style: TextStyle(
          color: const Color(0xFFFFF3D9),
          fontFamily:
              themes[Brightness.light]!.textTheme.titleLarge!.fontFamily,
          fontSize: 110,
          fontWeight: FontWeight.w700,
          height: 1.05,
        ),
      ),
    )..layout(maxWidth: 960);
    text.paint(canvas, const Offset(72, 150));
    text.dispose();
    final small = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: 'CHIBA INSTITUTE OF TECHNOLOGY',
        style: TextStyle(
          color: const Color(0xFFBFE0DF),
          fontSize: 26,
          fontFamily:
              themes[Brightness.light]!.textTheme.bodyMedium!.fontFamily,
        ),
      ),
    )..layout(maxWidth: 960);
    small.paint(canvas, const Offset(78, 535));
    small.dispose();
    final picture = recorder.endRecording();
    poster = await picture.toImage(1200, 675);
    picture.dispose();
  });
  tearDownAll(() => poster.dispose());

  Future<void> mount(
    WidgetTester tester, {
    BulletinFeedState? initial,
    Brightness mode = Brightness.light,
    double width = 390,
    double scale = 1,
    bool navigation = false,
    bool settle = true,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    PaintingBinding.instance.imageCache.putIfAbsent(
      const CachedNetworkImageProvider(photoUrl),
      () => OneFrameImageStreamCompleter(
        Future.value(ImageInfo(image: poster.clone())),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(null),
          bulletinFeedProvider.overrideWith(
            (ref) =>
                feed = _Feed(
                  ref,
                  initial ??
                      BulletinFeedState(
                        posts: [
                          fixture(
                            'event',
                            photo: true,
                            pinned: true,
                            comments: true,
                          ),
                          fixture(
                            'sponsor',
                            category: BulletinCategories.coupon,
                            sponsored: true,
                          ),
                          fixture('club', category: BulletinCategories.club),
                        ],
                        hasMore: false,
                      ),
                ),
          ),
          filteredBulletinPostsByCategoryProvider.overrideWith((ref, category) {
            final state = ref.watch(bulletinFeedProvider);
            if (state.isLoading) return const AsyncValue.loading();
            if (state.error != null && state.posts.isEmpty) {
              return AsyncValue.error(state.error!, StackTrace.current);
            }
            return AsyncValue.data(
              state.posts
                  .where(
                    (post) => category == null || category == post.category.id,
                  )
                  .toList(),
            );
          }),
          commentStatsProvider.overrideWith(
            (ref, id) async => CommentStats(
              totalComments: 5,
              directComments: 4,
              repliesCount: 1,
            ),
          ),
        ],
        child: MaterialApp(
          theme: themes[mode],
          debugShowCheckedModeBanner: false,
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(bottom: 48),
                ),
                child: RepaintBoundary(key: boundary, child: child!),
              ),
          home:
              navigation
                  ? Scaffold(
                    body: const BulletinScreen(),
                    bottomNavigationBar: MainNavigationBar(
                      selectedIndex: 3,
                      onDestinationSelected: (_) {},
                    ),
                  )
                  : const BulletinScreen(),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (themePreviewDirectory.isEmpty) return;
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$themePreviewDirectory/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('category selection filters posts and all restores the feed', (
    tester,
  ) async {
    await mount(tester);
    final event = find.byKey(const ValueKey('bulletin-category-event'));
    await tester.tap(event);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(event).selected, isTrue);
    expect(
      tester
          .widgetList<BulletinFeedCard>(find.byType(BulletinFeedCard))
          .every((card) => card.post.category.id == 'event'),
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('bulletin-category-all')));
    await tester.pumpAndSettle();
    expect(find.text('すべての投稿'), findsOneWidget);
    expect(find.byKey(const ValueKey('bulletin-post-sponsor')), findsOneWidget);
  });

  testWidgets(
    'empty category offers all posts and can still load earlier pages',
    (tester) async {
      await mount(
        tester,
        initial: BulletinFeedState(
          posts: [fixture('club', category: BulletinCategories.club)],
          hasMore: true,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('bulletin-category-event')));
      await tester.pumpAndSettle();
      expect(find.text('投稿がまだ見つかりません'), findsOneWidget);
      expect(find.text('すべての投稿を見る'), findsOneWidget);
      await tester.tap(find.text('以前の投稿を読み込む'));
      await tester.pumpAndSettle();
      expect(feed.loads, 1);
      expect(find.text('投稿がありません'), findsOneWidget);
      await tester.tap(find.text('すべての投稿を見る'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('bulletin-post-club')), findsOneWidget);
    },
  );

  testWidgets('empty feed remains pull-to-refresh enabled', (tester) async {
    await mount(tester, initial: const BulletinFeedState(hasMore: false));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(feed.refreshes, 1);
  });

  testWidgets('load failure is understandable and retry refreshes the feed', (
    tester,
  ) async {
    await mount(
      tester,
      initial: BulletinFeedState(
        error: StateError('private diagnostic'),
        hasMore: false,
      ),
    );
    expect(find.text('投稿を読み込めませんでした'), findsOneWidget);
    expect(find.textContaining('private diagnostic'), findsNothing);
    await tester.tap(find.text('再読み込み'));
    await tester.pumpAndSettle();
    expect(feed.refreshes, 1);
  });

  testWidgets('next-page failure keeps posts and offers an explicit retry', (
    tester,
  ) async {
    await mount(
      tester,
      initial: BulletinFeedState(
        posts: [fixture('text')],
        error: StateError('offline'),
        hasMore: true,
      ),
    );
    expect(find.byKey(const ValueKey('bulletin-post-text')), findsOneWidget);
    await tester.tap(find.text('もう一度読み込む'));
    await tester.pumpAndSettle();
    expect(feed.loads, 1);
  });

  testWidgets(
    'image-free posts omit the image area and photo cards retain count and crop',
    (tester) async {
      await mount(tester);
      final textCard = find.byKey(const ValueKey('bulletin-post-sponsor'));
      expect(
        find.descendant(of: textCard, matching: find.byType(BulletinThumbnail)),
        findsNothing,
      );
      expect(find.text('2枚'), findsOneWidget);
      expect(find.text('ピン留め'), findsNothing);
      expect(find.text('ピン留めを優先'), findsNothing);
      expect(find.text('ここまでが現在の投稿です'), findsNothing);
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pump();
        expect(find.bySemanticsLabel(RegExp('ピン留め')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('コメント 5件')), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('live update failure offers retry even after the last page', (
    tester,
  ) async {
    await mount(
      tester,
      initial: BulletinFeedState(
        posts: [fixture('text')],
        error: StateError('offline'),
        hasMore: false,
      ),
    );
    expect(find.byKey(const ValueKey('bulletin-post-text')), findsOneWidget);
    expect(find.text('投稿の更新を確認できませんでした。'), findsOneWidget);
    await tester.ensureVisible(find.text('もう一度読み込む'));
    await tester.tap(find.text('もう一度読み込む'));
    await tester.pumpAndSettle();
    expect(feed.refreshes, 1);
  });

  for (final mode in Brightness.values) {
    testWidgets(
      '${mode.name} empty and error states remain usable at 320px / 200%',
      (tester) async {
        await mount(
          tester,
          initial: const BulletinFeedState(hasMore: false),
          mode: mode,
          width: 320,
          scale: 2,
        );
        expect(tester.takeException(), isNull);
        feed.state = BulletinFeedState(
          hasMore: false,
          error: StateError('offline'),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('再読み込み'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.widgetWithText(FilledButton, '再読み込み')).bottom,
          lessThanOrEqualTo(844 - 48),
        );
      },
    );
    testWidgets('${mode.name} phone feed with navigation and photos', (
      tester,
    ) async {
      await mount(tester, mode: mode, navigation: true);
      expect(tester.takeException(), isNull);
      final first = tester.getRect(
        find.byKey(const ValueKey('bulletin-post-event')),
      );
      final second = tester.getRect(
        find.byKey(const ValueKey('bulletin-post-sponsor')),
      );
      expect(first.width, 173);
      expect(second.width, first.width);
      expect(second.height, lessThan(first.height));
      expect(first.height, lessThan(300));
      expect(second.top, first.top);
      expect(second.left, greaterThan(first.right));
      await capture(tester, 'feed-${mode.name}');
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -480));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, 'feed-scrolled-${mode.name}');
    });
    testWidgets(
      '${mode.name} 320px / 200% fits and reaches the final post above system buttons',
      (tester) async {
        await mount(tester, mode: mode, width: 320, scale: 2, navigation: true);
        expect(tester.takeException(), isNull);
        final first = tester.getRect(
          find.byKey(const ValueKey('bulletin-post-event')),
        );
        final second = tester.getRect(
          find.byKey(const ValueKey('bulletin-post-sponsor')),
        );
        expect(first.top, second.top);
        expect(second.height, lessThan(first.height));
        expect(second.left, greaterThan(first.right));
        await capture(tester, 'feed-large-top-${mode.name}');
        final lastPost = find.byKey(const ValueKey('bulletin-post-club'));
        await tester.scrollUntilVisible(
          lastPost,
          500,
          scrollable:
              find
                  .descendant(
                    of: find.byType(CustomScrollView),
                    matching: find.byType(Scrollable),
                  )
                  .first,
        );
        await tester.pumpAndSettle();
        await Scrollable.ensureVisible(tester.element(lastPost), alignment: 1);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(lastPost).height, lessThan(first.height));
        expect(
          tester.getRect(lastPost).bottom,
          lessThanOrEqualTo(tester.getRect(find.byType(MainNavigationBar)).top),
        );
        await capture(tester, 'feed-large-${mode.name}');
      },
    );
  }

  testWidgets(
    'tablet keeps equal column widths and content-sized heights without overflow',
    (tester) async {
      await mount(tester, width: 800);
      final first = tester.getRect(
        find.byKey(const ValueKey('bulletin-post-event')),
      );
      final second = tester.getRect(
        find.byKey(const ValueKey('bulletin-post-sponsor')),
      );
      expect(first.top, second.top);
      expect(second.left, greaterThan(first.right));
      final last = tester.getRect(
        find.byKey(const ValueKey('bulletin-post-club')),
      );
      expect(last.left, first.left);
      expect(last.width, first.width);
      expect(last.height, lessThan(first.height));
      expect(second.height, lessThan(first.height));
      expect(last.top, greaterThan(first.bottom));
      expect(tester.takeException(), isNull);
      await capture(tester, 'feed-tablet');
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('short cards do not reserve photo or sponsor space '
        'at 320px / text scale $scale', (tester) async {
      await mount(
        tester,
        width: 320,
        scale: scale,
        initial: BulletinFeedState(
          hasMore: false,
          posts: [
            fixture('short', title: 'お知らせ', description: ''),
            fixture(
              'long',
              title: List.filled(5, '学生向けのイベント開催について').join('\n'),
              photo: true,
              sponsored: true,
              pinned: true,
              comments: true,
            ),
          ],
        ),
      );
      final short = find.byKey(const ValueKey('bulletin-post-short'));
      final long = find.byKey(const ValueKey('bulletin-post-long'));
      final shortSize = tester.getSize(short);
      expect(shortSize.width, tester.getSize(long).width);
      expect(shortSize.height, lessThan(tester.getSize(long).height));
      if (scale == 1) expect(shortSize.height, lessThan(180));
      expect(tester.takeException(), isNull);

      // Filtering does not change the remaining card's own content or width.
      feed.state = BulletinFeedState(
        hasMore: false,
        posts: [fixture('short', title: 'お知らせ', description: '')],
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(short), shortSize);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'long titles and embedded blank lines use one line at scale $scale',
      (tester) async {
        final longTitle = List.filled(5, '学生向けのイベント開催について').join('\n\n  ');
        await mount(
          tester,
          width: 320,
          scale: scale,
          initial: BulletinFeedState(
            hasMore: false,
            posts: [
              fixture('short', title: 'お知らせ', description: ''),
              fixture('long', title: longTitle, description: ''),
            ],
          ),
        );
        final short = find.byKey(const ValueKey('bulletin-post-short'));
        final long = find.byKey(const ValueKey('bulletin-post-long'));
        expect(tester.getSize(long).width, tester.getSize(short).width);
        // Fallback fonts can alter one-line metrics slightly when drawing ….
        expect(
          tester.getSize(long).height,
          closeTo(tester.getSize(short).height, 4 * scale),
        );
        final title = find.byKey(const ValueKey('bulletin-title-long'));
        final text = tester.widget<Text>(title);
        expect(text.data, longTitle.replaceAll(RegExp(r'\s+'), ' '));
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: title, matching: find.byType(RichText)),
        );
        expect(paragraph.didExceedMaxLines, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
