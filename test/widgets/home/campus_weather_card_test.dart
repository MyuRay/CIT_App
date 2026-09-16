import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cit_app/core/theme/app_colors.dart';
import 'package:cit_app/models/weather/campus_weather.dart';
import 'package:cit_app/services/weather/campus_weather_service.dart';
import 'package:cit_app/widgets/common/app_system_safe_area.dart';
import 'package:cit_app/widgets/home/campus_weather_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../support/theme_test_fonts.dart';

final now = DateTime.utc(2026, 9, 12, 3, 15); // 12:15 JST
CampusWeather sample({
  WeatherCondition condition = WeatherCondition.rain,
  DateTime? time,
}) => CampusWeather(
  asOf: time ?? now,
  fetchedAt: time ?? now,
  condition: condition,
  temperature: 24,
  feelsLike: 27,
  maxTemp: 28,
  minTemp: 22,
  windSpeed: 3.2,
  humidity: 82,
  hours: [
    for (var i = 0; i < 25; i++)
      WeatherHour(
        endsAt: DateTime.utc(2026, 9, 12, 4 + i),
        temperature: 24 - (i % 5).toDouble(),
        precipitation:
            condition == WeatherCondition.rain && (i < 2 || i == 6) ? 1.5 : 0,
        probability:
            condition == WeatherCondition.rain && (i < 2 || i == 6) ? 80 : 10,
        code: condition == WeatherCondition.rain && (i < 2 || i == 6) ? 63 : 3,
      ),
  ],
);

class FakeWeatherService extends CampusWeatherService {
  FakeWeatherService(this.load);
  final Future<CampusWeather> Function(String) load;
  final calls = <String>[];
  @override
  Future<CampusWeather> fetch(String key) {
    calls.add(key);
    return load(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  setUpAll(() async => themes = await loadTestThemes());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> mount(
    WidgetTester tester, {
    Brightness mode = Brightness.light,
    double width = 390,
    double scale = 1,
    CampusWeatherService? service,
    GlobalKey<CampusWeatherCardState>? cardKey,
    GlobalKey? boundary,
    DateTime Function()? clock,
    String mainCampus = 'tsudanuma',
    bool settle = true,
  }) async {
    tester.view.physicalSize = Size(width, 1100);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: themes[mode],
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: AppSystemSafeArea(child: child!),
            ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: boundary,
              child: CampusWeatherCard(
                key: cardKey,
                mainCampusKey: mainCampus,
                service: service ?? FakeWeatherService((_) async => sample()),
                now: clock ?? () => now,
              ),
            ),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  for (final mode in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '$mode weather at 320px / ${scale * 100}% including 24-hour sheet',
        (tester) async {
          await mount(tester, mode: mode, width: 320, scale: scale);
          expect(tester.takeException(), isNull);
          expect(find.text('14時ごろに雨がやむ見込み'), findsOneWidget);
          expect(find.textContaining('18時ごろから再び雨'), findsNothing);
          expect(find.text('24時間の予報'), findsNothing);
          await tester.tap(find.byKey(const ValueKey('weather-expand')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.textContaining('18時ごろから再び雨'), findsOneWidget);
          final box = tester.widget<Container>(
            find.byKey(const ValueKey('weather-rain-outlook')),
          );
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text('14時ごろに雨がやむ見込み'),
          );
          expect(
            AppColors.contrastRatio(
              paragraph.text.style!.color!,
              (box.decoration! as BoxDecoration).color!,
            ),
            greaterThanOrEqualTo(4.5),
          );
          await tester.ensureVisible(find.text('24時間の予報'));
          await tester.tap(find.text('24時間の予報'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('津田沼の24時間予報'), findsOneWidget);
          final list = find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(ListView),
          );
          await tester.drag(list, const Offset(0, -8000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(tester.getRect(list).bottom, lessThanOrEqualTo(1100 - 48));
        },
      );
    }
  }

  testWidgets(
    'late campus response cannot overwrite the selected campus; choice stays local',
    (tester) async {
      final first = Completer<CampusWeather>();
      final second = Completer<CampusWeather>();
      final service = FakeWeatherService(
        (key) => key == 'tsudanuma' ? first.future : second.future,
      );
      tester.view.physicalSize = const Size(390, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: themes[Brightness.light],
          home: Scaffold(
            body: SingleChildScrollView(
              child: CampusWeatherCard(service: service, now: () => now),
            ),
          ),
        ),
      );
      // A loading spinner intentionally animates while these requests are pending.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const ValueKey('weather-campus-narashino')));
      await tester.pump();
      second.complete(sample(condition: WeatherCondition.clear));
      await tester.pumpAndSettle();
      expect(find.text('晴れ'), findsOneWidget);
      first.complete(sample());
      await tester.pumpAndSettle();
      expect(find.text('晴れ'), findsOneWidget);
      expect(find.text('14時ごろに雨がやむ見込み'), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'home_weather_campus_v1',
        ),
        isNull,
      );
      expect(service.calls, ['tsudanuma', 'narashino']);
    },
  );

