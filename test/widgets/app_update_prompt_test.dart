import 'dart:async';

import 'package:cit_app/core/services/app_update_service.dart';
import 'package:cit_app/widgets/common/app_update_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final update = AppUpdateInfo(
  currentVersion: '2.3.2',
  latestVersion: '2.3.3',
  storeUrl: Uri.parse(
    'https://play.google.com/store/apps/details?id=jp.ac.chibakoudai.citapp',
  ),
);

void main() {
  Future<void> finishStartup(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Widget app({
    required GlobalKey<NavigatorState> navigator,
    required AppUpdateNavigatorObserver observer,
    required Future<AppUpdateInfo?> Function() check,
    Future<bool> Function(Uri)? openStore,
    VoidCallback? onNoUpdate,
    ThemeData? theme,
    double textScale = 1,
  }) => MaterialApp(
    navigatorKey: navigator,
    navigatorObservers: [observer],
    theme: theme,
    builder:
        (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: AppUpdatePromptHost(
            navigatorKey: navigator,
            observer: observer,
            checkForUpdate: check,
            onNoUpdate: onNoUpdate,
            openStore: openStore ?? (_) async => true,
            child: child!,
          ),
        ),
    home: const Scaffold(body: Text('ホーム')),
  );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('shows once, later keeps app usable, resume does not repeat', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    final observer = AppUpdateNavigatorObserver();
    var checks = 0;
    await tester.pumpWidget(
      app(
        navigator: navigator,
        observer: observer,
        check: () async {
          checks++;
          return update;
        },
      ),
    );
    await finishStartup(tester);
    expect(find.text('アップデートのお知らせ'), findsOneWidget);
    await tester.tap(find.text('あとで'));
    await tester.pumpAndSettle();
    expect(find.text('ホーム'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await finishStartup(tester);
    expect(checks, 1);
    expect(find.byType(AppUpdateDialog), findsNothing);
  });

  testWidgets('no update does not interrupt startup and allows review flow', (
    tester,
  ) async {
    var noUpdate = 0;
    await tester.pumpWidget(
      app(
        navigator: GlobalKey<NavigatorState>(),
        observer: AppUpdateNavigatorObserver(),
        check: () async => null,
        onNoUpdate: () => noUpdate++,
      ),
    );
    await finishStartup(tester);
    expect(find.byType(AppUpdateDialog), findsNothing);
    expect(find.text('ホーム'), findsOneWidget);
    expect(noUpdate, 1);
  });

  testWidgets('waits for a startup dialog to close', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    final observer = AppUpdateNavigatorObserver();
    final pending = Completer<AppUpdateInfo?>();
    await tester.pumpWidget(
      app(
        navigator: navigator,
        observer: observer,
        check: () => pending.future,
      ),
    );
    unawaited(
      showDialog<void>(
        context: navigator.currentContext!,
        builder: (_) => const AlertDialog(title: Text('チュートリアル')),
      ),
    );
    pending.complete(update);
    await finishStartup(tester);
    expect(find.text('チュートリアル'), findsOneWidget);
    expect(find.byType(AppUpdateDialog), findsNothing);
    navigator.currentState!.pop();
    await finishStartup(tester);
    expect(find.byType(AppUpdateDialog), findsOneWidget);
  });

  testWidgets('background result waits until the app resumes', (tester) async {
    final pending = Completer<AppUpdateInfo?>();
    await tester.pumpWidget(
      app(
        navigator: GlobalKey<NavigatorState>(),
        observer: AppUpdateNavigatorObserver(),
        check: () => pending.future,
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    pending.complete(update);
    await finishStartup(tester);
    expect(find.byType(AppUpdateDialog), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await finishStartup(tester);
    expect(find.byType(AppUpdateDialog), findsOneWidget);
  });

  testWidgets('update opens the correct store once and closes dialog', (
    tester,
  ) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      app(
        navigator: GlobalKey<NavigatorState>(),
        observer: AppUpdateNavigatorObserver(),
        check: () async => update,
        openStore: (uri) async {
          opened.add(uri);
          return true;
        },
      ),
    );
    await finishStartup(tester);
    await tester.tap(find.text('更新する'));
    await tester.pumpAndSettle();
    expect(opened, [update.storeUrl]);
    expect(find.byType(AppUpdateDialog), findsNothing);
  });

  testWidgets('store launch failure allows retry or later', (tester) async {
    await tester.pumpWidget(
      app(
        navigator: GlobalKey<NavigatorState>(),
        observer: AppUpdateNavigatorObserver(),
        check: () async => update,
        openStore: (_) async => throw StateError('unavailable'),
      ),
    );
    await finishStartup(tester);
    await tester.tap(find.text('更新する'));
    await tester.pumpAndSettle();
    expect(find.text('ストアを開けませんでした。もう一度お試しください。'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tester.tap(find.text('あとで'));
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets('320px and 200% text remain usable in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(
          navigator: GlobalKey<NavigatorState>(),
          observer: AppUpdateNavigatorObserver(),
          check: () async => update,
          theme: ThemeData(brightness: brightness),
          textScale: 2,
        ),
      );
      await finishStartup(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('更新する').hitTestable(), findsOneWidget);
      expect(find.text('あとで').hitTestable(), findsOneWidget);
      await tester.tap(find.text('あとで'));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('a disposed host ignores a late response', (tester) async {
    final pending = Completer<AppUpdateInfo?>();
    await tester.pumpWidget(
      app(
        navigator: GlobalKey<NavigatorState>(),
        observer: AppUpdateNavigatorObserver(),
        check: () => pending.future,
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(update);
    await finishStartup(tester);
    expect(tester.takeException(), isNull);
  });
}
