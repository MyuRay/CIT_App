import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/cafeteria/cafeteria_review_model.dart';
import '../../models/cafeteria/cafeteria_menu_item_model.dart';
import 'cafeteria_favorite_provider.dart';

final myCafeteriaReviewsProvider = StreamProvider<List<CafeteriaReview>>((ref) {
  final uid = ref.watch(cafeteriaFavoriteUserIdProvider);
  if (uid == null) return Stream.value(const []);
  return FirebaseFirestore.instance
      .collection('cafeteria_reviews')
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((snap) {
        final reviews = [
          for (final doc in snap.docs)
            CafeteriaReview.fromJson({...doc.data(), 'id': doc.id}),
        ];
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reviews;
      });
});
final favoriteMenuItemProvider = StreamProvider.autoDispose
    .family<CafeteriaMenuItem?, String>((ref, id) {
      if (ref.watch(cafeteriaFavoriteUserIdProvider) == null || id.isEmpty) {
        return Stream.value(null);
      }
      return FirebaseFirestore.instance
          .collection('cafeteria_menu_items')
          .doc(id)
          .snapshots()
          .map(
            (doc) =>
                doc.exists
                    ? CafeteriaMenuItem.fromJson({...doc.data()!, 'id': doc.id})
                    : null,
          );
    });
