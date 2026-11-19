import 'dart:io';
import 'dart:ui' as ui;

import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/widgets/schedule/schedule_grid_widget.dart';
import 'package:cit_app/widgets/schedule/schedule_image_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../support/theme_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;

  setUpAll(() async {
    // Load brand glyphs before the theme helper installs its offline asset mock.
    final brands = FontLoader(
      'packages/font_awesome_flutter/FontAwesomeBrands',
    )..addFont(
      rootBundle.load(
        'packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Brands-Regular-400.otf',
      ),
    );
    await brands.load();
    themes = await loadTestThemes();
  });

  Future<void> mount(
    WidgetTester tester, {
    required Brightness brightness,
    required double scale,
    required GlobalKey boundary,
    bool withTimetable = false,
  }) async {
    tester.view.physicalSize = const Size(320, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: themes[brightness],
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: boundary,
              child: ColoredBox(
                color: themes[brightness]!.scaffoldBackgroundColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (withTimetable)
                      ScheduleGridWidget(
                        schedule: _previewSchedule(),
                        forceFullHeight: true,
                        enableScroll: false,
                        showSaturday: false,
                        showAttendanceActions: false,
                        onClassTap: (_, _, _) {},
                        onEmptySlotTap: (_, _) {},
                      ),
                    const ScheduleImageFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'branded footer fits one line at 320px and $scale in $brightness',
        (tester) async {
          final boundary = GlobalKey();
          await mount(
            tester,
            brightness: brightness,
            scale: scale,
            boundary: boundary,
          );

          expect(tester.takeException(), isNull);
          final label = find.text('CIT App-千葉工大向け大学生活支援アプリ-');
          final appIcon = find.byType(Image);
          expect(label, findsOneWidget);
          expect(appIcon, findsOneWidget);
          final googlePlay = find.byIcon(FontAwesomeIcons.googlePlay.data);
          final appStore = find.byIcon(FontAwesomeIcons.appStore.data);
          expect(googlePlay, findsOneWidget);
          expect(appStore, findsOneWidget);
          final footerRect = tester.getRect(find.byType(ScheduleImageFooter));
          expect(footerRect.height, lessThanOrEqualTo(32));
          var previousRight = footerRect.left;
          for (final item in [appIcon, label, appStore, googlePlay]) {
            final rect = tester.getRect(item);
            expect(rect.center.dy, closeTo(footerRect.center.dy, 0.01));
            expect(rect.left, greaterThanOrEqualTo(previousRight));
            expect(rect.left, greaterThanOrEqualTo(footerRect.left));
            expect(rect.right, lessThanOrEqualTo(footerRect.right));
            expect(rect.bottom, lessThanOrEqualTo(footerRect.bottom));
            previousRight = rect.right;
          }
          await _savePreview(
            tester,
            boundary,
            'schedule-footer-${brightness.name}-${scale.toInt()}x',
          );
        },
      );
    }

    testWidgets('footer follows the complete saved timetable in $brightness', (
      tester,
    ) async {
      final boundary = GlobalKey();
      await mount(
        tester,
        brightness: brightness,
        scale: 1,
        boundary: boundary,
        withTimetable: true,
      );
      expect(tester.takeException(), isNull);
      final gridRect = tester.getRect(find.byType(ScheduleGridWidget));
      final footerRect = tester.getRect(find.byType(ScheduleImageFooter));
      expect(footerRect.top, gridRect.bottom);
      expect(footerRect.width, gridRect.width);
      expect(footerRect.height, lessThanOrEqualTo(32));
      expect(find.byIcon(FontAwesomeIcons.googlePlay.data), findsOneWidget);
      expect(find.byIcon(FontAwesomeIcons.appStore.data), findsOneWidget);
      await _savePreview(tester, boundary, 'schedule-image-${brightness.name}');
    });
  }
}

Future<void> _savePreview(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  if (themePreviewDirectory.isEmpty) return;
  await tester.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$themePreviewDirectory/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Schedule _previewSchedule() {
  final empty = DefaultTimeSlots.createDefault(
    id: 'preview',
    userId: 'sample-student',
    semester: '2026年度後期',
  );
  return Schedule(
    id: empty.id,
    userId: empty.userId,
    semester: empty.semester,
    timeSlots: empty.timeSlots,
    timetable: {
      'monday': {
        1: const ScheduleClass(
          id: 'math',
          subjectName: '応用数学',
          classroom: '3101',
          instructor: '担当教員',
          color: '#43A047',
        ),
        3: const ScheduleClass(
          id: 'programming',
          subjectName: 'プログラミング',
          classroom: '実習室',
          instructor: '担当教員',
          color: '#1E88E5',
          duration: 2,
        ),
      },
      'tuesday': {
        2: const ScheduleClass(
          id: 'english',
          subjectName: '英語',
          classroom: '4202',
          instructor: '担当教員',
          color: '#8E24AA',
        ),
      },
      'wednesday': {
        3: const ScheduleClass(
          id: 'experiment',
          subjectName: '基礎実験',
          classroom: '実験室',
          instructor: '担当教員',
          color: '#EF6C00',
          duration: 2,
        ),
      },
      'thursday': {
        2: const ScheduleClass(
          id: 'information',
          subjectName: '情報工学',
          classroom: '5101',
          instructor: '担当教員',
          color: '#00897B',
        ),
      },
      'friday': {
        1: const ScheduleClass(
          id: 'seminar',
          subjectName: 'ゼミナール',
          classroom: '研究室',
          instructor: '担当教員',
          color: '#E53935',
        ),
      },
    },
  );
}
