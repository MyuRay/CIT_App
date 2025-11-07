import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/ads/in_app_ad_model.dart';

class InAppAdService {
  static final _collection = FirebaseFirestore.instance.collection(
    'in_app_ads',
  );

  static Stream<List<InAppAd>> streamAds() {
    return _collection
        .orderBy('targetType')
        .orderBy('title')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => InAppAd.fromFirestore(
                      doc as DocumentSnapshot<Map<String, dynamic>>,
                    ),
                  )
                  .toList(),
        );
  }

  static Future<void> createAd(InAppAd ad) async {
    await _collection.add({...ad.toFirestore(), 'createdAt': Timestamp.now()});
  }

  static Future<void> updateAd(String id, InAppAd ad) async {
    await _collection.doc(id).update(ad.toFirestore());
  }

  static Future<void> deleteAd(String id) async {
    await _collection.doc(id).delete();
  }
}
