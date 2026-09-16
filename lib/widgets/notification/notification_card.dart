import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/notification/notification_model.dart';

/// Notification content stays full width even with large system text.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
    required this.onDelete,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background =
        notification.isRead
            ? scheme.surfaceContainerLow
            : scheme.primaryContainer;
    final foreground =
        notification.isRead ? scheme.onSurface : scheme.onPrimaryContainer;
    final secondary =
        notification.isRead
            ? scheme.onSurfaceVariant
            : scheme.onPrimaryContainer;
    final accent = AppColors.ensureContrast(
      colorFor(notification.type),
      background,
    );

    return Card(
      color: background,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(iconFor(notification.type), color: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight:
                            notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notification.message,
                style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${notification.isRead ? '既読' : '未読'} · ${notification.timeAgo}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondary,
                      ),
                    ),
                  ),
                  if (!notification.isRead)
                    IconButton(
                      tooltip: '既読にする',
                      icon: Icon(Icons.mark_email_read, color: foreground),
                      onPressed: onMarkRead,
                    ),
                  IconButton(
                    tooltip: '通知を削除',
                    icon: Icon(Icons.delete_outline, color: foreground),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData iconFor(NotificationType type) => switch (type) {
    NotificationType.comment => Icons.comment,
    NotificationType.reply => Icons.reply,
    NotificationType.like => Icons.thumb_up,
    NotificationType.follow => Icons.person_add,
    NotificationType.postApproved => Icons.check_circle,
    NotificationType.postRejected => Icons.cancel,
    NotificationType.pinApproved => Icons.push_pin,
    NotificationType.pinRejected => Icons.push_pin_outlined,
    NotificationType.system => Icons.info,
    NotificationType.appUpdate => Icons.system_update,
    NotificationType.maintenance => Icons.build,
    NotificationType.important => Icons.priority_high,
    NotificationType.general => Icons.campaign,
    NotificationType.feature => Icons.new_releases,
  };

  static Color colorFor(NotificationType type) => switch (type) {
    NotificationType.comment ||
    NotificationType.pinApproved ||
    NotificationType.general => Colors.blue,
    NotificationType.reply ||
    NotificationType.follow ||
    NotificationType.postApproved => Colors.green,
    NotificationType.like ||
    NotificationType.postRejected ||
    NotificationType.important => Colors.red,
    NotificationType.pinRejected || NotificationType.system => Colors.orange,
    NotificationType.appUpdate => Colors.purple,
    NotificationType.maintenance => Colors.amber,
    NotificationType.feature => Colors.teal,
  };
}
