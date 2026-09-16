import 'package:flutter/foundation.dart';
import '../../models/schedule/schedule_model.dart';

class ScheduleClassOverlap extends StateError {
  ScheduleClassOverlap(int period, String subject)
    : super('$period限には既に「$subject」が登録されています');
}

/// Moves a complete lesson while retaining its identity, notes and duration.
/// Source validation and destination collision checks happen before any write.
Map<String, Map<int, ScheduleClass?>> applyScheduleClassMove({
  required Schedule schedule,
  required String fromWeekdayKey,
  required int fromPeriod,
  required String toWeekdayKey,
  required int toPeriod,
  required ScheduleClass expectedClass,
}) {
  final source = schedule.timetable[fromWeekdayKey];
  final latest = source?[fromPeriod];
  if (latest == null ||
      !latest.isStartCell ||
      !mapEquals(latest.toJson(), expectedClass.toJson())) {
    throw StateError('この講義は別の操作で変更されました。時間割を更新してから移動してください');
  }
  if (latest.duration < 1 ||
      fromPeriod < 1 ||
      fromPeriod + latest.duration - 1 > 10) {
    throw StateError('移動元の講義の時限を確認してください');
  }
  final timetable = {
    for (final day in schedule.timetable.entries)
      day.key: Map<int, ScheduleClass?>.from(day.value),
  };
  for (var offset = 0; offset < latest.duration; offset++) {
    final cell = source?[fromPeriod + offset];
    final expected = {...latest.toJson(), 'isStartCell': offset == 0};
    if (cell == null || !mapEquals(cell.toJson(), expected)) {
      throw StateError('連続講義の構成が変更されました。時間割を更新してください');
    }
    timetable[fromWeekdayKey]![fromPeriod + offset] = null;
  }
  return applyScheduleClassEdit(
    schedule: Schedule(
      id: schedule.id,
      userId: schedule.userId,
      semester: schedule.semester,
      timetable: timetable,
    ),
    weekdayKey: toWeekdayKey,
    period: toPeriod,
    replacement: latest,
  );
}

/// Computes the entire replacement before any write, without mutating the input.
Map<String, Map<int, ScheduleClass?>> applyScheduleClassEdit({
  required Schedule schedule,
  required String weekdayKey,
  required int period,
  required ScheduleClass replacement,
  ScheduleClass? expectedClass,
}) {
  if (!Weekday.values.any((day) => day.name == weekdayKey) ||
      period < 1 ||
      replacement.duration < 1 ||
      period + replacement.duration - 1 > 10) {
    throw StateError('連続講義は1限から10限の範囲に収めてください');
  }
  final day = schedule.timetable[weekdayKey] ?? {};
  if (expectedClass != null) {
    final latest = day[period];
    if (latest == null ||
        replacement.id != expectedClass.id ||
        !mapEquals(latest.toJson(), expectedClass.toJson())) {
      throw StateError('この科目は別の操作で変更されました。時間割を更新してから編集してください');
    }
  }
  for (var slot = period; slot < period + replacement.duration; slot++) {
    final existing = day[slot];
    if (existing != null &&
        (expectedClass == null || existing.id != expectedClass.id)) {
      throw ScheduleClassOverlap(slot, existing.subjectName);
    }
  }
  final timetable = {
    for (final entry in schedule.timetable.entries)
      entry.key: Map<int, ScheduleClass?>.from(entry.value),
  };
  final updatedDay = timetable.putIfAbsent(weekdayKey, () => {});
  if (expectedClass != null) {
    for (final slot in updatedDay.keys.toList()) {
      if (updatedDay[slot]?.id == expectedClass.id) updatedDay[slot] = null;
    }
  }
  for (var offset = 0; offset < replacement.duration; offset++) {
    updatedDay[period + offset] = ScheduleClass(
      id: replacement.id,
      subjectName: replacement.subjectName,
      classroom: replacement.classroom,
      instructor: replacement.instructor,
      color: replacement.color,
      notes: replacement.notes,
      duration: replacement.duration,
      isStartCell: offset == 0,
    );
  }
  return timetable;
}
