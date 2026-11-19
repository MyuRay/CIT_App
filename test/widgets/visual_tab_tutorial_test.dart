import 'package:cit_app/widgets/home/guide_highlight.dart';
import 'package:cit_app/screens/main/widgets/visual_tab_tutorial.dart';
import 'package:cit_app/widgets/home/my_page_relocation_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BuildContext page;
  late List<GlobalKey> anchors;
  late bool sessionCurrent;

  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(390, 780),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    anchors = [GlobalKey(), GlobalKey()];
    sessionCurrent = true;
    await tester.pumpWidget(
      MaterialApp(
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: true,
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
        home: Builder(
          builder: (context) {
            page = context;
            return Scaffold(
              appBar: AppBar(
                leading: Center(
                  child: CircleAvatar(key: anchors[0], radius: 18),
                ),
              ),
              body: const Center(child: Text('実際のホーム画面')),
              bottomNavigationBar: SizedBox(
                height: 64,
                child: Center(
                  child: TextButton(
                    key: anchors[1],
                    onPressed: () {},
                    child: const Text('時間割'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<bool> start({
    List<ControlTutorialStep>? steps,
    ControlTutorialStep? closingStep,
  }) => showVisualTabTutorial(
    page,
    isCurrentSession: () => sessionCurrent,
    closingStep: closingStep,
    steps:
        steps ??
        [
          ControlTutorialStep(
            anchor: anchors[0],
            title: 'マイページの案内',
            description: '実際のアイコンを囲んで説明します。',
          ),
          ControlTutorialStep(
            anchor: anchors[1],
            title: '時間割の案内',
            description: '講義や課題の管理はこちらから。',
          ),
        ],
  );

  ControlTutorialStep replayGuide({Future<void> Function()? onEnter}) =>
      ControlTutorialStep(
        anchor: anchors[0],
        title: 'チュートリアルの確認方法',
        description: 'このチュートリアルはマイページからいつでも確認可能です',
        onEnter: onEnter,
      );

  for (final finishEarly in [false, true]) {
    testWidgets(
      '${finishEarly ? 'later' : 'completion'} waits for the My Page arrow popup before finishing',
      (tester) async {
        await mount(tester);
        var finished = false;
        final pending = start(closingStep: replayGuide()).then((value) {
          finished = true;
          return value;
        });
        await tester.pumpAndSettle();
        if (!finishEarly) {
          await tester.tap(find.text('次へ'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text(finishEarly ? 'あとで' : '完了'));
        await tester.pumpAndSettle();

        expect(finished, isFalse);
        expect(find.text('このチュートリアルはマイページからいつでも確認可能です'), findsOneWidget);
        final guide = tester.widget<MyPageRelocationGuide>(
          find.byType(MyPageRelocationGuide),
        );
        expect(guide.target, resolveGuideHighlight(page, anchors[0])!.rect);
        expect(guide.avatarKey, same(anchors[0]));
        expect(guide.stepLabel, isNull);
        expect(find.text('あとで'), findsNothing);
        expect(find.text('戻る'), findsNothing);
        await tester.tap(find.text('終了する'));
        await tester.pumpAndSettle();
        expect(await pending, isTrue);
        expect(find.byType(MyPageRelocationGuide), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('closing guide opens home before measuring the My Page icon', (
    tester,
  ) async {
    await mount(tester);
    var activeTab = 1;
    late StateSetter changeTab;
    await tester.pumpWidget(
      MaterialApp(
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
        home: StatefulBuilder(
          builder: (context, update) {
            page = context;
            changeTab = update;
            return Scaffold(
              body: Center(
                child: TextButton(
                  key: anchors[activeTab],
                  onPressed: () {},
                  child: Text(activeTab == 0 ? 'マイページ' : '時間割'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(anchors[0].currentContext, isNull);
    final pending = start(
      steps: [
        ControlTutorialStep(
          anchor: anchors[1],
          title: '時間割の案内',
          description: '時間割を確認できます。',
        ),
      ],
      closingStep: replayGuide(
        onEnter: () async {
          changeTab(() => activeTab = 0);
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('あとで'));
    await tester.pumpAndSettle();
    expect(activeTab, 0);
    expect(
      tester
          .widget<MyPageRelocationGuide>(find.byType(MyPageRelocationGuide))
          .target,
      resolveGuideHighlight(page, anchors[0])!.rect,
    );
    await tester.tap(find.text('終了する'));
    await tester.pumpAndSettle();
    expect(await pending, isTrue);
  });

  testWidgets('session changes while opening home suppress the closing guide', (
    tester,
  ) async {
    await mount(tester);
    final pending = start(
      closingStep: replayGuide(onEnter: () async => sessionCurrent = false),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('あとで'));
    await tester.pumpAndSettle();
    expect(await pending, isFalse);
    expect(find.text('チュートリアルの確認方法'), findsNothing);
    expect(find.byType(MyPageRelocationGuide), findsNothing);
  });

  testWidgets('closing popup supports large text on a small screen', (
    tester,
  ) async {
    await mount(tester, size: const Size(320, 480), scale: 2);
    final pending = start(closingStep: replayGuide());
    await tester.pumpAndSettle();
    await tester.tap(find.text('あとで'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('終了する'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('終了する'));
    await tester.pumpAndSettle();
    expect(await pending, isTrue);
  });

  testWidgets(
    'explains the actual top and bottom controls with next and previous',
    (tester) async {
      await mount(tester);
      final pending = start();
      await tester.pumpAndSettle();
      expect(find.text('マイページの案内'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(
        tester.getRect(find.byKey(MyPageRelocationGuide.popupCardKey)).center,
        const Offset(195, 390),
      );
      expect(
        tester
            .widget<MyPageRelocationGuide>(find.byType(MyPageRelocationGuide))
            .target,
        resolveGuideHighlight(page, anchors[0])!.rect,
      );
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
      expect(find.text('時間割の案内'), findsOneWidget);
      expect(
        tester.getRect(find.byKey(MyPageRelocationGuide.popupCardKey)).center,
        const Offset(195, 390),
      );
      expect(
        tester
            .widget<MyPageRelocationGuide>(find.byType(MyPageRelocationGuide))
            .target,
        resolveGuideHighlight(page, anchors[1])!.rect,
      );
      await tester.tap(find.text('戻る'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('完了'));
      await tester.pumpAndSettle();
      expect(await pending, isTrue);
      expect(find.byType(MyPageRelocationGuide), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'each step switches the actual tab before measuring, including back',
    (tester) async {
      await mount(tester);
      var activeTab = 0;
      late StateSetter changeTab;
      await tester.pumpWidget(
        MaterialApp(
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
          home: StatefulBuilder(
            builder: (context, update) {
              page = context;
              changeTab = update;
              return Scaffold(
                body: Center(
                  child: TextButton(
                    key: anchors[activeTab],
                    onPressed: () {},
                    child: Text(activeTab == 0 ? '本物のホームボタン' : '本物の時間割ボタン'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tabs = <int>[];
      final pending = start(
        steps: [
          ControlTutorialStep(
            anchor: anchors[0],
            title: 'ホームで説明',
            description: 'ホーム',
            onEnter: () async {
              tabs.add(0);
              changeTab(() => activeTab = 0);
            },
          ),
          ControlTutorialStep(
            anchor: anchors[1],
            title: '時間割で説明',
            description: '時間割',
            onEnter: () async {
              tabs.add(1);
              changeTab(() => activeTab = 1);
            },
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(tabs, [0]);
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
      expect(tabs, [0, 1]);
      await tester.ensureVisible(find.text('戻る'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('戻る'));
      await tester.pumpAndSettle();
      expect(tabs, [0, 1, 0]);
      await tester.tap(find.text('あとで'));
      await tester.pumpAndSettle();
      expect(await pending, true);
    },
  );

  testWidgets('later closes the guide without operating any demo', (
    tester,
  ) async {
    await mount(tester);
    final pending = start();
    await tester.pumpAndSettle();
    await tester.tap(find.text('あとで'));
    await tester.pumpAndSettle();
    expect(await pending, isTrue);
    expect(find.text('実際のホーム画面'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets(
    'session changes stop before presenting another account a guide',
    (tester) async {
      await mount(tester);
      final pending = start();
      await tester.pumpAndSettle();
      sessionCurrent = false;
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
      expect(await pending, isFalse);
      expect(find.text('時間割の案内'), findsNothing);
    },
  );

  testWidgets('a missing control is not treated as a completed presentation', (
    tester,
  ) async {
    await mount(tester);
    final pending = start(
      steps: [
        ControlTutorialStep(
          anchor: GlobalKey(),
          title: 'Missing',
          description: 'Missing',
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(await pending, isFalse);
    expect(find.byType(MyPageRelocationGuide), findsNothing);
  });

  testWidgets(
    'bottom-button explanations remain readable with large text on a small screen',
    (tester) async {
      await mount(tester, size: const Size(320, 480), scale: 2);
      final pending = start(
        steps: [
          ControlTutorialStep(
            anchor: anchors[1],
            title: '時間割・課題管理',
            description: '時間割を登録・編集できます。ダブルタップすると課題管理に切り替えられます。',
          ),
        ],
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('完了'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('完了'));
      await tester.pumpAndSettle();
      expect(await pending, isTrue);
    },
  );
}
