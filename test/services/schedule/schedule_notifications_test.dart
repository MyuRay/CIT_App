import 'package:cit_app/models/assignments/assignment.dart';
import 'package:cit_app/models/schedule/lecture_period_model.dart';
import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/services/auth/session_work_guard.dart';
import 'package:cit_app/services/schedule/class_notification_payload.dart';
import 'package:cit_app/services/schedule/schedule_notification_service.dart';
import 'package:cit_app/services/schedule/schedule_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

const _lecture = ScheduleClass(
  id: 'lecture',
  subjectName: '情報科学',
  classroom: '101',
  instructor: '担当教員',
  color: '#2196F3',
);

Schedule _schedule(
  String id, {
  String userId = 'owner',
  DateTime? updatedAt,
  Map<String, Map<int, ScheduleClass?>>? timetable,
}) => Schedule(
  id: id,
  userId: userId,
  name: 'インポートした時間割',
  semester: '2100年度2期（後期）',
  timetable:
      timetable ??
      {
        'monday': {2: _lecture},
      },
  updatedAt: updatedAt,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  final pending = <int, Map<String, Object?>>{};
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  var permissionGranted = true;
  var exactAlarmAllowed = true;
  var schedulingFails = false;
  // A future Monday, so the plugin's real-clock validation also succeeds.
  final now = DateTime(2100, 1, 4, 9);
  final lecturePeriod = LecturePeriodSettings(
    fallStartDate: DateTime(2100, 1, 4),
    fallEndDate: DateTime(2100, 1, 4),
  );

  Future<int> reserve(Schedule schedule) =>
      ScheduleNotificationService.scheduleWeeklyNotifications(
        schedule,
        auth: auth,
        now: now,
        loadLecturePeriod: () async => lecturePeriod,
      );

  setUp(() {
    db = FakeFirebaseFirestore();
    ScheduleService.firestoreOverride = db;
    auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'owner'));
    SessionWorkGuard.resume();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls.clear();
    pending.clear();
    permissionGranted = true;
    exactAlarmAllowed = true;
    schedulingFails = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'canScheduleExactNotifications':
              return exactAlarmAllowed;
            case 'requestExactAlarmsPermission':
            case 'initialize':
            case 'requestNotificationsPermission':
              return true;
            case 'areNotificationsEnabled':
              return permissionGranted;
            case 'getNotificationAppLaunchDetails':
              return {'notificationLaunchedApp': false};
            case 'pendingNotificationRequests':
              return pending.values.toList();
            case 'cancel':
              pending.remove((call.arguments as Map)['id']);
              return null;
            case 'cancelAll':
              pending.clear();
              return null;
            case 'zonedSchedule':
              if (schedulingFails) throw PlatformException(code: 'unavailable');
              final arguments = Map<String, Object?>.from(
                call.arguments as Map,
              );
              pending[arguments['id']! as int] = arguments;
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    ScheduleService.firestoreOverride = null;
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('background scheduling does not open exact alarm settings without user action', () async {
    exactAlarmAllowed = false;
    final mode = await ScheduleNotificationService.ensureNotificationAccess();
    expect(mode, AndroidScheduleMode.inexactAllowWhileIdle);
    expect(calls.where((call) => call.method == 'requestExactAlarmsPermission'), isEmpty);
  });

  test(
    'task reminders reserve both deadlines and completion cancels only task alarms',
    () async {
      await reserve(_schedule('lecture'));
      final tasks = [
        Assignment(
          id: 'task',
          draft: AssignmentDraft(
            title: 'レポート',
            dueAt: now.add(const Duration(days: 2)),
            hasDueTime: true,
          ),
        ),
      ];
      expect(
        await ScheduleNotificationService.scheduleAssignmentReminders(
          'owner',
          tasks,
          enabled: true,
          auth: auth,
          now: now,
        ),
        2,
      );
      expect(pending.keys.where((id) => id < 0x10000000), hasLength(2));
      expect(pending.keys.where((id) => id >= 0x10000000), hasLength(1));
      await ScheduleNotificationService.scheduleAssignmentReminders(
        'owner',
        [],
        enabled: true,
        auth: auth,
        now: now,
      );
      expect(pending.keys.where((id) => id < 0x10000000), isEmpty);
      expect(pending.keys.where((id) => id >= 0x10000000), hasLength(1));
    },
  );

  test('five-hour lecture reminders retain the final end time', () async {
    await reserve(
      _schedule(
        'long',
        timetable: {
          'monday': {
            2: const ScheduleClass(
              id: 'long',
              subjectName: '集中講義',
              classroom: '101',
              instructor: '担当',
              color: '#2196F3',
              duration: 5,
            ),
          },
        },
      ),
    );
    final payload =
        ClassNotificationPayload.tryParse(
          pending.values.single['payload'] as String,
        )!;
    expect(payload.startDateTime, DateTime(2100, 1, 4, 10));
    expect(payload.endDateTime, DateTime(2100, 1, 4, 15));
  });

  test(
    'selected custom semester is loaded and reserved, despite legacy miss',
    () async {
      await db.doc('schedules/selected').set(_schedule('selected').toJson());
      await db
          .doc('schedules/newest')
          .set(_schedule('newest', updatedAt: now).toJson());
      expect(await ScheduleService.getScheduleByUserId('owner'), isNull);

      final selected = await ScheduleService.getSelectedScheduleByUserId(
        'owner',
        selectedScheduleId: 'selected',
      );
      expect(selected?.id, 'selected');
      expect(await reserve(selected!), 1);
      final request = pending.values.single;
      final payload = ClassNotificationPayload.tryParse(
        request['payload'] as String,
      );
      expect(payload?.scheduleId, 'selected');
      expect(payload?.subjectName, '情報科学');
      expect(payload?.classroom, '101');
      expect(payload?.startDateTime, DateTime(2100, 1, 4, 10));
      expect(request['timeZoneName'], 'Asia/Tokyo');
      expect((request['platformSpecifics'] as Map)['scheduleMode'], 'exactAllowWhileIdle');
      final expectedTime = tz.TZDateTime.from(
        DateTime(2100, 1, 4, 9, 45),
        tz.local,
      );
      expect(
        DateTime.parse(request['scheduledDateTime'] as String).hour,
        expectedTime.hour,
      );
      expect(DateTime.parse(request['scheduledDateTime'] as String).minute, 45);
    },
  );

  for (final selectedId in <String?>[null, 'deleted', 'other-owner']) {
    test(
      'missing or foreign selection $selectedId falls back to own newest',
      () async {
        await db.doc('schedules/old').set(_schedule('old').toJson());
        await db
            .doc('schedules/newest')
            .set(_schedule('newest', updatedAt: now).toJson());
        await db
            .doc('schedules/other-owner')
            .set(
              _schedule(
                'other-owner',
                userId: 'someone-else',
                updatedAt: now.add(const Duration(days: 1)),
              ).toJson(),
            );
        final selected = await ScheduleService.getSelectedScheduleByUserId(
          'owner',
          selectedScheduleId: selectedId,
        );
        expect(selected?.id, 'newest');
        expect(selected?.userId, 'owner');
      },
    );
  }

  test('no own timetable returns null without creating a timetable', () async {
    await db
        .doc('schedules/other')
        .set(_schedule('other', userId: 'other').toJson());
    expect(await ScheduleService.getSelectedScheduleByUserId('owner'), isNull);
    expect((await db.collection('schedules').get()).docs, hasLength(1));
  });

  test('past lectures and continuation cells are not reserved', () async {
    final schedule = _schedule(
      'selected',
      timetable: {
        'monday': {
          1: _lecture,
          2: _lecture,
          3: const ScheduleClass(
            id: 'continuation',
            subjectName: '情報科学',
            classroom: '101',
            instructor: '担当教員',
            color: '#2196F3',
            isStartCell: false,
          ),
        },
      },
    );
    expect(await reserve(schedule), 1);
    expect(pending, hasLength(1));
  });

  test(
    'rescheduling replaces lecture notifications and preserves other notices',
    () async {
      pending[0x10000001] = {
        'id': 0x10000001,
        'title': 'old lecture',
        'body': '',
        'payload': '',
      };
      pending[7] = {'id': 7, 'title': 'bulletin', 'body': '', 'payload': ''};
      expect(await reserve(_schedule('selected')), 1);
      expect(pending.containsKey(0x10000001), isFalse);
      expect(pending[7]?['title'], 'bulletin');
      expect(pending, hasLength(2));
    },
  );

  test(
    'denied permissions report failure before changing reservations',
    () async {
      permissionGranted = false;
      pending[0x10000001] = {
        'id': 0x10000001,
        'title': 'old',
        'body': '',
        'payload': '',
      };
      await expectLater(
        reserve(_schedule('selected')),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('通知を許可'),
          ),
        ),
      );
      expect(pending, hasLength(1));
      expect(calls.where((call) => call.method == 'zonedSchedule'), isEmpty);
    },
  );

  test(
    'native reservation errors are not reported as successful enablement',
    () async {
      schedulingFails = true;
      await expectLater(
        reserve(_schedule('selected')),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('予約できませんでした'),
          ),
        ),
      );
      expect(pending, isEmpty);
    },
  );

  test('empty timetable reports zero scheduled lectures', () async {
    expect(await reserve(_schedule('empty', timetable: {})), 0);
    expect(pending, isEmpty);
  });

  test(
    'late periods reserve correct start times and preserve the midnight end date',
    () async {
      final schedule = _schedule(
        'late',
        timetable: {
          'monday': {11: _lecture, 15: _lecture, 16: _lecture},
        },
      );
      expect(await reserve(schedule), 2);
      final payloads =
          pending.values
              .map(
                (request) =>
                    ClassNotificationPayload.tryParse(
                      request['payload'] as String,
                    )!,
              )
              .toList();
      expect(payloads.map((p) => p.period).toSet(), {11, 15});
      final last = payloads.singleWhere((p) => p.period == 15);
      expect(last.startDateTime.hour, 23);
      expect(last.endDateTime, DateTime(2100, 1, 5));
      final requestTimes =
          pending.values
              .map(
                (request) =>
                    DateTime.parse(request['scheduledDateTime'] as String),
              )
              .toList();
      expect(requestTimes.map((t) => t.hour).toSet(), {18, 22});
      expect(requestTimes.every((t) => t.minute == 45), isTrue);
    },
  );

  test(
    'another account cannot reserve or cancel the current account notifications',
    () async {
      expect(await reserve(_schedule('foreign', userId: 'someone-else')), 0);
      expect(calls, isEmpty);
    },
  );

  test(
    'signing out during period loading prevents subsequent reservations',
    () async {
      final count =
          await ScheduleNotificationService.scheduleWeeklyNotifications(
            _schedule('selected'),
            auth: auth,
            now: now,
            loadLecturePeriod: () async {
              await auth.signOut();
              return lecturePeriod;
            },
          );
      expect(count, 0);
      expect(calls.where((call) => call.method == 'zonedSchedule'), isEmpty);
    },
  );
  for (final active in [true, false]) {
    test(
      'year-specific periods control notifications: active=$active',
      () async {
        final day = DateTime(2100, 9, 1);
        final monday = day.add(
          Duration(days: (DateTime.monday - day.weekday + 7) % 7),
        );
        final settings = LecturePeriodSettings(
          periods: {
            '2100_fall': LecturePeriod(
              year: 2100,
              isFall: true,
              startDate: monday,
              endDate: monday,
              isActive: active,
            ),
            '2099_fall': LecturePeriod(
              year: 2099,
              isFall: true,
              startDate: DateTime(2099, 9, 1),
              endDate: DateTime(2100, 1, 31),
            ),
          },
        );
        final count =
            await ScheduleNotificationService.scheduleWeeklyNotifications(
              _schedule('year-specific'),
              auth: auth,
              now: monday.add(const Duration(hours: 9)),
              loadLecturePeriod: () async => settings,
            );
        expect(count, active ? 1 : 0);
        expect(pending.length, active ? 1 : 0);
      },
    );
  }
  test(
    'expired configured periods never fall back to current-week notifications',
    () async {
      final count =
          await ScheduleNotificationService.scheduleWeeklyNotifications(
            _schedule('expired'),
            auth: auth,
            now: DateTime(2101, 2, 1, 9),
            loadLecturePeriod:
                () async => LecturePeriodSettings(
                  periods: {
                    '2100_fall': LecturePeriod(
                      year: 2100,
                      isFall: true,
                      startDate: DateTime(2100, 9, 1),
                      endDate: DateTime(2101, 1, 31),
                    ),
                  },
                ),
          );
      expect(count, 0);
      expect(pending, isEmpty);
    },
  );
}
