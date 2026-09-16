import 'dart:io';
import 'dart:ui' as ui;
import 'package:cit_app/core/providers/cafeteria_favorite_provider.dart';
import 'package:cit_app/core/providers/my_cafeteria_provider.dart';
import 'package:cit_app/models/cafeteria/cafeteria_favorite_model.dart';
import 'package:cit_app/models/cafeteria/cafeteria_favorite_target.dart';
import 'package:cit_app/models/cafeteria/cafeteria_menu_item_model.dart';
import 'package:cit_app/models/cafeteria/cafeteria_review_model.dart';
import 'package:cit_app/screens/cafeteria/cafeteria_my_screen.dart';
import 'package:cit_app/services/cafeteria/cafeteria_favorite_service.dart';
import 'package:cit_app/widgets/cafeteria/cafeteria_favorite_button.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../support/theme_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  setUpAll(() async => themes = await loadTestThemes());
  final boundary = GlobalKey();
  final now = DateTime(2026, 9, 16);
  final favorites = [
    CafeteriaFavorite(
      id: 'curry',
      userId: 'u1',
      type: 'menu',
      cafeteriaId: 'tsudanuma',
      menuItemId: 'curry',
      menuName: '唐揚げカレー',
      createdAt: now,
    ),
    CafeteriaFavorite(
      id: 'ramen',
      userId: 'u1',
      type: 'menu',
      cafeteriaId: 'narashino_1f',
      menuName: '醤油ラーメン',
      createdAt: now,
    ),
  ];
  final reviews = [
    CafeteriaReview(
      id: 'review',
      cafeteriaId: 'tsudanuma',
      menuName: '唐揚げカレー',
      userId: 'u1',
      userName: '自分',
      taste: 5,
      volume: 4,
      recommend: 5,
      comment: '唐揚げがサクサクで、午後の授業も頑張れそう。',
      createdAt: now,
    ),
  ];

  Future<void> mount(
    WidgetTester tester, {
    Brightness mode = Brightness.light,
    double width = 390,
    double scale = 1,
    List<CafeteriaFavorite>? saved,
    bool loggedIn = true,
    bool failure = false,
    int? count = 12,
    FakeFirebaseFirestore? database,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cafeteriaFavoriteUserIdProvider.overrideWithValue(
            loggedIn ? 'u1' : null,
          ),
          cafeteriaFavoriteServiceProvider.overrideWithValue(
            CafeteriaFavoriteService(database ?? FakeFirebaseFirestore()),
          ),
          if (database == null)
            userCafeteriaFavoritesProvider.overrideWith(
              (ref) =>
                  failure
                      ? Stream.error(StateError('offline'))
                      : Stream.value(saved ?? favorites),
            ),
          myCafeteriaReviewsProvider.overrideWith(
            (ref) => Stream.value(reviews),
          ),
          cafeteriaFavoriteCountProvider.overrideWith(
            (ref, target) => Stream.value(count),
          ),
          favoriteMenuItemProvider.overrideWith(
            (ref, id) => Stream.value(
              CafeteriaMenuItem(
                id: id,
                cafeteriaId: 'tsudanuma',
                menuName: '唐揚げカレー',
                price: 450,
                createdAt: now,
              ),
            ),
          ),
        ],
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themes[mode],
            builder:
                (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    padding: const EdgeInsets.only(bottom: 48),
                  ),
                  child: child!,
                ),
            home: const MyCafeteriaScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (themePreviewDirectory.isEmpty) return;
    await tester.runAsync(() async {
      final picture =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      await Directory(themePreviewDirectory).create(recursive: true);
      await File(
        '$themePreviewDirectory/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  }

  for (final mode in Brightness.values) {
    testWidgets('${mode.name} My食堂 favorites and reviews preview', (
      tester,
    ) async {
      await mount(tester, mode: mode);
      expect(find.text('12人'), findsWidgets);
      expect(find.byTooltip('お気に入りを解除'), findsWidgets);
      await capture(tester, 'favorites-${mode.name}');
      await tester.tap(find.text('自分のレビュー'));
      await tester.pumpAndSettle();
      expect(find.text('レビューを編集'), findsOneWidget);
      await capture(tester, 'reviews-${mode.name}');
      expect(tester.takeException(), isNull);
    });
    testWidgets('${mode.name} My食堂 at 320px and 200% stays scrollable', (
      tester,
    ) async {
      await mount(tester, mode: mode, width: 320, scale: 2);
      await tester.ensureVisible(find.byType(CafeteriaFavoriteButton).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('自分のレビュー'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('自分のレビュー'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('レビューを編集'));
      await tester.pumpAndSettle();
      expect(find.text('レビューを編集').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('campus and search filters can be cleared', (tester) async {
    await mount(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, '津田沼'));
    await tester.pumpAndSettle();
    expect(find.text('唐揚げカレー'), findsOneWidget);
    expect(find.text('醤油ラーメン'), findsNothing);
    await tester.enterText(find.byType(TextField), '見つからない');
    await tester.pumpAndSettle();
    expect(find.text('条件に合うメニューがありません'), findsOneWidget);
    await tester.tap(find.text('条件をリセット'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(find.text('唐揚げカレー'), findsOneWidget);
  });
  testWidgets('missing counts are not displayed as zero', (tester) async {
    await mount(tester, count: null);
    expect(find.text('集計待ち'), findsWidgets);
    expect(find.text('0人'), findsNothing);
  });
  testWidgets('removing a favorite updates My食堂 and keeps other menus', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final service = CafeteriaFavoriteService(db);
    for (final favorite in favorites) {
      await service.setFavorite(
        userId: 'u1',
        target: CafeteriaFavoriteTarget.fromFavorite(favorite),
        enabled: true,
      );
    }
    await mount(tester, database: db);
    await tester.tap(
      find.descendant(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is CafeteriaFavoriteButton &&
              widget.target.menuItemId == 'curry',
        ),
        matching: find.byTooltip('お気に入りを解除'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('唐揚げカレー'), findsNothing);
    expect(find.text('醤油ラーメン'), findsOneWidget);
    expect(find.text('お気に入りを解除しました'), findsOneWidget);
    final remaining = await service.streamFavorites('u1').first;
    expect(remaining.single.menuName, '醤油ラーメン');
    expect(tester.takeException(), isNull);
  });
  testWidgets('empty, offline and signed-out states explain the next action', (
    tester,
  ) async {
    await mount(tester, saved: []);
    expect(find.text('お気に入りはありません'), findsOneWidget);
    await mount(tester, failure: true);
    expect(find.text('読み込めませんでした'), findsOneWidget);
    expect(find.text('再読み込み'), findsOneWidget);
    await mount(tester, loggedIn: false);
    expect(find.text('ログインすると、お気に入りや自分のレビューを確認できます。'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
