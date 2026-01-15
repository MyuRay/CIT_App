import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/cafeteria/cafeteria_favorite_model.dart';
import '../../services/cafeteria/cafeteria_favorite_service.dart';

/// 現在のユーザーIDプロバイダー（簡易版）
final _favoriteUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

/// 現在のユーザーのお気に入り一覧
final userCafeteriaFavoritesProvider =
    StreamProvider<List<CafeteriaFavorite>>((ref) {
  final uid = ref.watch(_favoriteUserIdProvider);
  if (uid == null) {
    return const Stream.empty();
  }
  return CafeteriaFavoriteService.streamFavorites(uid);
});

/// 特定の食堂がお気に入りかどうか
final isCafeteriaFavoriteProvider =
    FutureProvider.family<bool, String>((ref, cafeteriaId) async {
  final uid = ref.watch(_favoriteUserIdProvider);
  if (uid == null) return false;
  return CafeteriaFavoriteService.isFavorite(
    userId: uid,
    type: 'cafeteria',
    cafeteriaId: cafeteriaId,
  );
});

