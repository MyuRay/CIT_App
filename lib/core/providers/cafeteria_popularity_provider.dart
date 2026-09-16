import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../services/cafeteria/cafeteria_popularity_service.dart';
import 'cafeteria_favorite_provider.dart';

final cafeteriaPopularityServiceProvider = Provider(
  (ref) => CafeteriaPopularityService(FirebaseFirestore.instance),
);

/// A sorted, comma-separated set of hashed target IDs keeps the subscription
/// stable when reviews change without adding or removing menu targets.
final cafeteriaPopularityProvider = StreamProvider.autoDispose
    .family<Map<String, int>, String>((ref, targetKeys) {
      if (ref.watch(cafeteriaFavoriteUserIdProvider) == null) {
        return Stream.value(const {});
      }
      return ref
          .watch(cafeteriaPopularityServiceProvider)
          .watchCounts(targetKeys.isEmpty ? const [] : targetKeys.split(','));
    });
