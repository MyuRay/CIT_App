import 'package:cloud_firestore/cloud_firestore.dart';

// 通知の種類
enum NotificationType {
  comment('comment', 'コメント'),
  reply('reply', '返信'),
  like('like', 'いいね'),
  follow('follow', 'フォロー'),
  postApproved('post_approved', '投稿承認'),
  postRejected('post_rejected', '投稿却下'),
  pinApproved('pin_approved', 'ピン留め承認'),
  pinRejected('pin_rejected', 'ピン留め却下'),
  system('system', 'システム'),
  appUpdate('app_update', 'アプリアップデート'),
  maintenance('maintenance', 'メンテナンス'),
  important('important', '重要なお知らせ'),
  general('general', 'お知らせ'),
  feature('feature', '新機能');

  const NotificationType(this.id, this.displayName);
  final String id;
  final String displayName;
}

// 通知モデル
class AppNotification {
  final String id;
  final String userId; // 通知を受け取るユーザー
  final NotificationType type;
  final String title;
  final String message;
  final String? postId; // 関連する投稿ID
  final String? commentId; // 関連するコメントID
  final String? fromUserId; // 通知の送信者
  final String? fromUserName; // 通知の送信者名
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data; // 追加データ

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.postId,
    this.commentId,
    this.fromUserId,
    this.fromUserName,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: NotificationType.values.firstWhere(
        (t) => t.id == json['type'],
        orElse: () => NotificationType.system,
      ),
      title: json['title'] as String,
      message: json['message'] as String? ?? json['body'] as String? ?? '',
      postId: json['postId'] as String?,
      commentId: json['commentId'] as String?,
      fromUserId: json['fromUserId'] as String?,
      fromUserName: json['fromUserName'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isRead: json['isRead'] as bool? ?? json['read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.id,
      'title': title,
      'message': message,
      'postId': postId,
      'commentId': commentId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'data': data,
    };
  }

  // 通知の時間表示
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'たった今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${createdAt.month}/${createdAt.day}';
    }
  }

  // 通知のアイコン
  String get iconName {
    switch (type) {
      case NotificationType.comment:
        return 'comment';
      case NotificationType.reply:
        return 'reply';
      case NotificationType.like:
        return 'thumb_up';
      case NotificationType.follow:
        return 'person_add';
      case NotificationType.postApproved:
        return 'check_circle';
      case NotificationType.postRejected:
        return 'cancel';
      case NotificationType.pinApproved:
        return 'push_pin';
      case NotificationType.pinRejected:
        return 'push_pin_outlined';
      case NotificationType.system:
        return 'info';
      case NotificationType.appUpdate:
        return 'system_update';
      case NotificationType.maintenance:
        return 'build';
      case NotificationType.important:
        return 'priority_high';
      case NotificationType.general:
        return 'campaign';
      case NotificationType.feature:
        return 'new_releases';
    }
  }

  // コピーメソッド
  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? postId,
    String? commentId,
    String? fromUserId,
    String? fromUserName,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

// 通知作成用のファクトリーメソッド
class NotificationFactory {
  static AppNotification createCommentNotification({
    required String postAuthorId,
    required String postTitle,
    required String commentAuthorName,
    required String postId,
    required String commentId,
    String? fromUserId,
  }) {
    return AppNotification(
      id: '', // Firestoreで自動生成
      userId: postAuthorId,
      type: NotificationType.comment,
      title: '新しいコメント',
      message: '$commentAuthorName さんが「$postTitle」にコメントしました',
      postId: postId,
      commentId: commentId,
      fromUserId: fromUserId,
      fromUserName: commentAuthorName,
      createdAt: DateTime.now(),
    );
  }

  static AppNotification createReplyNotification({
    required String commentAuthorId,
    required String replyAuthorName,
    required String postTitle,
    required String postId,
    required String commentId,
    required String replyId,
    String? fromUserId,
  }) {
    return AppNotification(
      id: '', // Firestoreで自動生成
      userId: commentAuthorId,
      type: NotificationType.reply,
      title: '新しい返信',
      message: '$replyAuthorName さんが「$postTitle」であなたのコメントに返信しました',
      postId: postId,
      commentId: replyId, // 返信のID
      fromUserId: fromUserId,
      fromUserName: replyAuthorName,
      createdAt: DateTime.now(),
      data: {
        'parentCommentId': commentId, // 元のコメントID
      },
    );
  }

  static AppNotification createPostApprovedNotification({
    required String postAuthorId,
    required String postTitle,
    required String postId,
  }) {
    return AppNotification(
      id: '', // Firestoreで自動生成
      userId: postAuthorId,
      type: NotificationType.postApproved,
      title: '投稿が承認されました',
      message: '投稿「$postTitle」が管理者により承認され、公開されました',
      postId: postId,
      createdAt: DateTime.now(),
    );
  }

