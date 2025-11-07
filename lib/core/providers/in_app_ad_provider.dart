import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/ads/in_app_ad_model.dart';
import '../../services/ads/in_app_ad_service.dart';

final _firestore = FirebaseFirestore.instance;

final inAppAdProvider = FutureProvider.family<InAppAd?, AdPlacement>((
  ref,
  placement,
) async {
  final snapshot =
      await _firestore
          .collection('in_app_ads')
          .where('targetType', isEqualTo: adPlacementToString(placement))
          .where('isActive', isEqualTo: true)
          .get();

  final now = DateTime.now();
  final ads =
      snapshot.docs
          .map((doc) => InAppAd.fromFirestore(doc))
          .where((ad) => ad.isEligible(now))
          .toList();

  if (ads.isEmpty) return null;

  final totalWeight = ads.fold<int>(0, (sum, ad) => sum + max(ad.weight, 1));
  final random = Random();
  var pick = random.nextInt(totalWeight);

  for (final ad in ads) {
    pick -= max(ad.weight, 1);
    if (pick < 0) {
      return ad;
    }
  }

  return ads.last;
});

final inAppAdsStreamProvider = StreamProvider<List<InAppAd>>((ref) {
  return InAppAdService.streamAds();
});
