import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firebase/firebase_campus_service.dart';

// 全キャンパスマップデータを取得
final allCampusMapsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await FirebaseCampusService.getAllCampusMaps();
});

// 特定キャンパスのキャンパスマップを取得
final campusMapProvider = FutureProvider.family<String?, String>((ref, campus) async {
  return await FirebaseCampusService.getCampusMapUrl(campus);
});

// 特定キャンパスのフロアマップ一覧を取得
final floorMapsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, campus) async {
  return await FirebaseCampusService.getAvailableFloorMaps(campus);
});

// 特定のフロアマップを取得
final floorMapProvider = FutureProvider.family<String?, Map<String, dynamic>>((ref, params) async {
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