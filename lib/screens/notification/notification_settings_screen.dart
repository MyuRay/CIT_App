import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/notification_preference_provider.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../models/notification/notification_preference_model.dart';
import '../../services/notification/notification_preference_service.dart';
import '../../services/schedule/schedule_notification_service.dart';
import '../../services/schedule/schedule_service.dart';

/// プッシュ通知の受信設定（アプリ内の通知一覧はオフでも表示されます）
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final prefsAsync = ref.watch(notificationPreferencesProvider);
    final scheduleEnabled = ref.watch(scheduleNotificationEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('プッシュ通知設定')),
      body:
          uid == null
              ? const Center(child: Text('ログインが必要です'))
              : prefsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
                data:
                    (prefs) => ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _SectionHeader(title: '掲示板', subtitle: '掲示板でのやり取り'),
                        ..._keysForSection(_Section.bulletin).map(
                          (key) => _PreferenceTile(
                            preferenceKey: key,
                            enabled:
                                key == NotificationPreferenceKey.scheduleClass
                                    ? scheduleEnabled
                                    : prefs.isEnabled(key),
                            onChanged:
                                (value) =>
                                    _onChanged(context, ref, uid, key, value),
                          ),
                        ),
                        const Divider(height: 24),
                        _SectionHeader(
                          title: '交流（Cwitter）',
                          subtitle: 'Cwitterでのやり取り',
                        ),
                        ..._keysForSection(_Section.cwitter).map(
                          (key) => _PreferenceTile(
                            preferenceKey: key,
                            enabled: prefs.isEnabled(key),
                            onChanged:
                                (value) =>
                                    _onChanged(context, ref, uid, key, value),
                          ),
                        ),
                        const Divider(height: 24),
                        _SectionHeader(
                          title: '交流（ちばちゃんねる）',
                          subtitle: '匿名掲示板でのやり取り',
                        ),
                        ..._keysForSection(_Section.chibaChannel).map(
                          (key) => _PreferenceTile(
                            preferenceKey: key,
                            enabled: prefs.isEnabled(key),
                            onChanged:
                                (value) =>
                                    _onChanged(context, ref, uid, key, value),
                          ),
                        ),
                        const Divider(height: 24),
                        _SectionHeader(
                          title: 'その他',
                          subtitle: '審査・お問い合わせ・運営からの連絡',
                        ),
                        ..._keysForSection(_Section.other).map(
                          (key) => _PreferenceTile(
                            preferenceKey: key,
                            enabled:
                                key == NotificationPreferenceKey.scheduleClass
                                    ? scheduleEnabled
                                    : prefs.isEnabled(key),
                            onChanged:
                                (value) =>
                                    _onChanged(context, ref, uid, key, value),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'オフにした種類はプッシュ通知（端末への通知）のみ停止します。アプリ内の通知一覧には引き続き表示されます。講義開始前は端末のローカル通知です。',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
              ),
    );
  }

  static Future<void> _onChanged(
    BuildContext context,
    WidgetRef ref,
    String uid,
    NotificationPreferenceKey key,
    bool value,
  ) async {
    try {
      if (key == NotificationPreferenceKey.scheduleClass) {
        await ref
            .read(settingsProvider.notifier)
            .setScheduleNotificationEnabled(value);
        if (value) {
          // ON にしたら現在の時間割で通知を予約する。
          // （以前は ON 時に何もせず、再起動するまで通知が来なかった）
          await _rescheduleScheduleNotifications(ref, uid);
        } else {
          await ScheduleNotificationService.cancelAllNotifications();
        }
        return;
      }

      await NotificationPreferenceService.setEnabled(
        userId: uid,
        key: key,
        enabled: value,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('設定の保存に失敗しました: $e'),
          backgroundColor: AppColors.snackBarSurface(context, Colors.red),
        ),
      );
    }
  }

  /// 現在選択中（なければ先頭）の時間割で講義通知を予約し直す。
  static Future<void> _rescheduleScheduleNotifications(
    WidgetRef ref,
    String uid,
  ) async {
    try {
      final schedules = await ScheduleService.getAllSchedulesByUserId(uid);
      if (schedules.isEmpty) return;
      final selectedId = ref.read(selectedScheduleIdProvider);
      var schedule = schedules.first;
      if (selectedId != null) {
        for (final s in schedules) {
          if (s.id == selectedId) {
            schedule = s;
            break;
          }
        }
      }
      await ScheduleNotificationService.scheduleWeeklyNotifications(schedule);
    } catch (e) {
      // 予約失敗は通知設定自体の保存を妨げない。
      debugPrint('⚠️ 講義通知の再予約に失敗: $e');
    }
  }
}

enum _Section { bulletin, cwitter, chibaChannel, other }

List<NotificationPreferenceKey> _keysForSection(_Section section) {
  switch (section) {
    case _Section.bulletin:
      return [
        NotificationPreferenceKey.bulletinComment,
        NotificationPreferenceKey.bulletinReply,
        NotificationPreferenceKey.bulletinModeration,
      ];
    case _Section.cwitter:
      return [
        NotificationPreferenceKey.cwitterReply,
        NotificationPreferenceKey.cwitterLike,
        NotificationPreferenceKey.cwitterFollow,
      ];
    case _Section.chibaChannel:
      return [
        NotificationPreferenceKey.chibaChannelThreadReply,
        NotificationPreferenceKey.chibaChannelCommentReply,
      ];
    case _Section.other:
      return [
        NotificationPreferenceKey.contactReply,
        NotificationPreferenceKey.scheduleClass,
        NotificationPreferenceKey.globalAnnouncement,
      ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.preferenceKey,
    required this.enabled,
    required this.onChanged,
  });

  final NotificationPreferenceKey preferenceKey;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: enabled,
      onChanged: (v) => onChanged(v ?? false),
      title: Text(preferenceKey.title),
      subtitle: Text(preferenceKey.description),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
