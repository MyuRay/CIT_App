import 'package:cit_app/models/bus/bus_timetable_draft.dart';
import 'package:cit_app/services/bus/bus_timetable_admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/bus_timetable_fixtures.dart';

// fake_cloud_firestore 3.1.0's transaction.set drops SetOptions. Use its
// WriteBatch implementation so these tests exercise merge semantics faithfully.
class _BusFirestore extends FakeFirebaseFirestore {
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final writes = batch();
    final result = await handler(_BusTransaction(writes));
    await writes.commit();
    return result;
  }
}

class _BusTransaction implements Transaction {
  _BusTransaction(this.writes);
  final WriteBatch writes;
  bool hasWrites = false;

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(DocumentReference<T> ref) {
    if (hasWrites) throw StateError('Reads must precede writes');
    return ref.get();
  }

  @override
  Transaction update(DocumentReference ref, Map<String, dynamic> data) {
    hasWrites = true;
    writes.update(ref, data);
    return this;
  }

  @override
  Transaction set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    hasWrites = true;
    writes.set(ref, data, options);
    return this;
  }

  @override
  Transaction delete(DocumentReference ref) {
    hasWrites = true;
    writes.delete(ref);
    return this;
  }
}

void main() {
  test(
    'paste accepts times, full width, compact input and spreadsheet hour rows',
    () {
      expect(
        parseBusTimeList('８：１０　８３０, 09:00\n10時 00 20\n11\t05\t35\n12: 10 40'),
        [490, 510, 540, 600, 620, 665, 695, 730, 760],
      );
    },
  );

  test(
    'invalid tokens and ranges fail the whole input with the line number',
    () {
      for (final input in [
        '08:10\n9:60',
        '24:00',
        '08:10 missing',
        '8 30',
        '',
      ]) {
        expect(() => parseBusTimeList(input), throwsFormatException);
      }
      expect(
        () => parseBusTimeList('08:10\nbad'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'line',
            contains('2行目'),
          ),
        ),
      );
      expect(() => parseBusTime(''), throwsFormatException);
    },
  );

  test(
    'interval generator includes reachable end and rejects overnight or zero interval',
    () {
      expect(generateBusTimes('08:00', '09:00', '20'), [480, 500, 520, 540]);
      expect(generateBusTimes('08:00', '08:00', '15'), [480]);
      expect(generateBusTimes('08:00', '08:35', '20'), [480, 500]);
      expect(
        () => generateBusTimes('09:00', '08:00', '15'),
        throwsFormatException,
      );
      expect(
        () => generateBusTimes('08:00', '09:00', '0'),
        throwsFormatException,
      );
    },
  );

  test(
    'append deduplicates but keeps existing notes, inactive entries and extra fields',
    () {
      final route = busEditorRoute();
      final next = mergeBusDepartures(route.entries, [
        newBusDeparture(510, 'weekday', note: '置換しない'),
        newBusDeparture(540, 'weekday'),
        newBusDeparture(540, 'weekday'),
      ], 'weekday');
      expect(next, hasLength(3));
      expect(
        next.firstWhere((e) => e['id'] == 'existing'),
        route.entries.first,
      );
      expect(next.firstWhere((e) => e['id'] == 'saturday'), route.entries.last);
      expect(route.entries, hasLength(2));
    },
  );

  test(
    'replace changes only the selected day and copied entries have new ids',
    () {
      final route = busEditorRoute();
      final copies =
          busCopyRoute().entries
              .map(
                (entry) => newBusDeparture(
                  busDepartureMinute(entry),
                  'saturday',
                  note: entry['note'] as String?,
                  active: entry['isActive'] as bool,
                ),
              )
              .toList();
      final next = mergeBusDepartures(
        route.entries,
        copies,
        'saturday',
        replace: true,
      );
      expect(
        next.where((e) => busDepartureDay(e) == 'weekday').single,
        route.entries.first,
      );
      final saturday =
          next.where((e) => busDepartureDay(e) == 'saturday').toList();
      expect(saturday, hasLength(2));
      expect(saturday.last['isActive'], false);
      expect(saturday.last['note'], '運休の見本');
      expect(saturday.last['id'], isNot('source2'));
    },
  );

  test(
    'transaction retains route metadata and publishes the parent refresh together',
    () async {
      final db = _BusFirestore();
      final route = busEditorRoute();
      final ref = db.doc('bus_information/main/bus_routes/${route.id}');
      await db.doc('bus_information/main').set({'title': '学バス'});
      await ref.set({
        'name': route.name,
        'color': '#123456',
        'timeEntries': route.entries,
      });
      final updated = mergeBusDepartures(route.entries, [
        newBusDeparture(600, 'weekday'),
      ], 'weekday');
      await BusTimetableAdminService(db).save(
        routeId: route.id,
        original: route.entries,
        updated: updated,
        updatedBy: 'admin',
      );
      final stored = (await ref.get()).data()!;
      expect(stored['color'], '#123456');
      expect(stored['timeEntries'], updated);
      expect(stored['updatedBy'], 'admin');
      final parent = (await db.doc('bus_information/main').get()).data()!;
      expect(parent['title'], '学バス');
      expect(parent['lastUpdated'], isA<Timestamp>());
    },
  );

  test(
    'stale edit and deleted route do not overwrite newer data or recreate a route',
    () async {
      final db = _BusFirestore();
      final route = busEditorRoute();
      final ref = db.doc('bus_information/main/bus_routes/${route.id}');
      final newer = [...route.entries, newBusDeparture(600, 'weekday')];
      await ref.set({'timeEntries': newer});
      final service = BusTimetableAdminService(db);
      await expectLater(
        service.save(
          routeId: route.id,
          original: route.entries,
          updated: [],
          updatedBy: 'admin',
        ),
        throwsA(isA<BusTimetableConflict>()),
      );
      expect((await ref.get()).data()!['timeEntries'], newer);
      expect((await db.doc('bus_information/main').get()).exists, false);
      await ref.delete();
      await expectLater(
        service.save(
          routeId: route.id,
          original: route.entries,
          updated: [],
          updatedBy: 'admin',
        ),
        throwsStateError,
      );
      expect((await ref.get()).exists, false);
    },
  );

  test('invalid departure is rejected before storage writes', () async {
    final db = _BusFirestore();
    await expectLater(
      BusTimetableAdminService(db).save(
        routeId: 'bad',
        original: [],
        updated: [
          {'hour': 25, 'minute': 0, 'dayType': 'weekday'},
        ],
        updatedBy: 'admin',
      ),
      throwsFormatException,
    );
    expect((await db.doc('bus_information/main').get()).exists, false);
  });
}
