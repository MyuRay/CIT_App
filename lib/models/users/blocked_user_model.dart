import 'package:cloud_firestore/cloud_firestore.dart';

// ブロック理由の列挙型
enum BlockReason {
  harassment,
  spam,
  personal,
  other;

  String get displayName {
    switch (this) {
      case BlockReason.harassment:
        return 'ハラスメント';
      case BlockReason.spam:
        return 'スパム行為';
      case BlockReason.personal:
        return '個人的な理由';
      case BlockReason.other:
        return 'その他';
    }
  }

  static BlockReason fromString(String value) {
    switch (value) {
      case 'harassment':
        return BlockReason.harassment;
      case 'spam':
        return BlockReason.spam;
      case 'personal':
        return BlockReason.personal;
      case 'other':
        return BlockReason.other;
      default:
        return BlockReason.other;
    }
  }

  String toJson() => name;
}

// ブロックユーザーモデル
class BlockedUser {
  final String id;
  final String blockedUserId;
  final String blockedUserName;
  final String userId; // ブロックを実施したユーザーのUID
  final BlockReason reason;
  final String? notes;
  final DateTime blockedAt;

  const BlockedUser({
    required this.id,
    required this.blockedUserId,
    required this.blockedUserName,
    required this.userId,
    required this.reason,
    this.notes,
    required this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    try {
      return BlockedUser(
        id: json['id'] as String? ?? '',
        blockedUserId: json['blockedUserId'] as String? ?? '',
        blockedUserName: json['blockedUserName'] as String? ?? '不明なユーザー',
        userId: json['userId'] as String? ?? '',
        reason: BlockReason.fromString(json['reason'] as String? ?? 'other'),
        notes: json['notes'] as String?,
        blockedAt: _parseDateTime(json['blockedAt']),
      );
    } catch (e) {
      print('BlockedUser.fromJson エラー: $e');
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
      'blockedUserId': blockedUserId,
      'blockedUserName': blockedUserName,
      'userId': userId,
      'reason': reason.toJson(),
      'notes': notes,
      'blockedAt': Timestamp.fromDate(blockedAt),
    };
  }

  // 時間表示用フォーマット
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(blockedAt);

    if (difference.inMinutes < 1) {
      return 'たった今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${blockedAt.year}/${blockedAt.month}/${blockedAt.day}';
    }
  }

  // コピー用メソッド
  BlockedUser copyWith({
    String? id,
    String? blockedUserId,
    String? blockedUserName,
    String? userId,
    BlockReason? reason,
    String? notes,
    DateTime? blockedAt,
  }) {
    return BlockedUser(
      id: id ?? this.id,
      blockedUserId: blockedUserId ?? this.blockedUserId,
      blockedUserName: blockedUserName ?? this.blockedUserName,
      userId: userId ?? this.userId,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      blockedAt: blockedAt ?? this.blockedAt,
    );
  }
}
