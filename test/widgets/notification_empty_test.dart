import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'dart:async';
import 'package:cit_app/core/providers/auth_provider.dart';
import 'package:cit_app/core/providers/notification_provider.dart';
import 'package:cit_app/core/providers/global_notification_provider.dart';
import 'package:cit_app/models/notification/notification_model.dart';
import 'package:cit_app/screens/notification/notification_list_screen.dart';
import 'package:cit_app/screens/notification/global_notification_list_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  final user = MockUser(uid: 'self', isEmailVerified: true);
  Future<void> mount(
    WidgetTester tester,
    Stream<List<AppNotification>> Function() source,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          userNotificationStreamFactoryProvider(
            'self',
          ).overrideWithValue(source),
        ],
        child: const MaterialApp(
          home: NotificationListScreen(showAppBar: false),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'zero personal notifications display empty state instead of a spinner',
    (tester) async {
      await mount(tester, () => Stream.value([]));
      await tester.pumpAndSettle();
      expect(find.text('通知はありません'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
  testWidgets(
    'the actual personal query emits an empty snapshot and stays empty',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(user)),
            notificationFirestoreProvider.overrideWithValue(
              FakeFirebaseFirestore(),
            ),
          ],
          child: const MaterialApp(
            home: NotificationListScreen(showAppBar: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('通知はありません'), findsOneWidget);
      await tester.pump(const Duration(seconds: 13));
      expect(find.text('通知はありません'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('zero global notices display their empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          globalNotificationStreamFactoryProvider.overrideWithValue(
            () => Stream.value([]),
          ),
          unviewedNotificationCountProvider.overrideWithValue(0),
        ],
        child: const MaterialApp(home: GlobalNotificationListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('お知らせはありません'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
  testWidgets(
    'first stream error is visible and retry creates a fresh subscription',
    (tester) async {
      var subscriptions = 0;
      await mount(
        tester,
        () =>
            ++subscriptions == 1
                ? Stream.error(StateError('offline'))
                : Stream.value([]),
      );
      await tester.pumpAndSettle();
      expect(find.text('通知の読み込みに失敗しました'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.text('再読み込み'));
      await tester.pumpAndSettle();
      expect(subscriptions, 2);
      expect(find.text('通知はありません'), findsOneWidget);
    },
  );
  testWidgets(
    'a silent first subscription times out and can recover on a late empty snapshot',
    (tester) async {
      final source = StreamController<List<AppNotification>>();
      addTearDown(source.close);
      await mount(tester, () => source.stream);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 13));
      await tester.pumpAndSettle();
      expect(find.text('通知の読み込みに失敗しました'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      source.add([]);
      await tester.pumpAndSettle();
      expect(find.text('通知はありません'), findsOneWidget);
    },
  );
  testWidgets('a source that completes without a snapshot reports an error', (
    tester,
  ) async {
    await mount(tester, () => const Stream.empty());
    await tester.pumpAndSettle();
    expect(find.text('通知の読み込みに失敗しました'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
