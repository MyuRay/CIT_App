import 'dart:async';
import 'package:cit_app/core/constants/app_constants.dart';
import 'package:cit_app/core/providers/auth_provider.dart';
import 'package:cit_app/core/providers/legal_consent_provider.dart';
import 'package:cit_app/core/providers/settings_provider.dart';
import 'package:cit_app/screens/legal/community_legal_update_consent_gate.dart';
import 'package:cit_app/services/auth/legal_consent_service.dart';
import 'package:cit_app/services/auth/verified_profile.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ControlledConsentService extends LegalConsentService {
  ControlledConsentService(super.firestore, super.preferences);
  Future<void>? lookup;
  bool failLookup = false, failSave = false;
  @override
  Future<bool> hasAccepted(User user) async {
    await lookup;
    if (failLookup) throw StateError('offline');
    return super.hasAccepted(user);
  }

  @override
  Future<void> accept(User user) async {
    if (failSave) throw StateError('offline');
    return super.accept(user);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final user = MockUser(
    uid: 'old-user',
    email: 'old@chibatech.ac.jp',
    isEmailVerified: true,
  );
  late FakeFirebaseFirestore db;
  late SharedPreferences preferences;
  late ControlledConsentService service;
  late ProviderContainer container;
  setUp(() async {
    db = FakeFirebaseFirestore();
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    service = ControlledConsentService(db, preferences);
    container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(
          MockFirebaseAuth(mockUser: user, signedIn: true),
        ),
        authStateProvider.overrideWith((ref) => Stream.value(user)),
        sharedPreferencesProvider.overrideWithValue(preferences),
        legalConsentServiceProvider.overrideWithValue(service),
      ],
    );
  });
  tearDown(() => container.dispose());

  Future<void> mount(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(bottom: 48),
                ),
                child: child!,
              ),
          home: const Scaffold(
            body: CommunityLegalUpdateConsentGate(child: Text('ホーム')),
          ),
        ),
      ),
    );
  }

  Future<void> agree(WidgetTester tester) async {
    for (var i = 0; i < 2; i++) {
      await tester.ensureVisible(find.byType(Checkbox).at(i));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).at(i));
      await tester.pump();
    }
    await tester.ensureVisible(find.text('同意して利用を開始する'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('同意して利用を開始する'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'existing unconsented account sees notice once and stores agreement',
    (tester) async {
      await ensureVerifiedProfile(db, user);
      await mount(tester, scale: 2);
      await tester.pumpAndSettle();
      expect(find.text('同意して利用を開始する'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, '同意して利用を開始する'),
            )
            .onPressed,
        isNull,
      );
      await agree(tester);
      expect(find.text('同意して利用を開始する'), findsNothing);
      expect(hasCachedLegalConsent(preferences, user.uid), isTrue);
      expect(
        (await db.doc('users/${user.uid}').get())
            .data()!['legalConsentVersion'],
        AppConstants.currentLegalConsentVersion,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new account on another device never flashes the update notice during lookup',
    (tester) async {
      await ensureVerifiedProfile(
        db,
        user,
        acceptedLegalConsentVersion: AppConstants.currentLegalConsentVersion,
      );
      final lookup = Completer<void>();
      service.lookup = lookup.future;
      await mount(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('同意状況を確認しています…'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
      lookup.complete();
      await tester.pumpAndSettle();
      expect(find.text('同意して利用を開始する'), findsNothing);
      expect(container.read(hasAcceptedCurrentLegalConsentProvider), isTrue);
    },
  );

  testWidgets(
    'lookup failure offers retry without treating the user as unconsented',
    (tester) async {
      service.failLookup = true;
      await mount(tester);
      await tester.pumpAndSettle();
      expect(find.text('再試行'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
      service.failLookup = false;
      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();
      expect(find.text('同意して利用を開始する'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed acceptance keeps checkboxes and can retry without dismissing notice',
    (tester) async {
      service.failSave = true;
      await mount(tester);
      await tester.pumpAndSettle();
      await agree(tester);
      expect(find.textContaining('同意を保存できませんでした'), findsOneWidget);
      expect(hasCachedLegalConsent(preferences, user.uid), isFalse);
      for (final tile in tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      )) {
        expect(tile.value, isTrue);
      }
      service.failSave = false;
      await tester.ensureVisible(find.text('同意して利用を開始する'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('同意して利用を開始する'));
      await tester.pumpAndSettle();
      expect(find.text('同意して利用を開始する'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('switching accounts cannot reuse the previous account consent', (
    tester,
  ) async {
    await service.accept(user);
    final users = StreamController<User?>();
    addTearDown(users.close);
    container.updateOverrides([
      firebaseAuthProvider.overrideWithValue(
        MockFirebaseAuth(mockUser: user, signedIn: true),
      ),
      authStateProvider.overrideWith((ref) => users.stream),
      sharedPreferencesProvider.overrideWithValue(preferences),
      legalConsentServiceProvider.overrideWithValue(service),
    ]);
    await mount(tester);
    users.add(user);
    await tester.pumpAndSettle();
    expect(container.read(hasAcceptedCurrentLegalConsentProvider), isTrue);
    final other = MockUser(
      uid: 'other',
      email: 'other@chibatech.ac.jp',
      isEmailVerified: true,
    );
    users.add(other);
    await tester.pumpAndSettle();
    expect(find.text('同意して利用を開始する'), findsOneWidget);
    expect(container.read(hasAcceptedCurrentLegalConsentProvider), isFalse);
  });
}