  static AppNotification createPostRejectedNotification({
    required String postAuthorId,
    required String postTitle,
    required String postId,
    String? reason,
  }) {
    final message = reason != null
        ? '投稿「$postTitle」は管理者により却下されました。理由: $reason'
        : '投稿「$postTitle」は管理者により却下されました';
    
    return AppNotification(
      id: '', // Firestoreで自動生成
      userId: postAuthorId,
      type: NotificationType.postRejected,
      title: '投稿が却下されました',
      message: message,
      postId: postId,
      createdAt: DateTime.now(),
      data: reason != null ? {'reason': reason} : null,
    );
  }

  static AppNotification createPinApprovedNotification({
    required String postAuthorId,
    required String postTitle,
    required String postId,
  }) {
    return AppNotification(
      id: '', // Firestoreで自動生成
      userId: postAuthorId,
      type: NotificationType.pinApproved,
      title: 'ピン留めが承認されました',
      message: '投稿「$postTitle」のピン留め申請が承認されました',
      postId: postId,
      createdAt: DateTime.now(),
    );
  }

  static AppNotification createPinRejectedNotification({
    required String postAuthorId,
    required String postTitle,
    required String postId,
    String? reason,
  }) {
    final message = reason != null
        ? '投稿「$postTitle」のピン留め申請は却下されました。理由: $reason'
        : '投稿「$postTitle」のピン留め申請は却下されました';
    
    return AppNotification(
      id: '', // Firestoreで自動生成
      userId: postAuthorId,
      type: NotificationType.pinRejected,
      title: 'ピン留め申請が却下されました',
      message: message,
      postId: postId,
      createdAt: DateTime.now(),
      data: reason != null ? {'reason': reason} : null,
    );
  }

  static String _truncatePreview(String? text, int maxLen) {
    if (text == null || text.trim().isEmpty) return '';
    final t = text.trim();
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen)}…';
  }

  static AppNotification createCwitterReplyNotification({
    required String postAuthorId,
    required String postId,
    required String replyId,
    required String fromUserName,
    required String fromCwitterId,
    String? fromUserId,
    String? postBodyPreview,
  }) {
    final preview = _truncatePreview(postBodyPreview, 40);
    final suffix = preview.isNotEmpty ? '「$preview」' : '';
    return AppNotification(
      id: '',
      userId: postAuthorId,
      type: NotificationType.reply,
      title: 'Cwitterに返信がありました',
      message: '$fromUserName (@$fromCwitterId) さんがあなたのCweetに返信しました$suffix',
      postId: postId,
      commentId: replyId,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      createdAt: DateTime.now(),
      data: const {'source': 'cwitter'},
    );
  }

  static AppNotification createCwitterLikeNotification({
    required String postAuthorId,
    required String postId,
    required String fromUserName,
    required String fromCwitterId,
    String? fromUserId,
    String? postBodyPreview,
  }) {
    final preview = _truncatePreview(postBodyPreview, 40);
    final suffix = preview.isNotEmpty ? '「$preview」' : '';
    return AppNotification(
      id: '',
      userId: postAuthorId,
      type: NotificationType.like,
      title: 'Cwitterにいいねがつきました',
      message: '$fromUserName (@$fromCwitterId) さんがあなたのCweetにいいねしました$suffix',
      postId: postId,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      createdAt: DateTime.now(),
      data: const {'source': 'cwitter'},
    );
  }

  static AppNotification createCwitterFollowNotification({
    required String followeeId,
    required String fromUserName,
    required String fromCwitterId,
    String? fromUserId,
  }) {
    return AppNotification(
      id: '',
      userId: followeeId,
      type: NotificationType.follow,
      title: 'Cwitterでフォローされました',
      message: '$fromUserName (@$fromCwitterId) さんがあなたをフォローしました',
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      createdAt: DateTime.now(),
      data: {
        'source': 'cwitter',
        'type': 'follow',
        'fromCwitterId': fromCwitterId,
      },
    );
  }

  static AppNotification createChibaChannelThreadReplyNotification({
    required String threadAuthorId,
    required String threadId,
    required String threadTitle,
    required String commentId,
    String? bodyPreview,
  }) {
    final preview = _truncatePreview(bodyPreview, 40);
    final suffix = preview.isNotEmpty ? '「$preview」' : '';
    return AppNotification(
      id: '',
      userId: threadAuthorId,
      type: NotificationType.comment,
      title: 'ちばちゃんねるにレスがありました',
      message: '名無しさんがあなたのスレ「$threadTitle」にレスしました$suffix',
      postId: threadId,
      commentId: commentId,
      createdAt: DateTime.now(),
      data: const {
        'source': 'chiba_channel',
        'kind': 'thread_reply',
      },
    );
  }

  static AppNotification createChibaChannelCommentReplyNotification({
    required String commentAuthorId,
    required String threadId,
    required String threadTitle,
    required String commentId,
    required int replyToCommentNumber,
    String? bodyPreview,
  }) {
    final preview = _truncatePreview(bodyPreview, 40);
    final suffix = preview.isNotEmpty ? '「$preview」' : '';
    return AppNotification(
      id: '',
      userId: commentAuthorId,
      type: NotificationType.reply,
      title: 'ちばちゃんねるに返信がありました',
      message:
          '名無しさんがあなたのレス（>>$replyToCommentNumber）に返信しました$suffix',
      postId: threadId,
      commentId: commentId,
      createdAt: DateTime.now(),
      data: {
        'source': 'chiba_channel',
        'kind': 'comment_reply',
        'threadTitle': threadTitle,
        'replyToCommentNumber': replyToCommentNumber,
      },
    );
  }

  static AppNotification createContactResponseNotification({
    required String contactUserId,
    required String contactSubject,
    required String contactId,
    required String response,
    String? responderName,
  }) {
    return AppNotification(
      id: '', // Firestoreで自動生成
      userId: contactUserId,
      type: NotificationType.general,
      title: 'お問い合わせへの返信',
      message: 'お問い合わせ「$contactSubject」への返信が届きました',
      createdAt: DateTime.now(),
      data: {
        'contactId': contactId,
        'response': response,
        'type': 'contact_response',
      },
      fromUserName: responderName ?? '管理者',
    );
  }
}

