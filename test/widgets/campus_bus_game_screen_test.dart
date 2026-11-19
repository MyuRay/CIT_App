import 'package:cit_app/core/providers/firebase_campus_provider.dart';
import 'package:cit_app/screens/classroom_map/campus_3d_screen.dart';
import 'package:cit_app/screens/classroom_map/campus_3d_view.dart';
import 'package:cit_app/screens/classroom_map/campus_bus_game_screen.dart';
import 'package:cit_app/screens/classroom_map/campus_game_online_panel.dart';
import 'package:cit_app/services/campus_game/campus_race_best_store.dart';
import 'package:cit_app/widgets/campus_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('3D map button sits below campus name and opens accurate map', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          campusMapLoaderProvider.overrideWithValue((_) async => null),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CampusMapWidget(campus: 'narashino', height: 100),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('3Dマップ')).dy,
      greaterThan(tester.getBottomLeft(find.text('新習志野')).dy),
    );
    await tester.tap(find.text('3Dマップ'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Campus3dScreen>(find.byType(Campus3dScreen)).experience,
      'map',
    );
    expect(find.byType(CampusBusGameScreen), findsNothing);
    expect(find.byTooltip('オンラインレース'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'game route has no model dependency and preserves viewer on fullscreen/reset',
    (tester) async {
      rootBundle.evict('assets/models/campus/viewer.html');
      final assets = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            final asset = const StringCodec().decodeMessage(message)!;
            assets.add(asset);
            if (asset.endsWith('viewer.html')) {
              return ByteData.sublistView(
                Uint8List.fromList('<html></html>'.codeUnits),
              );
            }
            return null;
          });
      await tester.runAsync(
        () => rootBundle.loadString('assets/models/campus/viewer.html'),
      );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
          home: const Scaffold(body: CampusBusGameButton()),
        ),
      );
      await tester.tap(find.text('学バスタイムアタック'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.byType(CampusBusGameScreen), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
      final preparation =
          tester
              .widget<FutureBuilder<String?>>(
                find.byType(FutureBuilder<String?>),
              )
              .future!;
      await tester.runAsync(() => preparation);
      await tester.pump();
      final view = tester.widget<Campus3dView>(find.byType(Campus3dView));
      final state = tester.state(find.byType(Campus3dView));
      expect(view.experience, 'game');
      expect(view.reducedMotion, true);
      expect(assets.where((a) => a.endsWith('.glb')), isEmpty);
      view.onToggleFullscreen?.call();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(identical(state, tester.state(find.byType(Campus3dView))), true);
      view.onResetViewer?.call();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(view.gameBridge!.event?['type'], 'campus-reset-view');
      expect(identical(state, tester.state(find.byType(Campus3dView))), true);
      view.onExitFullscreen?.call();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
      view.gameBridge!.onCourseChanged?.call('neon_city');
      view.gameBridge!.onOpen?.call(null);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CampusGameOnlinePanel>(find.byType(CampusGameOnlinePanel))
            .direction,
        'neon_city',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('two-column campus entrances at 320px and 200 percent text fit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          campusMapLoaderProvider.overrideWithValue((_) async => null),
        ],
        child: MaterialApp(
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CampusMapWidget(
                          campus: 'tsudanuma',
                          height: 100,
                        ),
                      ),
                      Expanded(
                        child: CampusMapWidget(
                          campus: 'narashino',
                          height: 100,
                        ),
                      ),
                    ],
                  ),
                  CampusBusGameButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('3Dマップ'), findsNWidgets(2));
    expect(find.text('学バスタイムアタック'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test(
    'pop best records keep four courses and legacy map records separate',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = CampusRaceBestStore();
      expect(await store.save('cit_bus_best_v1_outward_12345678', 5000), true);
      for (final course in ['outward', 'return', 's_bay', 'neon_city']) {
        expect(
          await store.save('cit_bus_best_v2_pop_${course}_12345678', 6000),
          true,
        );
      }
      expect(await store.save('cit_bus_best_v1_s_bay_12345678', 1), false);
      expect(
        await store.save('cit_bus_best_v2_pop_unknown_12345678', 1),
        false,
      );
      final bests = await store.load();
      expect(bests.length, 5);
      expect(bests['cit_bus_best_v1_outward_12345678'], 5000);
      expect(bests['cit_bus_best_v2_pop_outward_12345678'], 6000);
    },
  );
}
