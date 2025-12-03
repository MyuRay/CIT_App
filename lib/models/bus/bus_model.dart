import 'package:cloud_firestore/cloud_firestore.dart';

/// 学バス情報の運行期間モデル
class BusOperationPeriod {
  final String id;
  final String name; // 例: "春学期", "秋学期", "夏休み"
  final String description; // 期間の説明
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  const BusOperationPeriod({
    required this.id,
    required this.name,
    this.description = '',
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory BusOperationPeriod.fromJson(Map<String, dynamic> json) {
    return BusOperationPeriod(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String? ?? '',
      startDate: (json['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
    };
  }

  /// 現在の日付が運行期間内かどうかをチェック
  bool isCurrentlyActive() {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(startDate.subtract(const Duration(days: 1))) && 
           now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// copyWithメソッド
  BusOperationPeriod copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return BusOperationPeriod(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// バス時刻表の1つの時刻エントリ
class BusTimeEntry {
  final String id;
  final int hour;
  final int minute;
  final String? note; // 例: "最終便", "土日のみ"
  final bool isActive;
  // ダイヤ種別: weekday | saturday | sunday
  final String dayType;

  const BusTimeEntry({
    required this.id,
    required this.hour,
    required this.minute,
    this.note,
    required this.isActive,
    this.dayType = 'weekday',
  });

  factory BusTimeEntry.fromJson(Map<String, dynamic> json) {
    return BusTimeEntry(
      id: (json['id'] as String?) ?? '',
      hour: (json['hour'] as int?) ?? 0,
      minute: (json['minute'] as int?) ?? 0,
      note: json['note'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      dayType: (json['dayType'] as String?) ?? 'weekday',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'note': note,
      'isActive': isActive,
      'dayType': dayType,
    };
  }

  /// 時刻を文字列で取得 (例: "08:30")
  String get timeString => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// copyWithメソッド
  BusTimeEntry copyWith({
    String? id,
    int? hour,
    int? minute,
    String? note,
    bool? isActive,
    String? dayType,
  }) {
    return BusTimeEntry(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      dayType: dayType ?? this.dayType,
    );
  }

  /// 現在時刻との比較用のDateTime
  DateTime get todayDateTime {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}

/// バス路線情報
class BusRoute {
  final String id;
  final String name; // 例: "津田沼 → 新習志野", "新習志野 → 津田沼"
  final String description; // 詳細説明
  final List<BusTimeEntry> timeEntries; // 時刻表
  final int sortOrder; // 表示順序
  final bool isActive;

  const BusRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.timeEntries,
    required this.sortOrder,
    required this.isActive,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String? ?? '',
      timeEntries: (json['timeEntries'] as List<dynamic>?)
          ?.map((e) => BusTimeEntry.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'timeEntries': timeEntries.map((e) => e.toJson()).toList(),
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  /// アクティブな時刻エントリのみを取得
  List<BusTimeEntry> get activeTimeEntries {
    final type = _currentDayType();
    return timeEntries
        .where((entry) => entry.isActive && (entry.dayType == type))
        .toList()
      ..sort((a, b) {
        if (a.hour != b.hour) return a.hour.compareTo(b.hour);
        return a.minute.compareTo(b.minute);
      });
  }

  /// copyWithメソッド
  BusRoute copyWith({
    String? id,
    String? name,
    String? description,
    List<BusTimeEntry>? timeEntries,
    int? sortOrder,
    bool? isActive,
  }) {
    return BusRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      timeEntries: timeEntries ?? this.timeEntries,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  /// 次のバスの時刻を取得
  BusTimeEntry? getNextBusTime() {
    final now = DateTime.now();
    final activeEntries = activeTimeEntries;
    for (final entry in activeEntries) {
      if (entry.todayDateTime.isAfter(now)) {
        return entry;
      }
    }
    // 本日の便が無ければ null（翌日は表示しない）
    return null;
  }

  /// その次のバスの時刻を取得（次の次の便）
  BusTimeEntry? getNextNextBusTime() {
    final now = DateTime.now();
    final activeEntries = activeTimeEntries;
    bool foundFirst = false;
    for (final entry in activeEntries) {
      if (entry.todayDateTime.isAfter(now)) {
        if (foundFirst) {
          // 最初の次の便の次を見つけた
          return entry;
        } else {
          // 最初の次の便を見つけた
          foundFirst = true;
        }
      }
    }
    // その次の便が無ければ null
    return null;
  }

  // 現在日のダイヤ種別を取得
  static String _currentDayType() {
    final wd = DateTime.now().weekday;
    if (wd == DateTime.saturday) return 'saturday';
    if (wd == DateTime.sunday) return 'sunday';
    return 'weekday';
  }
}

/// 学バス情報全体のモデル
class BusInformation {
  final String id;
  final String title; // 例: "千葉工業大学 学バス時刻表"
  final String description; // 全体的な説明
  final List<BusRoute> routes; // バス路線のリスト
  final List<BusOperationPeriod> operationPeriods; // 運行期間のリスト
  final DateTime lastUpdated; // 最終更新日時
  final String updatedBy; // 更新者

  const BusInformation({
    required this.id,
    required this.title,
    required this.description,
    required this.routes,
    required this.operationPeriods,
    required this.lastUpdated,
    required this.updatedBy,
  });

  factory BusInformation.fromJson(Map<String, dynamic> json) {
    return BusInformation(
      id: (json['id'] as String?) ?? '',
      title: json['title'] as String? ?? '学バス時刻表',
      description: json['description'] as String? ?? '',
      routes: (json['routes'] as List<dynamic>?)
          ?.map((e) => BusRoute.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      operationPeriods: (json['operationPeriods'] as List<dynamic>?)
          ?.map((e) => BusOperationPeriod.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      lastUpdated: (json['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: json['updatedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'routes': routes.map((e) => e.toJson()).toList(),
      'operationPeriods': operationPeriods.map((e) => e.toJson()).toList(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'updatedBy': updatedBy,
    };
  }

  /// 現在運行中かどうかをチェック
  bool get isCurrentlyOperating {
    return operationPeriods.any((period) => period.isCurrentlyActive());
  }

  /// 現在の運行期間を取得
  BusOperationPeriod? get currentOperationPeriod {
    try {
      return operationPeriods.firstWhere((period) => period.isCurrentlyActive());
    } catch (e) {
      return null;
    }
  }

  /// アクティブな路線のみを取得
  List<BusRoute> get activeRoutes {
    return routes.where((route) => route.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
  
  /// アクティブな運行期間のみを取得
  List<BusOperationPeriod> get activeOperationPeriods {
    return operationPeriods.where((period) => period.isActive).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }
}