  testWidgets('compact by default; details toggle without refetching', (
    tester,
  ) async {
    final service = FakeWeatherService((_) async => sample());
    await mount(tester, service: service);
    final card = find.byKey(const ValueKey('weather-card'));
    final compactHeight = tester.getSize(card).height;
    expect(compactHeight, lessThanOrEqualTo(220));
    expect(find.text('雨'), findsOneWidget);
    expect(find.text('24°'), findsOneWidget);
    expect(find.text('14時ごろに雨がやむ見込み'), findsOneWidget);
    expect(find.textContaining('体感'), findsNothing);
    expect(find.textContaining('湿度'), findsNothing);
    expect(find.byKey(const ValueKey('weather-hourly-timeline')), findsNothing);
    expect(find.text('雨雲レーダー'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('weather-expand')));
    await tester.pumpAndSettle();
    expect(tester.getSize(card).height, greaterThan(compactHeight));
    expect(find.textContaining('体感'), findsOneWidget);
    expect(find.textContaining('湿度'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('weather-hourly-timeline')),
      findsOneWidget,
    );
    expect(find.text('雨雲レーダー'), findsOneWidget);
    expect(find.text('天気を更新'), findsOneWidget);
    expect(find.text('24時間の予報'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('weather-expand')));
    await tester.pumpAndSettle();
    expect(tester.getSize(card).height, compactHeight);
    expect(find.text('詳細'), findsOneWidget);
    expect(service.calls, ['tsudanuma']);
    expect(tester.takeException(), isNull);
  });

