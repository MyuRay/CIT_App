import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import 'verified_profile.dart';

String legalConsentKeyForUser(String uid) =>
    '${AppConstants.legalConsentAcceptedVersionKey}:$uid';

bool hasCachedLegalConsent(SharedPreferences preferences, String uid) =>
    preferences.getString(legalConsentKeyForUser(uid)) ==
    AppConstants.currentLegalConsentVersion;

Future<void> cacheLegalConsentAcceptance(
  SharedPreferences preferences,
  String uid,
) async {
  await preferences.setString(
    legalConsentKeyForUser(uid),
    AppConstants.currentLegalConsentVersion,
  );
}

/// Registration and the update notice share the same account-scoped consent.
/// Account age is not evidence of consent, and another account's cache is not
/// reused. A failed remote lookup must not be interpreted as missing consent.
class LegalConsentService {
  LegalConsentService(this.firestore, this.preferences);
  final FirebaseFirestore firestore;
  final SharedPreferences preferences;

  Future<bool> hasAccepted(User user) async {
    if (!user.emailVerified) return false;
    if (hasCachedLegalConsent(preferences, user.uid)) return true;
    final profile = await firestore.collection('users').doc(user.uid).get();
    if (profile.data()?['legalConsentVersion'] ==
        AppConstants.currentLegalConsentVersion) {
      await cacheLegalConsentAcceptance(preferences, user.uid);
      return true;
    }
    if (profile.metadata.isFromCache) {
      throw StateError('Consent status could not be confirmed online');
    }
    // The old device-wide value has no owner. It cannot establish which
    // account accepted the update, so it is deliberately not migrated.
    return false;
  }

  Future<void> accept(User user) async {
    if (!user.emailVerified) throw StateError('Verified user required');
    await ensureVerifiedProfile(
      firestore,
      user,
      acceptedLegalConsentVersion: AppConstants.currentLegalConsentVersion,
    );
    await cacheLegalConsentAcceptance(preferences, user.uid);
  }
}
