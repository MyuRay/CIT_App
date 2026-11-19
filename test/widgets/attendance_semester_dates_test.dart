import 'package:cit_app/models/schedule/lecture_period_model.dart';
import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/screens/schedule/attendance_management_screen.dart';
import 'package:cit_app/services/schedule/attendance_service.dart';
import 'package:cit_app/services/schedule/lecture_period_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  setUp(() async {
    db = FakeFirebaseFirestore();
    AttendanceService.firestoreOverride = db;
    LecturePeriodService.firestoreOverride = db;
    await db
        .doc('app_settings/lecture_period')
        .set(
          LecturePeriodSettings(
            springStartDate: DateTime(2026, 4, 8),
            springEndDate: DateTime(2026, 7, 31),
            fallStartDate: DateTime(2026, 9, 17),
            fallEndDate: DateTime(2027, 1, 31),
          ).toMap(),
        );
  });
  tearDown(() {
    AttendanceService.firestoreOverride = null;
    LecturePeriodService.firestoreOverride = null;
  });

  Future<void> mount(
    WidgetTester tester,
    String term, {
    int period = 11,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceManagementScreen(
          schedule: Schedule(
            id: 'week',
            userId: 'owner',
            semester: term,
            timeSlots: DefaultTimeSlots.forPeriodCount(15),
            timetable: {
              'monday': {
                period: const ScheduleClass(
                  id: 'lesson',
                  subjectName: '夜間演習',
                  classroom: '',
                  instructor: '',
                  color: '#2196F3',
                ),
              },
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('spring and fall show different actual class dates', (
    tester,
  ) async {
    await mount(tester, '2026年度前期');
    expect(find.text('4/13'), findsOneWidget);
    expect(find.text('9/21'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await mount(tester, '2026年度後期');
    expect(find.text('9/21'), findsOneWidget);
    expect(find.text('4/13'), findsNothing);
    await tester.tap(find.text('9/21'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2026年度後期\n2026/09/21'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'missing selected semester start never falls back to today or spring',
    (tester) async {
      await db
          .doc('app_settings/lecture_period')
          .set(
            LecturePeriodSettings(
              springStartDate: DateTime(2026, 4, 8),
            ).toMap(),
          );
      await mount(tester, '2026年度後期');
      expect(find.text('2026年度後期の講義開始日が設定されていません'), findsOneWidget);
      expect(find.byType(DataTable), findsNothing);
    },
  );

  testWidgets(
    'large text dates and fifteenth-period attendance do not overflow',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await mount(tester, '2026年度後期', period: 15);
      expect(find.textContaining('月15限'), findsOneWidget);
      expect(find.text('9/21'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
