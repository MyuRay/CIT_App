import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/circle/circle_model.dart';
import '../../services/circle/circle_service.dart';

/// サークル一覧（デモ用・ローカルJSON）
final circlesProvider = FutureProvider<List<Circle>>((ref) async {
  return CircleService.loadCircles();
});

/// 診断結果（選択タグに基づくマッチング）
final circleDiagnosisProvider =
    FutureProvider.family<List<Circle>, List<String>>((ref, selectedTags) async {
  final circles = await ref.watch(circlesProvider.future);
  if (selectedTags.isEmpty) return circles;

  final scored = circles
      .map((c) => MapEntry(c, CircleService.getMatchScore(c, selectedTags)))
      .where((e) => e.value > 0)
      .toList();
  scored.sort((a, b) => b.value.compareTo(a.value));
  return scored.map((e) => e.key).toList();
});

/// 「行きたい」体験会のID保存用キー
const _keyWantToGo = 'circle_want_to_go_ids';

/// 行きたい体験会ID一覧
final wantToGoIdsProvider =
    FutureProvider<Set<String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList(_keyWantToGo) ?? [];
  return list.toSet();
});

/// 行きたい体験会をトグル（ref は WidgetRef または Ref）
Future<void> toggleWantToGo(
  dynamic ref,
  String circleId,
  int eventIndex,
) async {
  final key = '${circleId}_$eventIndex';
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList(_keyWantToGo) ?? [];
  final set = list.toSet();
  if (set.contains(key)) {
    set.remove(key);
  } else {
    set.add(key);
  }
  await prefs.setStringList(_keyWantToGo, set.toList());
  ref.invalidate(wantToGoIdsProvider);
}

/// 行きたいかどうか
bool isWantToGo(Set<String> ids, String circleId, int eventIndex) {
  return ids.contains('${circleId}_$eventIndex');
}
