import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user/user_model.dart';

/// Creation and lookup are one transaction: a failed read must never be treated
/// as a missing profile and overwrite an existing user's data with defaults.
Future<AppUser?> ensureVerifiedProfile(
  FirebaseFirestore firestore,
  User user, {
  bool syncDisplayName = false,
  String? acceptedLegalConsentVersion,
}) async {
  if (!user.emailVerified) return null;
  final ref = firestore.collection('users').doc(user.uid);
  return firestore.runTransaction((transaction) async {
    final snapshot = await transaction.get(ref);
    final existing = snapshot.data();
    if (existing == null) {
      final profile = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName:
            user.displayName ?? user.email?.split('@').first ?? '匿名ユーザー',
        profileImageUrl: user.photoURL,
        createdAt: DateTime.now(),
        emailVerified: true,
      );
      transaction.set(ref, {
        ...profile.toJson(),
        if (acceptedLegalConsentVersion != null) ...{
          'legalConsentVersion': acceptedLegalConsentVersion,
          'legalConsentRecordedAt': FieldValue.serverTimestamp(),
        },
      });
      return profile;
    }
    final updates = <String, dynamic>{};
    if (acceptedLegalConsentVersion != null &&
        existing['legalConsentVersion'] != acceptedLegalConsentVersion) {
      updates['legalConsentVersion'] = acceptedLegalConsentVersion;
      updates['legalConsentRecordedAt'] = FieldValue.serverTimestamp();
    }
    if (user.email?.isNotEmpty == true && existing['email'] != user.email) {
      updates['email'] = user.email;
    }
    if (existing['emailVerified'] != true) updates['emailVerified'] = true;
    if (syncDisplayName &&
        user.displayName?.isNotEmpty == true &&
        existing['displayName'] != user.displayName) {
      updates['displayName'] = user.displayName;
    }
    if (updates.isNotEmpty) {
      updates['updatedAt'] = Timestamp.now();
      transaction.update(ref, updates);
    }
    return AppUser.fromJson({...existing, ...updates});
  });
}
