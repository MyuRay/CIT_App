import 'dart:async';

import 'package:cit_app/core/providers/firebase_campus_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refresh recovers both maps after URL lookup failed', () async {
    var available = false;
    final calls = <String>[];
    final container = ProviderContainer(
      overrides: [
        campusMapLoaderProvider.overrideWithValue((campus) async {
          calls.add(campus);
          return available
              ? 'https://example.com/$campus.png?token=abc&alt=media'
              : null;
        }),
      ],
    );
    addTearDown(container.dispose);

    for (final campus in ['tsudanuma', 'narashino']) {
      expect(await container.read(campusMapProvider(campus).future), isNull);
    }
    available = true;
    await container.read(refreshCampusMapsProvider)();
    for (final campus in ['tsudanuma', 'narashino']) {
      final url = Uri.parse(
        (await container.read(campusMapProvider(campus).future))!,
      );
      expect(url.path, '/$campus.png');
      expect(url.queryParameters['token'], 'abc');
      expect(url.queryParameters['alt'], 'media');
      expect(url.queryParameters['campusRefresh'], isNotEmpty);
      expect(calls.where((value) => value == campus), hasLength(2));
    }
  });

  test('same source gets a new image cache key after refresh', () async {
    final container = ProviderContainer(
      overrides: [
        campusMapLoaderProvider.overrideWithValue(
          (_) async => 'https://example.com/map.png',
        ),
      ],
    );
    addTearDown(container.dispose);
    // A previous value ahead of the clock also covers repeated clock ticks.
    final previousVersion = DateTime(2100).microsecondsSinceEpoch;
    container.read(campusMapRefreshVersionProvider.notifier).state =
        previousVersion;
    final initial = await container.read(campusMapProvider('tsudanuma').future);
    await container.read(refreshCampusMapsProvider)();
    final refreshed = await container.read(
      campusMapProvider('tsudanuma').future,
    );
    expect(refreshed, isNot(initial));
    expect(
      container.read(campusMapRefreshVersionProvider),
      greaterThan(previousVersion),
    );
    await container.read(refreshCampusMapsProvider)();
    expect(
      await container.read(campusMapProvider('tsudanuma').future),
      isNot(refreshed),
    );
  });

  test('refresh waits for both campuses', () async {
    final pending = {
      'tsudanuma': Completer<String?>(),
      'narashino': Completer<String?>(),
    };
    final container = ProviderContainer(
      overrides: [
        campusMapLoaderProvider.overrideWithValue(
          (campus) => pending[campus]!.future,
        ),
      ],
    );
    addTearDown(container.dispose);
    var finished = false;
    final refresh = container
        .read(refreshCampusMapsProvider)()
        .then((_) => finished = true);
    pending['tsudanuma']!.complete(null);
    await Future<void>.delayed(Duration.zero);
    expect(finished, isFalse);
    pending['narashino']!.complete('https://example.com/map.png');
    await refresh;
    expect(finished, isTrue);
  });
}
