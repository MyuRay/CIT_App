import 'dart:convert';
import '../../models/assignments/assignment.dart';

class AssignmentReminder {
  const AssignmentReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.payload,
  });
  final int id;
  final DateTime at;
  final String title, body, payload;
}

List<AssignmentReminder> planAssignmentReminders(
  String uid,
  List<Assignment> tasks,
  DateTime now,
) {
  final reminders = <AssignmentReminder>[];
  for (final task in tasks) {
    if (task.isCompleted) continue;
    for (final hours in [24, 1]) {
      final at = task.deadline.subtract(Duration(hours: hours));
      if (!at.isAfter(now)) continue;
      var hash = 0x811c9dc5;
      for (final unit in '$uid/${task.id}/$hours'.codeUnits) {
        hash = ((hash ^ unit) * 0x01000193) & 0x07ffffff;
      }
      reminders.add(
        AssignmentReminder(
          id: 0x08000000 | hash,
          at: at,
          title: '課題の締切まで$hours時間',
          body:
              task.draft.title.trim().isEmpty
                  ? '課題の提出を確認しましょう'
                  : task.draft.title,
          payload: jsonEncode({
            'kind': 'assignment_reminder',
            'userId': uid,
            'assignmentId': task.id,
          }),
        ),
      );
    }
  }
  reminders.sort((a, b) {
    final order = a.at.compareTo(b.at);
    return order == 0 ? a.id.compareTo(b.id) : order;
  });
  return reminders;
}
