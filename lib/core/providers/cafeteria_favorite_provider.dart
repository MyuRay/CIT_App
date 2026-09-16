import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/cafeteria/cafeteria_favorite_model.dart';
import '../../models/cafeteria/cafeteria_favorite_target.dart';
import '../../services/cafeteria/cafeteria_favorite_service.dart';
import 'simple_auth_provider.dart';

final cafeteriaFavoriteUserIdProvider = Provider<String?>(
  (ref) => ref.watch(simpleAuthStateProvider).asData?.value?.uid,
);
final cafeteriaFavoriteServiceProvider = Provider(
  (ref) => CafeteriaFavoriteService(FirebaseFirestore.instance),
);
final userCafeteriaFavoritesProvider = StreamProvider<List<CafeteriaFavorite>>((
  ref,
) {
  final uid = ref.watch(cafeteriaFavoriteUserIdProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(cafeteriaFavoriteServiceProvider).streamFavorites(uid);
});
final cafeteriaFavoriteStateProvider =
    Provider.family<AsyncValue<bool>, CafeteriaFavoriteTarget>(
      (ref, target) => ref
          .watch(userCafeteriaFavoritesProvider)
          .whenData((favorites) => favorites.any(target.matches)),
    );
final cafeteriaFavoriteCountProvider = StreamProvider.autoDispose
    .family<int?, CafeteriaFavoriteTarget>((ref, target) {
      if (ref.watch(cafeteriaFavoriteUserIdProvider) == null) {
        return Stream.value(null);
      }
      return ref
          .watch(cafeteriaFavoriteServiceProvider)
          .streamFavoriteCount(target);
    });
final cafeteriaFavoriteMutationProvider = StateNotifierProvider.autoDispose
    .family<
      CafeteriaFavoriteMutation,
      AsyncValue<void>,
      CafeteriaFavoriteTarget
    >(
      (ref, target) => CafeteriaFavoriteMutation(
        ref.watch(cafeteriaFavoriteServiceProvider),
        ref.watch(cafeteriaFavoriteUserIdProvider),
        target,
      ),
    );

class CafeteriaFavoriteMutation extends StateNotifier<AsyncValue<void>> {
  CafeteriaFavoriteMutation(this.service, this.userId, this.target)
    : super(const AsyncData(null));
  final CafeteriaFavoriteService service;
  final String? userId;
  final CafeteriaFavoriteTarget target;
  Future<void> setEnabled(bool enabled) async {
    if (state.isLoading) return;
    if (userId == null) throw StateError('ログインが必要です');
    state = const AsyncLoading();
    try {
      await service.setFavorite(
        userId: userId!,
        target: target,
        enabled: enabled,
      );
      if (mounted) state = const AsyncData(null);
    } catch (error, stack) {
      if (mounted) state = AsyncError(error, stack);
      rethrow;
    }
  }
}
