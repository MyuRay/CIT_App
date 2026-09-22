import 'package:cit_app/models/bus/bus_model.dart';
import 'package:cit_app/services/widget/home_widget_payloads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 9, 22, 9);
  final expired = BusOperationPeriod(
    id: 'old',
    name: '通常運行',
    isActive: true,
    startDate: DateTime.utc(2025, 8, 1),
    endDate: DateTime.utc(2026, 9, 8),
  );
  BusRoute route({bool active = true, bool dates = true}) => BusRoute.fromJson({
    'id': 'fall',
    'name': '【後期】津田沼→新習志野',
    'isActive': active,
    if (dates) 'startDate': Timestamp.fromDate(DateTime.utc(2026, 9, 17, 15)),
    if (dates) 'endDate': Timestamp.fromDate(DateTime.utc(2026, 12, 21, 15)),
    'timeEntries': [
      {'id': 'bus', 'hour': 19, 'minute': 0, 'isActive': true},
    ],
  });
  BusInformation info(BusRoute value, {List<BusOperationPeriod>? periods}) =>
      BusInformation(
        id: 'main',
        title: '学バス',
        description: '',
        routes: [value],
        operationPeriods: periods ?? [expired],
        lastUpdated: now,
        updatedBy: '',
      );

  test('admin route dates override an expired legacy global period', () {
    expect(info(route()).operatingRoutesAt(now).single.id, 'fall');
  });
  test('route OFF is respected even during its configured period', () {
    expect(info(route(active: false)).operatingRoutesAt(now), isEmpty);
  });
  test('route dates include exactly the start and end dates in Japan', () {
    final data = info(route());
    expect(data.operatingRoutesAt(DateTime.utc(2026, 9, 17, 14, 59)), isEmpty);
    expect(data.operatingRoutesAt(DateTime.utc(2026, 9, 17, 15)), hasLength(1));
    expect(
      data.operatingRoutesAt(DateTime.utc(2026, 12, 22, 14, 59)),
      hasLength(1),
    );
    expect(data.operatingRoutesAt(DateTime.utc(2026, 12, 22, 15)), isEmpty);
  });
  test(
    'undated legacy routes retain the global operation-period restriction',
    () {
      expect(info(route(dates: false)).operatingRoutesAt(now), isEmpty);
      expect(
        info(route(dates: false), periods: []).operatingRoutesAt(now),
        hasLength(1),
      );
    },
  );
  test('editing a route preserves configured dates', () {
    final original = route();
    final saved = BusRoute.fromJson(
      original.copyWith(isActive: false).toJson(),
    );
    expect(saved.startDate, original.startDate);
    expect(saved.endDate, original.endDate);
    expect(saved.isActive, isFalse);
  });
  test('native home-widget payload uses the same date eligibility', () {
    expect(
      HomeWidgetPayloads.bus(info(route()), now: now)['routes'],
      hasLength(1),
    );
    expect(
      HomeWidgetPayloads.bus(info(route()), now: DateTime.utc(2027))['routes'],
      isEmpty,
    );
  });
  test('legacy status switch is used only if isActive is absent', () {
    expect(BusRoute.fromJson({'status': 'suspended'}).isActive, isFalse);
    expect(
      BusRoute.fromJson({'status': 'suspended', 'isActive': true}).isActive,
      isTrue,
    );
  });
}
