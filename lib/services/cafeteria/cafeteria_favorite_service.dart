import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/cafeteria/cafeteria_favorite_model.dart';
import '../../models/cafeteria/cafeteria_favorite_target.dart';

class CafeteriaFavoriteService {
  CafeteriaFavoriteService(this.firestore);
  final FirebaseFirestore firestore;
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      firestore.collection('users').doc(uid).collection('cafeteria_favorites');
  Stream<List<CafeteriaFavorite>> streamFavorites(String uid) =>
      _col(uid).snapshots().map(
        (snap) => uniqueCafeteriaFavorites([
          for (final doc in snap.docs)
            CafeteriaFavorite.fromJson({...doc.data(), 'id': doc.id}),
        ]),
      );

  /// Stable IDs prevent repeated adds. Legacy duplicates are all removed, and
  /// name-only menus are matched by cafeteria plus name, never by null ID alone.
  Future<void> setFavorite({
    required String userId,
    required CafeteriaFavoriteTarget target,
    required bool enabled,
  }) async {
    if (userId.isEmpty || !target.isValid) throw ArgumentError('お気に入りの対象が不明です');
    final collection = _col(userId);
    final snapshot = await collection.get();
    final matches =
        snapshot.docs
            .where(
              (doc) => target.matches(
                CafeteriaFavorite.fromJson({...doc.data(), 'id': doc.id}),
              ),
            )
            .toList();
    final canonical = collection.doc(target.key);
    final removals =
        matches.where((doc) => !enabled || doc.id != canonical.id).toList();
    // Set first so a failed legacy cleanup cannot lose a saved favorite.
    if (enabled) {
      final oldDate =
          matches.isEmpty ? null : matches.first.data()['createdAt'];
      await canonical.set({
        'userId': userId,
        'type': target.type,
        'cafeteriaId': target.cafeteriaId,
        'menuItemId': target.hasMenuId ? target.menuItemId!.trim() : null,
        'menuName': target.menuName?.trim(),
        'createdAt':
            oldDate is Timestamp ? oldDate : FieldValue.serverTimestamp(),
      });
    }
    for (var start = 0; start < removals.length; start += 400) {
      final batch = firestore.batch();
      for (final doc in removals.skip(start).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Stream<int?> streamFavoriteCount(CafeteriaFavoriteTarget target) => firestore
      .collection('cafeteria_favorite_stats')
      .doc(target.key)
      .snapshots()
      .map((doc) {
        final count = doc.data()?['count'];
        return count is int && count >= 0 ? count : null;
      });
}
