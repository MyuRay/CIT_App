import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'settings_provider.dart';

/// 規約同意後にインクリメントして UI を再評価する
final legalConsentRevisionProvider = StateProvider<int>((ref) => 0);

bool hasAcceptedCurrentLegalConsent(SharedPreferences prefs) {
  return prefs.getString(AppConstants.legalConsentAcceptedVersionKey) ==
      AppConstants.currentLegalConsentVersion;
}

final hasAcceptedCurrentLegalConsentProvider = Provider<bool>((ref) {
  ref.watch(legalConsentRevisionProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return hasAcceptedCurrentLegalConsent(prefs);
});

Future<void> recordLegalConsentAcceptance(WidgetRef ref) async {
  await ref.read(sharedPreferencesProvider).setString(
        AppConstants.legalConsentAcceptedVersionKey,
        AppConstants.currentLegalConsentVersion,
      );
  ref.read(legalConsentRevisionProvider.notifier).state++;
}
