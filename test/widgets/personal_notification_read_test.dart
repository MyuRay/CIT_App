import 'dart:async';

import 'package:cit_app/core/providers/auth_provider.dart';
import 'package:cit_app/core/providers/notification_provider.dart';
import 'package:cit_app/models/notification/notification_model.dart';
import 'package:cit_app/screens/notification/notification_list_screen.dart';
import 'package:cit_app/services/notification/notification_read_store.dart';
import 'package:cit_app/widgets/notification/notification_card.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DelayedReadStore extends NotificationReadStore {
  DelayedReadStore() : super(FakeFirebaseFirestore());
  final saved = Completer<void>();
  @override
  Future<void> markAsRead(String id) => saved.future;
  @override
  Future<void> markAllAsRead(String userId) => saved.future;
}

void main() {
  final user = MockUser(uid: 'self', isEmailVerified: true);
  final notifications = [
    for (var i = 0; i < 2; i++)
      AppNotification(
        id: 'n$i',
        userId: 'self',
        type: NotificationType.system,
        title: '通知$i',
        message: 'お知らせ本文',
        createdAt: DateTime.now(),
      ),
  ];

  Future<void> mount(WidgetTester tester, DelayedReadStore store) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          firebaseAuthProvider.overrideWithValue(
            MockFirebaseAuth(mockUser: user, signedIn: true),
          ),
          userNotificationsProvider(
            'self',
          ).overrideWith((ref) => Stream.value(notifications)),
          notificationReadStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(home: NotificationListScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'tap clears highlight before saving and persists after a rebuild',
    (tester) async {
      final store = DelayedReadStore();
      await mount(tester, store);
      await tester.tap(find.text('通知0'));
      await tester.pump();
      expect(
        tester
            .widgetList<NotificationCard>(find.byType(NotificationCard))
            .map((c) => c.notification.isRead),
        [true, false],
      );
      final card = tester.widget<Card>(
        find.descendant(
          of: find.byType(NotificationCard).first,
          matching: find.byType(Card),
        ),
      );
      final context = tester.element(find.byType(NotificationCard).first);
      expect(card.color, Theme.of(context).colorScheme.surfaceContainerLow);
      store.saved.complete();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NotificationCard>(find.byType(NotificationCard).first)
            .notification
            .isRead,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mark all clears every highlight immediately', (tester) async {
    final store = DelayedReadStore();
    await mount(tester, store);
    await tester.tap(find.byTooltip('全て既読'));
    await tester.pump();
    expect(
      tester
          .widgetList<NotificationCard>(find.byType(NotificationCard))
          .every((c) => c.notification.isRead),
      isTrue,
    );
    store.saved.complete();
    await tester.pumpAndSettle();
    expect(find.byTooltip('既読にする'), findsNothing);
  });

  testWidgets('failed save restores unread styling and reports failure', (
    tester,
  ) async {
    final store = DelayedReadStore();
    await mount(tester, store);
    await tester.tap(find.text('通知0'));
    await tester.pump();
    store.saved.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<NotificationCard>(find.byType(NotificationCard).first)
          .notification
          .isRead,
      isFalse,
    );
    expect(find.textContaining('既読化に失敗しました'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
