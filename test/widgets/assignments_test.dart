import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cit_app/core/providers/assignment_provider.dart';
import 'package:cit_app/core/providers/schedule_provider.dart';
import 'package:cit_app/core/providers/settings_provider.dart';
import 'package:cit_app/models/assignments/assignment.dart';
import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/services/assignments/assignment_repository.dart';
import 'package:cit_app/widgets/assignments/assignment_editor.dart';
import 'package:cit_app/widgets/assignments/assignment_flip_view.dart';
import 'package:cit_app/widgets/assignments/assignment_header.dart';
import 'package:cit_app/widgets/assignments/assignment_list.dart';
import 'package:cit_app/widgets/common/app_system_safe_area.dart';
import 'package:cit_app/widgets/schedule/semester_switch_button.dart';
import 'package:cit_app/widgets/schedule/schedule_class_detail_dialog.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/theme_test_fonts.dart';

const lesson = ScheduleClass(
  id: 'lesson',
  subjectName: '情報システム設計演習',
  classroom: '教室',
  instructor: '担当',
  color: '#1565C0',
);
final schedule = Schedule(
  id: 'fall',
  userId: 'owner',
  semester: '2026年度後期',
  timetable: {
    'monday': {1: lesson},
  },
);
const otherLesson = ScheduleClass(
  id: 'spring-lesson',
  subjectName: 'プログラミング基礎',
  classroom: '教室',
  instructor: '担当',
  color: '#1565C0',
);
final otherSchedule = Schedule(
  id: 'spring',
  userId: 'owner',
  semester: '2026年度前期',
  timetable: {
    'tuesday': {1: otherLesson},
  },
);
final clock = DateTime(2026, 9, 17, 12);
final task = Assignment(
  id: '1',
  draft: AssignmentDraft(
    title: '第3回レポート：調査結果をまとめて提出する',
    dueAt: DateTime(2026, 9, 17, 17),
    hasDueTime: true,
    course: AssignmentCourse.fromLesson(schedule, lesson),
    notes: '配布資料を確認して、提出フォームにPDFを送る。',
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  setUpAll(() async => themes = await loadTestThemes());
  late FakeFirebaseFirestore db;
  late AssignmentRepository repository;
  late SharedPreferences preferences;
  final boundary = GlobalKey();
  setUp(() async {
    SharedPreferences.setMockInitialValues({'selected_schedule_id': 'fall'});
    preferences = await SharedPreferences.getInstance();
    db = FakeFirebaseFirestore();
    repository = AssignmentRepository(db, currentUserId: () => 'owner');
  });
  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    double width = 390,
    double scale = 1,
    Brightness brightness = Brightness.light,
    double keyboard = 0,
    List<Schedule>? schedules,
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentUserIdProvider.overrideWithValue('owner'),
          assignmentRepositoryProvider.overrideWithValue(repository),
          assignmentClockProvider.overrideWith((_) => Stream.value(clock)),
          sharedPreferencesProvider.overrideWithValue(preferences),
          scheduleListProvider(
            'owner',
          ).overrideWith((_) async => schedules ?? [schedule]),
          ...overrides,
        ],
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themes[brightness],
            builder:
                (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    viewInsets: EdgeInsets.only(bottom: keyboard),
                  ),
                  child: AppSystemSafeArea(child: child!),
                ),
            home: child,
          ),
        ),
      ),
    );
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

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'registration from lecture detail preselects lecture and reaches both lists',
    (tester) async {
      await mount(
        tester,
        Scaffold(
          body: Consumer(
            builder:
                (context, ref, _) => Column(
                  children: [
                    TextButton(
                      onPressed:
                          () => showDialog<void>(
                            context: context,
                            builder:
                                (context) => ScheduleClassDetailDialog(
                                  lesson: lesson,
                                  dayLabel: '月曜日',
                                  periodRange: '1限',
                                  timeRange: '9:00–10:40',
                                  onAddAssignment:
                                      () => showAssignmentEditor(
                                        context,
                                        ref,
                                        schedule: schedule,
                                        lesson: lesson,
                                      ),
                                ),
                          ),
                      child: const Text('講義を開く'),
                    ),
                    const Expanded(
                      child: SingleChildScrollView(child: AssignmentHomeCard()),
                    ),
                  ],
                ),
          ),
        ),
      );
      await tap(tester, find.text('講義を開く'));
      await tap(tester, find.text('この講義の課題を登録'));
      expect(
        find.descendant(
          of: find.byType(AssignmentEditor),
          matching: find.text(lesson.subjectName),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('（${schedule.semester}）'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('assignment-title')),
        '提出レポート',
      );
      await tap(tester, find.byKey(const ValueKey('assignment-save')));
      expect(find.byType(AssignmentEditor), findsNothing);
      await tap(tester, find.byTooltip('閉じる'));
      expect(find.text('提出レポート'), findsOneWidget);
      await tap(tester, find.text('課題管理を開く'));
      expect(find.text('提出レポート'), findsOneWidget);
      await tap(tester, find.byType(Checkbox));
      expect(find.text('課題はすべて完了しました'), findsOneWidget);
      await tap(tester, find.text('完了 1'));
      expect(find.text('提出レポート'), findsOneWidget);
      await tap(tester, find.byType(Checkbox));
      await tap(tester, find.text('未完了 1'));
      expect(find.text('提出レポート'), findsOneWidget);
    },
  );
  testWidgets('home registration offers only the selected timetable courses', (
    tester,
  ) async {
    await mount(
      tester,
      const Scaffold(body: AssignmentHomeCard()),
      schedules: [otherSchedule, schedule],
    );
    await tap(tester, find.text('登録'));
    final editor = tester.widget<AssignmentEditor>(
      find.byType(AssignmentEditor),
    );
    expect(editor.courses.map((c) => c.scheduleId), ['fall']);
    await tap(tester, find.byType(DropdownButtonFormField<String>));
    expect(find.text(otherLesson.subjectName), findsNothing);
    expect(find.textContaining('（${schedule.semester}）'), findsNothing);
    await tap(tester, find.text(lesson.subjectName).last);
    await tester.enterText(
      find.byKey(const ValueKey('assignment-title')),
      '後期の課題',
    );
    await tap(tester, find.byKey(const ValueKey('assignment-save')));
    expect(find.text(lesson.subjectName), findsOneWidget);
    final saved = await db.collection('users/owner/assignments').get();
    expect(saved.docs.single.data()['course']['scheduleId'], 'fall');
  });
  testWidgets(
    'current selection takes priority over an earlier board timetable',
    (tester) async {
      await preferences.setString('selected_schedule_id', 'spring');
      await mount(
        tester,
        Scaffold(body: AssignmentBoard(preferredSchedule: schedule)),
        schedules: [schedule, otherSchedule],
      );
      await tap(tester, find.text('課題を登録'));
      final editor = tester.widget<AssignmentEditor>(
        find.byType(AssignmentEditor),
      );
      expect(editor.courses.map((c) => c.scheduleId), ['spring']);
      await tap(tester, find.byType(DropdownButtonFormField<String>));
      expect(find.text(lesson.subjectName), findsNothing);
      await tap(tester, find.text(otherLesson.subjectName).last);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AssignmentEditor)),
      );
      await container.read(selectedScheduleIdProvider.notifier).set('fall');
      await tester.pumpAndSettle();
      final updated = tester.widget<AssignmentEditor>(
        find.byType(AssignmentEditor),
      );
      expect(updated.courses.map((c) => c.scheduleId), ['fall']);
      // A previously selected course cannot remain attached to a new task after
      // switching the active timetable while its editor is open.
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(dropdown.initialValue, '');
      await tester.enterText(
        find.byKey(const ValueKey('assignment-title')),
        '講義を変更',
      );
      await tap(tester, find.byKey(const ValueKey('assignment-save')));
      final saved = await db.collection('users/owner/assignments').get();
      expect(saved.docs.single.data()['course'], isNull);
    },
  );
  testWidgets(
    'editing preserves an older course without offering it for selection',
    (tester) async {
      await repository.save('owner', task.id, task.draft, creating: true);
      await preferences.setString('selected_schedule_id', 'spring');
      await mount(
        tester,
        const Scaffold(body: AssignmentBoard()),
        schedules: [schedule, otherSchedule],
      );
      await tap(tester, find.text(task.draft.title));
      final dropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(
        dropdown.items!.where((item) => item.enabled).map((item) => item.value),
        ['', AssignmentCourse.fromLesson(otherSchedule, otherLesson).key],
      );
      expect(dropdown.value, task.draft.course!.key);
      await tester.enterText(
        find.byKey(const ValueKey('assignment-title')),
        '修正した課題',
      );
      await tap(tester, find.byKey(const ValueKey('assignment-save')));
      final saved = await db.doc('users/owner/assignments/${task.id}').get();
      expect(saved.data()!['course']['scheduleId'], 'fall');
      expect(saved.data()!['title'], '修正した課題');
    },
  );
  testWidgets('board registers an empty name as 課題, edits and deletes', (
    tester,
  ) async {
    await mount(tester, const Scaffold(body: AssignmentBoard()));
    expect(find.text('現在課題は登録されていません'), findsOneWidget);
    await tap(tester, find.text('課題を登録'));
    await tap(tester, find.byKey(const ValueKey('assignment-save')));
    await tap(tester, find.text('課題'));
    await tester.enterText(
      find.byKey(const ValueKey('assignment-title')),
      '修正済みの課題',
    );
    await tap(tester, find.byKey(const ValueKey('assignment-save')));
    expect(find.text('修正済みの課題'), findsOneWidget);
    for (final confirm in [false, true]) {
      await tap(tester, find.byTooltip('課題の操作'));
      await tap(tester, find.text('削除'));
      await tap(tester, find.text(confirm ? '削除' : 'キャンセル'));
      expect(find.text('修正済みの課題'), confirm ? findsNothing : findsOneWidget);
    }
  });
  testWidgets('saving guard, failure retains input and retry succeeds', (
    tester,
  ) async {
    var calls = 0;
    final pending = Completer<void>();
    await mount(
      tester,
      Scaffold(
        body: Builder(
          builder:
              (context) => TextButton(
                onPressed:
                    () => showDialog<void>(
                      context: context,
                      builder:
                          (_) => AssignmentEditor(
                            courses: const [],
                            onSave: (_) {
                              calls++;
                              return calls == 1
                                  ? pending.future
                                  : Future.value();
                            },
                          ),
                    ),
                child: const Text('開く'),
              ),
        ),
      ),
    );
    await tap(tester, find.text('開く'));
    await tester.enterText(
      find.byKey(const ValueKey('assignment-title')),
      '消えない入力',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('assignment-save')));
    await tester.tap(find.byKey(const ValueKey('assignment-save')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('assignment-save')))
          .onPressed,
      isNull,
    );
    pending.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('入力内容は残っています'), findsOneWidget);
    expect(find.text('消えない入力'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('assignment-save')));
    expect(calls, 2);
    expect(find.byType(AssignmentEditor), findsNothing);
  });
  testWidgets('unsaved system back asks before discarding', (tester) async {
    await mount(
      tester,
      Scaffold(
        body: Builder(
          builder:
              (context) => TextButton(
                onPressed:
                    () => showDialog<void>(
                      context: context,
                      builder:
                          (_) => AssignmentEditor(
                            courses: const [],
                            onSave: (_) async {},
                          ),
                    ),
                child: const Text('開く'),
              ),
        ),
      ),
    );
    await tap(tester, find.text('開く'));
    await tester.enterText(
      find.byKey(const ValueKey('assignment-title')),
      '保存前',
    );
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('入力内容を破棄しますか？'), findsOneWidget);
    await tap(tester, find.text('編集を続ける'));
    expect(find.text('保存前'), findsOneWidget);
  });
  testWidgets(
    'home manual empty display, automatic disappearance and load failure',
    (tester) async {
      final state = StateProvider<AsyncValue<List<Assignment>>>(
        (_) => const AsyncData([]),
      );
      final forced = StateProvider<bool>((_) => false);
      await mount(
        tester,
        Scaffold(
          body: Consumer(
            builder:
                (context, ref, _) => Column(
                  children: [
                    TextButton(
                      onPressed: () => ref.read(forced.notifier).state = true,
                      child: const Text('表示'),
                    ),
                    if (showAssignmentHomeCard(
                      ref.watch(assignmentsProvider),
                      alwaysShow: ref.watch(forced),
                    ))
                      const AssignmentHomeCard(),
                  ],
                ),
          ),
        ),
        overrides: [
          assignmentsProvider.overrideWith((ref) => ref.watch(state)),
        ],
      );
      expect(find.byType(AssignmentHomeCard), findsNothing);
      await tap(tester, find.text('表示'));
      expect(find.text('現在課題は登録されていません'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AssignmentHomeCard)),
      );
      container.read(forced.notifier).state = false;
      container.read(state.notifier).state = AsyncData([task]);
      await tester.pumpAndSettle();
      expect(find.byType(AssignmentHomeCard), findsOneWidget);
      container.read(state.notifier).state = AsyncData([
        Assignment(id: task.id, draft: task.draft, isCompleted: true),
      ]);
      await tester.pumpAndSettle();
      expect(find.byType(AssignmentHomeCard), findsNothing);
      container.read(state.notifier).state = AsyncError(
        StateError('denied'),
        StackTrace.current,
      );
      await tester.pumpAndSettle();
      expect(find.text('課題を読み込めませんでした。'), findsOneWidget);
      expect(find.text('現在課題は登録されていません'), findsNothing);
    },
  );

  for (final mode in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      for (final width in [320.0, 390.0, 600.0]) {
        testWidgets(
          'flip, header, board and home fit $mode at ${width}px / $scale',
          (tester) async {
            var back = false;
            var shareCount = 0;
            await mount(
              tester,
              StatefulBuilder(
                builder:
                    (context, setState) => Scaffold(
                      appBar: AssignmentHeader.appBar(
                        context,
                        semesterButton: SemesterSwitchButton(
                          label: schedule.semester,
                          onPressed: () {},
                        ),
                        showAssignments: back,
                        onToggle: () => setState(() => back = !back),
                        actions: [
                          for (final icon in [
                            Icons.notifications_active,
                            Icons.fact_check_outlined,
                            Icons.edit,
                            Icons.share,
                          ])
                            IconButton(
                              onPressed: () {
                                if (icon == Icons.share) shareCount++;
                              },
                              icon: Icon(icon),
                            ),
                        ],
                      ),
                      body: AssignmentFlipView(
                        showAssignments: back,
                        timetable: const SingleChildScrollView(
                          child: AssignmentHomeCard(),
                        ),
                        assignments: const AssignmentBoard(),
                      ),
                    ),
              ),
              width: width,
              scale: scale,
              brightness: mode,
              overrides: [
                assignmentsProvider.overrideWithValue(AsyncData([task])),
              ],
            );
            expect(find.text('課題管理'), findsNothing);
            final semesterButton = find.descendant(
              of: find.byType(SemesterSwitchButton),
              matching: find.byType(TextButton),
            );
            final toggle = find.byKey(const ValueKey('assignment-flip-button'));
            void checkHeader() {
              expect(tester.widget<AppBar>(find.byType(AppBar)).bottom, isNull);
              expect(
                tester.getRect(find.byIcon(Icons.share)).center.dy,
                closeTo(tester.getRect(toggle).center.dy, 0.1),
              );
              expect(
                tester.getRect(toggle).left -
                    tester.getRect(semesterButton).right,
                closeTo(8, 0.1),
              );
              expect(
                find.descendant(
                  of: find.byType(AppBar),
                  matching: find.byIcon(Icons.more_vert),
                ),
                findsNothing,
              );
              expect(
                tester
                    .renderObject<RenderParagraph>(
                      find.descendant(
                        of: find.descendant(
                          of: find.byType(SemesterSwitchButton),
                          matching: find.byType(Text),
                        ),
                        matching: find.byType(RichText),
                      ),
                    )
                    .didExceedMaxLines,
                isFalse,
              );
            }

            checkHeader();
            final headerScroll = find.byKey(
              const ValueKey('schedule-header-scroll'),
            );
            await tester.drag(headerScroll, const Offset(-600, 0));
            await tester.pumpAndSettle();
            await tester.tap(find.byIcon(Icons.share));
            await tester.pumpAndSettle();
            expect(shareCount, 1);
            await tester.drag(headerScroll, const Offset(600, 0));
            await tester.pumpAndSettle();
            final title = tester.widget<Text>(
              find.byKey(const ValueKey('assignment-home-title')),
            );
            expect(
              title.style,
              Theme.of(
                tester.element(find.byType(AssignmentHomeCard)),
              ).textTheme.titleMedium,
            );
            expect(find.text(lesson.subjectName), findsOneWidget);
            expect(find.textContaining('（${schedule.semester}）'), findsNothing);
            expect(tester.takeException(), isNull);
            if (width == 320) {
              await capture(tester, 'home-${mode.name}-${scale.toInt()}');
            }
            if (width == 390 && scale == 1) {
              await capture(tester, 'home-${mode.name}-390');
            }
            await tap(
              tester,
              find.byKey(const ValueKey('assignment-flip-button')),
            );
            checkHeader();
            expect(find.text('課題管理'), findsOneWidget);
            expect(tester.takeException(), isNull);
            if (width == 320) {
              await capture(tester, 'board-${mode.name}-${scale.toInt()}');
            }
            if (width == 390 && scale == 1) {
              await capture(tester, 'board-${mode.name}-390');
            }
            await tap(
              tester,
              find.byKey(const ValueKey('assignment-flip-button')),
            );
            expect(find.text('課題管理'), findsNothing);
            expect(tester.takeException(), isNull);
          },
        );
      }
      testWidgets('editor fits keyboard and navigation $mode / $scale', (
        tester,
      ) async {
        await mount(
          tester,
          Scaffold(
            body: Builder(
              builder:
                  (context) => TextButton(
                    onPressed:
                        () => showDialog<void>(
                          context: context,
                          builder:
                              (_) => AssignmentEditor(
                                assignment: task,
                                courses: [
                                  AssignmentCourse.fromLesson(schedule, lesson),
                                ],
                                onSave: (_) async {},
                              ),
                        ),
                    child: const Text('開く'),
                  ),
            ),
          ),
          width: 320,
          scale: scale,
          brightness: mode,
          keyboard: 260,
        );
        await tap(tester, find.text('開く'));
        await tester.ensureVisible(
          find.byKey(const ValueKey('assignment-save')),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byKey(const ValueKey('assignment-save'))).bottom,
          lessThanOrEqualTo(844 - 260),
        );
        expect(tester.takeException(), isNull);
        await capture(tester, 'editor-${mode.name}-${scale.toInt()}');
      });
    }
  }
}
