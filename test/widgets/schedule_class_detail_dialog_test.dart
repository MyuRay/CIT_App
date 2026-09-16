import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/models/schedule/attendance_session.dart';
import 'package:cit_app/core/theme/app_colors.dart';
import 'package:cit_app/widgets/schedule/attendance_status_chip.dart';
import 'package:cit_app/services/schedule/attendance_service.dart';
import 'package:cit_app/widgets/common/app_system_safe_area.dart';
import 'package:cit_app/widgets/schedule/schedule_class_detail_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const lesson = ScheduleClass(
  id: 'lecture',
  subjectName: '情報システム設計演習',
  classroom: '津田沼キャンパス 7号館 701教室',
  instructor: '工大 太郎',
  color: '#2563EB',
  duration: 2,
  notes: 'ノートPCを持参。\n参考資料 https://example.com/course',
);
const previewDirectory = String.fromEnvironment('WIDGET_PREVIEW_DIR');

void main() {
  final boundaryKey = GlobalKey();
  Future<void> open(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
    double keyboard = 0,
    bool dark = false,
    Future<bool> Function(String?)? save,
    VoidCallback? room,
    Future<void> Function()? attendance,
    Future<List<AttendanceSession>> Function()? sessions,
    Future<void> Function(AttendanceSession, String?)? saveAttendance,
    Future<AttendanceClassSummary> Function()? summary,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    tester.view.padding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);
    if (previewDirectory.isNotEmpty) {
      await tester.runAsync(() async {
        final font = File('C:/Windows/Fonts/meiryo.ttc');
        if (font.existsSync()) {
          final loader = FontLoader('PreviewJapanese')..addFont(
            Future.value(ByteData.sublistView(await font.readAsBytes())),
          );
          await loader.load();
        }
        final icons = FontLoader('MaterialIcons')..addFont(
          Future.value(
            ByteData.sublistView(
              File(
                'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
              ).readAsBytesSync(),
            ),
          ),
        );
        await icons.load();
      });
    }
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: previewDirectory.isEmpty ? null : 'PreviewJapanese',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff2563eb),
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
          ),
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  viewInsets: EdgeInsets.only(bottom: keyboard),
                ),
                child: AppSystemSafeArea(child: child!),
              ),
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => Center(
                    child: FilledButton(
                      onPressed:
                          () => showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (_) => ScheduleClassDetailDialog(
                                  lesson: lesson,
                                  dayLabel: '月曜日',
                                  periodRange: '2–3限',
                                  timeRange: '10:00–11:50',
                                  onSaveNotes: save ?? (_) async => true,
                                  onOpenRoom: room ?? () {},
                                  onAttendance: attendance ?? () async {},
                                  loadAttendanceSessions:
                                      sessions ??
                                      () async => [
                                        AttendanceSession(
                                          week: 1,
                                          date: DateTime(2026, 9, 7),
                                          status: 'present',
                                          recordId: 'record',
                                        ),
                                      ],
                                  onSaveAttendance:
                                      saveAttendance ?? (_, _) async {},
                                  loadAttendance:
                                      summary ??
                                      () async => const AttendanceClassSummary(
                                        presentCount: 8,
                                        lateCount: 1,
                                        absentCount: 0,
                                      ),
                                ),
                          ),
                      child: const Text('講義を開く'),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('講義を開く'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'details retain room navigation, attendance and readable information',
    (tester) async {
      var roomOpened = false;
      await open(tester, room: () => roomOpened = true);
      expect(find.text(lesson.subjectName), findsOneWidget);
      expect(find.text('10:00–11:50'), findsOneWidget);
      expect(find.text(lesson.instructor), findsOneWidget);
      await tester.ensureVisible(find.text('教室の場所を調べる'));
      await tester.tap(find.text('教室の場所を調べる'));
      expect(roomOpened, isTrue);
      await tester.ensureVisible(find.text('QRを読み取って出席'));
      expect(tester.takeException(), isNull);
      if (previewDirectory.isNotEmpty) {
        await tester.drag(
          find.byKey(const ValueKey('class-detail-scroll')),
          const Offset(0, 1000),
        );
        await tester.pumpAndSettle();
        final boundary =
            boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(previewDirectory).create(recursive: true);
          await File(
            '$previewDirectory/lecture-detail-light.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    },
  );
  testWidgets(
    'failed memo save keeps input and successful retry updates the view',
    (tester) async {
      var succeed = false;
      String? saved;
      await open(
        tester,
        save: (value) async {
          saved = value;
          return succeed;
        },
      );
      await tester.ensureVisible(find.text('メモを編集'));
      await tester.tap(find.text('メモを編集'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '提出期限は金曜日');
      await tester.ensureVisible(find.text('メモを保存'));
      await tester.tap(find.text('メモを保存'));
      await tester.pumpAndSettle();
      expect(find.textContaining('入力内容を残しています'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '提出期限は金曜日',
      );
      succeed = true;
      await tester.ensureVisible(find.text('メモを保存'));
      await tester.tap(find.text('メモを保存'));
      await tester.pumpAndSettle();
      expect(saved, '提出期限は金曜日');
      expect(find.byType(TextField), findsNothing);
      expect(find.text('提出期限は金曜日', findRichText: true), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'large text, narrow screen and keyboard keep save actions reachable',
    (tester) async {
      await open(tester, width: 320, scale: 2, keyboard: 280, dark: true);
      await tester.ensureVisible(find.text('メモを編集'));
      await tester.tap(find.text('メモを編集'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('メモを保存'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final saveRect = tester.getRect(find.text('メモを保存'));
      expect(saveRect.bottom, lessThan(844 - 280));
    },
  );
  testWidgets('closing an edited memo allows continuing without losing input', (
    tester,
  ) async {
    await open(tester);
    await tester.ensureVisible(find.text('メモを編集'));
    await tester.tap(find.text('メモを編集'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '未保存のメモ');
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, '教室の場所を調べる'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'QRを読み取って出席'))
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byTooltip('閉じる'));
    await tester.tap(find.byTooltip('閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('メモの変更を破棄しますか？'), findsOneWidget);
    await tester.tap(find.text('編集を続ける'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '未保存のメモ',
    );
  });

  Future<void> editAttendance(WidgetTester tester) async {
    await tester.ensureVisible(find.text('出欠を編集'));
    await tester.tap(find.text('出欠を編集'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseStatus(
    WidgetTester tester,
    String value, {
    bool settle = true,
  }) async {
    final choice = find.byKey(ValueKey('attendance-edit-$value'));
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  for (final dark in [false, true]) {
    testWidgets(
      'attendance colors match management with readable text; dark=$dark',
      (tester) async {
        await open(tester, dark: dark);
        for (final status in [
          AttendanceStatusStyle.present,
          AttendanceStatusStyle.late,
          AttendanceStatusStyle.absent,
        ]) {
          final box = find.byKey(ValueKey('attendance-count-${status.value}'));
          final container = tester.widget<Container>(box);
          final background = (container.decoration as BoxDecoration).color!;
          final label = tester.widget<Text>(
            find.descendant(of: box, matching: find.text(status.label)),
          );
          expect(
            background,
            AppColors.tintedSurface(tester.element(box), status.color),
          );
          expect(
            AppColors.contrastRatio(label.style!.color!, background),
            greaterThanOrEqualTo(4.5),
          );
        }
        await editAttendance(tester);
        for (final status in AttendanceStatusStyle.values) {
          final chip = tester.widget<ChoiceChip>(
            find.descendant(
              of: find.byKey(
                ValueKey('attendance-edit-${status.value ?? 'unrecorded'}'),
              ),
              matching: find.byType(ChoiceChip),
            ),
          );
          expect(
            AppColors.contrastRatio(
              chip.labelStyle!.color!,
              chip.selected ? chip.selectedColor! : chip.backgroundColor!,
            ),
            greaterThanOrEqualTo(4.5),
          );
        }
        expect(tester.takeException(), isNull);
        if (previewDirectory.isNotEmpty) {
          await tester.ensureVisible(
            find.byKey(const ValueKey('attendance-edit-unrecorded')),
          );
          await tester.pumpAndSettle();
          final boundary =
              boundaryKey.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(previewDirectory).create(recursive: true);
            await File(
              '$previewDirectory/attendance-editor-${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      },
    );
  }

  testWidgets(
    'failed attendance save keeps the record; retry and clear refresh counts',
    (tester) async {
      var status = 'present';
      var calls = 0;
      final pending = Completer<void>();
      await open(
        tester,
        saveAttendance: (session, value) async {
          calls++;
          expect(session.recordId, calls <= 2 ? 'record' : isNull);
          if (calls == 1) await pending.future;
          status = value ?? '';
        },
        summary:
            () async => AttendanceClassSummary(
              presentCount: status == 'present' ? 1 : 0,
              lateCount: status == 'late' ? 1 : 0,
              absentCount: status == 'absent' ? 1 : 0,
            ),
      );
      await editAttendance(tester);
      await chooseStatus(tester, 'absent', settle: false);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) => widget is IconButton && widget.tooltip == '閉じる',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<DropdownButtonFormField<int>>(
              find.byType(DropdownButtonFormField<int>),
            )
            .onChanged,
        isNull,
      );
      await chooseStatus(tester, 'late', settle: false);
      expect(calls, 1);
      pending.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(find.textContaining('変更前の記録'), findsOneWidget);
      expect(
        tester
            .widget<AttendanceStatusChip>(
              find.byKey(const ValueKey('attendance-edit-present')),
            )
            .selected,
        isTrue,
      );
      await chooseStatus(tester, 'absent');
      expect(status, 'absent');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('attendance-count-absent')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      await chooseStatus(tester, 'unrecorded');
      expect(status, '');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('attendance-count-absent')),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
      expect(find.byType(ScheduleClassDetailDialog), findsOneWidget);
      expect(find.text('QRを読み取って出席'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selecting another lecture date saves only that session', (
    tester,
  ) async {
    AttendanceSession? saved;
    String? savedStatus;
    await open(
      tester,
      sessions:
          () async => [
            AttendanceSession(
              week: 1,
              date: DateTime(2026, 9, 7),
              status: 'present',
              recordId: 'first',
            ),
            AttendanceSession(week: 2, date: DateTime(2026, 9, 14)),
          ],
      saveAttendance: (session, value) async {
        saved = session;
        savedStatus = value;
      },
    );
    await editAttendance(tester);
    await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('9/14（第2週） · 未記録').last);
    await tester.pumpAndSettle();
    await chooseStatus(tester, 'late');
    expect(saved!.date, DateTime(2026, 9, 14));
    expect(saved!.recordId, isNull);
    expect(savedStatus, 'late');
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'attendance editor fits 320px at 200% above system buttons; dark=$dark',
      (tester) async {
        await open(tester, width: 320, scale: 2, dark: dark);
        await editAttendance(tester);
        await tester.ensureVisible(
          find.byKey(const ValueKey('attendance-edit-unrecorded')),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .getRect(find.byKey(const ValueKey('attendance-edit-unrecorded')))
              .bottom,
          lessThanOrEqualTo(844 - 48),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'attendance loading failures can be retried without losing lecture details',
    (tester) async {
      var fail = true;
      await open(
        tester,
        sessions: () async {
          if (fail) throw Exception('offline');
          return [AttendanceSession(week: 1, date: DateTime(2026, 9, 7))];
        },
      );
      await editAttendance(tester);
      expect(find.textContaining('出欠を読み込めませんでした'), findsOneWidget);
      fail = false;
      await tester.ensureVisible(find.text('出欠を再読み込み'));
      await tester.tap(find.text('出欠を再読み込み'));
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
      expect(find.text(lesson.subjectName), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