  for (final mode in Brightness.values) {
    testWidgets(
      '$mode split selector keeps positions and uses soft campus colors',
      (tester) async {
        const palette = {'tsudanuma': Colors.blue, 'narashino': Colors.green};
        await mount(tester, mode: mode);
        final left = find.byKey(const ValueKey('weather-campus-tsudanuma'));
        final right = find.byKey(const ValueKey('weather-campus-narashino'));
        final leftRect = tester.getRect(left);
        final rightRect = tester.getRect(right);
        expect(leftRect.right, rightRect.left);
        expect(leftRect.width, rightRect.width);
        expect(leftRect.height, greaterThanOrEqualTo(48));
        final initialCardColor =
            tester
                .widget<Card>(find.byKey(const ValueKey('weather-card')))
                .color;
        void checkSelection(String key, String label) {
          final node = tester.getSemantics(
            find.byKey(ValueKey('weather-campus-$key')),
          );
          expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
          final surface = tester.widget<Material>(
            find.byKey(ValueKey('weather-campus-surface-$key')),
          );
          expect(surface.color, isNot(palette[key]));
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(label),
          );
          expect(
            AppColors.contrastRatio(
              paragraph.text.style!.color!,
              surface.color!,
            ),
            greaterThanOrEqualTo(4.5),
          );
        }

        checkSelection('tsudanuma', '津田沼');
        await tester.tap(find.byKey(const ValueKey('weather-expand')));
        await tester.pumpAndSettle();
        await tester.tap(right);
        await tester.pumpAndSettle();
        checkSelection('narashino', '新習志野');
        expect(tester.getRect(left), leftRect);
        expect(tester.getRect(right), rightRect);
        expect(
          tester.getSemantics(left).flagsCollection.isSelected,
          ui.Tristate.isFalse,
        );
        expect(
          tester.widget<Card>(find.byKey(const ValueKey('weather-card'))).color,
          isNot(initialCardColor),
        );
        expect(find.text('閉じる'), findsOneWidget);
        expect(find.text('24時間の予報'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final mainCampus in ['tsudanuma', 'narashino']) {
    testWidgets(
      '$mainCampus is left and default, overriding old weather choice',
      (tester) async {
        final other = mainCampus == 'tsudanuma' ? 'narashino' : 'tsudanuma';
        SharedPreferences.setMockInitialValues({
          'home_weather_campus_v1': other,
        });
        final service = FakeWeatherService((_) async => sample());
        final key = GlobalKey<CampusWeatherCardState>();
        await mount(
          tester,
          service: service,
          cardKey: key,
          mainCampus: mainCampus,
        );
        final left = find.byKey(ValueKey('weather-campus-$mainCampus'));
        final right = find.byKey(ValueKey('weather-campus-$other'));
        expect(tester.getRect(left).right, tester.getRect(right).left);
        expect(tester.widget<Semantics>(left).properties.selected, isTrue);
        expect(service.calls, [mainCampus]);
        expect(find.text('詳細'), findsOneWidget);
        expect(find.text('24時間の予報'), findsNothing);

        await tester.tap(right);
        await tester.pumpAndSettle();
        // An ordinary parent rebuild preserves a temporary weather selection.
        await mount(
          tester,
          service: service,
          cardKey: key,
          mainCampus: mainCampus,
        );
        expect(tester.widget<Semantics>(right).properties.selected, isTrue);
        expect(tester.getRect(left).right, tester.getRect(right).left);
        // Reopening the card defaults back to the main campus.
        await mount(
          tester,
          service: service,
          cardKey: GlobalKey<CampusWeatherCardState>(),
          mainCampus: mainCampus,
        );
        expect(tester.widget<Semantics>(left).properties.selected, isTrue);
        expect(service.calls, [mainCampus, other, mainCampus]);
      },
    );
  }

  testWidgets(
    'main-campus settings change updates order and forecast on the same card',
    (tester) async {
      final pending = Completer<CampusWeather>();
      final service = FakeWeatherService(
        (key) => key == 'narashino' ? pending.future : Future.value(sample()),
      );
      final key = GlobalKey<CampusWeatherCardState>();
      await mount(tester, service: service, cardKey: key);
      final state = key.currentState;
      await tester.tap(find.byKey(const ValueKey('weather-expand')));
      await tester.pumpAndSettle();
      await mount(
        tester,
        service: service,
        cardKey: key,
        mainCampus: 'narashino',
        settle: false,
      );
      expect(key.currentState, same(state));
      final narashino = find.byKey(const ValueKey('weather-campus-narashino'));
      final tsudanuma = find.byKey(const ValueKey('weather-campus-tsudanuma'));
      expect(tester.getRect(narashino).right, tester.getRect(tsudanuma).left);
      expect(tester.widget<Semantics>(narashino).properties.selected, isTrue);
      expect(find.byType(CampusWeatherForecast), findsNothing);
      // A second settings change uses cached data; the late response stays isolated.
      await mount(
        tester,
        service: service,
        cardKey: key,
        mainCampus: 'tsudanuma',
      );
      pending.complete(sample(condition: WeatherCondition.clear));
      await tester.pumpAndSettle();
      expect(tester.getRect(tsudanuma).right, tester.getRect(narashino).left);
      expect(tester.widget<Semantics>(tsudanuma).properties.selected, isTrue);
      expect(find.text('雨'), findsOneWidget);
      expect(find.text('晴れ'), findsNothing);
      expect(find.text('閉じる'), findsOneWidget);
      expect(service.calls, ['tsudanuma', 'narashino']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed refresh retains data, marks age and offers retry', (
    tester,
  ) async {
    var fail = false;
    var clock = now;
    final service = FakeWeatherService((_) async {
      if (fail) throw Exception('offline');
      return sample();
    });
    final key = GlobalKey<CampusWeatherCardState>();
    await mount(tester, service: service, cardKey: key, clock: () => clock);
    fail = true;
    clock = now.add(const Duration(hours: 1));
    await key.currentState!.refresh();
    await tester.pumpAndSettle();
    expect(find.textContaining('前回取得した予報'), findsOneWidget);
    expect(find.textContaining('前回の天気'), findsOneWidget);
    expect(find.text('いまの天気（推定）'), findsNothing);
    expect(find.text('再試行'), findsOneWidget);
    expect(tester.takeException(), isNull);
    fail = false;
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(find.text('再試行'), findsNothing);
  });

  testWidgets(
    'empty failure is retryable without displaying another campus forecast',
    (tester) async {
      final service = FakeWeatherService(
        (_) async => throw Exception('offline'),
      );
      await mount(tester, service: service);
      expect(find.textContaining('天気を取得できませんでした'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
      expect(find.byType(CampusWeatherForecast), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'weather refreshes after ten minutes and is deduplicated while pending',
    (tester) async {
      var clock = now;
      final pending = Completer<CampusWeather>();
      var requests = 0;
      final service = FakeWeatherService((_) {
        requests++;
        return requests == 1 ? Future.value(sample()) : pending.future;
      });
      final key = GlobalKey<CampusWeatherCardState>();
      await mount(tester, service: service, cardKey: key, clock: () => clock);
      clock = now.add(const Duration(minutes: 10));
      await tester.pump(const Duration(minutes: 1));
      unawaited(key.currentState!.refresh());
      unawaited(key.currentState!.refresh());
      expect(service.calls, hasLength(2));
      pending.complete(sample(time: clock));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  if (themePreviewDirectory.isNotEmpty) {
    for (final mode in Brightness.values) {
      testWidgets('$mode weather visual preview', (tester) async {
        final boundary = GlobalKey();
        await mount(tester, mode: mode, boundary: boundary);
        expect(tester.takeException(), isNull);
        Future<void> capture(String suffix) => tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(themePreviewDirectory).create(recursive: true);
          await File(
            '$themePreviewDirectory/weather-${mode.name}$suffix.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await capture('');
        await tester.tap(find.byKey(const ValueKey('weather-expand')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capture('-expanded');
        await tester.tap(find.byKey(const ValueKey('weather-expand')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('weather-campus-narashino')),
        );
        await tester.pumpAndSettle();
        await capture('-narashino');
      });
    }
  }
}
