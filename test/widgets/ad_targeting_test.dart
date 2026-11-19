import 'package:cit_app/widgets/admin/admin_tab_visibility_switch.dart';
import 'package:cit_app/core/providers/admin_navigation_provider.dart';
import 'dart:async';
import 'package:cit_app/core/providers/ad_analytics_provider.dart';
import 'package:cit_app/core/providers/admin_provider.dart';
import 'package:cit_app/core/providers/in_app_ad_provider.dart';
import 'package:cit_app/core/providers/settings_provider.dart';
import 'package:cit_app/core/services/analytics_service.dart';
import 'package:cit_app/models/admin/admin_model.dart';
import 'package:cit_app/models/ads/ad_analytics.dart';
import 'package:cit_app/models/ads/in_app_ad_model.dart';
import 'package:cit_app/screens/admin/ad_analytics_screen.dart';
import 'package:cit_app/services/ads/ad_event_service.dart';
import 'package:cit_app/widgets/ads/ad_slot_position.dart';
import 'package:cit_app/widgets/ads/in_app_ad_card.dart';
import 'package:cit_app/widgets/ads/in_app_ad_creative.dart';
import 'package:cit_app/widgets/ads/in_app_ad_editor_dialog.dart';
import 'package:cit_app/widgets/ads/in_app_ad_list_inserter.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/sponsor_fixtures.dart';

