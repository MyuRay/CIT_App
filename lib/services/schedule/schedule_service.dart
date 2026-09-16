import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'schedule_class_edit.dart';
import '../../models/schedule/schedule_model.dart';
import '../../models/schedule/academic_year_model.dart';

class ScheduleService {
  @visibleForTesting
  static FirebaseFirestore? firestoreOverride;
  static FirebaseFirestore get _firestore => firestoreOverride ?? FirebaseFirestore.instance;
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
    return await getScheduleByUserIdAndAcademicYear(
      userId,
      currentAcademicYear,
    );
  }

  /// 時間割を取得（ユーザーID・年度・学期別）
  static Future<Schedule?> getScheduleByUserIdAndAcademicYear(
    String userId,
    AcademicYear academicYear,
  ) async {
    try {
      final querySnapshot =
          await _firestore
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
      rethrow;
    }
  }

  /// 初期時間割を作成（ユーザー用）- 現在の年度・学期
  static Future<Schedule> createInitialSchedule(String userId) async {
    final currentAcademicYear = AcademicYear.current();
    return await createInitialScheduleForAcademicYear(
      userId,
      currentAcademicYear,
    );
  }

  /// 初期時間割を作成（年度・学期指定）
  static Future<Schedule> createInitialScheduleForAcademicYear(
    String userId,
    AcademicYear academicYear,
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

  /// 名前付き時間割を作成
  static Future<Schedule> createNamedSchedule({
    required String userId,
    required String name,
    required String semester,
  }) async {
    final trimmedName = name.trim();
    final trimmedSemester = semester.trim();
    if (trimmedName.isEmpty) {
      throw Exception('時間割名を入力してください');
    }
    if (trimmedSemester.isEmpty) {
      throw Exception('semesterを入力してください');
    }

    final scheduleId = _firestore.collection(_collection).doc().id;
    final schedule = Schedule(
      id: scheduleId,
      userId: userId,
      name: trimmedName,
      semester: trimmedSemester,
      timetable: DefaultTimeSlots.createEmptyTimetable(),
      timeSlots: DefaultTimeSlots.citTimeSlots,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveSchedule(schedule);
    return schedule;
  }

  /// 時間割を更新
  static Future<void> updateSchedule(Schedule schedule) async {
    try {
      final updatedSchedule = Schedule(
        id: schedule.id,
        userId: schedule.userId,
        name: schedule.name,
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
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .get();

      final schedules =
          querySnapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();

      // userId配下の全時間割を返しつつ、更新日時が新しい順に表示する
      schedules.sort((a, b) {
        final aCreated = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final aUpdated = a.updatedAt ?? aCreated;
        final aTime = aUpdated.isAfter(aCreated) ? aUpdated : aCreated;
        final bCreated = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bUpdated = b.updatedAt ?? bCreated;
        final bTime = bUpdated.isAfter(bCreated) ? bUpdated : bCreated;
        return bTime.compareTo(aTime);
      });

      return schedules;
    } catch (e) {
      print('❌ 時間割一覧取得エラー: $e');
      rethrow;
    }
  }

  /// ユーザーが持つ年度・学期のリストを取得
  static Future<List<AcademicYear>> getUserAcademicYears(String userId) async {
    try {
      final querySnapshot =
          await _firestore
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
      if (!academicYears.any(
        (year) =>
            year.year == currentYear.year &&
            year.semester == currentYear.semester,
      )) {
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
  static Future<void> saveClass({
    required String scheduleId,
    required String weekdayKey,
    required int period,
    required ScheduleClass scheduleClass,
    ScheduleClass? expectedClass,
  }) async {
    final document = _firestore.collection(_collection).doc(scheduleId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) throw StateError('対象の時間割が見つかりません');
      final schedule = Schedule.fromFirestore(snapshot);
      final timetable = applyScheduleClassEdit(
        schedule: schedule, weekdayKey: weekdayKey, period: period,
        replacement: scheduleClass, expectedClass: expectedClass,
      );
      transaction.update(document, {
        'timetable': {
          for (final day in timetable.entries) day.key: {
            for (final slot in day.value.entries) slot.key.toString(): slot.value?.toJson(),
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Move and remove the source in the same transaction; never overwrite a
  /// destination occupied since the drag or picker operation started.
  static Future<Schedule> moveClass({
    required String scheduleId,
    required String fromWeekdayKey,
    required int fromPeriod,
    required String toWeekdayKey,
    required int toPeriod,
    required ScheduleClass expectedClass,
  }) async {
    final document = _firestore.collection(_collection).doc(scheduleId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) throw StateError('対象の時間割が見つかりません');
      final schedule = Schedule.fromFirestore(snapshot);
      final timetable = applyScheduleClassMove(
        schedule: schedule, fromWeekdayKey: fromWeekdayKey, fromPeriod: fromPeriod,
        toWeekdayKey: toWeekdayKey, toPeriod: toPeriod, expectedClass: expectedClass,
      );
      transaction.update(document, {
        'timetable': {
          for (final day in timetable.entries) day.key: {
            for (final cell in day.value.entries) cell.key.toString(): cell.value?.toJson(),
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Schedule(
        id: schedule.id, userId: schedule.userId, name: schedule.name,
        semester: schedule.semester, timetable: timetable,
        timeSlots: schedule.timeSlots, createdAt: schedule.createdAt,
        updatedAt: DateTime.now(),
      );
    });
  }

  /// 時間割を取得（ID別）
  static Future<Schedule?> getScheduleById(String scheduleId) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(scheduleId).get();

      if (doc.exists && doc.data() != null) {
        return Schedule.fromFirestore(doc);
      }

      return null;
    } catch (e) {
      print('❌ 時間割取得エラー: $e');
      rethrow;
    }
  }

  /// 科目を削除（連続講義対応）
  static Future<void> removeClass({
    required String scheduleId,
    required String weekdayKey,
    required int period,
    ScheduleClass? expectedClass,
  }) async {
    final document = _firestore.collection(_collection).doc(scheduleId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) throw StateError('対象の時間割が見つかりません');
      final schedule = Schedule.fromFirestore(snapshot);
      final day = schedule.timetable[weekdayKey] ?? {};
      final target = day[period];
      if (expectedClass != null &&
          (target == null || !mapEquals(target.toJson(), expectedClass.toJson()))) {
        throw StateError('この科目は別の操作で変更されました。時間割を更新してください');
      }
      if (target == null) return;
      transaction.update(document, {
        for (final slot in day.entries)
          if (slot.value?.id == target.id) 'timetable.$weekdayKey.${slot.key}': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// 時間割を削除
  static Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _firestore.collection(_collection).doc(scheduleId).delete();

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
      rethrow;
    }
  }

  /// 指定した時間割IDの今日の時間割を取得
  static Future<List<ScheduleClass?>> getTodayScheduleByScheduleId(
    String scheduleId,
  ) async {
    try {
      final schedule = await getScheduleById(scheduleId);
      if (schedule == null) return [];
      return ScheduleUtils.getTodayClasses(schedule);
    } catch (e) {
      print('❌ 指定時間割の今日の時間割取得エラー: $e');
      rethrow;
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
      rethrow;
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
      rethrow;
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
        name: schedule.name,
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
