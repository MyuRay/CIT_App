import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/schedule/schedule_model.dart';
import '../../models/schedule/academic_year_model.dart';

class ScheduleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'schedules';

  /// 時間割を保存
  static Future<void> saveSchedule(Schedule schedule) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(schedule.id)
          .set(schedule.toJson());
      
      print('✅ 時間割を保存しました: ${schedule.id}');
    } catch (e) {
      print('❌ 時間割保存エラー: $e');
      // 互換: timeSlotsをListで要求する環境向けに再試行
      try {
        await _firestore
            .collection(_collection)
            .doc(schedule.id)
            .set(schedule.toJsonWithListTimeSlots());
        print('✅ 互換形式(List timeSlots)で時間割を保存しました: ${schedule.id}');
      } catch (e2) {
        print('❌ 互換形式での保存も失敗: $e2');
        rethrow;
      }
    }
  }

  /// 時間割を取得（ユーザーID別）- 現在の年度・学期
  static Future<Schedule?> getScheduleByUserId(String userId) async {
    final currentAcademicYear = AcademicYear.current();
    return await getScheduleByUserIdAndAcademicYear(userId, currentAcademicYear);
  }

  /// 時間割を取得（ユーザーID・年度・学期別）
  static Future<Schedule?> getScheduleByUserIdAndAcademicYear(
    String userId, 
    AcademicYear academicYear
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('semester', isEqualTo: academicYear.displayName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return Schedule.fromFirestore(doc);
      }
      // 見つからない場合は自動作成せず、UIで作成ボタンを表示できるように null を返す
      print('時間割が見つかりません（${academicYear.displayName}）。自動作成は行いません');
      return null;
    } catch (e) {
      print('❌ 時間割取得エラー: $e');
      // エラー時も自動作成は行わない
      return null;
    }
  }

  /// 初期時間割を作成（ユーザー用）- 現在の年度・学期
  static Future<Schedule> createInitialSchedule(String userId) async {
    final currentAcademicYear = AcademicYear.current();
    return await createInitialScheduleForAcademicYear(userId, currentAcademicYear);
  }

  /// 初期時間割を作成（年度・学期指定）
  static Future<Schedule> createInitialScheduleForAcademicYear(
    String userId, 
    AcademicYear academicYear
  ) async {
    try {
      final scheduleId = _firestore.collection(_collection).doc().id;
      final schedule = DefaultTimeSlots.createDefault(
        id: scheduleId,
        userId: userId,
        semester: academicYear.displayName,
      );

      await saveSchedule(schedule);
      print('✅ 初期時間割を作成しました: $scheduleId (${academicYear.displayName})');
      
      return schedule;
    } catch (e) {
      print('❌ 初期時間割作成エラー: $e');
      rethrow;
    }
  }

  /// 時間割を更新
  static Future<void> updateSchedule(Schedule schedule) async {
    try {
      final updatedSchedule = Schedule(
        id: schedule.id,
        userId: schedule.userId,
        semester: schedule.semester,
        timetable: schedule.timetable,
        timeSlots: schedule.timeSlots,
        createdAt: schedule.createdAt,
        updatedAt: DateTime.now(), // 更新時刻を現在時刻に設定
      );

      try {
        await _firestore
            .collection(_collection)
            .doc(schedule.id)
            .set(updatedSchedule.toJson());
      } catch (e) {
        print('❌ 時間割更新エラー(通常形式): $e');
        // 互換形式で再試行
        await _firestore
            .collection(_collection)
            .doc(schedule.id)
            .set(updatedSchedule.toJsonWithListTimeSlots());
        print('✅ 互換形式(List timeSlots)で時間割を更新しました: ${schedule.id}');
      }
      
      print('✅ 時間割を更新しました: ${schedule.id}');
    } catch (e) {
      print('❌ 時間割更新エラー: $e');
      rethrow;
    }
  }

  /// ユーザーの全時間割を取得（年度・学期別）
  static Future<List<Schedule>> getAllSchedulesByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('semester', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Schedule.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ 時間割一覧取得エラー: $e');
      return [];
    }
  }

  /// ユーザーが持つ年度・学期のリストを取得
  static Future<List<AcademicYear>> getUserAcademicYears(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('semester', descending: true)
          .get();

      final academicYears = <AcademicYear>[];
      final seenSemesters = <String>{};

      for (final doc in querySnapshot.docs) {
        final semester = doc.data()['semester'] as String?;
        if (semester != null && !seenSemesters.contains(semester)) {
          seenSemesters.add(semester);
          try {
            // "2024年度前期" -> AcademicYear に変換
            final academicYear = _parseAcademicYearFromDisplayName(semester);
            if (academicYear != null) {
              academicYears.add(academicYear);
            }
          } catch (e) {
            print('年度解析エラー: $semester');
          }
        }
      }

      // デフォルトで現在の年度・学期を含める
      final currentYear = AcademicYear.current();
      if (!academicYears.any((year) => 
          year.year == currentYear.year && year.semester == currentYear.semester)) {
        academicYears.insert(0, currentYear);
      }

      return academicYears;
    } catch (e) {
      print('❌ ユーザー年度一覧取得エラー: $e');
      // エラー時は現在の年度のみ返す
      return [AcademicYear.current()];
    }
  }

  /// 表示名から AcademicYear を解析
  static AcademicYear? _parseAcademicYearFromDisplayName(String displayName) {
    // "2024年度前期" -> AcademicYear(2024, 前期)
    final pattern = RegExp(r'(\d{4})年度(前期|後期|通年)');
    final match = pattern.firstMatch(displayName);
    
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final semesterName = match.group(2)!;
      
      AcademicSemester semester;
      switch (semesterName) {
        case '前期':
          semester = AcademicSemester.firstSemester;
          break;
        case '後期':
          semester = AcademicSemester.secondSemester;
          break;
        case '通年':
          semester = AcademicSemester.fullYear;
          break;
        default:
          return null;
      }
      
      return AcademicYear(year: year, semester: semester);
    }
    
    return null;
  }

  /// 科目を追加/更新（単一セル登録）
  static Future<void> addOrUpdateClass({
    required String scheduleId,
    required String weekdayKey,
    required int period,
    required ScheduleClass scheduleClass,
  }) async {
    try {
      final schedule = await getScheduleById(scheduleId);
      if (schedule == null) {
        throw Exception('時間割が見つかりません: $scheduleId');
      }

      final updatedTimetable = Map<String, Map<int, ScheduleClass?>>.from(schedule.timetable);
      if (updatedTimetable[weekdayKey] == null) {
        updatedTimetable[weekdayKey] = <int, ScheduleClass?>{};
      }

      // 指定された時限に単一セルとして登録
      updatedTimetable[weekdayKey]![period] = scheduleClass;

      final updatedSchedule = Schedule(
        id: schedule.id,
        userId: schedule.userId,
        semester: schedule.semester,
        timetable: updatedTimetable,
        timeSlots: schedule.timeSlots,
        createdAt: schedule.createdAt,
        updatedAt: DateTime.now(),
      );

      await updateSchedule(updatedSchedule);
      print('✅ 科目を追加しました: ${scheduleClass.subjectName} ($weekdayKey ${period}限)');
    } catch (e) {
      print('❌ 科目追加エラー: $e');
      rethrow;
    }
  }

  /// 既存の連続講義を削除（内部メソッド）
  static Future<void> _removeExistingContinuousClass(
    Map<String, Map<int, ScheduleClass?>> timetable, 
    String weekdayKey, 
    String classId
  ) async {
    if (timetable[weekdayKey] == null) return;
    
    final periodsToRemove = <int>[];
    
    // 指定されたクラスIDの全ての時限を収集
    for (final entry in timetable[weekdayKey]!.entries) {
      final periodClass = entry.value;
      if (periodClass != null && periodClass.id == classId) {
        periodsToRemove.add(entry.key);
      }
    }
    
    // 収集した時限を削除
    for (final period in periodsToRemove) {
      timetable[weekdayKey]![period] = null;
    }
  }

  /// 時間割を取得（ID別）
  static Future<Schedule?> getScheduleById(String scheduleId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(scheduleId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Schedule.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      print('❌ 時間割取得エラー: $e');
      return null;
    }
  }

  /// 科目を削除（連続講義対応）
  static Future<void> removeClass({
    required String scheduleId,
    required String weekdayKey,
    required int period,
  }) async {
    try {
      final schedule = await getScheduleById(scheduleId);
      if (schedule == null) {
        throw Exception('時間割が見つかりません: $scheduleId');
      }

      final updatedTimetable = Map<String, Map<int, ScheduleClass?>>.from(schedule.timetable);
      
      // 指定された曜日の時間割が存在しない場合は初期化
      if (updatedTimetable[weekdayKey] == null) {
        updatedTimetable[weekdayKey] = <int, ScheduleClass?>{};
      }

      final targetClass = updatedTimetable[weekdayKey]![period];
      if (targetClass == null) {
        print('指定された時限に科目がありません: $weekdayKey ${period}限');
        return; // エラーではなく正常終了
      }

      // 連続講義の場合、同じIDの全ての時限を削除
      final classId = targetClass.id;
      final className = targetClass.subjectName;
      
      // 安全に削除を実行
      await _removeExistingContinuousClass(updatedTimetable, weekdayKey, classId);

      final updatedSchedule = Schedule(
        id: schedule.id,
        userId: schedule.userId,
        semester: schedule.semester,
        timetable: updatedTimetable,
        timeSlots: schedule.timeSlots,
        createdAt: schedule.createdAt,
        updatedAt: DateTime.now(),
      );

      await updateSchedule(updatedSchedule);
      print('✅ 科目を削除しました: $className ($weekdayKey ${period}限)');
    } catch (e) {
      print('❌ 科目削除エラー: $e');
      rethrow;
    }
  }

  /// 時間割を削除
  static Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(scheduleId)
          .delete();
      
      print('✅ 時間割を削除しました: $scheduleId');
    } catch (e) {
      print('❌ 時間割削除エラー: $e');
      rethrow;
    }
  }

  /// 今日の時間割を取得
  static Future<List<ScheduleClass?>> getTodaySchedule(String userId) async {
    try {
      final schedule = await getScheduleByUserId(userId);
      if (schedule == null) return [];
      
      return ScheduleUtils.getTodayClasses(schedule);
    } catch (e) {
      print('❌ 今日の時間割取得エラー: $e');
      return [];
    }
  }

  /// 次の授業を取得
  static Future<ScheduleClass?> getNextClass(String userId) async {
    try {
      final schedule = await getScheduleByUserId(userId);
      if (schedule == null) return null;
      
      return ScheduleUtils.getNextClass(schedule);
    } catch (e) {
      print('❌ 次の授業取得エラー: $e');
      return null;
    }
  }

  /// 現在の時限を取得
  static Future<int?> getCurrentPeriod(String userId) async {
    try {
      final schedule = await getScheduleByUserId(userId);
      if (schedule == null) return null;
      
      return ScheduleUtils.getCurrentPeriod(schedule.timeSlots);
    } catch (e) {
      print('❌ 現在時限取得エラー: $e');
      return null;
    }
  }

  /// 時間割をクリア（全ての科目を削除）
  static Future<void> clearSchedule(String scheduleId) async {
    try {
      final schedule = await getScheduleById(scheduleId);
      if (schedule == null) {
        throw Exception('時間割が見つかりません: $scheduleId');
      }

      final clearedSchedule = Schedule(
        id: schedule.id,
        userId: schedule.userId,
        semester: schedule.semester,
        timetable: DefaultTimeSlots.createEmptyTimetable(),
        timeSlots: schedule.timeSlots,
        createdAt: schedule.createdAt,
        updatedAt: DateTime.now(),
      );

      await updateSchedule(clearedSchedule);
      print('✅ 時間割をクリアしました: $scheduleId');
    } catch (e) {
      print('❌ 時間割クリアエラー: $e');
      rethrow;
    }
  }
}
