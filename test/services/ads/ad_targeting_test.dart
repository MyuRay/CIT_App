import 'package:cit_app/core/providers/in_app_ad_provider.dart';
import 'package:cit_app/core/providers/ad_analytics_provider.dart';
import 'package:cit_app/core/providers/admin_provider.dart';
import 'package:cit_app/core/providers/admin_navigation_provider.dart';
import 'package:cit_app/core/providers/settings_provider.dart';
import 'package:cit_app/models/admin/admin_model.dart';
import 'package:cit_app/models/ads/ad_audience.dart';
import 'package:cit_app/models/ads/ad_analytics.dart';
import 'package:cit_app/models/ads/in_app_ad_model.dart';
import 'package:cit_app/services/ads/ad_event_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ad = InAppAd(
  id: 'ad1',
  title: 'テスト',
  body: '学生向け',
  placement: AdPlacement.homeTop,
  actionType: AdActionType.external,
  actionPayload: 'https://example.com',
  isActive: true,
);
const nowEmail = '26c1001@chibatech.ac.jp';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('s-prefixed student email uses the admission year', () {
    final now = DateTime.utc(2026, 11, 14);
    expect(adGradeFromEmail('s2311001@s.chibakoudai.jp', now), '4');
    expect(adGradeFromEmail('s2611001@s.chibakoudai.jp', now), '1');
    expect(adGradeFromEmail('S2611001@CHIBATECH.AC.JP', now), '1');
    expect(
      adGradeFromEmail(
        's2311001@s.chibakoudai.jp',
        DateTime.utc(2027, 3, 31, 15),
      ),
      '5_plus',
    );
  });
  test('academic year changes at midnight April 1 JST', () {
    expect(
      adGradeFromEmail(nowEmail, DateTime.utc(2027, 3, 31, 14, 59, 59)),
      '1',
    );
    expect(adGradeFromEmail(nowEmail, DateTime.utc(2027, 3, 31, 15)), '2');
    expect(
      adGradeFromEmail(nowEmail, DateTime.utc(2026, 3, 31, 14)),
      'unknown',
    );
  });
  test(
    'both student domains, numeric IDs, case and whitespace are supported',
    () {
      expect(
        adGradeFromEmail(' 26C1001@CHIBATECH.AC.JP ', DateTime.utc(2026, 11)),
        '1',
      );
      expect(
        adGradeFromEmail('2311001@s.chibakoudai.jp', DateTime.utc(2026, 11)),
        '4',
      );
      expect(
        adGradeFromEmail('22c1001@s.chibakoudai.jp', DateTime.utc(2026, 11)),
        '5_plus',
      );
    },
  );
  test(
    'graduate, staff, external and malformed email never becomes a student grade',
    () {
      for (final email in [
        null,
        'test-old@s.chibakoudai.jp',
        'staff@chibatech.ac.jp',
        '26c1001@p.chibakoudai.jp',
        '26c1001@example.com',
        '26c1001@s.chibakoudai.jp.evil.com',
        '26c1001@chibatech.ac.jp@evil.com',
        '99c1001@chibatech.ac.jp',
      ]) {
        expect(
          adGradeFromEmail(email, DateTime.utc(2026, 11)),
          'unknown',
          reason: '$email',
        );
      }
    },
  );
  test(
    'old ads target everyone and targeting survives Firestore round trip and copy',
    () async {
      final db = FakeFirebaseFirestore();
      final doc = db.collection('in_app_ads').doc('ad1');
      final old = ad.toFirestore()..remove('targetGrades');
      await doc.set(old);
      final original = InAppAd.fromFirestore(await doc.get());
      expect(original.matchesGrade('unknown'), isTrue);
      final target = original.copyWith(targetGrades: ['1', '3']);
      await doc.set(target.toFirestore());
      final loaded = InAppAd.fromFirestore(await doc.get());
      expect(loaded.targetGrades, ['1', '3']);
      expect(loaded.copyWith(title: 'コピー').targetGrades, ['1', '3']);
      expect(loaded.matchesGrade('2'), isFalse);
      expect(loaded.matchesGrade('unknown'), isFalse);
      expect(loaded.copyWith(targetGrades: []).matchesGrade('unknown'), isTrue);
    },
  );
  test(
    'malformed targeting cannot broaden a restricted ad to everyone',
    () async {
      final db = FakeFirebaseFirestore();
      for (final invalid in [
        null,
        '1',
        [1],
        ['invalid'],
      ]) {
        final doc = db.collection('in_app_ads').doc('bad');
        await doc.set({...ad.toFirestore(), 'targetGrades': invalid});
        final loaded = InAppAd.fromFirestore(await doc.get());
        for (final grade in adGrades) {
          expect(loaded.matchesGrade(grade), isFalse);
        }
      }
    },
  );
  test(
    'ad selection reacts to grade and excludes inactive, expired and wrong placement',
    () async {
      final db = FakeFirebaseFirestore();
      for (final item in [
        ad.copyWith(id: 'first', targetGrades: ['1']),
        ad.copyWith(id: 'second', targetGrades: ['2']),
        ad.copyWith(id: 'inactive', isActive: false),
        ad.copyWith(id: 'expired', endAt: DateTime(2000)),
        ad.copyWith(id: 'wrong', placement: AdPlacement.cafeteria),
      ]) {
        await db.collection('in_app_ads').doc(item.id).set(item.toFirestore());
      }
      final viewer = StateProvider((ref) => '1');
      final container = ProviderContainer(
        overrides: [
          adFirestoreProvider.overrideWithValue(db),
          adViewerGradeProvider.overrideWith((ref) => ref.watch(viewer)),
        ],
      );
      addTearDown(container.dispose);
      expect(
        (await container.read(inAppAdProvider(AdPlacement.homeTop).future))?.id,
        'first',
      );
      container.read(viewer.notifier).state = '2';
      expect(
        (await container.read(inAppAdProvider(AdPlacement.homeTop).future))?.id,
        'second',
      );
      container.read(viewer.notifier).state = 'unknown';
      expect(
        await container.read(inAppAdProvider(AdPlacement.homeTop).future),
        isNull,
      );
    },
  );
  test('recording stores only bounded attributes, not email or UID', () async {
    final db = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'private-uid',
        email: nowEmail,
        isEmailVerified: true,
      ),
    );
    await AdEventService(db, auth).record(
      ad: ad,
      placement: ad.placement,
      grade: '1',
      kind: 'click',
      slotIndex: 6,
    );
    final data = (await db.collection('ad_events').get()).docs.single.data();
    expect(data.keys.toSet(), {
      'adId',
      'placement',
      'grade',
      'kind',
      'slotIndex',
      'createdAt',
    });
    expect(data['placement'], 'home_top');
    expect(data['grade'], '1');
    expect(data['slotIndex'], 6);
    expect(data.values.contains('private-uid'), isFalse);
    expect(data.values.contains(nowEmail), isFalse);
  });
  test(
    'unsigned, unverified and ineligible clients produce no events',
    () async {
      final db = FakeFirebaseFirestore();
      for (final auth in [
        MockFirebaseAuth(),
        MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(isEmailVerified: false),
        ),
      ]) {
        await AdEventService(db, auth).record(
          ad: ad,
          placement: ad.placement,
          grade: '1',
          kind: 'click',
          slotIndex: 0,
        );
      }
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(isEmailVerified: true),
      );
      for (final item in [
        ad.copyWith(targetGrades: ['2']),
        ad.copyWith(isActive: false),
        ad.copyWith(endAt: DateTime(2000)),
      ]) {
        await AdEventService(db, auth).record(
          ad: item,
          placement: item.placement,
          grade: '1',
          kind: 'click',
          slotIndex: 0,
        );
      }
      await AdEventService(db, auth).record(
        ad: ad,
        placement: AdPlacement.cafeteria,
        grade: '1',
        kind: 'click',
        slotIndex: 0,
      );
      await AdEventService(db, auth).record(
        ad: ad,
        placement: ad.placement,
        grade: '1',
        kind: 'click',
        slotIndex: -1,
      );
      await AdEventService(db, auth).record(
        ad: ad,
        placement: ad.placement,
        grade: '1',
        kind: 'delete',
        slotIndex: 0,
      );
      expect((await db.collection('ad_events').get()).docs, isEmpty);
    },
  );
  test(
    'analytics separates ad, grade, placement and slot; filters and CTR are exact',
    () {
      AdEvent event(
        String kind, {
        String id = 'ad1',
        String grade = '1',
        int slot = 0,
        AdPlacement placement = AdPlacement.homeTop,
      }) => AdEvent(
        adId: id,
        placement: placement,
        grade: grade,
        slotIndex: slot,
        kind: kind,
      );
      final events = [
        event('impression'),
        event('impression'),
        event('click'),
        event('click', grade: '2'),
        event('click', slot: 6),
        event('click', id: 'other'),
        event('click', placement: AdPlacement.cafeteria),
      ];
      final rows = summarizeAdEvents(events);
      expect(rows.length, 5);
      final first = summarizeAdEvents(
        events,
        adId: 'ad1',
        grade: '1',
        placement: AdPlacement.homeTop,
      );
      expect(first.length, 2);
      final fixed = first.singleWhere((row) => row.slotIndex == 0);
      expect(fixed.impressions, 2);
      expect(fixed.clicks, 1);
      expect(fixed.ctr, 50);
      expect(first.singleWhere((row) => row.slotIndex == 6).ctr, isNull);
    },
  );
  test('malformed events are ignored without breaking the report', () {
    final valid = {
      'adId': 'ad1',
      'placement': 'home_top',
      'grade': '1',
      'kind': 'click',
      'slotIndex': 0,
    };
    expect(AdEvent.fromMap(valid), isNotNull);
    for (final patch in [
      {'placement': 1},
      {'grade': '9'},
      {'kind': 'x'},
      {'slotIndex': -1},
      {'slotIndex': 100000},
      {'adId': null},
    ]) {
      expect(AdEvent.fromMap({...valid, ...patch}), isNull);
    }
  });
  test('analytics period includes today in JST across a year boundary', () {
    expect(
      adAnalyticsPeriodStart(DateTime.utc(2026, 12, 31, 16), 7),
      DateTime.utc(2026, 12, 25, 15),
    );
  });
  test('large reports explicitly cap data to the newest 5000 events', () async {
    final db = FakeFirebaseFirestore();
    for (var i = 0; i < 5001; i++) {
      await db.collection('ad_events').doc('event$i').set({
        'adId': 'ad$i',
        'placement': 'home_top',
        'grade': '1',
        'kind': 'click',
        'slotIndex': 0,
        'createdAt': DateTime.utc(2026, 1, 1).add(Duration(seconds: i)),
      });
    }
    final snapshot =
        await db
            .collection('ad_events')
            .orderBy('createdAt', descending: true)
            .get();
    final report = adAnalyticsReportFromSnapshot(
      snapshot,
      DateTime.utc(2026),
      DateTime.utc(2027),
    );
    expect(report.truncated, isTrue);
    expect(report.events.length, 5000);
    expect(report.events.first.adId, 'ad5000');
    expect(report.events.last.adId, 'ad1');
  });
  test('only administrators can request an analytics report', () async {
    final db = FakeFirebaseFirestore();
    final container = ProviderContainer(
      overrides: [
        adFirestoreProvider.overrideWithValue(db),
        currentUserAdminProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(adAnalyticsProvider(30).future), throwsStateError);
  });
  test('administrator query excludes events outside the period', () async {
    final db = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(isEmailVerified: true),
    );
    await AdEventService(db, auth).record(
      ad: ad,
      placement: ad.placement,
      grade: '1',
      kind: 'click',
      slotIndex: 0,
    );
    await db.collection('ad_events').doc('old').set({
      'adId': 'ad1',
      'placement': 'home_top',
      'grade': '1',
      'kind': 'click',
      'slotIndex': 0,
      'createdAt': DateTime(2000),
    });
    final container = ProviderContainer(
      overrides: [
        adFirestoreProvider.overrideWithValue(db),
        currentUserAdminProvider.overrideWith(
          (ref) => Stream.value(
            AdminPermissions.fromJson({'userId': 'admin', 'isAdmin': true}),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final report = await container.read(adAnalyticsProvider(30).future);
    expect(report.events.length, 1);
    expect(report.truncated, isFalse);
  });
  test('admin tab visibility is restored from the device preference', () async {
    SharedPreferences.setMockInitialValues({adminTabVisibleKey: false});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    expect(container.read(adminTabVisibleProvider), isFalse);
    await prefs.setBool(adminTabVisibleKey, true);
    final reopened = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(reopened.dispose);
    expect(reopened.read(adminTabVisibleProvider), isTrue);
  });
}