// 全体通知モデル（アプリアップデート等の全ユーザー向け通知）
class GlobalNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isActive;
  final String? version; // アプリバージョン（アップデート通知用）
  final String? url; // リンク先URL（任意）
  final DateTime? expiresAt; // 有効期限（任意）
  final Map<String, dynamic>? data; // 追加データ

  const GlobalNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isActive = true,
    this.version,
    this.url,
    this.expiresAt,
    this.data,
  });

  factory GlobalNotification.fromJson(Map<String, dynamic> json) {
    return GlobalNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (t) => t.id == json['type'],
        orElse: () => NotificationType.general,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isActive: json['isActive'] as bool? ?? true,
      version: json['version'] as String?,
      url: json['url'] as String?,
      expiresAt: json['expiresAt'] != null 
          ? (json['expiresAt'] as Timestamp).toDate() 
          : null,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.id,
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'version': version,
      'url': url,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'data': data,
    };
  }

  // 通知が現在有効かチェック
  bool get isCurrentlyActive {
    if (!isActive) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) {
      return false;
    }
    return true;
  }

  // 絵文字アイコン
  String get emoji {
    switch (type) {
      case NotificationType.appUpdate:
        return '🔄';
      case NotificationType.maintenance:
        return '🔧';
      case NotificationType.important:
        return '⚠️';
      case NotificationType.general:
        return '📢';
      case NotificationType.feature:
        return '✨';
      default:
        return '📱';
    }
  }

  GlobalNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isActive,
    String? version,
    String? url,
    DateTime? expiresAt,
    Map<String, dynamic>? data,
  }) {
    return GlobalNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      version: version ?? this.version,
      url: url ?? this.url,
      expiresAt: expiresAt ?? this.expiresAt,
      data: data ?? this.data,
    );
  }
}

// 全体通知作成用ファクトリーメソッド
class GlobalNotificationFactory {
  static GlobalNotification createAppUpdateNotification({
    required String version,
    required String message,
    DateTime? expiresAt,
  }) {
    return GlobalNotification(
      id: '', // Firestoreで自動生成
      type: NotificationType.appUpdate,
      title: 'CIT App アップデートのお知らせ',
      message: message,
      createdAt: DateTime.now(),
      version: version,
      expiresAt: expiresAt,
    );
  }

  static GlobalNotification createMaintenanceNotification({
    required String message,
    DateTime? expiresAt,
  }) {
    return GlobalNotification(
      id: '', // Firestoreで自動生成
      type: NotificationType.maintenance,
      title: 'メンテナンスのお知らせ',
      message: message,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
    );
  }

  static GlobalNotification createFeatureNotification({
    required String title,
    required String message,
    String? url,
    DateTime? expiresAt,
  }) {
    return GlobalNotification(
      id: '', // Firestoreで自動生成
      type: NotificationType.feature,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      url: url,
      expiresAt: expiresAt,
    );
  }
}