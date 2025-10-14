import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cafeteria/cafeteria_model.dart';
import '../../services/cafeteria/cafeteria_scraping_service.dart';

// 学食メニュープロバイダー
final cafeteriaMenuProvider = FutureProvider.family<CafeteriaMenu?, String>((ref, campus) async {
  // 実際のCITサイトからスクレイピング
  return await CafeteriaScrapeService.fetchTodayMenu(campus);
  
  // テスト用にモックデータを使いたい場合は以下をコメントイン
  // return CafeteriaScrapeService.getMockMenu(campus);
});

// 学食混雑状況プロバイダー
final cafeteriaCongestionProvider = FutureProvider.family<CafeteriaCongestion?, String>((ref, campus) async {
  // 実際のCITサイトから混雑状況を取得（時間帯ベースで推定）
  return await CafeteriaScrapeService.fetchCongestionStatus(campus);
  
  // テスト用にモックデータを使いたい場合は以下をコメントイン
  // return CafeteriaScrapeService.getMockCongestion(campus);
});

// 津田沼キャンパスの学食情報
final tsudanumaMenuProvider = Provider((ref) {
  return ref.watch(cafeteriaMenuProvider('tsudanuma'));
});

final tsudanumaCongestionProvider = Provider((ref) {
  return ref.watch(cafeteriaCongestionProvider('tsudanuma'));
});

// 新習志野キャンパスの学食情報
final narashinoMenuProvider = Provider((ref) {
  return ref.watch(cafeteriaMenuProvider('narashino'));
});

final narashinoCongestionProvider = Provider((ref) {
  return ref.watch(cafeteriaCongestionProvider('narashino'));
});