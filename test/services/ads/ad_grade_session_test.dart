import 'dart:async';

import 'package:cit_app/core/providers/auth_provider.dart';
import 'package:cit_app/core/providers/in_app_ad_provider.dart';
import 'package:cit_app/core/providers/simple_auth_provider.dart';
import 'package:cit_app/models/ads/in_app_ad_model.dart';
import 'package:cit_app/services/ads/ad_event_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const sampleAd = InAppAd(
  id: 'grade-ad',
  title: '広告',
  body: '',
  placement: AdPlacement.homeTop,
  actionType: AdActionType.external,
  actionPayload: 'https://example.com',
  isActive: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'restored verified session has a grade before the auth stream emits',
    () async {
      final japan = DateTime.now().toUtc().add(const Duration(hours: 9));
      final academicYear = japan.year - (japan.month < 4 ? 1 : 0);
      final admission = ((academicYear - 3) % 100).toString().padLeft(2, '0');
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          email: 's${admission}11001@chibatech.ac.jp',
          isEmailVerified: true,
        ),
      );
      final stream = StreamController<User?>();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          simpleAuthStateProvider.overrideWith((ref) => stream.stream),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await stream.close();
      });
      container.listen(adViewerGradeProvider, (_, __) {});
      expect(container.read(simpleAuthStateProvider).isLoading, isTrue);
      expect(container.read(adViewerGradeProvider), '4');
      await auth.signOut();
      stream.add(null);
      await Future<void>.delayed(Duration.zero);
      await container.pump();
      expect(container.read(adViewerGradeProvider), 'unknown');
    },
  );

  for (final admission in [23, 24, 25, 26]) {
    test(
      'startup unknown is replaced by the verified ${2027 - admission - 2000} grade for $admission',
      () async {
        final db = FakeFirebaseFirestore();
        final auth = MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(
            uid: 'private-user',
            email: 's${admission}11001@chibatech.ac.jp',
            isEmailVerified: true,
          ),
        );
        await AdEventService(
          db,
          auth,
          now: () => DateTime.utc(2026, 11, 17),
        ).record(
          ad: sampleAd,
          placement: sampleAd.placement,
          grade: 'unknown',
          kind: 'impression',
          slotIndex: 0,
        );
        final event =
            (await db.collection('ad_events').get()).docs.single.data();
        expect(event['grade'], '${27 - admission}');
        expect(event.keys.toSet(), {
          'adId',
          'placement',
          'grade',
          'kind',
          'slotIndex',
          'createdAt',
        });
      },
    );
  }

  test(
    'stale grade from a previous account cannot bypass ad targeting',
    () async {
      final db = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          email: 's2411001@s.chibakoudai.jp',
          isEmailVerified: true,
        ),
      );
      final service = AdEventService(
        db,
        auth,
        now: () => DateTime.utc(2026, 11, 17),
      );
      await service.record(
        ad: sampleAd.copyWith(targetGrades: ['1']),
        placement: sampleAd.placement,
        grade: '1',
        kind: 'click',
        slotIndex: 0,
      );
      expect((await db.collection('ad_events').get()).docs, isEmpty);
      await service.record(
        ad: sampleAd.copyWith(targetGrades: ['3']),
        placement: sampleAd.placement,
        grade: '1',
        kind: 'click',
        slotIndex: 0,
      );
      expect(
        (await db.collection('ad_events').get()).docs.single.data()['grade'],
        '3',
      );
    },
  );

  test('the recording boundary uses the April 1 JST academic year', () async {
    final db = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        email: 's2611001@chibatech.ac.jp',
        isEmailVerified: true,
      ),
    );
    var time = DateTime.utc(2027, 3, 31, 14, 59, 59);
    final service = AdEventService(db, auth, now: () => time);
    await service.record(
      ad: sampleAd,
      placement: sampleAd.placement,
      grade: '1',
      kind: 'click',
      slotIndex: 0,
    );
    time = DateTime.utc(2027, 3, 31, 15);
    await service.record(
      ad: sampleAd,
      placement: sampleAd.placement,
      grade: '1',
      kind: 'click',
      slotIndex: 0,
    );
    expect(
      (await db.collection('ad_events').get()).docs.map(
        (d) => d.data()['grade'],
      ),
      unorderedEquals(['1', '2']),
    );
  });

  test(
    'a nonstudent email is never assigned the caller supplied student grade',
    () async {
      final db = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          email: 'staff@chibatech.ac.jp',
          isEmailVerified: true,
        ),
      );
      await AdEventService(db, auth).record(
        ad: sampleAd,
        placement: sampleAd.placement,
        grade: '2',
        kind: 'click',
        slotIndex: 0,
      );
      expect(
        (await db.collection('ad_events').get()).docs.single.data()['grade'],
        'unknown',
      );
    },
  );
}
