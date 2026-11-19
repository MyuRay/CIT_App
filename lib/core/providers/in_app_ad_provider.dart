import 'dart:async';
import 'auth_provider.dart';
import 'simple_auth_provider.dart';
import '../../models/ads/ad_audience.dart';
import 'dart:math';

import '../../services/ads/ad_event_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/ads/in_app_ad_model.dart';
import '../../services/ads/in_app_ad_service.dart';

final adViewerGradeProvider = Provider<String>((ref) {
  // Share the app's session stream, but do not classify its initial loading
  // state as an unknown student when Firebase already restored the session.
  ref.watch(simpleAuthStateProvider);
  final user = ref.watch(firebaseAuthProvider).currentUser;
  final email = user?.emailVerified == true ? user?.email : null;
  final now = DateTime.now().toUtc();
  final japan = now.add(const Duration(hours: 9));
  final next = DateTime.utc(
    japan.month < 4 ? japan.year : japan.year + 1,
    4,
    1,
  ).subtract(const Duration(hours: 9));
  final untilRollover = next.difference(now) + const Duration(seconds: 1);
  // JavaScript timers cannot safely represent delays longer than about 24 days.
  final timer = Timer(
    untilRollover > const Duration(days: 1)
        ? const Duration(days: 1)
        : untilRollover,
    ref.invalidateSelf,
  );
  ref.onDispose(timer.cancel);
  return adGradeFromEmail(email, now);
});

final inAppAdProvider = FutureProvider.family<InAppAd?, AdPlacement>((
  ref,
  placement,
) async {
  final grade = ref.watch(adViewerGradeProvider);
  final snapshot =
      await ref
          .watch(adFirestoreProvider)
          .collection('in_app_ads')
          .where('targetType', isEqualTo: adPlacementToString(placement))
          .where('isActive', isEqualTo: true)
          .get();

  final now = DateTime.now();
  final ads =
      snapshot.docs
          .map((doc) => InAppAd.fromFirestore(doc))
          .where((ad) => ad.isEligible(now) && ad.matchesGrade(grade))
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
