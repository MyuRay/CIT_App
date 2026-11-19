import 'dart:async';
import 'package:cit_app/core/providers/cafeteria_favorite_provider.dart';
import 'package:cit_app/core/providers/cafeteria_menu_provider.dart';
import 'package:cit_app/core/providers/cafeteria_review_provider.dart';
import 'package:cit_app/core/providers/in_app_ad_provider.dart';
import 'package:cit_app/models/ads/in_app_ad_model.dart';
import 'package:cit_app/models/cafeteria/cafeteria_menu_item_model.dart';
import 'package:cit_app/models/cafeteria/cafeteria_review_model.dart';
import 'package:cit_app/screens/cafeteria/cafeteria_reviews_screen.dart';
import 'package:cit_app/services/cafeteria/cafeteria_review_day.dart';
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
  final noon = DateTime.utc(2026, 11, 13, 3);
  CafeteriaReview review(
    String name,
    String campus,
    DateTime at, {
    int rating = 5,
  }) => CafeteriaReview(
    id: name,
    cafeteriaId: campus,
    menuName: name,
    taste: rating,
    volume: rating,
    recommend: rating,
    userId: 'reviewer',
    userName: '利用者',
    createdAt: at,
  );
  Future<void> mount(
    WidgetTester tester, {
    String campus = Cafeterias.tsudanuma,
    List<CafeteriaReview> reviews = const [],
    Stream<List<CafeteriaReview>>? updates,
    DateTime Function()? clock,
    List<String> menuNames = const [],
  }) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cafeteriaFavoriteUserIdProvider.overrideWithValue(null),
          cafeteriaReviewNowProvider.overrideWithValue(clock ?? () => noon),
          for (final id in Cafeterias.all)
            cafeteriaReviewsProvider(id).overrideWith(
              (ref) =>
                  id == campus
                      ? updates ?? Stream.value(reviews)
                      : Stream.value([]),
            ),
          for (final id in Cafeterias.all)
            cafeteriaMenuItemsListProvider(id).overrideWith(
              (ref) => Stream.value([
                if (id == campus)
                  for (final name in menuNames)
                    CafeteriaMenuItem(
                      id: name,
                      cafeteriaId: campus,
                      menuName: name,
                      createdAt: noon,
                    ),
              ]),
            ),
          inAppAdProvider(
            AdPlacement.cafeteria,
          ).overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          home: CafeteriaReviewsScreen(initialCafeteriaId: campus),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test(
    'review days use Japan midnight with an exclusive next-day boundary',
    () {
      final before = cafeteriaReviewDayBounds(
        DateTime.parse('2026-11-13T14:59:59Z'),
      );
      expect(before.start, DateTime.utc(2026, 11, 12, 15));
      expect(before.end, DateTime.utc(2026, 11, 13, 15));
      final after = cafeteriaReviewDayBounds(
        DateTime.parse('2026-11-13T15:00:00Z'),
      );
      expect(after.start, before.end);
      expect(after.end, DateTime.utc(2026, 11, 14, 15));
    },
  );
  for (final campus in Cafeterias.all) {
    testWidgets(
      'today is first even with a lower rating in $campus, without duplicate cards',
      (tester) async {
        await mount(
          tester,
          campus: campus,
          reviews: [
            review('定番カレー', campus, noon.subtract(const Duration(days: 1))),
            review('本日のランチ', campus, noon, rating: 1),
          ],
        );
        expect(find.text('本日レビューされたメニュー (1件)'), findsOneWidget);
        expect(find.text('本日のランチ'), findsOneWidget);
        expect(find.text('定番カレー'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('本日のランチ')).dy,
          lessThan(tester.getTopLeft(find.text('定番カレー')).dy),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'a newly received review promotes its menu without reopening the screen',
    (tester) async {
      final source = StreamController<List<CafeteriaReview>>();
      addTearDown(source.close);
      final old = review(
        '定番カレー',
        Cafeterias.tsudanuma,
        noon.subtract(const Duration(days: 1)),
      );
      final stream = Stream<List<CafeteriaReview>>.multi((controller) {
        controller.add([old]);
        final sub = source.stream.listen(controller.add);
        controller.onCancel = sub.cancel;
      });
      await mount(tester, updates: stream);
      expect(find.textContaining('本日レビューされたメニュー ('), findsNothing);
      source.add([
        old,
        review('本日のランチ', Cafeterias.tsudanuma, noon, rating: 1),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('本日レビューされたメニュー (1件)'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('本日のランチ')).dy,
        lessThan(tester.getTopLeft(find.text('定番カレー')).dy),
      );
    },
  );
  testWidgets(
    'search filters the today section and unreviewed menus remain available',
    (tester) async {
      await mount(
        tester,
        menuNames: ['未レビューの定食'],
        reviews: [
          review('本日のランチ', Cafeterias.tsudanuma, noon),
          review(
            '定番カレー',
            Cafeterias.tsudanuma,
            noon.subtract(const Duration(days: 1)),
          ),
        ],
      );
      await tester.enterText(find.byType(TextField).first, '定番');
      await tester.pumpAndSettle();
      expect(find.textContaining('本日レビューされたメニュー ('), findsNothing);
      expect(find.text('定番カレー'), findsOneWidget);
      expect(find.text('本日のランチ'), findsNothing);
      await tester.enterText(find.byType(TextField).first, '未レビュー');
      await tester.pumpAndSettle();
      expect(find.text('未レビューの定食'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();
      expect(find.text('本日レビューされたメニュー (1件)'), findsOneWidget);
    },
  );
  testWidgets(
    'midnight removes yesterday from the today section without a new snapshot',
    (tester) async {
      var clock = DateTime.utc(2026, 11, 13, 14, 59, 59);
      await mount(
        tester,
        clock: () => clock,
        reviews: [review('昨日になるメニュー', Cafeterias.tsudanuma, clock)],
      );
      expect(find.text('本日レビューされたメニュー (1件)'), findsOneWidget);
      clock = clock.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.textContaining('本日レビューされたメニュー ('), findsNothing);
      expect(find.text('今日のレビューあり'), findsNothing);
      expect(find.text('昨日になるメニュー'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('today priority can be selected again after a global ranking', (
    tester,
  ) async {
    await mount(
      tester,
      reviews: [
        review(
          '定番カレー',
          Cafeterias.tsudanuma,
          noon.subtract(const Duration(days: 1)),
        ),
        review('本日のランチ', Cafeterias.tsudanuma, noon, rating: 1),
      ],
    );
    Future<void> choose(String label) async {
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    await choose('おすすめ順（評価が高い順）');
    expect(
      tester.getTopLeft(find.text('定番カレー')).dy,
      lessThan(tester.getTopLeft(find.text('本日のランチ')).dy),
    );
    await choose('本日のレビューを優先');
    expect(
      tester.getTopLeft(find.text('本日のランチ')).dy,
      lessThan(tester.getTopLeft(find.text('定番カレー')).dy),
    );
  });
}
