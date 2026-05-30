import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 授業出席通知用の payload。
///
/// 通知に「具体的な日時」を載せておき、後日タップしたときも
/// 「いつの授業の通知か」を一意に判定できるようにする。
@immutable
class ClassNotificationPayload {
  const ClassNotificationPayload({
    required this.scheduleId,
    required this.subjectName,
    required this.weekday,
    required this.period,
    required this.classDate,
    required this.startDateTime,
    required this.endDateTime,
    this.classroom,
  });

  /// 授業出席通知であることを示すタイプ識別子。
  static const String typeKey = 'class_attendance';

  /// 紐づく時間割の id。
  final String scheduleId;

  /// 科目名（通知本文/出席判定時の表示に使用）。
  final String subjectName;

  /// 曜日番号（DateTime.monday=1 .. sunday=7）。
  final int weekday;

  /// 時限（1〜10）。
  final int period;

  /// 授業対象日（時刻なし、ローカル日付）。ISO `yyyy-MM-dd`。
  final DateTime classDate;

  /// 授業の具体的な開始日時（ローカルタイムゾーン）。
  final DateTime startDateTime;

  /// 授業の具体的な終了日時（ローカルタイムゾーン）。
  final DateTime endDateTime;

  /// 教室名（任意）。
  final String? classroom;

  Map<String, dynamic> toJson() {
    return {
      'type': typeKey,
      'scheduleId': scheduleId,
      'subjectName': subjectName,
      'weekday': weekday,
      'period': period,
      'classDate':
          '${classDate.year.toString().padLeft(4, '0')}-${classDate.month.toString().padLeft(2, '0')}-${classDate.day.toString().padLeft(2, '0')}',
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      if (classroom != null && classroom!.isNotEmpty) 'classroom': classroom,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  /// payload 文字列を解析。`type == "class_attendance"` 以外、
  /// あるいは必須フィールドの欠落・パース失敗時は null を返す。
  static ClassNotificationPayload? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final type = decoded['type'];
      if (type != typeKey) return null;

      final scheduleId = decoded['scheduleId'] as String?;
      final subjectName = decoded['subjectName'] as String?;
      final weekday = (decoded['weekday'] as num?)?.toInt();
      final period = (decoded['period'] as num?)?.toInt();
      final classDateStr = decoded['classDate'] as String?;
      final startStr = decoded['startDateTime'] as String?;
      final endStr = decoded['endDateTime'] as String?;
      final classroom = decoded['classroom'] as String?;

      if (scheduleId == null ||
          subjectName == null ||
          weekday == null ||
          period == null ||
          classDateStr == null ||
          startStr == null ||
          endStr == null) {
        return null;
      }

      final classDate = DateTime.tryParse(classDateStr);
      final start = DateTime.tryParse(startStr);
      final end = DateTime.tryParse(endStr);
      if (classDate == null || start == null || end == null) {
        return null;
      }

      return ClassNotificationPayload(
        scheduleId: scheduleId,
        subjectName: subjectName,
        weekday: weekday,
        period: period,
        classDate: DateTime(classDate.year, classDate.month, classDate.day),
        startDateTime: start.toLocal(),
        endDateTime: end.toLocal(),
        classroom: (classroom != null && classroom.trim().isNotEmpty)
            ? classroom
            : null,
      );
    } catch (e) {
      debugPrint('⚠️ ClassNotificationPayload parse error: $e');
      return null;
    }
  }
}
