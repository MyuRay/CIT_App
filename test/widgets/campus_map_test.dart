import 'dart:async';
import 'dart:ui' as ui;
import 'package:cit_app/core/providers/firebase_campus_provider.dart';
import 'package:cit_app/widgets/campus_map_widget.dart';
import 'package:cit_app/widgets/campus_map_image.dart';
import 'package:cit_app/widgets/common/safe_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final campus in ['tsudanuma', 'narashino']) {
    test('bundled $campus image decodes', () async {
      final data = await rootBundle.load(
        'assets/images/campus_maps/${campus}_campus_map.png',
      );
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(500));
      expect(frame.image.height, greaterThan(500));
      frame.image.dispose();
      codec.dispose();
    });
  }

  for (final mode in ['loading', 'missing', 'error']) {
    testWidgets('map remains visible and zoomable on $mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            campusMapLoaderProvider.overrideWithValue((_) {
              if (mode == 'loading') return Completer<String?>().future;
              if (mode == 'error') return Future.error(Exception('offline'));
              return Future.value(null);
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CampusMapWidget(
                campus: 'tsudanuma',
                height: 100,
                campusNavigationMap: {'tsudanuma': '津田沼', 'narashino': '新習志野'},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      await tester.tap(find.byType(CampusMapImage));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsWidgets);
      expect(find.byType(Image), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('network image uses bundled map for loading and failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CampusMapImage(
          campus: 'narashino',
          imageUrl: 'https://example.com/map.png',
        ),
      ),
    );
    final remote = tester.widget<SafeCachedNetworkImage>(
      find.byType(SafeCachedNetworkImage),
    );
    expect(remote.placeholder, isA<Image>());
    expect(remote.errorWidget, isA<Image>());
    expect((remote.errorWidget! as Image).image, isA<AssetImage>());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
