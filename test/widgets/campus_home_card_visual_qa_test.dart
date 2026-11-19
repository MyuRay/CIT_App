// QA fixture generated verbatim from the current HomeScreen card methods.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cit_app/core/providers/firebase_campus_provider.dart';
import 'package:cit_app/widgets/campus_map_widget.dart';

const _campusNavigationOptions = {'tsudanuma': '津田沼', 'narashino': '新習志野'};

class _ActualHomeCardFixture extends StatelessWidget {
  const _ActualHomeCardFixture();
  void _openCampusWebsite(BuildContext context) {}
  void _openClassroomMap(BuildContext context) {}
  @override
  Widget build(BuildContext context) => _buildCampusMapCard(context);
  Widget _buildCampusMapCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'キャンパスマップ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openCampusWebsite(context),
                  icon: Icon(
                    Icons.open_in_browser,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    '詳細',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 12),
            _buildCampusMaps(context),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openClassroomMap(context),
                icon: const Icon(Icons.search, size: 16),
                label: const Text('教室・学内施設を探す'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const CampusBusGameButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCampusMaps(BuildContext context) {
    return Row(
      children: [
        // 津田沼キャンパス
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CampusMapWidget(
                campus: 'tsudanuma',
                height: 100,
                showTitle: false,
                campusNavigationMap: _campusNavigationOptions,
              ),
              const SizedBox(height: 4),
              Text(
                '津田沼',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              const Campus3dMapButton(campus: 'tsudanuma'),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // 新習志野キャンパス
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CampusMapWidget(
                campus: 'narashino',
                height: 100,
                showTitle: false,
              ),
              const SizedBox(height: 4),
              Text(
                '新習志野',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              const Campus3dMapButton(campus: 'narashino'),
            ],
          ),
        ),
      ],
    );
  }
}

void main() {
  testWidgets('actual HomeScreen card positions and screenshot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final japaneseFontPath = Platform.environment['CIT_CAMPUS_VISUAL_QA_FONT'];
    if (japaneseFontPath != null && japaneseFontPath.isNotEmpty) {
      await tester.runAsync(() async {
        final font = FontLoader('QaJapanese');
        font.addFont(
          Future.value(
            ByteData.sublistView(await File(japaneseFontPath).readAsBytes()),
          ),
        );
        await font.load();
      });
    }
    const capture = ValueKey('capture');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          campusMapLoaderProvider.overrideWithValue((_) async => null),
        ],
        child: MaterialApp(
          theme: ThemeData(
            fontFamily: 'QaJapanese',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff00695c),
            ),
          ),
          home: Scaffold(
            body: RepaintBoundary(
              key: capture,
              child: const ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: _ActualHomeCardFixture(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final buttons = find.byType(Campus3dMapButton);
    expect(buttons, findsNWidgets(2));
    expect(
      tester.getTopLeft(buttons.at(0)).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text('津田沼')).dy),
    );
    expect(
      tester.getTopLeft(buttons.at(1)).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text('新習志野')).dy),
    );
    expect(
      tester.getTopLeft(find.byType(CampusBusGameButton)).dy,
      greaterThan(
        tester
            .getBottomLeft(find.widgetWithText(FilledButton, '教室・学内施設を探す'))
            .dy,
      ),
    );
    expect(tester.takeException(), isNull);
    final configuredDirectory =
        Platform.environment['CIT_CAMPUS_VISUAL_QA_DIR'];
    if (configuredDirectory == null || configuredDirectory.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(capture),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final outputDirectory = Directory(configuredDirectory);
      await outputDirectory.create(recursive: true);
      await File(
        '${outputDirectory.path}${Platform.pathSeparator}home-campus-card-flutter.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  });
}
