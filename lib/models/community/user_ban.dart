import 'package:cloud_firestore/cloud_firestore.dart';

/// 垢BANの理由（運営が選択）
enum BanReason {
  spam('スパム・宣伝行為'),
  harassment('誹謗中傷・嫌がらせ'),
  inappropriate('不適切・公序良俗に反する投稿'),
  privacy('個人情報・プライバシーの侵害'),
  impersonation('なりすまし行為'),
  illegal('違法行為・犯罪予告'),
  other('その他の利用規約違反');

  const BanReason(this.label);

  /// ユーザーに表示する理由文
  final String label;

  static BanReason fromKey(String? key) {
    return BanReason.values.firstWhere(
      (reason) => reason.name == key,
      orElse: () => BanReason.other,
    );
  }
}

/// 垢BANの期間
enum BanDuration {
  day('1日BAN', Duration(days: 1)),
  month('30日BAN', Duration(days: 30)),
  permanent('永久BAN', null);

  const BanDuration(this.label, this.duration);

  final String label;

  /// null の場合は永久BAN
  final Duration? duration;

  bool get isPermanent => duration == null;

  static BanDuration fromKey(String? key) {
    return BanDuration.values.firstWhere(
      (value) => value.name == key,
      orElse: () => BanDuration.permanent,
    );
  }
}

/// 運営による垢BAN情報（banned_users/{userId}）
class UserBan {
  const UserBan({
    required this.userId,
    required this.reason,
    required this.duration,
    required this.bannedAt,
    required this.expiresAt,
    required this.bannedBy,
  });

  final String userId;
  final BanReason reason;
  final BanDuration duration;
  final DateTime bannedAt;

  /// 永久BAN（[duration] が permanent）の場合は null
  final DateTime? expiresAt;
  final String bannedBy;

  bool get isPermanent => duration.isPermanent;

  /// 現在もBANが有効か（期限切れなら false）
  bool isActiveAt(DateTime now) {
    if (isPermanent) return true;
    final expires = expiresAt;
    if (expires == null) return true;
    return now.isBefore(expires);
  }

  factory UserBan.fromJson(String userId, Map<String, dynamic> json) {
    final duration = BanDuration.fromKey(json['durationKey'] as String?);
    return UserBan(
      userId: userId,
      reason: BanReason.fromKey(json['reasonKey'] as String?),
      duration: duration,
      bannedAt: _parseDate(json['bannedAt']) ?? DateTime.now(),
      expiresAt: duration.isPermanent ? null : _parseDate(json['expiresAt']),
      bannedBy: json['bannedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'reasonKey': reason.name,
      'reasonLabel': reason.label,
      'durationKey': duration.name,
      'durationLabel': duration.label,
      'permanent': isPermanent,
      'bannedAt': Timestamp.fromDate(bannedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'bannedBy': bannedBy,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
