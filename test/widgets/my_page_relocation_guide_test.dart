import 'package:cit_app/services/auth/my_page_relocation_progress.dart';
import 'package:cit_app/widgets/common/app_update_prompt.dart';
import 'package:cit_app/widgets/home/my_page_relocation_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<
  ({
    BuildContext context,
    GlobalKey avatar,
    AppUpdateNavigatorObserver observer,
  })
>
mountHome(
  WidgetTester tester, {
  bool reducedMotion = false,
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  final avatar = GlobalKey();
  final observer = AppUpdateNavigatorObserver();
  late BuildContext pageContext;
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      navigatorObservers: [observer],
      theme: ThemeData(brightness: brightness),
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reducedMotion,
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
      home: Builder(
        builder: (context) {
          pageContext = context;
          return Scaffold(
            appBar: AppBar(
              leading: Center(child: CircleAvatar(key: avatar, radius: 18)),
              title: const Text('ホーム'),
            ),
            body: const Text('ホームの内容'),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (context: pageContext, avatar: avatar, observer: observer);
}

void main() {
  test(
    'acknowledgement survives recreation and belongs to the signed-in user',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final progress = MyPageRelocationProgress(prefs);
      expect(progress.shouldShow('existing-user'), isTrue);
      await progress.markSeen('existing-user');
      final restarted = MyPageRelocationProgress(
        await SharedPreferences.getInstance(),
      );
      expect(restarted.shouldShow('existing-user'), isFalse);
      expect(restarted.shouldShow('another-user'), isTrue);
      expect(restarted.shouldShow(''), isFalse);
    },
  );

  testWidgets(
    'guide targets the real avatar and blocks competing update prompts until acknowledged',
    (tester) async {
      final home = await mountHome(tester);
      final expectedTarget = tester.getRect(find.byKey(home.avatar));
      final pending = showMyPageRelocationGuide(
        home.context,
        avatarKey: home.avatar,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('マイページがここに移動しました'), findsOneWidget);
      expect(
        tester
            .widget<MyPageRelocationGuide>(find.byType(MyPageRelocationGuide))
            .target,
        expectedTarget,
      );
      expect(home.observer.canShowPrompt, isFalse);
      await tester.pump(const Duration(milliseconds: 1500));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('わかりました'));
      await tester.pumpAndSettle();
      expect(await pending, isTrue);
      expect(home.observer.canShowPrompt, isTrue);
      expect(find.byType(MyPageRelocationGuide), findsNothing);
    },
  );

  testWidgets('missing avatar defers the guide without opening a dialog', (
    tester,
  ) async {
    final home = await mountHome(tester);
    expect(
      await showMyPageRelocationGuide(home.context, avatarKey: GlobalKey()),
      isFalse,
    );
    expect(find.byType(MyPageRelocationGuide), findsNothing);
    expect(home.observer.canShowPrompt, isTrue);
  });

  testWidgets(
    'small screens and large text remain dismissible in both themes with reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(320, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final brightness in Brightness.values) {
        final home = await mountHome(
          tester,
          reducedMotion: true,
          textScale: 2,
          brightness: brightness,
        );
        final pending = showMyPageRelocationGuide(
          home.context,
          avatarKey: home.avatar,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('わかりました'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('わかりました'));
        await tester.pumpAndSettle();
        expect(await pending, isTrue);
      }
    },
  );

  testWidgets('resizing while the guide is open keeps the overlay usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final home = await mountHome(tester);
    final pending = showMyPageRelocationGuide(
      home.context,
      avatarKey: home.avatar,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    tester.view.physicalSize = const Size(780, 390);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.ensureVisible(find.text('わかりました'));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('わかりました'));
    await tester.pumpAndSettle();
    expect(await pending, isTrue);
  });
}
