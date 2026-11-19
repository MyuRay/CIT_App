import 'dart:typed_data';
import 'package:cit_app/screens/classroom_map/campus_3d_view.dart';
import 'package:cit_app/screens/classroom_map/campus_3d_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final asset = const StringCodec().decodeMessage(message);
          if (asset != null && asset.endsWith('.glb')) return null;
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null),
  );

  testWidgets(
    'unavailable model remains usable: switch, retry and back',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: TextButton(
                    onPressed:
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => const Campus3dScreen(
                                  initialCampusId: 'narashino',
                                ),
                          ),
                        ),
                    child: const Text('open'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '新習志野'))
            .selected,
        isTrue,
      );
      expect(find.text('3Dモデルを読み込めませんでした'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, '津田沼'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '津田沼'))
            .selected,
        isTrue,
      );
      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('視点をリセット'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
    },
  );

  testWidgets('320px phone layout with 200 percent text has no overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
        home: const Campus3dScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('再試行'), findsOneWidget);
  });
  testWidgets('landscape layout keeps model area and campus switching usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: Campus3dScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(FutureBuilder<String?>)).height,
      greaterThan(250),
    );
    await tester.tap(find.widgetWithText(ChoiceChip, '新習志野'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '新習志野'))
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('fullscreen hides chrome, exits on back, then route can pop', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const Campus3dScreen(),
                        ),
                      ),
                  child: const Text('open'),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('全画面にする'));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('全画面を解除'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(Campus3dScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('back closes HTML overlay, then fullscreen, then the route', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final asset = const StringCodec().decodeMessage(message);
          if (asset != null && asset.endsWith('.glb')) {
            return ByteData(12)
              ..setUint32(0, 0x46546c67, Endian.little)
              ..setUint32(4, 2, Endian.little);
          }
          return const StringCodec().encodeMessage('<html></html>');
        });
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const Campus3dScreen(),
                        ),
                      ),
                  child: const Text('open'),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final viewer = tester.widget<Campus3dView>(find.byType(Campus3dView));
    final bridge = viewer.gameBridge!;
    viewer.onToggleFullscreen?.call();
    bridge.onOverlayChanged?.call(true);
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(bridge.event?['type'], 'campus-close-overlay');
    expect(find.byType(Campus3dScreen), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
