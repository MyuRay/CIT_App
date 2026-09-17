import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cit_app/core/config/app_router.dart';
import 'package:cit_app/core/providers/auth_provider.dart';
import 'package:cit_app/core/providers/email_registration_provider.dart';
import 'package:cit_app/core/providers/legal_consent_provider.dart';
import 'package:cit_app/core/constants/app_constants.dart';
import 'package:cit_app/core/providers/settings_provider.dart';
import 'package:cit_app/core/services/analytics_service.dart';
import 'package:cit_app/screens/auth/signup_screen.dart';
import 'package:cit_app/services/auth/email_registration.dart';
import 'package:cit_app/services/auth/tab_tutorial_progress.dart';
import 'package:cit_app/services/auth/legal_consent_service.dart';
import 'package:cit_app/services/auth/verified_profile.dart';
import 'package:cit_app/screens/legal/community_legal_update_consent_gate.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/registration_fakes.dart';
import '../support/theme_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  setUpAll(() async => themes = await loadTestThemes());
  final boundary = GlobalKey();
  late RegistrationTestAuth auth;
  late ProviderContainer container;
  late GoRouter router;

  Future<void> mount(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    bool complete = false,
    double width = 390,
    double scale = 1,
    bool realRouter = false,
    String? pendingEmail = 'student@chibatech.ac.jp',
    Future<void> Function()? saveProfile,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    SharedPreferences.setMockInitialValues({
      if (pendingEmail != null) registrationEmailKey: pendingEmail,
      'tab_tutorial_seen_version': TabTutorialProgress.currentVersion,
    });
    final preferences = await SharedPreferences.getInstance();
    final firestore = FakeFirebaseFirestore();
    auth = RegistrationTestAuth(RegistrationTestUser());
    final service = EmailRegistrationService(
      auth,
      preferences,
      saveProfile: (user) async {
        await saveProfile?.call();
        await ensureVerifiedProfile(
          firestore,
          user,
          acceptedLegalConsentVersion: AppConstants.currentLegalConsentVersion,
        );
      },
    );
    final location =
        complete
            ? Uri(
              path: '/signup/complete',
              queryParameters: {'link': registrationTestLink},
            ).toString()
            : '/signup';
    container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        sharedPreferencesProvider.overrideWithValue(preferences),
        emailRegistrationServiceProvider.overrideWithValue(service),
        legalConsentServiceProvider.overrideWithValue(
          LegalConsentService(firestore, preferences),
        ),
        firebaseAnalyticsObserverProvider.overrideWithValue(
          NavigatorObserver(),
        ),
        initialRouteFromWidgetProvider.overrideWithValue(location),
      ],
    );
    addTearDown(container.dispose);
    router =
        realRouter
            ? container.read(routerProvider)
            : GoRouter(
              initialLocation: location,
              routes: [
                GoRoute(
                  path: '/signup',
                  builder: (_, __) => const SignUpScreen(),
                ),
                GoRoute(
                  path: '/signup/complete',
                  builder:
                      (_, state) => SignUpScreen(
                        completing: true,
                        emailLink: state.uri.queryParameters['link'],
                      ),
                ),
                GoRoute(
                  path: '/home',
                  builder:
                      (_, __) => const Scaffold(
                        body: CommunityLegalUpdateConsentGate(
                          child: Text('登録完了'),
                        ),
                      ),
                ),
                GoRoute(
                  path: '/login',
                  builder: (_, __) => const Scaffold(body: Text('ログイン')),
                ),
                GoRoute(
                  path: '/terms',
                  builder: (_, __) => const Scaffold(body: Text('規約')),
                ),
                GoRoute(
                  path: '/privacy',
                  builder: (_, __) => const Scaffold(body: Text('ポリシー')),
                ),
              ],
            );
    if (!realRouter) addTearDown(router.dispose);
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: themes[brightness],
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(bottom: 48),
                ),
                child: RepaintBoundary(key: boundary, child: child!),
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (themePreviewDirectory.isEmpty) return;
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/icons/app_launcher_icon.png'),
        boundary.currentContext!,
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$themePreviewDirectory/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> fillCompletion(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(1), '学生さん');
    await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
    await tester.enterText(find.byType(TextFormField).at(3), 'Password123');
    for (var index = 0; index < 2; index++) {
      await tester.ensureVisible(find.byType(Checkbox).at(index));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).at(index));
      await tester.pump();
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(index)).value,
        isTrue,
      );
    }
    await tester.ensureVisible(find.text('メールを認証して登録を完了'));
    await tester.pumpAndSettle();
  }

  for (final mode in Brightness.values) {
    testWidgets('${mode.name} request and completion previews', (tester) async {
      await mount(tester, brightness: mode);
      expect(find.byType(TextFormField), findsOneWidget);
      await capture(tester, 'request-${mode.name}');
      await mount(tester, brightness: mode, complete: true);
      expect(find.byType(TextFormField), findsNWidgets(4));
      await capture(tester, 'complete-top-${mode.name}');
      await tester.ensureVisible(find.text('メールを認証して登録を完了'));
      await tester.pumpAndSettle();
      await capture(tester, 'complete-bottom-${mode.name}');
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      '${mode.name} request and completion fit 320px at 200% above system buttons',
      (tester) async {
        await mount(tester, brightness: mode, width: 320, scale: 2);
        await tester.ensureVisible(find.text('確認メールを再送'));
        expect(tester.takeException(), isNull);
        await mount(
          tester,
          brightness: mode,
          width: 320,
          scale: 2,
          complete: true,
        );
        await fillCompletion(tester);
        expect(find.text('メールを認証して登録を完了').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'email request leaves Auth empty, starts cooldown and offers paste fallback',
    (tester) async {
      await mount(tester);
      await tester.ensureVisible(find.text('確認メールを再送'));
      await tester.tap(find.text('確認メールを再送'));
      await tester.pumpAndSettle();
      expect(auth.sends, 1);
      expect(auth.currentUser, isNull);
      expect(auth.unverifiedCreates, 0);
      expect(find.textContaining('再送まで'), findsOneWidget);
      await tester.ensureVisible(find.text('リンクからアプリが開かない場合'));
      await tester.tap(find.text('リンクからアプリが開かない場合'));
      await tester.pumpAndSettle();
      expect(find.text('貼り付けたリンクで続ける'), findsOneWidget);
    },
  );
  testWidgets(
    'completion requires consent and reaches home only after verified persistence',
    (tester) async {
      await mount(tester, complete: true);
      expect(auth.currentUser, isNull);
      await fillCompletion(tester);
      await tester.tap(find.text('メールを認証して登録を完了'));
      await tester.pumpAndSettle();
      expect(auth.currentUser!.emailVerified, isTrue);
      expect(auth.unverifiedCreates, 0);
      expect(find.text('登録完了'), findsOneWidget);
      expect(find.text('同意して利用を開始する'), findsNothing);
      expect(container.read(hasAcceptedCurrentLegalConsentProvider), isTrue);
      expect(
        TabTutorialProgress(
          container.read(sharedPreferencesProvider),
        ).shouldShow(auth.currentUser!.uid),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'completion locks the stored recipient without disabling readability',
    (tester) async {
      await mount(tester, complete: true);
      final email = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(email.controller!.text, 'student@chibatech.ac.jp');
      expect(email.enabled, isTrue);
      final editable = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      expect(editable.readOnly, isTrue);
      expect(
        find.descendant(
          of: find.byType(TextFormField).first,
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(TextFormField).first);
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(email.controller!.text, 'student@chibatech.ac.jp');
    },
  );
  testWidgets(
    'another device asks for the recipient once before locking the form',
    (tester) async {
      await mount(tester, complete: true, pendingEmail: null);
      expect(find.byType(TextFormField), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField),
        'student@chibatech.ac.jp',
      );
      await tester.ensureVisible(find.text('このメールアドレスで続ける'));
      await tester.tap(find.text('このメールアドレスで続ける'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(
        tester.widget<EditableText>(find.byType(EditableText).first).readOnly,
        isTrue,
      );
      expect(auth.currentUser, isNull);
      await fillCompletion(tester);
      await tester.tap(find.text('メールを認証して登録を完了'));
      await tester.pumpAndSettle();
      expect(find.text('登録完了'), findsOneWidget);
    },
  );
  testWidgets(
    'production router keeps registration form through token events and a failed save',
    (tester) async {
      final persistence = Completer<void>();
      await mount(
        tester,
        complete: true,
        realRouter: true,
        saveProfile: () => persistence.future,
      );
      final initialRouter = router;
      await fillCompletion(tester);
      await tester.tap(find.text('メールを認証して登録を完了'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(auth.currentUser!.emailVerified, isTrue);
      expect(container.read(routerProvider), same(initialRouter));
      expect(
        router.routeInformationProvider.value.uri.path,
        '/signup/complete',
      );
      expect(container.read(registrationCompletingProvider), isTrue);
      persistence.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/signup/complete',
      );
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(container.read(registrationCompletingProvider), isFalse);
      final preferences = container.read(sharedPreferencesProvider);
      expect(hasCachedLegalConsent(preferences, auth.testUser.uid), isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
