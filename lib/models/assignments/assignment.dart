import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../schedule/schedule_model.dart';

class AssignmentCourse {
  const AssignmentCourse({
    required this.scheduleId,
    required this.classId,
    required this.subjectName,
    required this.semester,
  });
  final String scheduleId, classId, subjectName, semester;
  String get key => jsonEncode([scheduleId, classId]);
  String get label => subjectName;
  Map<String, dynamic> toJson() => {
    'scheduleId': scheduleId,
    'classId': classId,
    'subjectName': subjectName,
    'semester': semester,
  };
  factory AssignmentCourse.fromJson(Map<String, dynamic> data) =>
      AssignmentCourse(
        scheduleId: data['scheduleId'] as String,
        classId: data['classId'] as String,
        subjectName: data['subjectName'] as String,
        semester: data['semester'] as String,
      );
  factory AssignmentCourse.fromLesson(
    Schedule schedule,
    ScheduleClass lesson,
  ) => AssignmentCourse(
    scheduleId: schedule.id,
    classId: lesson.id,
    subjectName: lesson.subjectName,
    semester: schedule.semester,
  );

  static List<AssignmentCourse> fromSchedules(Iterable<Schedule> schedules) {
    final courses = <String, AssignmentCourse>{};
    for (final schedule in schedules) {
      for (final day in schedule.timetable.values) {
        for (final lesson in day.values.whereType<ScheduleClass>()) {
          final course = AssignmentCourse.fromLesson(schedule, lesson);
          courses.putIfAbsent(course.key, () => course);
        }
      }
    }
    return courses.values.toList();
  }
}

class AssignmentDraft {
  const AssignmentDraft({
    this.title = '',
    required this.dueAt,
    this.hasDueTime = false,
    this.notes = '',
    this.course,
  });
  final String title, notes;
  final DateTime dueAt;
  final bool hasDueTime;
  final AssignmentCourse? course;
  void validate() {
    if (title.trim().length > 120 || notes.trim().length > 4000) {
      throw ArgumentError('課題名は120文字以内、メモは4000文字以内で入力してください');
    }
  }

  Map<String, dynamic> toJson() => {
    'title': title.trim().isEmpty ? '課題' : title.trim(),
    'notes': notes.trim(),
    'dueAt': Timestamp.fromDate(
      hasDueTime ? dueAt : DateTime(dueAt.year, dueAt.month, dueAt.day),
    ),
    'hasDueTime': hasDueTime,
    'course': course?.toJson(),
  };
}

class Assignment {
  const Assignment({
    required this.id,
    required this.draft,
    this.isCompleted = false,
  });
  final String id;
  final AssignmentDraft draft;
  final bool isCompleted;
  DateTime get deadline =>
      draft.hasDueTime
          ? draft.dueAt
          : DateTime(draft.dueAt.year, draft.dueAt.month, draft.dueAt.day + 1);
  bool isOverdue(DateTime now) => !isCompleted && !now.isBefore(deadline);
  factory Assignment.fromJson(String id, Map<String, dynamic> data) =>
      Assignment(
        id: id,
        isCompleted: data['isCompleted'] == true,
        draft: AssignmentDraft(
          title: data['title'] as String,
          notes: data['notes'] as String? ?? '',
          dueAt: (data['dueAt'] as Timestamp).toDate(),
          hasDueTime: data['hasDueTime'] == true,
          course:
              data['course'] == null
                  ? null
                  : AssignmentCourse.fromJson(
                    Map<String, dynamic>.from(data['course'] as Map),
                  ),
        ),
      );
  static int compare(Assignment a, Assignment b) {
    if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
    final due = a.deadline.compareTo(b.deadline);
    return due == 0 ? a.id.compareTo(b.id) : due;
  }
}

String assignmentDueLabel(Assignment task, DateTime now) {
  final due = task.draft.dueAt;
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(due.year, due.month, due.day);
  final prefix =
      date == today
          ? '今日'
          : date == DateTime(today.year, today.month, today.day + 1)
          ? '明日'
          : '${due.year == now.year ? '' : '${due.year}/'}${due.month}/${due.day}';
  final time =
      task.draft.hasDueTime
          ? '${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')}'
          : 'まで';
  return '${task.isOverdue(now) ? '期限超過 · ' : ''}$prefix $time';
}
