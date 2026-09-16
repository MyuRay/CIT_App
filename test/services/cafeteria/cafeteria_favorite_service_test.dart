import 'package:cit_app/core/providers/cafeteria_favorite_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cit_app/models/cafeteria/cafeteria_favorite_target.dart';
import 'package:cit_app/services/cafeteria/cafeteria_favorite_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async';

void main() {
  test('favorite keys match the shared Cloud Functions contract', () {
    final cases =
        jsonDecode(
              File(
                'test/fixtures/cafeteria_favorite_keys.json',
              ).readAsStringSync(),
            )
            as List;
    for (final value in cases) {
      final data = value['target'];
      final target =
          data['type'] == 'cafeteria'
              ? CafeteriaFavoriteTarget.cafeteria(data['cafeteriaId'])
              : CafeteriaFavoriteTarget.menu(
                cafeteriaId: data['cafeteriaId'],
                menuName: data['menuName'],
                menuItemId: data['menuItemId'],
              );
      expect(target.key, value['key']);
    }
  });
  const curry = CafeteriaFavoriteTarget.menu(
    cafeteriaId: 'tsudanuma',
    menuName: 'カレー',
    menuItemId: 'curry',
  );
  const curryName = CafeteriaFavoriteTarget.menu(
    cafeteriaId: 'tsudanuma',
    menuName: ' カレー ',
  );
  const ramen = CafeteriaFavoriteTarget.menu(
    cafeteriaId: 'tsudanuma',
    menuName: 'ラーメン',
  );
  Map<String, dynamic> data(
    CafeteriaFavoriteTarget target, {
    String userId = 'u1',
  }) => {
    'type': target.type,
    'userId': userId,
    'menuItemId': target.menuItemId,
    'menuName': target.menuName,
    'cafeteriaId': target.cafeteriaId,
    'createdAt': Timestamp.fromDate(DateTime(2026, 9, 16)),
  };
  test(
    'repeated add is idempotent and removes all legacy duplicates',
    () async {
      final db = FakeFirebaseFirestore();
      final service = CafeteriaFavoriteService(db);
      final col = db.collection('users/u1/cafeteria_favorites');
      await col.doc('legacy-one').set(data(curry));
      await col.doc('legacy-two').set(data(curryName));
      await service.setFavorite(userId: 'u1', target: curry, enabled: true);
      await service.setFavorite(userId: 'u1', target: curry, enabled: true);
      expect((await col.get()).docs.map((d) => d.id), [curry.key]);
      await service.setFavorite(userId: 'u1', target: curry, enabled: false);
      await service.setFavorite(userId: 'u1', target: curry, enabled: false);
      expect((await col.get()).docs, isEmpty);
    },
  );
  test('name-only menus never remove another menu or campus', () async {
    final db = FakeFirebaseFirestore();
    final service = CafeteriaFavoriteService(db);
    const otherCampus = CafeteriaFavoriteTarget.menu(
      cafeteriaId: 'narashino_1f',
      menuName: 'カレー',
    );
    for (final target in [curryName, ramen, otherCampus]) {
      await service.setFavorite(userId: 'u1', target: target, enabled: true);
    }
    await service.setFavorite(userId: 'u1', target: curryName, enabled: false);
    final remaining = await service.streamFavorites('u1').first;
    expect(remaining.length, 2);
    expect(remaining.any(ramen.matches), isTrue);
    expect(remaining.any(otherCampus.matches), isTrue);
  });
  test(
    'legacy stream deduplicates equivalent IDs and names and uses real doc IDs',
    () async {
      final db = FakeFirebaseFirestore();
      final col = db.collection('users/u1/cafeteria_favorites');
      await col.doc('id').set({...data(curry), 'id': 'forged'});
      await col.doc('name').set(data(curryName));
      final result =
          await CafeteriaFavoriteService(db).streamFavorites('u1').first;
      expect(result.length, 1);
      expect(result.single.id, 'id');
    },
  );
  test(
    'counts distinguish missing initialization from a confirmed zero',
    () async {
      final db = FakeFirebaseFirestore();
      final service = CafeteriaFavoriteService(db);
      expect(await service.streamFavoriteCount(curry).first, isNull);
      await db.doc('cafeteria_favorite_stats/${curry.key}').set({'count': 0});
      expect(await service.streamFavoriteCount(curry).first, 0);
    },
  );
  test(
    'sign-out and account switch replace the active favorite stream',
    () async {
      final db = FakeFirebaseFirestore();
      final uid = StateProvider<String?>((ref) => 'u1');
      await db.doc('users/u1/cafeteria_favorites/a').set(data(curry));
      await db
          .doc('users/u2/cafeteria_favorites/b')
          .set(data(ramen, userId: 'u2'));
      final container = ProviderContainer(
        overrides: [
          cafeteriaFavoriteServiceProvider.overrideWithValue(
            CafeteriaFavoriteService(db),
          ),
          cafeteriaFavoriteUserIdProvider.overrideWith((ref) => ref.watch(uid)),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        userCafeteriaFavoritesProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);
      expect(
        (await container.read(
          userCafeteriaFavoritesProvider.future,
        )).single.menuName,
        'カレー',
      );
      container.read(uid.notifier).state = null;
      expect(
        await container.read(userCafeteriaFavoritesProvider.future),
        isEmpty,
      );
      container.read(uid.notifier).state = 'u2';
      expect(
        (await container.read(
          userCafeteriaFavoritesProvider.future,
        )).single.menuName,
        'ラーメン',
      );
    },
  );
  test(
    'shared mutation blocks double submission and can retry an error',
    () async {
      final service = _ControlledService();
      final mutation = CafeteriaFavoriteMutation(service, 'u1', curry);
      addTearDown(mutation.dispose);
      final first = mutation.setEnabled(true);
      final errorExpectation = expectLater(first, throwsStateError);
      await mutation.setEnabled(true);
      expect(service.calls, 1);
      service.pending.completeError(StateError('offline'));
      await errorExpectation;
      expect(mutation.state.hasError, isTrue);
      service.pending = Completer<void>();
      final retry = mutation.setEnabled(true);
      service.pending.complete();
      await retry;
      expect(service.calls, 2);
      expect(mutation.state.hasError, isFalse);
    },
  );
  test('invalid identity is rejected without affecting favorites', () async {
    final service = CafeteriaFavoriteService(FakeFirebaseFirestore());
    expect(
      service.setFavorite(
        userId: 'u1',
        target: const CafeteriaFavoriteTarget.menu(
          cafeteriaId: '',
          menuName: '',
        ),
        enabled: true,
      ),
      throwsArgumentError,
    );
  });
}

class _ControlledService extends CafeteriaFavoriteService {
  _ControlledService() : super(FakeFirebaseFirestore());
  int calls = 0;
  Completer<void> pending = Completer<void>();
  @override
  Future<void> setFavorite({
    required String userId,
    required CafeteriaFavoriteTarget target,
    required bool enabled,
  }) {
    calls++;
    return pending.future;
  }
}
