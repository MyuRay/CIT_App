import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Called only when a user enables reminders, never by background scheduling.
Future<bool> ensureReminderAlarmPermission(BuildContext context) async {
  final android =
      FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
  // iOS/web do not have Android's special alarm access setting.
  if (android == null) return true;

  try {
    final granted = await android.canScheduleExactNotifications() == true;
    if (!context.mounted) return false;
    if (granted) return true;

    final openSettings = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('アラームとリマインダーの設定'),
            content: const Text(
              '時間割・課題の通知を指定した時刻に届けるため、'
              'Androidの「アラームとリマインダー」を許可してください。\n\n'
              '設定画面でCIT Appの「アラームとリマインダーの設定を許可」を'
              'オンにしてから、アプリに戻ってください。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('設定を開く'),
              ),
            ],
          ),
    );
    if (openSettings != true || !context.mounted) return false;

    // The plugin opens this app's Android settings page and completes when the
    // user returns, reporting whether exact alarm access was actually granted.
    final allowed = await android.requestExactAlarmsPermission() == true;
    if (!context.mounted) return false;
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('「アラームとリマインダー」が許可されていないため、通知をオンにできませんでした。'),
        ),
      );
    }
    return allowed;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アラームとリマインダーの設定を確認できませんでした。もう一度お試しください。')),
      );
    }
    return false;
  }
}