class _SilentAnalytics implements FirebaseAnalytics {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PendingEvents extends AdEventService {
  _PendingEvents(super.db, super.auth);
  final calls = <String>[];
  final pending = Completer<void>();
  @override
  Future<void> record({
    required InAppAd ad,
    required AdPlacement placement,
    required String grade,
    required String kind,
    required int slotIndex,
  }) {
    calls.add(kind);
    return pending.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  late SharedPreferences prefs;
  setUp(() async {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        email: 's2611001@chibatech.ac.jp',
        isEmailVerified: true,
      ),
    );
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });
  Future<void> mount(
    WidgetTester tester,
    Widget body, {
    String grade = '1',
    AdEventService? service,
  }) async {
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          adViewerGradeProvider.overrideWithValue(grade),
          adEventServiceProvider.overrideWithValue(
            service ?? AdEventService(db, auth),
          ),
          analyticsServiceProvider.overrideWithValue(
            AnalyticsService(_SilentAnalytics()),
          ),
        ],
        child: MaterialApp(home: Scaffold(body: body)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget card({InAppAd? ad}) =>
      InAppAdCard(ad: ad ?? sponsorTestAd(), placement: AdPlacement.homeTop);

  testWidgets(
    'cached ads disappear when the viewer is outside the target grade',
    (tester) async {
      await mount(
        tester,
        card(ad: sponsorTestAd().copyWith(targetGrades: ['2'])),
      );
      expect(find.byType(InAppAdCreative), findsNothing);
      expect((await db.collection('ad_events').get()).docs, isEmpty);
    },
  );
  testWidgets(
    'visible ads record one impression with inherited slot and grade',
    (tester) async {
      await mount(tester, AdSlotPosition(index: 6, child: card()));
      await tester.pump(const Duration(seconds: 2));
      final data = (await db.collection('ad_events').get()).docs.single.data();
      expect(data['kind'], 'impression');
      expect(data['grade'], '1');
      expect(data['slotIndex'], 6);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'ads below the viewport are counted only after scrolling into view',
    (tester) async {
      await mount(
        tester,
        SingleChildScrollView(
          child: Column(children: [const SizedBox(height: 1200), card()]),
        ),
      );
      expect((await db.collection('ad_events').get()).docs, isEmpty);
      await tester.ensureVisible(find.byType(InAppAdCard));
      await tester.pump(const Duration(milliseconds: 600));
      expect((await db.collection('ad_events').get()).docs.length, 1);
    },
  );
  testWidgets(
    'a cached unknown banner grade records the authenticated student grade',
    (tester) async {
      await mount(tester, card(), grade: 'unknown');
      final data = (await db.collection('ad_events').get()).docs.single.data();
      expect(data['grade'], '1');
      expect(data['kind'], 'impression');
    },
  );

  testWidgets('hidden IndexedStack tabs never count impressions', (
    tester,
  ) async {
    await mount(
      tester,
      IndexedStack(
        index: 0,
        children: [const SizedBox.expand(child: Text('別のタブ')), card()],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect((await db.collection('ad_events').get()).docs, isEmpty);
  });
  testWidgets('analytics opt-out also disables ad event recording', (
    tester,
  ) async {
    await prefs.setBool(analyticsCollectionPreferenceKey, false);
    await mount(tester, card());
    await tester.pump(const Duration(seconds: 1));
    expect((await db.collection('ad_events').get()).docs, isEmpty);
  });
  testWidgets('a pending analytics write never delays opening the ad link', (
    tester,
  ) async {
    var launches = 0;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      launches++;
      return true;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final pending = _PendingEvents(db, auth);
    await mount(tester, card(), service: pending);
    await tester.tap(find.byType(InAppAdCreative));
    await tester.pump();
    expect(pending.calls, contains('click'));
    expect(launches, 1);
  });
  testWidgets('repeated banner slots receive distinct list positions', (
    tester,
  ) async {
    final rows = interleaveWidgetListWithBannerAds(
      items: List.generate(4, (i) => Text('item$i')),
      interval: 2,
      ad: const Text('ad'),
    );
    await tester.pumpWidget(MaterialApp(home: Column(children: rows)));
    expect(
      tester
          .widgetList<AdSlotPosition>(find.byType(AdSlotPosition))
          .map((slot) => slot.index),
      [3, 6],
    );
    final generic = interleaveWidgetsWithBannerAds(
      items: [1, 2, 3, 4],
      interval: 2,
      positionOffset: 6,
      itemBuilder: (item) => Text('$item'),
      adBuilder: () => const Text('ad'),
    );
    await tester.pumpWidget(MaterialApp(home: Column(children: generic)));
    expect(
      tester
          .widgetList<AdSlotPosition>(find.byType(AdSlotPosition))
          .map((slot) => slot.index),
      [9, 12],
    );
  });
  testWidgets('the editor saves multiple target grades', (tester) async {
    InAppAd? saved;
    await mount(
      tester,
      InAppAdEditorDialog(
        ad: sponsorTestAd(),
        onSave: (ad) async {
          saved = ad;
        },
        pickBulletin: () async => null,
      ),
    );
    await tester.ensureVisible(find.text('1年生'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1年生'));
    await tester.pump();
    await tester.ensureVisible(find.text('3年生'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3年生'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ad_editor_save')));
    await tester.pumpAndSettle();
    expect(saved?.targetGrades, ['1', '3']);
  });
  testWidgets(
    'admin toggle persists hiding and can be re-enabled after reopening',
    (tester) async {
      await mount(tester, const AdminTabVisibilitySwitch());
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('admin_tab_visibility')),
            )
            .value,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('admin_tab_visibility')));
      await tester.pumpAndSettle();
      expect(prefs.getBool(adminTabVisibleKey), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await mount(tester, const AdminTabVisibilitySwitch());
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('admin_tab_visibility')),
            )
            .value,
        isFalse,
      );
      await tester.tap(find.byKey(const Key('admin_tab_visibility')));
      await tester.pumpAndSettle();
      expect(prefs.getBool(adminTabVisibleKey), isTrue);
    },
  );
  testWidgets('analytics denies non-admins without requesting event data', (
    tester,
  ) async {
    var requested = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserAdminProvider.overrideWith((ref) => Stream.value(null)),
          adAnalyticsProvider(30).overrideWith((ref) async {
            requested = true;
            throw StateError('should not fetch');
          }),
        ],
        child: const MaterialApp(home: AdAnalyticsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('管理者権限が必要です'), findsOneWidget);
    expect(requested, isFalse);
  });
  testWidgets('analytics table fits narrow screens at large text sizes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final report = AdAnalyticsReport(
      from: DateTime.utc(2026, 11, 1),
      to: DateTime.utc(2026, 11, 13),
      events: [
        AdEvent(
          adId: 'ad',
          placement: AdPlacement.homeTop,
          grade: '1',
          slotIndex: 0,
          kind: 'click',
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserAdminProvider.overrideWith(
            (ref) => Stream.value(
              AdminPermissions.fromJson({'userId': 'admin', 'isAdmin': true}),
            ),
          ),
          inAppAdsStreamProvider.overrideWith(
            (ref) => Stream.value([sponsorTestAd()]),
          ),
          adAnalyticsProvider(30).overrideWith((ref) async => report),
        ],
        child: MaterialApp(
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
          home: const AdAnalyticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(PaginatedDataTable),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'analytics shows totals and empty filters without endless loading',
    (tester) async {
      final report = AdAnalyticsReport(
        from: DateTime.utc(2026, 11, 1),
        to: DateTime.utc(2026, 11, 13),
        events: [
          for (final kind in ['impression', 'impression', 'click'])
            AdEvent(
              adId: 'ad',
              placement: AdPlacement.homeTop,
              grade: '1',
              slotIndex: 0,
              kind: kind,
            ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserAdminProvider.overrideWith(
              (ref) => Stream.value(
                AdminPermissions.fromJson({'userId': 'admin', 'isAdmin': true}),
              ),
            ),
            inAppAdsStreamProvider.overrideWith(
              (ref) => Stream.value([sponsorTestAd()]),
            ),
            adAnalyticsProvider(30).overrideWith((ref) async => report),
          ],
          child: const MaterialApp(home: AdAnalyticsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('表示数  2'), findsOneWidget);
      expect(find.text('クリック数  1'), findsOneWidget);
      expect(find.text('クリック率  50.0%'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('学年-null')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2年生').last);
      await tester.pumpAndSettle();
      expect(find.text('この条件の記録はまだありません。'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
