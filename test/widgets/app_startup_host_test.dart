import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cit_app/widgets/common/app_startup_host.dart';
import 'package:cit_app/core/constants/app_constants.dart';
import 'package:cit_app/core/constants/home_feature_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('keeps the $brightness splash logo centered and uncropped', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final captureKey = GlobalKey();
      final pending = Completer<Widget>();
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: AppStartupHost(initialize: () => pending.future),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(Image));
        await precacheImage(
          const AssetImage('assets/icons/app_splash_icon.png'),
          context,
        );
      });
      await tester.pump();
      final logo = find.byType(Image);
      expect(tester.getSize(logo), const Size(112, 112));
      expect(tester.getCenter(logo), const Offset(180, 400));
      expect(tester.widget<Image>(logo).fit, BoxFit.contain);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(Text), findsNothing);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor ??
            Theme.of(tester.element(logo)).scaffoldBackgroundColor,
        const Color(0xFF16856B),
      );
      expect(tester.takeException(), isNull);
      // Optional actual Flutter renders for visual QA, outside the source tree.
      if (const bool.fromEnvironment('SPLASH_VISUAL_QA')) {
        final boundary =
            captureKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final rendered = await boundary.toImage(pixelRatio: 2);
          final data = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          final file = File('build/splash_qa/${brightness.name}.png');
          file.parent.createSync(recursive: true);
          file.writeAsBytesSync(data!.buffer.asUint8List());
          rendered.dispose();
        });
      }
      pending.complete(const MaterialApp(home: Text('Ready')));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('shows only the brand mark, then fades into the ready app', (
    tester,
  ) async {
    final pending = Completer<Widget>();
    var calls = 0;
    await tester.pumpWidget(
      AppStartupHost(
        initialize: () {
          calls++;
          return pending.future;
        },
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(calls, 1);
    pending.complete(const MaterialApp(home: Text('ホームの内容')));
    await tester.pump();
    expect(find.text('ホームの内容'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('ホームの内容'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
  testWidgets('slow startup reveals feedback after three seconds', (
    tester,
  ) async {
    final pending = Completer<Widget>();
    await tester.pumpWidget(AppStartupHost(initialize: () => pending.future));
    await tester.pump(const Duration(milliseconds: 2999));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(const MaterialApp(home: Text('Ready')));
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('respects reduced motion and adds no minimum startup wait', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      AppStartupHost(
        initialize: () async => const MaterialApp(home: Text('Ready')),
      ),
    );
    await tester.pump();
    expect(find.text('Ready'), findsOneWidget);
    expect(
      tester
          .widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher).first)
          .duration,
      Duration.zero,
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
  });
  testWidgets(
    'initialization failure can retry without killing the application',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        AppStartupHost(
          initialize: () async {
            if (++calls == 1) throw StateError('platform unavailable');
            return const MaterialApp(home: Text('ホームへ復帰'));
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('再試行'), findsOneWidget);
      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();
      expect(find.text('ホームへ復帰'), findsOneWidget);
      expect(calls, 2);
    },
  );
  test(
    'time attack is temporarily hidden and Tips include the hide setting',
    () {
      expect(AppConstants.campusBusTimeAttackEnabled, isFalse);
      expect(kHomeTipIds, contains(HomeFeatureIntroId.tipsVisibilityTip));
      expect(
        homeFeatureIntroMessage(HomeFeatureIntroId.tipsVisibilityTip),
        'このTipsはマイページから非表示にすることもできます',
      );
      expect(AppConstants.appVersion, '2.5.0');
    },
  );
}
