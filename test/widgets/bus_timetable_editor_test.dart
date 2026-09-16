import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cit_app/models/bus/bus_timetable_draft.dart';
import 'package:cit_app/screens/admin/bus_timetable_editor_screen.dart';
import 'package:cit_app/widgets/bus/bus_departure_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/bus_timetable_fixtures.dart';
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
    Future<void> Function(List<BusDepartureData>)? onSave,
    ValueChanged<bool?>? onClose,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
                  padding: const EdgeInsets.only(bottom: 48),
                ),
                child: child!,
              ),
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => TextButton(
                    onPressed: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder:
                              (_) => BusTimetableEditorScreen(
                                route: busEditorRoute(),
                                sources: [busEditorRoute(), busCopyRoute()],
                                onSave: onSave ?? (_) async {},
                              ),
                        ),
                      );
                      onClose?.call(result);
                    },
                    child: const Text('開く'),
                  ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('開く'));
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

  Future<void> type(WidgetTester tester, String key, String text) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (themePreviewDirectory.isEmpty) return;
    await tester.runAsync(() async {
      final picture =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final data = await picture.toByteData(format: ui.ImageByteFormat.png);
      await Directory(themePreviewDirectory).create(recursive: true);
      await File(
        '$themePreviewDirectory/$name.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      picture.dispose();
    });
  }

  testWidgets('bulk paste is staged, deduplicated and persisted only on save', (
    tester,
  ) async {
    List<BusDepartureData>? saved;
    await open(tester, onSave: (entries) async => saved = entries);
    await type(tester, 'bus_paste', '08:30\n09:00 09:20 09:20');
    await tap(tester, 'bus_apply');
    expect(saved, isNull);
    expect(find.text('平日 3便'), findsOneWidget);
    expect(find.text('既存の備考'), findsOneWidget);
    await tap(tester, 'bus_save');
    expect(saved, hasLength(4));
    expect(
      saved!.where((e) => busDepartureDay(e) == 'saturday').single['isActive'],
      false,
    );
    expect(find.byType(BusTimetableEditorScreen), findsNothing);
  });

  testWidgets(
    'invalid paste adds no partial entries; undo restores the whole draft',
    (tester) async {
      await open(tester);
      await type(tester, 'bus_paste', '09:00\nbad');
      await tap(tester, 'bus_apply');
      expect(find.textContaining('2行目'), findsOneWidget);
      expect(find.text('平日 1便'), findsOneWidget);
      await type(tester, 'bus_paste', '09:00');
      await tap(tester, 'bus_apply');
      expect(find.text('平日 2便'), findsOneWidget);
      await tap(tester, 'bus_undo');
      expect(find.text('平日 1便'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('bus_save')))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'interval replaces only the chosen day and preserves other-day metadata',
    (tester) async {
      List<BusDepartureData>? saved;
      await open(tester, onSave: (entries) async => saved = entries);
      await tap(tester, 'bus_day_saturday');
      await tap(tester, 'bus_mode_interval');
      await type(tester, 'bus_start', '0800');
      await type(tester, 'bus_end', '0900');
      await type(tester, 'bus_interval', '20');
      await tap(tester, 'bus_replace');
      await tap(tester, 'bus_apply');
      expect(find.text('土曜 4便'), findsOneWidget);
      await tap(tester, 'bus_save');
      expect(
        saved!.where((e) => busDepartureDay(e) == 'weekday').single,
        busEditorRoute().entries.first,
      );
      expect(
        saved!
            .where((e) => busDepartureDay(e) == 'saturday')
            .map(busDepartureMinute),
        [480, 500, 520, 540],
      );
    },
  );

  testWidgets(
    'copy route preserves notes and inactive departures without changing source',
    (tester) async {
      List<BusDepartureData>? saved;
      await open(tester, onSave: (entries) async => saved = entries);
      await tap(tester, 'bus_day_sunday');
      await tap(tester, 'bus_mode_copy');
      await tap(tester, 'bus_copy_route');
      await tester.tap(find.text('新習志野 → 津田沼').last);
      await tester.pumpAndSettle();
      await tap(tester, 'bus_copy_day');
      await tester.tap(find.text('平日').last);
      await tester.pumpAndSettle();
      await tap(tester, 'bus_apply');
      expect(find.text('日曜 2便'), findsOneWidget);
      await tap(tester, 'bus_save');
      final copied =
          saved!.where((e) => busDepartureDay(e) == 'sunday').toList();
      expect(copied.last['isActive'], false);
      expect(copied.last['note'], '運休の見本');
      expect(copied.first['id'], isNot('source1'));
    },
  );

  testWidgets(
    'save failure retains draft and blocks double submission until retry',
    (tester) async {
      var pending = Completer<void>();
      var count = 0;
      await open(
        tester,
        onSave: (_) {
          count++;
          return pending.future;
        },
      );
      await type(tester, 'bus_paste', '09:00');
      await tap(tester, 'bus_apply');
      await tap(tester, 'bus_save');
      expect(count, 1);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('bus_save')))
            .onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(BusTimetableEditorScreen), findsOneWidget);
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('平日 2便'), findsOneWidget);
      pending = Completer<void>();
      await tap(tester, 'bus_save');
      pending.complete();
      await tester.pumpAndSettle();
      expect(count, 2);
      expect(find.byType(BusTimetableEditorScreen), findsNothing);
    },
  );

  testWidgets(
    'unapplied input cannot be silently saved and leaving asks to discard',
    (tester) async {
      var saves = 0;
      await open(tester, onSave: (_) async => saves++);
      await type(tester, 'bus_paste', '09:00');
      await tap(tester, 'bus_apply');
      await type(tester, 'bus_paste', '10:00');
      await tap(tester, 'bus_save');
      expect(saves, 0);
      expect(find.textContaining('反映してから保存'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('編集内容を破棄しますか？'), findsOneWidget);
      await tester.tap(find.text('編集を続ける'));
      await tester.pumpAndSettle();
      expect(find.byType(BusTimetableEditorScreen), findsOneWidget);
    },
  );

  testWidgets(
    'single departure editor rejects blank time and keeps note/status edits',
    (tester) async {
      await open(tester);
      await tester.ensureVisible(find.text('1便追加'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1便追加'));
      await tester.pumpAndSettle();
      await tap(tester, 'departure_save');
      expect(find.byType(BusDepartureDialog), findsOneWidget);
      await type(tester, 'departure_time', '10:05');
      await tester.tap(find.byKey(const Key('departure_active')));
      await tester.pumpAndSettle();
      await tap(tester, 'departure_save');
      expect(find.text('10:05 ・運休'), findsOneWidget);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      '$brightness input modes fit small screens and system navigation',
      (tester) async {
        await open(
          tester,
          brightness: brightness,
          size: const Size(320, 700),
          scale: 2,
        );
        for (final mode in ['paste', 'interval', 'copy']) {
          await tap(tester, 'bus_mode_$mode');
          await tester.ensureVisible(find.byKey(const Key('bus_apply')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester.getRect(find.byKey(const Key('bus_save'))).bottom,
            lessThanOrEqualTo(652),
          );
        }
      },
    );

    testWidgets('$brightness editor previews', (tester) async {
      await open(tester, brightness: brightness);
      await capture(tester, 'bus-editor-${brightness.name}');
      await tap(tester, 'bus_mode_interval');
      await capture(tester, 'bus-interval-${brightness.name}');
    });
  }
}
