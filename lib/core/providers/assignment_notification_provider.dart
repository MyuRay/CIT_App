import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../services/schedule/schedule_notification_service.dart';
import 'assignment_provider.dart';
import 'settings_provider.dart';

final assignmentNotificationsEnabledProvider = StateProvider<bool>((ref) {
  final uid = ref.watch(assignmentUserIdProvider);
  return uid != null &&
      (ref
              .watch(sharedPreferencesProvider)
              .getBool('assignmentReminders:$uid') ??
          false);
});
final setAssignmentNotificationsEnabledProvider = Provider(
  (ref) => (bool enabled) async {
    final uid = ref.read(assignmentUserIdProvider);
    if (uid == null) throw StateError('ログイン状態を確認してください');
    await ref
        .read(sharedPreferencesProvider)
        .setBool('assignmentReminders:$uid', enabled);
    if (ref.read(assignmentUserIdProvider) == uid) {
      ref.read(assignmentNotificationsEnabledProvider.notifier).state = enabled;
    }
  },
);

/// Reconcile all reminders after task edits, completion, deletion or sign-in.
final assignmentReminderSyncProvider = Provider<void>((ref) {
  final uid = ref.watch(assignmentUserIdProvider);
  final enabled = ref.watch(assignmentNotificationsEnabledProvider);
  final tasks = ref.watch(assignmentsProvider);
  if (uid == null || (enabled && !tasks.hasValue)) return;
  unawaited(
    ScheduleNotificationService.scheduleAssignmentReminders(
      uid,
      tasks.valueOrNull ?? [],
      enabled: enabled,
    ).catchError((Object _) => 0),
  );
});
