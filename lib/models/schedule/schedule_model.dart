import 'package:cloud_firestore/cloud_firestore.dart';

// 時間割のクラス（科目）を表すモデル
class ScheduleClass {
  final String id;
  final String subjectName;  // 科目名
  final String classroom;    // 教室
  final String instructor;   // 担当教員
  final String color;        // 表示色（HEX形式）
  final String? notes;       // メモ
  final int duration;        // 連続時間（1=単体、以上は連続）
  final bool isStartCell;    // 連続講義の開始セルかどうか

  const ScheduleClass({
    required this.id,
    required this.subjectName,
    required this.classroom,
    required this.instructor,
    required this.color,
    this.notes,
    this.duration = 1,
    this.isStartCell = true,
  });

  factory ScheduleClass.fromJson(Map<String, dynamic> json) {
    return ScheduleClass(
      id: json['id'] ?? '',
      subjectName: json['subjectName'] ?? '',
      classroom: json['classroom'] ?? '',
      instructor: json['instructor'] ?? '',
      color: json['color'] ?? '#2196F3',
      notes: json['notes'] as String?,
      duration: json['duration'] ?? 1,
      isStartCell: json['isStartCell'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectName': subjectName,
      'classroom': classroom,
      'instructor': instructor,
      'color': color,
      'notes': notes,
      'duration': duration,
      'isStartCell': isStartCell,
    };
  }
}

// 時間割の時間枠を表すモデル
class TimeSlot {
  final int period;        // 時限（1-10）
  final String startTime;  // 開始時刻（例: "9:00"）
  final String endTime;    // 終了時刻（例: "10:00"）

