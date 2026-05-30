import '../../models/notification/notification_model.dart';

/// ユーザーがオン/オフできる通知カテゴリ（実際に送信されうる種別）
enum NotificationPreferenceKey {
  bulletinComment(
    'bulletin_comment',
    '掲示板のコメント',
    '自分の投稿にコメントが付いたときのプッシュ通知',
  ),
  bulletinReply(
    'bulletin_reply',
    '掲示板の返信',
    '自分のコメントに返信が付いたときのプッシュ通知',
  ),
  cwitterReply(
    'cwitter_reply',
    'Cwitterの返信',
    '自分のCweetに返信が付いたときのプッシュ通知',
  ),
  cwitterLike(
    'cwitter_like',
    'Cwitterのいいね',
    '自分のCweetにいいねが付いたときのプッシュ通知',
  ),
  cwitterFollow(
    'cwitter_follow',
    'Cwitterのフォロー',
    '自分がフォローされたときのプッシュ通知',
  ),
  chibaChannelThreadReply(
    'chiba_channel_thread',
    'ちばちゃんねる（スレへのレス）',
    '自分のスレッドにレスが付いたときのプッシュ通知',
  ),
  chibaChannelCommentReply(
    'chiba_channel_comment_reply',
    'ちばちゃんねる（返信）',
    '自分のレスに返信が付いたときのプッシュ通知',
  ),
  bulletinModeration(
    'bulletin_moderation',
    '掲示板の審査結果',
    '投稿・ピン留めの承認・却下のプッシュ通知',
  ),
  contactReply(
    'contact_reply',
    'お問い合わせへの返信',
    '管理者から返信が届いたときのプッシュ通知',
  ),
  scheduleClass(
    'schedule_class',
    '講義開始前',
    '講義開始まもなくのリマインダー（端末のローカル通知）',
  ),
  globalAnnouncement(
    'global_announcement',
    '運営からのお知らせ',
    'アップデート・メンテナンス・新機能などのプッシュ通知',
  );

  const NotificationPreferenceKey(this.id, this.title, this.description);

  final String id;
  final String title;
  final String description;

  static NotificationPreferenceKey? fromNotification(AppNotification notification) {
    switch (notification.type) {
      case NotificationType.comment:
        if (notification.data?['source'] == 'chiba_channel') {
          return NotificationPreferenceKey.chibaChannelThreadReply;
        }
        return NotificationPreferenceKey.bulletinComment;
      case NotificationType.reply:
        if (notification.data?['source'] == 'cwitter') {
          return NotificationPreferenceKey.cwitterReply;
        }
        if (notification.data?['source'] == 'chiba_channel') {
          return NotificationPreferenceKey.chibaChannelCommentReply;
        }
        return NotificationPreferenceKey.bulletinReply;
      case NotificationType.like:
        if (notification.data?['source'] == 'cwitter') {
          return NotificationPreferenceKey.cwitterLike;
        }
        return null;
      case NotificationType.follow:
        if (notification.data?['source'] == 'cwitter') {
          return NotificationPreferenceKey.cwitterFollow;
        }
        return null;
      case NotificationType.postApproved:
      case NotificationType.postRejected:
      case NotificationType.pinApproved:
      case NotificationType.pinRejected:
        return NotificationPreferenceKey.bulletinModeration;
      case NotificationType.general:
        if (notification.data?['type'] == 'contact_response') {
          return NotificationPreferenceKey.contactReply;
        }
        return null;
      case NotificationType.appUpdate:
      case NotificationType.maintenance:
      case NotificationType.important:
      case NotificationType.feature:
      case NotificationType.system:
        return NotificationPreferenceKey.globalAnnouncement;
    }
  }

  static bool isGlobalAnnouncementType(NotificationType type) {
    switch (type) {
      case NotificationType.appUpdate:
      case NotificationType.maintenance:
      case NotificationType.important:
      case NotificationType.general:
      case NotificationType.feature:
      case NotificationType.system:
        return true;
      default:
        return false;
    }
  }
}

/// Firestore `user_settings/{uid}.notificationPreferences` のマップ
class NotificationPreferences {
  const NotificationPreferences(this.values);

  final Map<NotificationPreferenceKey, bool> values;

  factory NotificationPreferences.defaults() {
    return NotificationPreferences({
      for (final key in NotificationPreferenceKey.values) key: true,
    });
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic>? raw) {
    final defaults = NotificationPreferences.defaults();
    if (raw == null || raw.isEmpty) return defaults;

    final merged = Map<NotificationPreferenceKey, bool>.from(defaults.values);
    for (final key in NotificationPreferenceKey.values) {
      final v = raw[key.id];
      if (v is bool) merged[key] = v;
    }
    return NotificationPreferences(merged);
  }

  Map<String, dynamic> toMap() {
    return {for (final e in values.entries) e.key.id: e.value};
  }

  bool isEnabled(NotificationPreferenceKey key) => values[key] ?? true;

  NotificationPreferences copyWithKey(NotificationPreferenceKey key, bool enabled) {
    return NotificationPreferences({...values, key: enabled});
  }
}
