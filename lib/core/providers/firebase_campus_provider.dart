import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firebase/firebase_campus_service.dart';

final campusMapLoaderProvider = Provider<Future<String?> Function(String)>(
  (ref) => FirebaseCampusService.getCampusMapUrl,
);

// A new URL also retries failed image streams and bypasses stale image caches.
final campusMapRefreshVersionProvider = StateProvider<int>((ref) => 0);

final refreshCampusMapsProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.read(campusMapRefreshVersionProvider.notifier).update((previous) {
      final now = DateTime.now().microsecondsSinceEpoch;
      return now > previous ? now : previous + 1;
    });
    await Future.wait([
      ref.read(campusMapProvider('tsudanuma').future),
      ref.read(campusMapProvider('narashino').future),
    ]);
  };
});

// 全キャンパスマップデータを取得
final allCampusMapsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await FirebaseCampusService.getAllCampusMaps();
});

// 特定キャンパスのキャンパスマップを取得
final campusMapProvider = FutureProvider.family<String?, String>((
  ref,
  campus,
) async {
  final version = ref.watch(campusMapRefreshVersionProvider);
  final load = ref.watch(campusMapLoaderProvider);
  final url = await load(campus);
  if (url == null || url.isEmpty || version == 0) return url;
  final uri = Uri.parse(url);
  return uri
      .replace(
        queryParameters: {...uri.queryParameters, 'campusRefresh': '$version'},
      )
      .toString();
});

// 特定キャンパスのフロアマップ一覧を取得
final floorMapsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      campus,
    ) async {
      return await FirebaseCampusService.getAvailableFloorMaps(campus);
    });

// 特定のフロアマップを取得
final floorMapProvider = FutureProvider.family<String?, Map<String, dynamic>>((
  ref,
  params,
) async {
  final campus = params['campus'] as String;
  final building = params['building'] as String;
  final floor = params['floor'] as int;

  return await FirebaseCampusService.getFloorMapUrl(campus, building, floor);
});

// 津田沼キャンパスマップ
final tsudanumaCampusMapProvider = Provider((ref) {
  return ref.watch(campusMapProvider('tsudanuma'));
});

// 新習志野キャンパスマップ
final narashinoCampusMapProvider = Provider((ref) {
  return ref.watch(campusMapProvider('narashino'));
});

// 津田沼フロアマップ一覧
final tsudanumaFloorMapsProvider = Provider((ref) {
  return ref.watch(floorMapsProvider('tsudanuma'));
});

// 新習志野フロアマップ一覧
final narashinoFloorMapsProvider = Provider((ref) {
  return ref.watch(floorMapsProvider('narashino'));
});
