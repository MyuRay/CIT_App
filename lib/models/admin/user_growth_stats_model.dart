/// ユーザー数推移の統計データモデル
class UserGrowthStats {
  final int totalUsers;
  final List<DailyStat> daily;
  final List<MonthlyStat> monthly;
  final DateTime generatedAt;

  UserGrowthStats({
    required this.totalUsers,
    required this.daily,
    required this.monthly,
    required this.generatedAt,
  });

  factory UserGrowthStats.fromJson(Map<String, dynamic> json) {
    return UserGrowthStats(
      totalUsers: json['totalUsers'] as int? ?? 0,
      daily: (json['daily'] as List<dynamic>?)
              ?.map((e) => DailyStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      monthly: (json['monthly'] as List<dynamic>?)
              ?.map((e) => MonthlyStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'daily': daily.map((e) => e.toJson()).toList(),
      'monthly': monthly.map((e) => e.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

/// 日次統計データ
class DailyStat {
  final String date;
  final int count;
  final int cumulative;

  DailyStat({
    required this.date,
    required this.count,
    required this.cumulative,
  });

  factory DailyStat.fromJson(Map<String, dynamic> json) {
    return DailyStat(
      date: json['date'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      cumulative: json['cumulative'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'count': count,
      'cumulative': cumulative,
    };
  }

  DateTime get dateTime => DateTime.parse(date);
}

/// 月次統計データ
class MonthlyStat {
  final String month;
  final int count;
  final int cumulative;

  MonthlyStat({
    required this.month,
    required this.count,
    required this.cumulative,
  });

  factory MonthlyStat.fromJson(Map<String, dynamic> json) {
    return MonthlyStat(
      month: json['month'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      cumulative: json['cumulative'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'count': count,
      'cumulative': cumulative,
    };
  }

  DateTime get dateTime {
    final parts = month.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }
}


