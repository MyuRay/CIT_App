import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cit_app/models/schedule/academic_calendar_event_model.dart';
import 'package:cit_app/widgets/common/app_system_safe_area.dart';
import 'package:cit_app/widgets/home/academic_calendar_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/theme_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  setUpAll(() async => themes = await loadTestThemes());
  final today = DateTime(2026, 9, 16);
  final events = [
    AcademicCalendarEvent(
      id: '1',
      date: today,
      title: '後期授業開始',
      note: '時間割を確認してください。',
      colorHex: '#1565C0',
    ),
    AcademicCalendarEvent(
      id: '2',
      date: DateTime(2026, 9, 18),
      title: '履修登録締切',
      note: '17時までに登録を完了してください。',
      colorHex: '#E53935',
    ),
    AcademicCalendarEvent(
      id: '3',
      date: DateTime(2026, 9, 23),
      title: '授業実施日',
      colorHex: '#2E7D32',
    ),
    AcademicCalendarEvent(
      id: '4',
      date: DateTime(2026, 9, 30),
      title: '履修確認期間終了',
      note: List.filled(12, '履修内容と登録結果を確認してください。').join('\n'),
    ),
  ];
  final boundary = GlobalKey();
  late int loads;
  late List<(DateTime, DateTime)> ranges;
  late int imageOpens;

  setUp(() {
    loads = 0;
    ranges = [];
    imageOpens = 0;
  });

  Stream<List<AcademicCalendarEvent>> load(DateTime start, DateTime end) {
    loads++;
    ranges.add((start, end));
    return Stream.value(
      events
          .where(
            (event) => !event.date.isBefore(start) && !event.date.isAfter(end),
          )
          .toList(),
    );
  }

  Future<void> mount(
    WidgetTester tester, {
    DateTime? date,
    bool sunday = true,
    double width = 390,
    double scale = 1,
    Brightness brightness = Brightness.light,
    AcademicEventsLoader? loader,
    bool settle = true,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: themes[brightness],
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: AppSystemSafeArea(child: child!),
            ),
        home: RepaintBoundary(
          key: boundary,
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: AcademicCalendarCard(
                today: date ?? today,
                startsOnSunday: sunday,
                onOpenAnnualImages: () => imageOpens++,
                loadEvents: loader ?? load,
              ),
            ),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (themePreviewDirectory.isEmpty) return;
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$themePreviewDirectory/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  bool selected(WidgetTester tester, String id) =>
      tester
          .widget<Semantics>(find.byKey(ValueKey('academic-event-$id')))
          .properties
          .selected ??
      false;

  testWidgets(
    'all month events stay visible and selected dates only highlight matching rows',
    (tester) async {
      await mount(
        tester,
        loader:
            (start, end) => Stream.value([
              ...events,
              AcademicCalendarEvent(
                id: '5',
                date: events.last.date,
                title: '登録内容確認と履修科目の修正および担当教員への問い合わせ期限について',
              ),
            ]),
      );
      for (final event in events) {
        expect(find.text(event.title), findsOneWidget);
      }
      expect(find.text(events.last.note), findsNothing);
      expect(find.textContaining('すべての予定'), findsNothing);
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('学年暦')).style,
        Theme.of(tester.element(find.text('学年暦'))).textTheme.titleMedium,
      );
      final collapsedHeights = {
        for (final event in events)
          event.id:
              tester
                  .getSize(find.byKey(ValueKey('academic-event-${event.id}')))
                  .height,
      };
      expect(collapsedHeights.values, everyElement(lessThan(40)));
      await tap(tester, find.byKey(const ValueKey('academic-day-2026-9-30')));
      for (final event in events) {
        expect(find.text(event.title), findsOneWidget);
        expect(selected(tester, event.id), event.id == '4');
      }
      expect(selected(tester, '5'), isTrue);
      expect(tester.widget<Text>(find.text(events.last.note)).maxLines, 3);
      expect(
        tester.widget<Text>(find.textContaining('登録内容確認と履修科目')).maxLines,
        isNull,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('academic-event-4'))).height,
        greaterThan(collapsedHeights['4']!),
      );
      for (final event in events.take(3)) {
        expect(
          tester
              .getSize(find.byKey(ValueKey('academic-event-${event.id}')))
              .height,
          collapsedHeights[event.id],
        );
      }
      await tap(tester, find.byKey(const ValueKey('academic-day-2026-9-17')));
      expect(find.text(events.last.note), findsNothing);
      expect(find.text('この日の予定はありません'), findsNothing);
      for (final event in events) {
        expect(find.text(event.title), findsOneWidget);
        expect(selected(tester, event.id), isFalse);
        expect(
          tester
              .getSize(find.byKey(ValueKey('academic-event-${event.id}')))
              .height,
          collapsedHeights[event.id],
        );
      }
      await tap(tester, find.text('履修確認期間終了'));
      expect(tester.widget<Text>(find.text(events.last.note)).maxLines, isNull);
      await tap(tester, find.byTooltip('閉じる'));
      await tap(tester, find.byKey(const ValueKey('academic-annual-images')));
      expect(imageOpens, 1);
      final images = tester.getRect(
        find.byKey(const ValueKey('academic-annual-images')),
      );
      expect(
        images.right,
        closeTo(tester.getRect(find.byType(PageView)).right, 0.1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'month return restores full list and clears selection without resubscribing',
    (tester) async {
      await mount(tester);
      await tap(tester, find.byKey(const ValueKey('academic-day-2026-9-16')));
      expect(selected(tester, '1'), isTrue);
      await tap(tester, find.text('当月に戻る'));
      expect(selected(tester, '1'), isFalse);
      await tap(tester, find.byTooltip('次の月'));
      expect(find.text('2026年10月'), findsOneWidget);
      expect(find.text('この月の予定はありません'), findsOneWidget);
      await mount(tester, sunday: false, scale: 2);
      expect(find.textContaining(RegExp(r'2026年\s*10月')), findsOneWidget);
      await tap(tester, find.text('当月に戻る'));
      expect(find.textContaining(RegExp(r'2026年\s*9月')), findsOneWidget);
      for (final event in events) {
        expect(find.text(event.title), findsOneWidget);
        expect(selected(tester, event.id), isFalse);
      }
      expect(loads, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'month arrows cross academic years and month return restores original year',
    (tester) async {
      await mount(tester, date: DateTime(2027, 3, 31));
      expect(ranges.single, (DateTime(2026, 4), DateTime(2027, 3, 31)));
      await tap(tester, find.byTooltip('次の月'));
      expect(find.text('2027年4月'), findsOneWidget);
      expect(ranges.last, (DateTime(2027, 4), DateTime(2028, 3, 31)));
      await tap(tester, find.text('当月に戻る'));
      expect(find.text('2027年3月'), findsOneWidget);
      expect(ranges.last, (DateTime(2026, 4), DateTime(2027, 3, 31)));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'swiping into six weeks expands the grid and restores compact height on return',
    (tester) async {
      await mount(tester);
      final septemberHeight = tester.getSize(find.byType(PageView)).height;
      await tap(tester, find.byKey(const ValueKey('academic-day-2026-9-16')));
      await tester.drag(find.byType(PageView), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(find.text('2026年8月'), findsOneWidget);
      expect(
        tester.getSize(find.byType(PageView)).height,
        greaterThan(septemberHeight),
      );
      final lastDay = find.byKey(const ValueKey('academic-day-2026-8-31'));
      expect(
        tester.getRect(lastDay).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(PageView)).bottom),
      );
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(PageView)).height, septemberHeight);
      expect(selected(tester, '1'), isFalse);
      expect(loads, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'loading and errors do not appear as an empty calendar, retry recovers',
    (tester) async {
      final controller = StreamController<List<AcademicCalendarEvent>>();
      addTearDown(controller.close);
      var attempts = 0;
      await mount(
        tester,
        settle: false,
        loader: (start, end) {
          attempts++;
          return attempts == 1 ? controller.stream : Stream.value(events);
        },
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('この月の予定はありません'), findsNothing);
      controller.addError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('予定を取得できませんでした'), findsOneWidget);
      expect(find.text('この月の予定はありません'), findsNothing);
      await tap(tester, find.text('再読み込み'));
      expect(find.text('後期授業開始'), findsOneWidget);
      expect(attempts, 2);
    },
  );

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'compact calendar and details fit $brightness, width $width, scale $scale',
          (tester) async {
            await mount(
              tester,
              brightness: brightness,
              width: width,
              scale: scale,
            );
            final cardHeight =
                tester
                    .getSize(
                      find.byKey(const ValueKey('academic-calendar-card')),
                    )
                    .height;
            if (scale == 1) expect(cardHeight, lessThan(600));
            await tap(
              tester,
              find.byKey(const ValueKey('academic-day-2026-9-18')),
            );
            expect(selected(tester, '2'), isTrue);
            expect(
              tester
                  .getSize(find.byKey(const ValueKey('academic-calendar-card')))
                  .height,
              greaterThan(cardHeight),
            );
            await capture(
              tester,
              'calendar-${brightness.name}-${width.toInt()}-${scale.toInt()}',
            );
            await tap(tester, find.byTooltip('前の月'));
            final lastDay = find.byKey(
              const ValueKey('academic-day-2026-8-31'),
            );
            expect(
              tester.getRect(lastDay).bottom,
              lessThanOrEqualTo(tester.getRect(find.byType(PageView)).bottom),
            );
            await tap(tester, find.text('当月に戻る'));
            await tap(tester, find.text('履修確認期間終了'));
            await Scrollable.ensureVisible(
              tester.element(find.text(events.last.note)),
              alignment: 1,
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              tester.getRect(find.text(events.last.note)).bottom,
              lessThanOrEqualTo(844 - 48),
            );
          },
        );
      }
    }
  }
}
