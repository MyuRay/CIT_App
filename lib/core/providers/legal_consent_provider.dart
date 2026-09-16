import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth/legal_consent_service.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';

/// 規約同意後にインクリメントして UI を再評価する
final legalConsentRevisionProvider = StateProvider<int>((ref) => 0);

final legalConsentServiceProvider = Provider(
  (ref) => LegalConsentService(
    FirebaseFirestore.instance,
    ref.watch(sharedPreferencesProvider),
  ),
);

final legalConsentStatusProvider = FutureProvider<bool>((ref) async {
  ref.watch(legalConsentRevisionProvider);
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null || !user.emailVerified) return false;
  return ref.watch(legalConsentServiceProvider).hasAccepted(user);
});

final hasAcceptedCurrentLegalConsentProvider = Provider<bool>((ref) {
  ref.watch(legalConsentRevisionProvider);
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null || !user.emailVerified) return false;
  final prefs = ref.watch(sharedPreferencesProvider);
  final status = ref.watch(legalConsentStatusProvider);
  return hasCachedLegalConsent(prefs, user.uid) ||
      (!status.isLoading && status.asData?.value == true);
});

Future<void> recordLegalConsentAcceptance(WidgetRef ref) async {
  final user = ref.read(firebaseAuthProvider).currentUser;
  if (user == null) throw StateError('Signed-in user required');
  final revision = ref.read(legalConsentRevisionProvider.notifier);
  await ref.read(legalConsentServiceProvider).accept(user);
  revision.state++;
}
