import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cit_app/core/providers/settings_provider.dart';
import 'package:cit_app/screens/main/widgets/visual_tab_tutorial.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/theme_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  setUpAll(() async => themes = await loadTestThemes());
  final boundary = GlobalKey();

  Future<void> open(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    Size size = const Size(390, 844),
    double scale = 1,
    ValueChanged<int?>? onClose,
    ValueChanged<TutorialDestination?>? onDestination,
    String initialCampus = 'tsudanuma',
    Future<void> Function(String)? onSaveCampus,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themes[brightness],
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(top: 24, bottom: 48),
                  disableAnimations: true,
                ),
                child: child!,
              ),
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => TextButton(
                    onPressed: () async {
                      final result = await showDialog<TutorialDestination>(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (_) => VisualTabTutorial(
                              initialCampus: initialCampus,
                              onSaveCampus: onSaveCampus ?? (_) async {},
                            ),
                      );
                      onClose?.call(result?.tabIndex);
                      onDestination?.call(result);
                    },
                    child: const Text('ガイドを開く'),
                  ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ガイドを開く'));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (themePreviewDirectory.isEmpty) return;
    await tester.ensureVisible(find.byKey(const Key('tutorial_progress')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final picture =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      await Directory(themePreviewDirectory).create(recursive: true);
      await File(
        '$themePreviewDirectory/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  }

  testWidgets('home example changes visibility without leaving the tutorial', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, 'demo_home_menu');
    await tap(tester, 'demo_home_edit');
    await tap(tester, 'demo_home_visible_天気');
    await tap(tester, 'demo_home_save');
    expect(find.text('晴れ 24°C'), findsNothing);
    expect(find.text('次の便まで 8分'), findsOneWidget);
    expect(find.byType(VisualTabTutorial), findsOneWidget);
  });

  testWidgets(
    'Excel appears only in edit mode and demo state survives going back',
    (tester) async {
      await open(tester);
      await tap(tester, 'tutorial_next');
      expect(find.byKey(const Key('demo_schedule_import')), findsNothing);
      await tap(tester, 'demo_schedule_edit');
      await tap(tester, 'demo_schedule_import');
      expect(find.text('英語'), findsOneWidget);
      await tap(tester, 'tutorial_back');
      await tap(tester, 'tutorial_next');
      expect(find.text('英語'), findsOneWidget);
      await tap(tester, 'demo_schedule_edit');
      await tap(tester, 'demo_schedule_attendance');
      expect(find.text('出席 8'), findsOneWidget);
    },
  );

  testWidgets('community, application and campus examples respond to input', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, 'tutorial_topic_3');
    await tap(tester, 'demo_community_channel');
    expect(find.text('おすすめの学食メニューは？'), findsOneWidget);
    await tap(tester, 'tutorial_topic_4');
    await tap(tester, 'demo_bulletin_add');
    expect(find.text('管理者の承認後に公開'), findsOneWidget);
    await tap(tester, 'tutorial_topic_5');
    await tap(tester, 'demo_campus_settings');
    await tap(tester, 'demo_campus_true');
    expect(find.text('新習志野の天気'), findsOneWidget);
    await tap(tester, 'demo_campus_false');
    expect(find.text('津田沼の天気'), findsOneWidget);
  });

  testWidgets(
    'skip and system back preserve the current tab; finish opens home',
    (tester) async {
      final closed = <int?>[];
      await open(tester, onClose: closed.add);
      await tap(tester, 'tutorial_skip');
      expect(closed, [null]);
      await tester.tap(find.text('ガイドを開く'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(closed, [null, null]);
      await tester.tap(find.text('ガイドを開く'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        await tap(tester, 'tutorial_next');
      }
      expect(closed, [null, null, 0]);
      expect(find.byType(VisualTabTutorial), findsNothing);
    },
  );

  testWidgets('open-tab action returns only the chosen destination', (
    tester,
  ) async {
    for (var i = 0; i < 6; i++) {
      int? result;
      await open(tester, onClose: (value) => result = value);
      await tap(tester, 'tutorial_topic_$i');
      await tap(tester, 'tutorial_open_tab');
      expect(result, [0, 1, 1, 2, 3, 4][i]);
    }
  });

  testWidgets(
    'assignment guide opens the assignment face of the schedule tab',
    (tester) async {
      TutorialDestination? result;
      await open(tester, onDestination: (value) => result = value);
      await tap(tester, 'tutorial_topic_2');
      expect(find.text('3 / 6 ・ 課題管理'), findsOneWidget);
      await tap(tester, 'tutorial_open_tab');
      expect(result?.tabIndex, 1);
      expect(result?.showAssignments, isTrue);
    },
  );

  Future<void> practiceAssignments(WidgetTester tester) async {
    await tap(tester, 'tutorial_topic_2');
    await tap(tester, 'demo_assignment_toggle');
    await tap(tester, 'demo_assignment_add');
    await tester.enterText(
      find.byKey(const Key('demo_assignment_title')),
      '演習レポート',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tap(tester, 'demo_assignment_due_true');
    await tap(tester, 'demo_assignment_save');
    expect(find.text('演習レポート'), findsOneWidget);
    expect(find.text('締切 今日 23:59'), findsOneWidget);
    await tap(tester, 'demo_assignment_complete');
    expect(find.text('課題はすべて完了しました'), findsOneWidget);
    await tap(tester, 'demo_assignment_filter_true');
    expect(find.text('演習レポート'), findsOneWidget);
    await tap(tester, 'demo_assignment_complete');
    await tap(tester, 'demo_assignment_filter_false');
    expect(find.text('演習レポート'), findsOneWidget);
    await tap(tester, 'demo_assignment_toggle');
    expect(find.text('月曜 2限\n情報基礎'), findsOneWidget);
    await tap(tester, 'demo_assignment_toggle');
    expect(find.text('演習レポート'), findsOneWidget);
  }

  testWidgets(
    'assignment example adds and completes locally without campus writes',
    (tester) async {
      var writes = 0;
      await open(tester, onSaveCampus: (_) async => writes++);
      await practiceAssignments(tester);
      expect(writes, 0);
      expect(find.byType(VisualTabTutorial), findsOneWidget);
    },
  );

  for (final campus in ['narashino', 'tsudanuma']) {
    testWidgets(
      'finish persists $campus before opening home and after reload',
      (tester) async {
        final previous = campus == 'narashino' ? 'tsudanuma' : 'narashino';
        SharedPreferences.setMockInitialValues({
          'preferredBusCampus': previous,
        });
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);
        int? destination;
        await open(
          tester,
          initialCampus: container.read(preferredBusCampusProvider),
          onSaveCampus: container.read(setPreferredBusCampusProvider),
          onClose: (value) {
            destination = value;
            expect(container.read(preferredBusCampusProvider), campus);
          },
        );
        await tap(tester, 'tutorial_topic_5');
        await tap(tester, 'demo_campus_settings');
        await tap(tester, 'demo_campus_${campus == 'narashino'}');
        expect(container.read(preferredBusCampusProvider), previous);
        expect(prefs.getString('preferredBusCampus'), previous);
        await tap(tester, 'tutorial_next');
        expect(destination, 0);
        await prefs.reload();
        final restored = SettingsNotifier(prefs);
        addTearDown(restored.dispose);
        expect(restored.state.preferredBusCampus, campus);
      },
    );
  }

  testWidgets(
    'current campus is shown and untouched completion does not overwrite it',
    (tester) async {
      var writes = 0;
      await open(
        tester,
        initialCampus: 'narashino',
        onSaveCampus: (_) async => writes++,
      );
      await tap(tester, 'tutorial_topic_5');
      expect(find.text('新習志野の天気'), findsOneWidget);
      await tap(tester, 'tutorial_next');
      expect(writes, 0);
    },
  );

  testWidgets('skip, open-tab and system back do not commit a pending campus', (
    tester,
  ) async {
    var writes = 0;
    for (final action in [
      'tutorial_skip',
      'tutorial_open_tab',
      'system_back',
    ]) {
      await open(tester, onSaveCampus: (_) async => writes++);
      await tap(tester, 'tutorial_topic_5');
      await tap(tester, 'demo_campus_settings');
      await tap(tester, 'demo_campus_true');
      if (action == 'system_back') {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      } else {
        await tap(tester, action);
      }
      expect(find.byType(VisualTabTutorial), findsNothing);
      expect(writes, 0);
    }
  });

  testWidgets(
    'failed save retains selection and retries; closing is blocked during save',
    (tester) async {
      var pending = Completer<void>();
      final saved = <String>[];
      await open(
        tester,
        onSaveCampus: (campus) {
          saved.add(campus);
          return pending.future;
        },
      );
      await tap(tester, 'tutorial_topic_5');
      await tap(tester, 'demo_campus_settings');
      await tap(tester, 'demo_campus_true');
      await tap(tester, 'tutorial_next');
      expect(saved, ['narashino']);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('tutorial_next')))
            .onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(VisualTabTutorial), findsOneWidget);
      pending.completeError(StateError('storage unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('キャンパスを保存できませんでした。もう一度お試しください。'), findsOneWidget);
      expect(find.text('新習志野の天気'), findsOneWidget);
      pending = Completer<void>();
      await tap(tester, 'tutorial_next');
      pending.complete();
      await tester.pumpAndSettle();
      expect(saved, ['narashino', 'narashino']);
      expect(find.byType(VisualTabTutorial), findsNothing);
    },
  );

  for (final brightness in Brightness.values) {
    for (final viewport in [
      (const Size(320, 700), 2.0),
      (const Size(640, 360), 1.6),
    ]) {
      testWidgets('$brightness tutorial fits $viewport with system navigation', (
        tester,
      ) async {
        await open(
          tester,
          brightness: brightness,
          size: viewport.$1,
          scale: viewport.$2,
        );
        await practiceAssignments(tester);
        await tap(tester, 'tutorial_topic_0');
        for (var i = 0; i < 6; i++) {
          final next = find.byKey(const Key('tutorial_next'));
          expect(
            tester.getRect(next).bottom,
            lessThanOrEqualTo(viewport.$1.height - 48),
          );
          expect(next.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tap(tester, 'tutorial_open_tab');
          // Each step must also remain reachable without completing previous demos.
          if (i < 5) {
            await tester.tap(find.text('ガイドを開く'));
            await tester.pumpAndSettle();
            await tap(tester, 'tutorial_topic_${i + 1}');
          }
        }
      });
    }

    testWidgets('$brightness visual previews', (tester) async {
      await open(tester, brightness: brightness);
      for (var i = 0; i < 6; i++) {
        await tap(tester, 'tutorial_topic_$i');
        await capture(tester, 'tutorial-${brightness.name}-$i');
      }
      await tap(tester, 'demo_campus_settings');
      await tap(tester, 'demo_campus_true');
      await capture(tester, 'tutorial-${brightness.name}-campus-selected');
      await tap(tester, 'tutorial_topic_1');
      await tap(tester, 'demo_schedule_edit');
      await tap(tester, 'demo_schedule_import');
      await capture(tester, 'tutorial-${brightness.name}-excel');
      await tap(tester, 'tutorial_topic_2');
      await tap(tester, 'demo_assignment_toggle');
      await tap(tester, 'demo_assignment_add');
      await capture(tester, 'tutorial-${brightness.name}-assignment-form');
      await tap(tester, 'demo_assignment_save');
      await capture(
        tester,
        'tutorial-${brightness.name}-assignment-registered',
      );
      await tap(tester, 'demo_assignment_complete');
      await tap(tester, 'demo_assignment_filter_true');
      await capture(tester, 'tutorial-${brightness.name}-assignment-completed');
    });
  }
}
