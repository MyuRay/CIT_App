import 'dart:async';

import 'package:cit_app/core/providers/bulletin_provider.dart';
import 'package:cit_app/core/providers/filtered_bulletin_provider.dart';
import 'package:cit_app/core/providers/schedule_provider.dart';
import 'package:cit_app/core/providers/user_block_provider.dart';
import 'package:cit_app/services/bulletin/bulletin_feed_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../support/sponsor_fixtures.dart';

Future<void> writePost(
  FakeFirebaseFirestore db,
  String id, {
  bool pinned = false,
  int age = 0,
  String approval = 'approved',
  bool active = true,
  DateTime? expiry,
  bool legacy = false,
}) async {
  final data =
      sponsorTestPost(
        id: id,
        approval: approval,
        active: active,
        expiry: expiry,
      ).toJson();
  data['isPinned'] = pinned;
  data['authorId'] = id == 'blocked' ? 'blocked-author' : 'owner';
  // Dates are intentionally well before now, independent of the test run date.
  data['createdAt'] = DateTime(2020).subtract(Duration(days: age));
  if (legacy) data.remove('isPinned');
  await db.collection('bulletin_posts').doc(id).set(data);
}

List<String> ids(BulletinFeedBatch batch) =>
    batch.posts.map((p) => p.id).toList();

Future<BulletinFeedBatch> nextWhere(
  StreamIterator<BulletinFeedBatch> iterator,
  bool Function(BulletinFeedBatch) predicate,
) async {
  while (await iterator.moveNext().timeout(const Duration(seconds: 5))) {
    if (predicate(iterator.current)) return iterator.current;
  }
  throw StateError('Feed ended before the expected update');
}

class _ControlledFeed extends BulletinFeedService {
  _ControlledFeed() : super(FakeFirebaseFirestore());
  final requests =
      <({int limit, StreamController<BulletinFeedBatch> stream})>[];

  @override
  Stream<BulletinFeedBatch> watchFeed({required int recentLimit}) {
    final stream = StreamController<BulletinFeedBatch>.broadcast();
    requests.add((limit: recentLimit, stream: stream));
    return stream.stream;
  }

  Future<void> close() async {
    for (final request in requests) {
      await request.stream.close();
    }
  }
}

