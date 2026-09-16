import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/ads/in_app_ad_model.dart';

class InAppAdService {
  static final _collection = FirebaseFirestore.instance.collection(
    'in_app_ads',
  );

  static Stream<List<InAppAd>> streamAds() {
    return _collection.snapshots().map((snapshot) {
      final ads =
          snapshot.docs
              .map(
                (doc) => InAppAd.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList();
      ads.sort((a, b) {
        final byPlacement = adPlacementToString(
          a.placement,
        ).compareTo(adPlacementToString(b.placement));
        if (byPlacement != 0) return byPlacement;
        return a.title.compareTo(b.title);
      });
      return ads;
    });
  }

  static Future<void> createAd(InAppAd ad) async {
    final data = {...ad.toFirestore(), 'createdAt': Timestamp.now()};
    await _collection.add(data);
  }

  static Future<void> updateAd(String id, InAppAd ad) async {
    await _collection.doc(id).update(ad.toFirestore());
  }

  static Future<void> setActive(String id, bool active) =>
      _collection.doc(id).update({
        'isActive': active, 'updatedAt': FieldValue.serverTimestamp(),
      });

  static Future<void> deleteAd(String id) async {
    await _collection.doc(id).delete();
  }
}
