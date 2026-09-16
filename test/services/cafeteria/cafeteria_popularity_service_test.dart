import 'dart:async';

import 'package:cit_app/services/cafeteria/cafeteria_popularity_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'reads more than one batch and keeps missing counts distinct from zero',
    () async {
      final db = FakeFirebaseFirestore();
      final keys = [for (var i = 0; i < 42; i++) 'menu_$i'];
      for (var i = 0; i < 40; i++) {
        await db.collection('cafeteria_favorite_stats').doc(keys[i]).set({
          'count': i,
        });
      }
      await db.collection('cafeteria_favorite_stats').doc(keys[40]).set({
        'count': -1,
      });
      await db.collection('cafeteria_favorite_stats').doc('other_campus').set({
        'count': 999,
      });
      final counts =
          await CafeteriaPopularityService(
            db,
          ).watchCounts([...keys, keys.first]).first;
      expect(counts.length, 40);
      expect(counts[keys.first], 0);
      expect(counts[keys[39]], 39);
      expect(counts.containsKey(keys[40]), isFalse);
      expect(counts.containsKey(keys[41]), isFalse);
      expect(counts.containsKey('other_campus'), isFalse);
    },
  );

  test(
    'count changes and deleted aggregates update the shared ranking',
    () async {
      final db = FakeFirebaseFirestore();
      final ref = db.collection('cafeteria_favorite_stats').doc('menu');
      await ref.set({'count': 4});
      final iterator = StreamIterator(
        CafeteriaPopularityService(db).watchCounts(['menu']),
      );
      try {
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, {'menu': 4});
        await ref.update({'count': 12});
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, {'menu': 12});
        await ref.delete();
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, isEmpty);
      } finally {
        await iterator.cancel();
      }
    },
  );

  test('no menus needs no aggregate query', () async {
    final db = FakeFirebaseFirestore();
    expect(await CafeteriaPopularityService(db).watchCounts([]).first, isEmpty);
  });
}
