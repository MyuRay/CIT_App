import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth/email_registration.dart';
import '../../services/auth/verified_profile.dart';
import '../constants/app_constants.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';

final registrationCompletingProvider = StateProvider<bool>((ref) => false);
final emailRegistrationServiceProvider = Provider(
  (ref) => EmailRegistrationService(
    ref.watch(firebaseAuthProvider),
    ref.watch(sharedPreferencesProvider),
    saveProfile: (user) async {
      await ensureVerifiedProfile(
        FirebaseFirestore.instance,
        user,
        syncDisplayName: true,
        acceptedLegalConsentVersion: AppConstants.currentLegalConsentVersion,
      );
    },
  ),
);
