import 'package:cit_app/core/providers/cafeteria_review_provider.dart';
import 'package:cit_app/core/providers/cafeteria_menu_provider.dart';
import 'package:cit_app/core/providers/in_app_ad_provider.dart';
import 'package:cit_app/models/cafeteria/cafeteria_review_model.dart';
import 'package:cit_app/models/cafeteria/cafeteria_menu_item_model.dart';
import 'package:cit_app/widgets/cafeteria/cafeteria_menu_item_image.dart';
import 'package:cit_app/models/ads/in_app_ad_model.dart';
import 'package:cit_app/screens/cafeteria/cafeteria_reviews_screen.dart';
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
  testWidgets('review count sorting is global and does not prioritize today', (
    tester,
  ) async {
    final now = DateTime.now();
    CafeteriaReview review(String id, String menu, DateTime date) =>
        CafeteriaReview(
          id: id,
          cafeteriaId: 'tsudanuma',
          menuName: menu,
          taste: 4,
          volume: 4,
          recommend: 4,
          userId: id,
          userName: '利用者',
          createdAt: date,
        );
    final reviews = [
      review('a', '本日のメニュー', now),
      for (var i = 0; i < 4; i++)
        review('b$i', '定番カレー', now.subtract(const Duration(days: 1))),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          for (final campus in Cafeterias.all)
            cafeteriaReviewsProvider(campus).overrideWith(
              (ref) => Stream.value(campus == 'tsudanuma' ? reviews : []),
            ),
          for (final campus in Cafeterias.all)
            cafeteriaMenuItemsListProvider(
              campus,
            ).overrideWith((ref) => Stream.value([])),
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
    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('レビューの多い順').last);
    await tester.pumpAndSettle();
    expect(find.text('レビュー件数順 (2件)'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('定番カレー')).dy,
      lessThan(tester.getTopLeft(find.text('本日のメニュー')).dy),
    );
    expect(find.textContaining('本日レビューされたメニュー ('), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'only nearby menu images mount and the last menu stays reachable',
    (tester) async {
      final menus = [
        for (var i = 0; i < 40; i++)
          CafeteriaMenuItem(
            id: 'menu-$i',
            cafeteriaId: 'tsudanuma',
            menuName: 'メニュー' + i.toString().padLeft(2, '0'),
            createdAt: DateTime(2026, 9, 16),
          ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            for (final campus in Cafeterias.all)
              cafeteriaReviewsProvider(
                campus,
              ).overrideWith((ref) => Stream.value([])),
            for (final campus in Cafeterias.all)
              cafeteriaMenuItemsListProvider(campus).overrideWith(
                (ref) => Stream.value(campus == 'tsudanuma' ? menus : []),
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
      final initialImages =
          find.byType(CafeteriaMenuItemImage).evaluate().length;
      expect(initialImages, greaterThan(0));
      expect(initialImages, lessThan(12));
      expect(find.text('メニュー39'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('メニュー39'),
        450,
        scrollable:
            find
                .descendant(
                  of: find.byKey(const ValueKey('cafeteria-menu-list')),
                  matching: find.byType(Scrollable),
                )
                .first,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      expect(find.text('メニュー39').hitTestable(), findsOneWidget);
      expect(
        find.byType(CafeteriaMenuItemImage).evaluate().length,
        lessThan(12),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
