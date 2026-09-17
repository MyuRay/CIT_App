import 'dart:async';

import 'package:cit_app/core/providers/cafeteria_favorite_provider.dart';
import 'package:cit_app/core/providers/cafeteria_menu_provider.dart';
import 'package:cit_app/core/providers/cafeteria_popularity_provider.dart';
import 'package:cit_app/core/providers/cafeteria_review_provider.dart';
import 'package:cit_app/core/providers/in_app_ad_provider.dart';
import 'package:cit_app/models/ads/in_app_ad_model.dart';
import 'package:cit_app/models/cafeteria/cafeteria_favorite_target.dart';
import 'package:cit_app/models/cafeteria/cafeteria_menu_item_model.dart';
import 'package:cit_app/models/cafeteria/cafeteria_review_model.dart';
import 'package:cit_app/screens/cafeteria/cafeteria_reviews_screen.dart';
import 'package:cit_app/widgets/cafeteria/cafeteria_favorite_button.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });
  const labels = [
    'おすすめ順（評価が高い順）',
    'おすすめ評価が低い順',
    '人気順（お気に入りが多い順）',
    'お気に入りが少ない順',
    'レビューの多い順',
    '追加日の古い順',
    '追加日の新しい順',
  ];
  const names = ['高評価メニュー', 'お気に入り多数', '未集計メニュー', 'お気に入りゼロ'];
  final menus = [
    for (var i = 0; i < names.length; i++)
      CafeteriaMenuItem(
        id: 'menu-$i',
        cafeteriaId: 'tsudanuma',
        menuName: names[i],
        createdAt: DateTime(2026, 9, 1 + i),
        viewCount: 123456789,
      ),
  ];
  String key(int index) =>
      CafeteriaFavoriteTarget.menu(
        cafeteriaId: 'tsudanuma',
        menuItemId: menus[index].id,
        menuName: names[index],
      ).key;
  final keys = ([for (var i = 0; i < menus.length; i++) key(i)]
    ..sort()).join(',');
  Map<String, int> initialCounts() => {key(0): 2, key(1): 20, key(3): 0};

  Future<void> mount(
    WidgetTester tester, {
    Stream<Map<String, int>> Function()? watch,
    Set<int> withoutReviews = const {},
    int? favoriteCount,
  }) async {
    tester.view.physicalSize = const Size(430, 980);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = DateTime.now();
    final reviews = [
      for (var i = 0; i < names.length; i++)
        if (!withoutReviews.contains(i))
          CafeteriaReview(
            id: 'review-$i',
            cafeteriaId: 'tsudanuma',
            menuName: names[i],
            taste: 4,
            volume: 4,
            recommend: [5, 1, 4, 3][i],
            userId: 'user-$i',
            userName: '利用者',
            createdAt: i == 0 ? now : now.subtract(const Duration(days: 1)),
          ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cafeteriaFavoriteUserIdProvider.overrideWithValue(null),
          if (favoriteCount != null)
            cafeteriaFavoriteCountProvider.overrideWith(
              (ref, target) => Stream.value(favoriteCount),
            ),
          for (final campus in Cafeterias.all)
            cafeteriaReviewsProvider(campus).overrideWith(
              (ref) => Stream.value(campus == 'tsudanuma' ? reviews : []),
            ),
          for (final campus in Cafeterias.all)
            cafeteriaMenuItemsListProvider(campus).overrideWith(
              (ref) => Stream.value(campus == 'tsudanuma' ? menus : []),
            ),
          cafeteriaPopularityProvider(keys).overrideWith(
            (ref) => watch?.call() ?? Stream.value(initialCounts()),
          ),
          inAppAdProvider(
            AdPlacement.cafeteria,
          ).overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          home: CafeteriaReviewsScreen(initialCafeteriaId: 'tsudanuma'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> choose(
    WidgetTester tester,
    String label, {
    bool settle = true,
  }) async {
    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  void expectOrder(WidgetTester tester, List<int> order) {
    final positions = [
      for (final i in order) tester.getTopLeft(find.text(names[i])).dy,
    ];
    for (var i = 1; i < positions.length; i++) {
      expect(positions[i - 1], lessThan(positions[i]));
    }
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'favorite count sits directly below heart without raising the menu card',
    (tester) async {
      await mount(tester, favoriteCount: 123);
      final favorite = find.byWidgetPredicate(
        (widget) =>
            widget is CafeteriaFavoriteButton &&
            widget.target.menuItemId == menus[1].id,
      );
      final heart = find.descendant(
        of: favorite,
        matching: find.byIcon(Icons.favorite_border),
      );
      final count = find.descendant(of: favorite, matching: find.text('123人'));
      final heartRect = tester.getRect(heart);
      final countRect = tester.getRect(count);
      expect(countRect.center.dx, closeTo(heartRect.center.dx, 0.1));
      expect(countRect.top - heartRect.bottom, closeTo(1, 0.1));
      expect(tester.getSize(favorite).height, 48);
      // The 72px menu image plus the existing card padding/margin sets the height.
      final card =
          find.ancestor(of: favorite, matching: find.byType(Card)).first;
      expect(tester.getSize(card).height, lessThanOrEqualTo(100));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'clear labels and recommendation defaults without popularity fetch',
    (tester) async {
      var requests = 0;
      await mount(
        tester,
        watch: () {
          requests++;
          return Stream.value(initialCounts());
        },
      );
      expect(requests, 0);
      expectOrder(tester, [0, 2, 3, 1]);
      expect(find.text('123456789'), findsNothing);
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      for (final label in labels) {
        expect(find.text(label), findsWidgets);
      }
      expect(find.textContaining('昇順'), findsNothing);
      expect(find.textContaining('降順'), findsNothing);
    },
  );

  testWidgets(
    'favorites outrank ratings and today; unknown follows known zero in both directions',
    (tester) async {
      await mount(tester);
      await choose(tester, labels[2]);
      expectOrder(tester, [1, 0, 3, 2]);
      expect(find.text('集計待ちのメニューは最後に表示しています'), findsOneWidget);
      expect(find.text('今日のレビューあり'), findsOneWidget);
      await choose(tester, labels[3]);
      expectOrder(tester, [3, 0, 1, 2]);
    },
  );

  testWidgets('low ratings and old/new dates use the full list', (
    tester,
  ) async {
    await mount(tester);
    await choose(tester, labels[1]);
    expectOrder(tester, [1, 3, 2, 0]);
    await choose(tester, labels[5]);
    expectOrder(tester, [0, 1, 2, 3]);
    await choose(tester, labels[6]);
    expectOrder(tester, [3, 2, 1, 0]);
  });

  testWidgets(
    'unrated menus follow rated menus in both recommendation orders',
    (tester) async {
      await mount(tester, withoutReviews: {2});
      expectOrder(tester, [0, 3, 1, 2]);
      await choose(tester, labels[1]);
      expectOrder(tester, [1, 3, 0, 2]);
    },
  );

  testWidgets(
    'live count changes reorder menus and filtering keeps one subscription',
    (tester) async {
      final counts = StreamController<Map<String, int>>();
      addTearDown(counts.close);
      var requests = 0;
      await mount(
        tester,
        watch: () {
          requests++;
          return counts.stream;
        },
      );
      await choose(tester, labels[2], settle: false);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      counts.add(initialCounts());
      await tester.pumpAndSettle();
      expectOrder(tester, [1, 0, 3, 2]);
      counts.add({...initialCounts(), key(0): 30});
      await tester.pumpAndSettle();
      expectOrder(tester, [0, 1, 3, 2]);
      await tester.enterText(find.byType(TextField).first, '高評価');
      await tester.pumpAndSettle();
      expect(find.text(names[0]), findsOneWidget);
      expect(find.text(names[1]), findsNothing);
      expect(requests, 1);
    },
  );

  testWidgets('failed count load offers retry and retains menus', (
    tester,
  ) async {
    var requests = 0;
    await mount(
      tester,
      watch:
          () =>
              ++requests == 1
                  ? Stream.error(StateError('offline'))
                  : Stream.value(initialCounts()),
    );
    await choose(tester, labels[2]);
    expect(find.text('お気に入り人数を取得できませんでした'), findsOneWidget);
    expect(find.text(names[0]), findsOneWidget);
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expectOrder(tester, [1, 0, 3, 2]);
    expect(requests, 2);
  });
}
