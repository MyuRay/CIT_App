import 'dart:async';

import 'package:cit_app/core/providers/cwitter_pin_provider.dart';
import 'package:cit_app/core/providers/schedule_provider.dart';
import 'package:cit_app/core/providers/user_block_provider.dart';
import 'package:cit_app/models/community/cwitter_post.dart';
import 'package:cit_app/services/auth/session_work_guard.dart';
import 'package:cit_app/services/community/cwitter_pin_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  late CwitterPinService service;
  late ProviderContainer container;
  late StreamController<Set<String>> hidden;

  Map<String, Object?> post(String author) => {
    'authorId': author,
    'cwitterId': author,
    'body': '古いCweet',
    'createdAt': DateTime(2020),
  };
  Future<void> pin(String id, {bool pinned = true, String uid = 'owner'}) =>
      service.setPinned(userId: uid, postId: id, pinned: pinned);
  Future<void> flush() async {
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() async {
    SessionWorkGuard.resume();
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'owner', isEmailVerified: true),
    );
    service = CwitterPinService(firestore: db, auth: auth);
    hidden = StreamController<Set<String>>.broadcast();
    container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('owner'),
        cwitterPinServiceProvider.overrideWithValue(service),
        hiddenUserIdsProvider.overrideWith((ref) async* {
          yield <String>{};
          yield* hidden.stream;
        }),
      ],
    );
    await db.doc('users/owner').set({
      'displayName': '学生',
      'cwitterId': 'owner',
    });
    await db.doc('users/other').set({'displayName': '別の学生'});
    await db.doc('cwitter_posts/old').set(post('owner'));
    await db.doc('cwitter_posts/new').set(post('owner'));
    await db.doc('cwitter_posts/foreign').set(post('other'));
  });
  tearDown(() async {
    container.dispose();
    await hidden.close();
  });

  test(
    'pin replaces a single reference without modifying the post or other profile fields',
    () async {
      final original = (await db.doc('cwitter_posts/old').get()).data();
      await pin('old');
      expect(
        (await db.doc('users/owner').get()).data()![CwitterPinService.field],
        'old',
      );
      await pin('new');
      final profile = (await db.doc('users/owner').get()).data()!;
      expect(profile[CwitterPinService.field], 'new');
      expect(profile['displayName'], '学生');
      expect((await db.doc('cwitter_posts/old').get()).data(), original);
    },
  );

  test('unpin is idempotent and never clears a later replacement', () async {
    await pin('old');
    await pin('new');
    await pin('old', pinned: false);
    expect(
      (await db.doc('users/owner').get()).data()![CwitterPinService.field],
      'new',
    );
    await pin('new', pinned: false);
    await pin('new', pinned: false);
    expect(
      (await db.doc('users/owner').get()).data()!.containsKey(
        CwitterPinService.field,
      ),
      isFalse,
    );
  });

  test(
    'foreign, missing and malformed posts cannot replace a valid pin',
    () async {
      await pin('old');
      for (final id in ['foreign', 'deleted', 'posts/old', '', '../old']) {
        await expectLater(pin(id), throwsStateError);
        expect(
          (await db.doc('users/owner').get()).data()![CwitterPinService.field],
          'old',
        );
      }
    },
  );

  test('another profile and a signed-out account cannot be changed', () async {
    await expectLater(pin('foreign', uid: 'other'), throwsStateError);
    await auth.signOut();
    await expectLater(pin('old'), throwsStateError);
    expect(
      (await db.doc('users/other').get()).data()!.containsKey(
        CwitterPinService.field,
      ),
      isFalse,
    );
  });

  test('inactive and missing profiles cannot be pinned', () async {
    await db.doc('users/owner').update({'isActive': false});
    await expectLater(pin('old'), throwsStateError);
    await db.doc('users/owner').delete();
    await expectLater(pin('old'), throwsStateError);
    expect((await db.doc('users/owner').get()).exists, isFalse);
  });

  test(
    'pins survive a new service instance and clear after the post is deleted',
    () async {
      await pin('old');
      final reloaded = CwitterPinService(firestore: db, auth: auth);
      expect(
        await reloaded
            .watchPinnedPostId('owner')
            .firstWhere((id) => id == 'old'),
        'old',
      );
      final provider = visibleCwitterPinnedPostProvider('owner');
      container.listen(provider, (_, _) {});
      await flush();
      expect(container.read(provider).requireValue?.id, 'old');
      await db.doc('cwitter_posts/old').delete();
      await flush();
      expect(container.read(provider).requireValue, isNull);
      // A dangling pointer can still be cleared, without the deleted post.
      await pin('old', pinned: false);
      expect(
        await reloaded
            .watchPinnedPostId('owner')
            .firstWhere((id) => id == null),
        isNull,
      );
    },
  );

  test(
    'live replacement and post edits reach the pinned profile card',
    () async {
      await pin('old');
      final provider = visibleCwitterPinnedPostProvider('owner');
      container.listen(provider, (_, _) {});
      await flush();
      expect(container.read(provider).requireValue?.id, 'old');
      await pin('new');
      await flush();
      expect(container.read(provider).requireValue?.id, 'new');
      await db.doc('cwitter_posts/new').update({'body': '更新されたCweet'});
      await flush();
      expect(container.read(provider).requireValue?.body, '更新されたCweet');
    },
  );

  test(
    'blocked and banned authors disappear even if the pin was already displayed',
    () async {
      await pin('old');
      final provider = visibleCwitterPinnedPostProvider('owner');
      container.listen(provider, (_, _) {});
      await flush();
      expect(container.read(provider).requireValue?.id, 'old');
      hidden.add({'owner'});
      await flush();
      expect(container.read(provider).requireValue, isNull);
      hidden.add(<String>{});
      await flush();
      expect(container.read(provider).requireValue?.id, 'old');
      hidden.addError(StateError('visibility unavailable'));
      await flush();
      expect(container.read(provider).hasError, isTrue);
      expect(container.read(provider).valueOrNull, isNull);
    },
  );

  test(
    'forged foreign references and invalid stored paths do not render',
    () async {
      final provider = visibleCwitterPinnedPostProvider('owner');
      container.listen(provider, (_, _) {});
      for (final id in ['foreign', 'users/owner', 'missing', 42]) {
        await db.doc('users/owner').update({CwitterPinService.field: id});
        await flush();
        expect(container.read(provider).requireValue, isNull);
      }
    },
  );

  test('a pin cannot bypass pending visibility checks', () async {
    final visibility = StreamController<Set<String>>();
    final checking = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('owner'),
        cwitterPinServiceProvider.overrideWithValue(service),
        hiddenUserIdsProvider.overrideWith((ref) => visibility.stream),
      ],
    );
    addTearDown(checking.dispose);
    addTearDown(visibility.close);
    await pin('old');
    final provider = visibleCwitterPinnedPostProvider('owner');
    checking.listen<AsyncValue<CwitterPost?>>(provider, (_, _) {});
    await flush();
    expect(checking.read(provider).isLoading, isTrue);
    visibility.add({'owner'});
    await flush();
    expect(checking.read(provider).requireValue, isNull);
  });
}
