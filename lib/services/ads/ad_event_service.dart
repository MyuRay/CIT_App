import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/ads/in_app_ad_model.dart';
import '../../models/ads/ad_audience.dart';
import '../../core/providers/auth_provider.dart' show firebaseAuthProvider;

final adFirestoreProvider = Provider((ref) => FirebaseFirestore.instance);
final adEventServiceProvider = Provider(
  (ref) => AdEventService(
    ref.watch(adFirestoreProvider),
    ref.watch(firebaseAuthProvider),
  ),
);

class AdEventService {
  AdEventService(this.db, this.auth, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  final DateTime Function() _now;

  String get viewerGrade {
    final user = auth.currentUser;
    return user?.emailVerified == true
        ? adGradeFromEmail(user?.email, _now())
        : 'unknown';
  }

  Future<void> record({
    required InAppAd ad,
    required AdPlacement placement,
    required String grade,
    required String kind,
    required int slotIndex,
  }) async {
    final user = auth.currentUser;
    final now = _now();
    // A widget can hold a grade from startup or a previous account. Derive the
    // stored grade from the current verified session at the recording boundary.
    final actualGrade = adGradeFromEmail(user?.email, now);
    if (user?.emailVerified != true ||
        !ad.matchesGrade(actualGrade) ||
        !adGrades.contains(grade) ||
        !const ['impression', 'click'].contains(kind) ||
        slotIndex < 0 ||
        slotIndex > 99999 ||
        placement != ad.placement ||
        !ad.isEligible(now)) {
      return;
    }
    await db.collection('ad_events').add({
      'adId': ad.id,
      'placement': adPlacementToString(placement),
      'grade': actualGrade,
      'kind': kind,
      'slotIndex': slotIndex,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
