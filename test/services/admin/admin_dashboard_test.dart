import 'dart:async';
import 'package:cit_app/core/providers/admin_provider.dart';
import 'package:cit_app/core/providers/admin_dashboard_provider.dart';
import 'package:cit_app/core/providers/auth_provider.dart';
import 'package:cit_app/models/admin/admin_destination.dart';
import 'package:cit_app/models/admin/admin_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final admin = AdminPermissions.fromJson({
    'userId': 'operator',
    'isAdmin': true,
  });

  test(
    'authentication switches and logout replace an infinite permission stream',
    () async {
      final auth = StreamController<User?>();
      final first = StreamController<AdminPermissions?>();
      final second = StreamController<AdminPermissions?>();
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => auth.stream),
          adminPermissionsProvider(
            'operator',
          ).overrideWith((ref) => first.stream),
          adminPermissionsProvider(
            'member',
          ).overrideWith((ref) => second.stream),
        ],
      );
      container.listen(currentUserAdminProvider, (_, __) {});
      auth.add(MockUser(uid: 'operator'));
      await container.pump();
      first.add(admin);
      await container.pump();
      expect(await container.read(currentUserAdminProvider.future), admin);
      auth.add(MockUser(uid: 'member'));
      await container.pump();
      second.add(null);
      await container.pump();
      expect(await container.read(currentUserAdminProvider.future), isNull);
      auth.add(null);
      await container.pump();
      expect(await container.read(currentUserAdminProvider.future), isNull);
      container.dispose();
      await auth.close();
      await first.close();
      await second.close();
    },
  );

  test(
    'permissions errors are surfaced and revocation removes admin state',
    () async {
      final permissions = StreamController<AdminPermissions?>();
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(MockUser(uid: 'operator')),
          ),
          adminPermissionsProvider(
            'operator',
          ).overrideWith((ref) => permissions.stream),
        ],
      );
      container.listen(currentUserAdminProvider, (_, __) {});
      await container.pump();
      permissions.add(admin);
      await container.pump();
      expect(
        (await container.read(currentUserAdminProvider.future))?.isAdmin,
        isTrue,
      );
      permissions.add(null);
      await container.pump();
      expect(await container.read(currentUserAdminProvider.future), isNull);
      permissions.addError(StateError('offline'));
      await container.pump();
      await expectLater(
        container.read(currentUserAdminProvider.future),
        throwsStateError,
      );
      expect(container.read(currentUserAdminProvider).hasError, isTrue);
      container.dispose();
      await permissions.close();
    },
  );

  test(
    'pending counters exclude resolved records and role lookup uses document IDs',
    () async {
      final firestore = FakeFirebaseFirestore();
      for (final queue in AdminQueue.values) {
        await firestore.collection(queue.collection).doc('pending').set({
          queue.field: queue.value,
        });
        await firestore.collection(queue.collection).doc('done').set({
          queue.field: 'resolved',
        });
      }
      await firestore.collection('admin_permissions').doc('operator').set({
        'isAdmin': true,
      });
      await firestore.collection('admin_permissions').doc('member').set({
        'isAdmin': false,
      });
      final container = ProviderContainer(
        overrides: [
          currentUserAdminProvider.overrideWith((ref) => Stream.value(admin)),
          adminDashboardFirestoreProvider.overrideWithValue(firestore),
        ],
      );
      container.listen(currentUserAdminProvider, (_, __) {});
      await container.read(currentUserAdminProvider.future);
      for (final queue in AdminQueue.values) {
        final subscription = container.listen(
          adminQueueCountProvider(queue),
          (_, __) {},
        );
        expect(await container.read(adminQueueCountProvider(queue).future), 1);
        subscription.close();
      }
      final subscription = container.listen(adminUserIdsProvider, (_, __) {});
      expect(await container.read(adminUserIdsProvider.future), {'operator'});
      subscription.close();
      container.dispose();
    },
  );

  test('non-admin counters do not initialize Firestore', () async {
    var touched = false;
    final container = ProviderContainer(
      overrides: [
        currentUserAdminProvider.overrideWith((ref) => Stream.value(null)),
        adminDashboardFirestoreProvider.overrideWith((ref) {
          touched = true;
          throw StateError('must not read');
        }),
      ],
    );
    container.listen(currentUserAdminProvider, (_, __) {});
    await container.read(currentUserAdminProvider.future);
    await expectLater(
      container.read(adminQueueCountProvider(AdminQueue.contacts).future),
      throwsStateError,
    );
    expect(touched, isFalse);
    container.dispose();
  });

  test(
    'favorite tools persist empty selections and stay separate per account',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final first = AdminFavoriteTools(preferences, 'first');
      await Future.wait(
        [
          AdminDestination.bulletin,
          AdminDestination.ads,
          AdminDestination.notifications,
        ].map(first.toggle),
      );
      expect(first.state, isEmpty);
      final reopened = AdminFavoriteTools(preferences, 'first');
      expect(reopened.state, isEmpty);
      final other = AdminFavoriteTools(preferences, 'second');
      expect(other.state, contains('ads'));
      first.dispose();
      reopened.dispose();
      other.dispose();
    },
  );

  test(
    'destination catalog includes every existing feature and operational aliases',
    () {
      expect(
        AdminDestination.values.map((tool) => tool.name).toSet().length,
        10,
      );
      expect(AdminDestination.ads.matches('スポンサー'), isTrue);
      expect(AdminDestination.bus.matches('時刻表'), isTrue);
      expect(AdminDestination.ads.matches('時刻表'), isFalse);
    },
  );
}
