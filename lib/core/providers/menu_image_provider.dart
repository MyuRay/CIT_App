import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/cafeteria/menu_image_service.dart';

// 今日のメニュー画像プロバイダー
final todayMenuImageProvider = FutureProvider.family<String?, String>((ref, campus) async {
  return await MenuImageService.getTodayMenuImage(campus);
});

// 特定の日のメニュー画像プロバイダー
final menuImageProvider = FutureProvider.family<String?, MenuImageRequest>((ref, request) async {
  if (kIsWeb) {
    // Web版では直接URLを返す（ダウンロード不要）
    return 'web_direct_url';
  } else {
    // モバイル版ではローカルキャッシュを使用
    return await MenuImageService.getMenuImageForDate(request.campus, request.date);
  }
});

// 今週の全メニュー画像パスプロバイダー
final weeklyMenuPathsProvider = FutureProvider.family<Map<String, String?>, String>((ref, campus) async {
  return await MenuImageService.getWeeklyMenuPaths(campus);
});

// 週間メニュー画像ダウンロードプロバイダー
final weeklyMenuDownloadProvider = FutureProvider.family<Map<String, String?>, String>((ref, campus) async {
  return await MenuImageService.downloadWeeklyMenuImages(campus);
});

// 津田沼キャンパスの今日のメニュー画像
final tsudanumaTodayMenuProvider = Provider((ref) {
  return ref.watch(todayMenuImageProvider('td'));
});

// 新習志野キャンパスの今日のメニュー画像
final narashinoTodayMenuProvider = Provider((ref) {
  return ref.watch(todayMenuImageProvider('ns'));
});

// 津田沼キャンパスの週間メニュー
final tsudanumaWeeklyMenuProvider = Provider((ref) {
  return ref.watch(weeklyMenuPathsProvider('td'));
});

// 新習志野キャンパスの週間メニュー
final narashinoWeeklyMenuProvider = Provider((ref) {
  return ref.watch(weeklyMenuPathsProvider('ns'));
});

// メニュー画像リクエストクラス
class MenuImageRequest {
  final String campus;
  final DateTime date;

  MenuImageRequest({required this.campus, required this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuImageRequest &&
          runtimeType == other.runtimeType &&
          campus == other.campus &&
          date == other.date;

  @override
  int get hashCode => campus.hashCode ^ date.hashCode;
}