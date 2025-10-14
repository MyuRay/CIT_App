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
  user;

  String get displayName {
    switch (this) {
      case ReportType.post:
        return '投稿';
      case ReportType.comment:
        return 'コメント';
      case ReportType.user:
        return 'ユーザー';
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
      default:
        return ReportType.post;
    }
  }

  String toJson() => name;
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
    };
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