void main() {
  test(
    'all old pins are present before the first page, deduplicated on expansion',
    () async {
      final db = FakeFirebaseFirestore();
      for (var i = 0; i < 43; i++) {
        await writePost(db, 'recent-$i', age: i, legacy: i == 0);
      }
      for (var i = 0; i < 35; i++) {
        await writePost(db, 'pin-$i', pinned: true, age: 100 + i);
      }
      final service = BulletinFeedService(db);
      final first = await service.watchFeed(recentLimit: 30).first;
      expect(first.posts.length, 65);
      expect(first.posts.take(35).every((post) => post.isPinned), isTrue);
      expect(
        first.posts[35].id,
        'recent-0',
      ); // Missing legacy field remains visible.
      expect(first.hasMore, isTrue);

      final expanded = await service.watchFeed(recentLimit: 90).first;
      expect(expanded.posts.length, 78);
      expect(ids(expanded).toSet().length, 78);
      expect(ids(expanded).take(35), ids(first).take(35));
      expect(expanded.hasMore, isFalse);
    },
  );

  test(
    'same-date pins have a stable order; pending, hidden and expired pins stay excluded',
    () async {
      final db = FakeFirebaseFirestore();
      await writePost(db, 'normal');
      await writePost(db, 'a-pin', pinned: true, age: 5);
      await writePost(db, 'z-pin', pinned: true, age: 5);
      await writePost(db, 'pending', pinned: true, approval: 'pending');
      await writePost(db, 'hidden', pinned: true, active: false);
      await writePost(db, 'expired', pinned: true, expiry: DateTime(2020));
      final service = BulletinFeedService(db);
      expect(ids(await service.watchFeed(recentLimit: 30).first), [
        'z-pin',
        'a-pin',
        'normal',
      ]);
      expect(ids(await service.watchFeed(recentLimit: 30).first), [
        'z-pin',
        'a-pin',
        'normal',
      ]);
    },
  );

  test(
    'live pin, unpin, hide and delete do not restore stale copies',
    () async {
      final db = FakeFirebaseFirestore();
      await writePost(db, 'new');
      await writePost(db, 'old', age: 10);
      final iterator = StreamIterator(
        BulletinFeedService(db).watchFeed(recentLimit: 30),
      );
      addTearDown(iterator.cancel);
      expect(ids(await nextWhere(iterator, (_) => true)), ['new', 'old']);

      await db.doc('bulletin_posts/old').update({'isPinned': true});
      final pinned = await nextWhere(
        iterator,
        (batch) => batch.posts.first.isPinned,
      );
      expect(ids(pinned), ['old', 'new']);
      await db.doc('bulletin_posts/old').update({'isPinned': false});
      final unpinned = await nextWhere(
        iterator,
        (batch) =>
            batch.posts.length == 2 && !batch.posts.any((p) => p.isPinned),
      );
      expect(ids(unpinned), ['new', 'old']);

      await db.doc('bulletin_posts/old').update({
        'isPinned': true,
        'isActive': false,
      });
      expect(
        ids(await nextWhere(iterator, (batch) => !ids(batch).contains('old'))),
        ['new'],
      );
      await db.doc('bulletin_posts/old').update({'isActive': true});
      await nextWhere(iterator, (batch) => batch.posts.first.isPinned);
      await db.doc('bulletin_posts/old').delete();
      expect(
        ids(await nextWhere(iterator, (batch) => !ids(batch).contains('old'))),
        ['new'],
      );
    },
  );

  test('a pinned post disappears on expiry without a database write', () async {
    final db = FakeFirebaseFirestore();
    await writePost(
      db,
      'pin',
      pinned: true,
      expiry: DateTime.now().add(const Duration(seconds: 1)),
    );
    final iterator = StreamIterator(
      BulletinFeedService(db).watchFeed(recentLimit: 30),
    );
    addTearDown(iterator.cancel);
    expect(ids(await nextWhere(iterator, (_) => true)), ['pin']);
    expect(
      ids(await nextWhere(iterator, (batch) => batch.posts.isEmpty)),
      isEmpty,
    );
  });

  test(
    'refresh supersedes a pending page and its old result cannot overwrite pins',
    () async {
      final service = _ControlledFeed();
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('student'),
          bulletinFeedServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await service.close();
      });
      final notifier = container.read(bulletinFeedProvider.notifier);
      service.requests[0].stream.add(
        BulletinFeedBatch(
          posts: [sponsorTestPost(id: 'initial')],
          hasMore: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      final more = notifier.loadMore();
      expect(service.requests[1].limit, 60);
      final refresh = notifier.refresh();
      await more;
      expect(service.requests[1].stream.hasListener, isFalse);
      expect(service.requests[2].limit, 30);
      service.requests[2].stream.add(
        BulletinFeedBatch(
          posts: [sponsorTestPost(id: 'fresh')],
          hasMore: false,
        ),
      );
      await refresh;
      service.requests[1].stream.add(
        BulletinFeedBatch(posts: [sponsorTestPost(id: 'stale')], hasMore: true),
      );
      await Future<void>.delayed(Duration.zero);
      expect(container.read(bulletinFeedProvider).posts.single.id, 'fresh');
      expect(container.read(bulletinFeedProvider).hasMore, isFalse);
    },
  );

  test(
    'load failure retains the existing feed and retries the same window',
    () async {
      final service = _ControlledFeed();
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('student'),
          bulletinFeedServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await service.close();
      });
      final notifier = container.read(bulletinFeedProvider.notifier);
      service.requests[0].stream.add(
        BulletinFeedBatch(posts: [sponsorTestPost(id: 'kept')], hasMore: true),
      );
      await Future<void>.delayed(Duration.zero);
      final failed = notifier.loadMore();
      service.requests[1].stream.addError(StateError('offline'));
      await failed;
      expect(container.read(bulletinFeedProvider).posts.single.id, 'kept');
      expect(container.read(bulletinFeedProvider).error, isNotNull);
      final retry = notifier.loadMore();
      expect(service.requests[2].limit, 60);
      service.requests[2].stream.add(
        const BulletinFeedBatch(posts: [], hasMore: false),
      );
      await retry;
      expect(container.read(bulletinFeedProvider).error, isNull);
    },
  );

  test(
    'sign-out cancels listeners and prevents old-session posts returning',
    () async {
      final service = _ControlledFeed();
      final uid = StateProvider<String?>((ref) => 'student');
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => ref.watch(uid)),
          bulletinFeedServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await service.close();
      });
      container.read(bulletinFeedProvider);
      service.requests[0].stream.add(
        BulletinFeedBatch(posts: [sponsorTestPost()], hasMore: true),
      );
      await Future<void>.delayed(Duration.zero);
      container.read(uid.notifier).state = null;
      await container.pump();
      expect(service.requests[0].stream.hasListener, isFalse);
      expect(container.read(bulletinFeedProvider).posts, isEmpty);
      service.requests[0].stream.add(
        BulletinFeedBatch(posts: [sponsorTestPost()], hasMore: true),
      );
      await Future<void>.delayed(Duration.zero);
      expect(container.read(bulletinFeedProvider).posts, isEmpty);
    },
  );

  test(
    'pin priority still respects blocked authors and the chosen category',
    () async {
      final db = FakeFirebaseFirestore();
      await writePost(db, 'blocked', pinned: true);
      await writePost(db, 'visible-pin', pinned: true, age: 5);
      await writePost(db, 'visible-normal');
      final batch =
          await BulletinFeedService(db).watchFeed(recentLimit: 30).first;
      final container = ProviderContainer(
        overrides: [
          bulletinPostsProvider.overrideWithValue(AsyncData(batch.posts)),
          hiddenUserIdsProvider.overrideWith(
            (ref) => Stream.value({'blocked-author'}),
          ),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(
        filteredBulletinPostsByCategoryProvider('coupon'),
        (_, __) {},
      );
      addTearDown(sub.close);
      await container.read(hiddenUserIdsProvider.future);
      await container.pump();
      expect(
        container
            .read(filteredBulletinPostsByCategoryProvider('coupon'))
            .value!
            .map((p) => p.id),
        ['visible-pin', 'visible-normal'],
      );
      expect(
        container.read(filteredBulletinPostsByCategoryProvider('event')).value,
        isEmpty,
      );
    },
  );
}
