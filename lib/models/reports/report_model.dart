import 'package:cloud_firestore/cloud_firestore.dart';

// 通報理由の列挙型
enum ReportReason {
  spam,
  abuse,
  inappropriate,
  other;

  String get displayName {
    switch (this) {
      case ReportReason.spam:
        return 'スパム';
      case ReportReason.abuse:
        return '誹謗中傷・嫌がらせ';
      case ReportReason.inappropriate:
        return '不適切なコンテンツ';
      case ReportReason.other:
        return 'その他';
    }
  }

  static ReportReason fromString(String value) {
    switch (value) {
      case 'spam':
        return ReportReason.spam;
      case 'abuse':
        return ReportReason.abuse;
      case 'inappropriate':
        return ReportReason.inappropriate;
      case 'other':
        return ReportReason.other;
      default:
        return ReportReason.other;
    }
  }

  String toJson() => name;
}

// 通報ステータスの列挙型
enum ReportStatus {
  pending,
  reviewing,
  resolved,
  rejected;

  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return '未対応';
      case ReportStatus.reviewing:
        return '確認中';
      case ReportStatus.resolved:
        return '対応済み';
      case ReportStatus.rejected:
        return '却下';
    }
  }

  static ReportStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return ReportStatus.pending;
      case 'reviewing':
        return ReportStatus.reviewing;
      case 'resolved':
        return ReportStatus.resolved;
      case 'rejected':
        return ReportStatus.rejected;
      default:
        return ReportStatus.pending;
    }
  }

  String toJson() => name;
}

// 通報対象の種別
enum ReportType {
  post,
  comment,
  user,
  cwitterPost,
  cwitterReply,
  chibaChannelComment;

  String get displayName {
    switch (this) {
      case ReportType.post:
        return '掲示板投稿';
      case ReportType.comment:
        return '掲示板コメント';
      case ReportType.user:
        return 'ユーザー';
      case ReportType.cwitterPost:
        return 'Cweet';
      case ReportType.cwitterReply:
        return 'Cwitter返信';
      case ReportType.chibaChannelComment:
        return 'ちばちゃんねるレス';
    }
  }

  static ReportType fromString(String value) {
    switch (value) {
      case 'post':
        return ReportType.post;
      case 'comment':
        return ReportType.comment;
      case 'user':
        return ReportType.user;
      case 'cwitter_post':
        return ReportType.cwitterPost;
      case 'cwitter_reply':
        return ReportType.cwitterReply;
      case 'chiba_channel_comment':
        return ReportType.chibaChannelComment;
      default:
        return ReportType.post;
    }
  }

  String toJson() {
    switch (this) {
      case ReportType.cwitterPost:
        return 'cwitter_post';
      case ReportType.cwitterReply:
        return 'cwitter_reply';
      case ReportType.chibaChannelComment:
        return 'chiba_channel_comment';
      default:
        return name;
    }
  }
}

/// 管理者向けに保存する通報時点のスナップショット
class ReportModerationSnapshot {
  const ReportModerationSnapshot({
    this.reporterEmail,
    this.targetContent,
    this.targetAuthorId,
    this.targetAuthorName,
    this.targetAuthorEmail,
    this.targetAuthorCwitterId,
    this.targetPostId,
    this.source,
  });

  final String? reporterEmail;
  final String? targetContent;
  final String? targetAuthorId;
  final String? targetAuthorName;
  final String? targetAuthorEmail;
  final String? targetAuthorCwitterId;
  final String? targetPostId;
  final String? source;

  Map<String, dynamic> toJson() {
    return {
      if (reporterEmail != null && reporterEmail!.isNotEmpty)
        'reporterEmail': reporterEmail,
      if (targetContent != null && targetContent!.isNotEmpty)
        'targetContent': targetContent,
      if (targetAuthorId != null && targetAuthorId!.isNotEmpty)
        'targetAuthorId': targetAuthorId,
      if (targetAuthorName != null && targetAuthorName!.isNotEmpty)
        'targetAuthorName': targetAuthorName,
      if (targetAuthorEmail != null && targetAuthorEmail!.isNotEmpty)
        'targetAuthorEmail': targetAuthorEmail,
      if (targetAuthorCwitterId != null && targetAuthorCwitterId!.isNotEmpty)
        'targetAuthorCwitterId': targetAuthorCwitterId,
      if (targetPostId != null && targetPostId!.isNotEmpty)
        'targetPostId': targetPostId,
      if (source != null && source!.isNotEmpty) 'source': source,
    };
  }
}

