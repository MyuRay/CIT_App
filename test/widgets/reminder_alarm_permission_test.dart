import 'dart:async';

import 'package:cit_app/widgets/notification/reminder_alarm_permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <String>[];
  var allowed = false;
  var grantInSettings = true;
  var settingsFails = false;
  Completer<bool>? settingsResult;
  bool? result;

  void alarmTest(
    String description,
    WidgetTesterCallback callback, {
    TargetPlatform platform = TargetPlatform.android,
  }) {
    testWidgets(
      description,
      callback,
      variant: TargetPlatformVariant({platform}),
    );
  }

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls.clear();
    allowed = false;
    grantInSettings = true;
    settingsFails = false;
    settingsResult = null;
    result = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'canScheduleExactNotifications') return allowed;
          if (call.method == 'requestExactAlarmsPermission') {
            if (settingsFails) {
              throw PlatformException(code: 'settings_unavailable');
            }
            allowed =
                await (settingsResult?.future ?? Future.value(grantInSettings));
            return allowed;
          }
          throw StateError('Unexpected notification call: ${call.method}');
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => FilledButton(
                  onPressed: () async {
                    result = await ensureReminderAlarmPermission(context);
                  },
                  child: const Text('通知をオン'),
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('通知をオン'));
    await tester.pumpAndSettle();
  }

  alarmTest('already allowed: no popup or settings request', (tester) async {
    allowed = true;
    await mount(tester);
    expect(result, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    expect(calls, ['canScheduleExactNotifications']);
  });

  alarmTest('explains missing access before opening the app alarm settings', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('アラームとリマインダーの設定'), findsOneWidget);
    expect(result, isNull);
    expect(calls, ['canScheduleExactNotifications']);
    await tester.tap(find.text('設定を開く'));
    await tester.pumpAndSettle();
    expect(calls, [
      'canScheduleExactNotifications',
      'requestExactAlarmsPermission',
    ]);
    expect(result, isTrue);
  });

  alarmTest('cancel keeps reminders off and never opens settings', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(calls, ['canScheduleExactNotifications']);
  });

  alarmTest('dismissing the popup keeps reminders off', (tester) async {
    await mount(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(calls, ['canScheduleExactNotifications']);
  });

  alarmTest(
    'returning without permission keeps reminders off with an explanation',
    (tester) async {
      grantInSettings = false;
      await mount(tester);
      await tester.tap(find.text('設定を開く'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(find.textContaining('通知をオンにできませんでした'), findsOneWidget);
    },
  );

  alarmTest('cannot enable reminders until the settings result arrives', (
    tester,
  ) async {
    settingsResult = Completer<bool>();
    await mount(tester);
    await tester.tap(find.text('設定を開く'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    settingsResult!.complete(true);
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  alarmTest(
    'unmounting while settings is open does not enable reminders or throw',
    (tester) async {
      settingsResult = Completer<bool>();
      await mount(tester);
      await tester.tap(find.text('設定を開く'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      settingsResult!.complete(true);
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  alarmTest(
    'a settings launch failure is recoverable and leaves reminders off',
    (tester) async {
      settingsFails = true;
      await mount(tester);
      await tester.tap(find.text('設定を開く'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(find.textContaining('設定を確認できませんでした'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  alarmTest('iOS does not query or show Android alarm permissions', (
    tester,
  ) async {
    await mount(tester);
    expect(result, isTrue);
    expect(calls, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
  }, platform: TargetPlatform.iOS);
}
