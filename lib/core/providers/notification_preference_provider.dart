import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/notification/notification_preference_model.dart';
import '../../services/notification/notification_preference_service.dart';
import 'auth_provider.dart';

final notificationPreferencesProvider =
    StreamProvider<NotificationPreferences>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) {
    return Stream.value(NotificationPreferences.defaults());
  }
  return NotificationPreferenceService.watchPreferences(uid);
});
