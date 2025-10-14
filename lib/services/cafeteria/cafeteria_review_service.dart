import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/cafeteria/cafeteria_review_model.dart';

class CafeteriaReviewService {
  static final _col = FirebaseFirestore.instance.collection('cafeteria_reviews');

  static Stream<List<CafeteriaReview>> streamReviews(String cafeteriaId) {
    return _col
        .where('cafeteriaId', isEqualTo: cafeteriaId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CafeteriaReview.fromJson({
              'id': d.id,
              ...d.data(),
            })).toList());
  }

  static Future<void> addReview(CafeteriaReview review) async {
    await _col.add(review.toJson());
  }

  static Future<void> updateReview(String id, Map<String, dynamic> data) async {
    if (id.isEmpty) {
      throw Exception('レビューIDが無効です');
    }
    await _col.doc(id).update(data);
  }

  static Future<void> deleteReview(String id) async {
    if (id.isEmpty) {
      throw Exception('レビューIDが無効です');
    }
    await _col.doc(id).delete();
  }
}