  const TimeSlot({
    required this.period,
    required this.startTime,
    required this.endTime,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      period: json['period'] ?? 1,
      startTime: json['startTime'] ?? '9:00',
      endTime: json['endTime'] ?? '10:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

// 曜日を表すenum
enum Weekday {
  monday('月', 'Monday'),
  tuesday('火', 'Tuesday'),
  wednesday('水', 'Wednesday'),
  thursday('木', 'Thursday'),
  friday('金', 'Friday'),
  saturday('土', 'Saturday');

  const Weekday(this.shortName, this.fullName);
  
  final String shortName;  // 日本語短縮形
  final String fullName;   // 英語フルネーム
}

// 時間割のメインモデル
class Schedule {
  final String id;
  final String userId;
  final String semester;  // 学期（例: "2024年度前期"）
  final Map<String, Map<int, ScheduleClass?>> timetable; // [曜日][時限] = クラス
  final List<TimeSlot> timeSlots;  // 時間枠の定義
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Schedule({
    required this.id,
    required this.userId,
    required this.semester,
    required this.timetable,
    this.timeSlots = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    try {
      // Firestoreから取得したtimetableデータを解析
      final timetableData = json['timetable'] as Map<String, dynamic>? ?? {};
      final Map<String, Map<int, ScheduleClass?>> parsedTimetable = {};
      
      for (final weekdayEntry in timetableData.entries) {
        final weekdayKey = weekdayEntry.key;
        final periodsData = weekdayEntry.value as Map<String, dynamic>? ?? {};
        
        parsedTimetable[weekdayKey] = {};
        
        for (int period = 1; period <= 10; period++) {
          final periodData = periodsData[period.toString()];
          if (periodData != null && periodData is Map<String, dynamic>) {
            parsedTimetable[weekdayKey]![period] = ScheduleClass.fromJson(periodData);
          } else {
            parsedTimetable[weekdayKey]![period] = null;
          }
        }
      }
      
      // timeSlotsの解析（List/Map両対応）
      final dynamic timeSlotsField = json['timeSlots'];
      final List<TimeSlot> parsedTimeSlots;
      if (timeSlotsField is List) {
        parsedTimeSlots = timeSlotsField
            .where((item) => item is Map<String, dynamic>)
            .map((item) => TimeSlot.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (timeSlotsField is Map<String, dynamic>) {
        parsedTimeSlots = timeSlotsField.entries
            .where((e) => e.value is Map<String, dynamic>)
            .map((e) => TimeSlot.fromJson(e.value as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.period.compareTo(b.period));
      } else {
        parsedTimeSlots = [];
      }

      return Schedule(
        id: json['id'] ?? '',
        userId: json['userId'] ?? '',
        semester: json['semester'] ?? '${DateTime.now().year}年度',
        timetable: parsedTimetable,
        timeSlots: parsedTimeSlots,
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
      );
    } catch (e) {
      print('Schedule.fromJson エラー: $e');
      print('問題のあるJSON: $json');
      rethrow;
    }
  }

  // Firestoreのドキュメントから生成（ドキュメントIDを優先的に利用）
  factory Schedule.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    // データ内にidフィールドが無い/空の場合はdoc.idを使う
    final json = Map<String, dynamic>.from(data);
    final hasId = (json['id'] is String) && (json['id'] as String).isNotEmpty;
    if (!hasId) {
      json['id'] = doc.id;
    }
    return Schedule.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> timetableJson = {};
    
    for (final weekdayEntry in timetable.entries) {
      final weekdayKey = weekdayEntry.key;
      final periodsMap = weekdayEntry.value;
      
      timetableJson[weekdayKey] = {};
      
      for (final periodEntry in periodsMap.entries) {
        final period = periodEntry.key;
        final scheduleClass = periodEntry.value;
        
        timetableJson[weekdayKey][period.toString()] = scheduleClass?.toJson();
      }
    }

    final Map<String, dynamic> timeSlotsJson = {
      for (final slot in timeSlots) slot.period.toString(): slot.toJson(),
    };

    return {
      'id': id,
      'userId': userId,
      'semester': semester,
      'timetable': timetableJson,
      // Firestoreルール準拠のため、timeSlotsはMapとして保存
      'timeSlots': timeSlotsJson,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // 互換用: timeSlotsをListで保存する形式
  Map<String, dynamic> toJsonWithListTimeSlots() {
    final base = toJson();
    final List<Map<String, dynamic>> timeSlotsList = timeSlots.map((e) => e.toJson()).toList();
    base['timeSlots'] = timeSlotsList;
    return base;
  }

  static DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    
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
        return null;
      }
    }
    
    return null;
  }
}

// デフォルトの時間枠を提供するクラス
class DefaultTimeSlots {
  static List<TimeSlot> get citTimeSlots => [
    const TimeSlot(period: 1, startTime: "9:00", endTime: "10:00"),
    const TimeSlot(period: 2, startTime: "10:00", endTime: "11:00"),
    const TimeSlot(period: 3, startTime: "11:00", endTime: "12:00"),
    const TimeSlot(period: 4, startTime: "12:00", endTime: "13:00"),
    const TimeSlot(period: 5, startTime: "13:00", endTime: "14:00"),
    const TimeSlot(period: 6, startTime: "14:00", endTime: "15:00"),
    const TimeSlot(period: 7, startTime: "15:00", endTime: "16:00"),
    const TimeSlot(period: 8, startTime: "16:00", endTime: "17:00"),
    const TimeSlot(period: 9, startTime: "17:00", endTime: "18:00"),
    const TimeSlot(period: 10, startTime: "18:00", endTime: "19:00"),
  ];

  // 空の時間割を作成するヘルパー
  static Map<String, Map<int, ScheduleClass?>> createEmptyTimetable() {
    final timetable = <String, Map<int, ScheduleClass?>>{};
    
    for (final weekday in Weekday.values) {
      timetable[weekday.name] = <int, ScheduleClass?>{};
      for (int period = 1; period <= 10; period++) {
        timetable[weekday.name]![period] = null;
      }
    }
    
    return timetable;
  }

  // デフォルトの時間割を作成
  static Schedule createDefault({
    required String id,
    required String userId,
    String? semester,
  }) {
    return Schedule(
      id: id,
      userId: userId,
      semester: semester ?? '${DateTime.now().year}年度',
      timetable: createEmptyTimetable(),
      timeSlots: citTimeSlots,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

// 時間割に関するユーティリティクラス
class ScheduleUtils {
  // 現在の時間からアクティブな時限を取得
  static int? getCurrentPeriod(List<TimeSlot> timeSlots) {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    for (final slot in timeSlots) {
      if (_isTimeInRange(currentTime, slot.startTime, slot.endTime)) {
        return slot.period;
      }
    }
    return null;
  }

  // 現在の曜日を取得（CIT用）
  static String? getCurrentWeekdayKey() {
    final now = DateTime.now();
    switch (now.weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      default: return null; // 日曜日は授業なし
    }
  }

  // 今日の時間割を取得
  static List<ScheduleClass?> getTodayClasses(Schedule schedule) {
    final todayKey = getCurrentWeekdayKey();
    if (todayKey == null) return [];
    
    final todaySchedule = schedule.timetable[todayKey];
    if (todaySchedule == null) return [];
    
    return List.generate(10, (index) => todaySchedule[index + 1]);
  }

  // 次の授業を取得
  static ScheduleClass? getNextClass(Schedule schedule) {
    final todayKey = getCurrentWeekdayKey();
    final currentPeriod = getCurrentPeriod(schedule.timeSlots);
    
    if (todayKey == null || currentPeriod == null) return null;
    
    final todaySchedule = schedule.timetable[todayKey];
    if (todaySchedule == null) return null;
    
    // 現在の時限以降の最初の授業を探す
    for (int period = currentPeriod + 1; period <= 10; period++) {
      final nextClass = todaySchedule[period];
      if (nextClass != null) return nextClass;
    }
    
    return null;
  }

  static bool _isTimeInRange(String currentTime, String startTime, String endTime) {
    final current = _timeToMinutes(currentTime);
    final start = _timeToMinutes(startTime);
    final end = _timeToMinutes(endTime);
    
    return current >= start && current < end;
  }

  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // 連続講義の終了時間を取得
  static String getClassEndTime(Schedule schedule, int startPeriod, int duration) {
    final endPeriod = startPeriod + duration - 1;
    final endTimeSlot = schedule.timeSlots.firstWhere(
      (slot) => slot.period == endPeriod,
      orElse: () => TimeSlot(
        period: endPeriod,
        startTime: '${endPeriod + 8}:00',
        endTime: '${endPeriod + 9}:00',
      ),
    );
    return endTimeSlot.endTime;
  }

  // 連続講義の時間範囲文字列を取得
  static String getClassTimeRange(Schedule schedule, int startPeriod, int duration) {
    final startTimeSlot = schedule.timeSlots.firstWhere(
      (slot) => slot.period == startPeriod,
      orElse: () => TimeSlot(
        period: startPeriod,
        startTime: '${startPeriod + 8}:00',
        endTime: '${startPeriod + 9}:00',
      ),
    );
    
    final endTime = getClassEndTime(schedule, startPeriod, duration);
    
    if (duration == 1) {
      return '${startTimeSlot.startTime} - ${startTimeSlot.endTime}';
    } else {
      return '${startTimeSlot.startTime} - $endTime';
    }
  }

  // 連続講義の時限範囲文字列を取得
  static String getClassPeriodRange(int startPeriod, int duration) {
    if (duration == 1) {
      return '${startPeriod}限';
    } else {
      final endPeriod = startPeriod + duration - 1;
      return '${startPeriod}-${endPeriod}限';
    }
  }

  // 時間割の統計情報を取得
  static Map<String, int> getScheduleStats(Schedule schedule) {
    int totalClasses = 0;
    int occupiedSlots = 0;
    final subjects = <String>{};
    
    for (final daySchedule in schedule.timetable.values) {
      for (final scheduleClass in daySchedule.values) {
        totalClasses++;
        if (scheduleClass != null) {
          occupiedSlots++;
          subjects.add(scheduleClass.subjectName);
        }
      }
    }
    
    return {
      'totalSlots': totalClasses,
      'occupiedSlots': occupiedSlots,
      'emptySlots': totalClasses - occupiedSlots,
      'uniqueSubjects': subjects.length,
    };
  }
}
