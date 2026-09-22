import 'dart:async';

import 'package:cit_app/models/bus/bus_model.dart';
import 'package:cit_app/services/bus/bus_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'child-only switches and timetable edits reach an existing listener',
    () async {
      final firestore = FakeFirebaseFirestore();
      final main = firestore.doc('bus_information/main');
      final route = main.collection('bus_routes').doc('route');
      final period = main.collection('operation_periods').doc('period');
      await main.set({'title': '学バス'});
      await route.set({
        'name': '津田沼 → 新習志野',
        'isActive': false,
        'timeEntries': [
          {'id': 'departure', 'hour': 10, 'minute': 0, 'isActive': false},
        ],
      });
      await period.set(
        BusOperationPeriod(
          id: 'period',
          name: '講義期間',
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 1)),
          isActive: false,
        ).toJson(),
      );
      final events = StreamIterator(
        BusService(firestore: firestore).watchBusInformation(),
      );
      addTearDown(events.cancel);
      Future<BusInformation> next() async {
        expect(
          await events.moveNext().timeout(const Duration(seconds: 5)),
          isTrue,
        );
        return events.current!;
      }

      expect((await next()).activeRoutes, isEmpty);
      await route.update({'isActive': true});
      expect((await next()).activeRoutes.single.id, 'route');
      await period.update({'isActive': true});
      expect((await next()).isCurrentlyOperating, isTrue);
      await route.update({
        'timeEntries': [
          {'id': 'departure', 'hour': 11, 'minute': 30, 'isActive': true},
        ],
      });
      final departure = (await next()).activeRoutes.single.timeEntries.single;
      expect(departure.isActive, isTrue);
      expect(departure.hour, 11);
      expect(departure.minute, 30);
      await route.update({'isActive': false});
      expect((await next()).activeRoutes, isEmpty);
      await period.update({'isActive': false});
      expect((await next()).isCurrentlyOperating, isFalse);
      await route.delete();
      expect((await next()).routes, isEmpty);

      // A newly registered route must reach an already-open home screen,
      // and its own dates must override a disabled legacy global period.
      final newRoute = main.collection('bus_routes').doc('new-season');
      await newRoute.set({
        'name': '新ダイヤ',
        'isActive': true,
        'startDate': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        'endDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
        'timeEntries': [
          {'id': 'new', 'hour': 19, 'minute': 0, 'isActive': true},
        ],
      });
      expect((await next()).operatingRoutes.single.id, 'new-season');
      await newRoute.update({
        'startDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 10)),
        ),
      });
      expect((await next()).operatingRoutes, isEmpty);
      expect((await main.get()).data(), {'title': '学バス'});
    },
  );
}