// 通報モデル
class Report {
  final String id;
  final ReportType type;
  final String targetId;
  final String reporterId;
  final String reporterName;
  final ReportReason reason;
  final String? detail;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? resolutionNote; // 管理者の対応メモ
  final String? reporterEmail;
  final String? targetContent;
  final String? targetAuthorId;
  final String? targetAuthorName;
  final String? targetAuthorEmail;
  final String? targetAuthorCwitterId;
  final String? targetPostId;
  final String? source;

  const Report({
    required this.id,
    required this.type,
    required this.targetId,
    required this.reporterId,
    required this.reporterName,
    required this.reason,
    this.detail,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.resolutionNote,
    this.reporterEmail,
    this.targetContent,
    this.targetAuthorId,
    this.targetAuthorName,
    this.targetAuthorEmail,
    this.targetAuthorCwitterId,
    this.targetPostId,
    this.source,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    try {
      return Report(
        id: json['id'] as String? ?? '',
        type: ReportType.fromString(json['type'] as String? ?? 'post'),
        targetId: json['targetId'] as String? ?? '',
        reporterId: json['reporterId'] as String? ?? '',
        reporterName: json['reporterName'] as String? ?? '匿名',
        reason: ReportReason.fromString(json['reason'] as String? ?? 'other'),
        detail: json['detail'] as String?,
        status: ReportStatus.fromString(json['status'] as String? ?? 'pending'),
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: json['updatedAt'] != null ? _parseDateTime(json['updatedAt']) : null,
        resolutionNote: json['resolutionNote'] as String?,
        reporterEmail: json['reporterEmail'] as String?,
        targetContent: json['targetContent'] as String?,
        targetAuthorId: json['targetAuthorId'] as String?,
        targetAuthorName: json['targetAuthorName'] as String?,
        targetAuthorEmail: json['targetAuthorEmail'] as String?,
        targetAuthorCwitterId: json['targetAuthorCwitterId'] as String?,
        targetPostId: json['targetPostId'] as String?,
        source: json['source'] as String?,
      );
    } catch (e) {
      print('Report.fromJson エラー: $e');
      print('問題のあるJSON: $json');
      rethrow;
    }
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) {
      return DateTime.now();
    }

    // Firestore Timestamp型の場合
    if (dateTime is Timestamp) {
      return dateTime.toDate();
    }

    // DateTime型の場合
    if (dateTime is DateTime) {
      return dateTime;
    }

    // String型の場合
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        print('日付の解析に失敗: $dateTime, エラー: $e');
        return DateTime.now();
      }
    }

    // その他の場合は現在時刻を返す
    print('未対応の日付型: ${dateTime.runtimeType} - $dateTime');
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJson(),
      'targetId': targetId,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reason': reason.toJson(),
      'detail': detail,
      'status': status.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'resolutionNote': resolutionNote,
      if (reporterEmail != null) 'reporterEmail': reporterEmail,
      if (targetContent != null) 'targetContent': targetContent,
      if (targetAuthorId != null) 'targetAuthorId': targetAuthorId,
      if (targetAuthorName != null) 'targetAuthorName': targetAuthorName,
      if (targetAuthorEmail != null) 'targetAuthorEmail': targetAuthorEmail,
      if (targetAuthorCwitterId != null)
        'targetAuthorCwitterId': targetAuthorCwitterId,
      if (targetPostId != null) 'targetPostId': targetPostId,
      if (source != null) 'source': source,
    };
  }

  String get targetAuthorLabel {
    final name = targetAuthorName?.trim();
    final cwitterId = targetAuthorCwitterId?.trim();
    if (name != null && name.isNotEmpty && cwitterId != null && cwitterId.isNotEmpty) {
      return '$name (@$cwitterId)';
    }
    if (name != null && name.isNotEmpty) return name;
    if (cwitterId != null && cwitterId.isNotEmpty) return '@$cwitterId';
    return targetAuthorId ?? '不明';
  }

  // 時間表示用フォーマット
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
      return '${createdAt.year}/${createdAt.month}/${createdAt.day}';
    }
  }

  // コピー用メソッド
  Report copyWith({
    String? id,
    ReportType? type,
    String? targetId,
    String? reporterId,
    String? reporterName,
    ReportReason? reason,
    String? detail,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? resolutionNote,
  }) {
    return Report(
      id: id ?? this.id,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reason: reason ?? this.reason,
      detail: detail ?? this.detail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolutionNote: resolutionNote ?? this.resolutionNote,
    );
  }
}
