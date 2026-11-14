import 'dart:convert';
import 'package:cit_app/models/assignments/assignment.dart';
import 'package:cit_app/services/assignments/assignment_reminders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2100, 1, 1, 12);
  test(
    '24-hour and 1-hour notices have stable IDs, ordered times and own-account targets',
    () {
      final due = DateTime(2100, 1, 3, 15);
      final tasks = [
        Assignment(
          id: 'a',
          draft: AssignmentDraft(title: '提出', dueAt: due, hasDueTime: true),
        ),
      ];
      final plan = planAssignmentReminders('u', tasks, now);
      expect(plan.map((item) => item.at), [
        due.subtract(const Duration(hours: 24)),
        due.subtract(const Duration(hours: 1)),
      ]);
      expect(plan.map((item) => item.id).toSet(), hasLength(2));
      expect(
        plan.map((item) => item.id),
        planAssignmentReminders('u', tasks, now).map((item) => item.id),
      );
      expect(jsonDecode(plan.first.payload), {
        'kind': 'assignment_reminder',
        'userId': 'u',
        'assignmentId': 'a',
      });
    },
  );
  test(
    'completed and past tasks cancel, while date-only tasks use end of the day',
    () {
      final plan = planAssignmentReminders('u', [
        Assignment(
          id: 'done',
          isCompleted: true,
          draft: AssignmentDraft(dueAt: DateTime(2100, 1, 3)),
        ),
        Assignment(
          id: 'past',
          draft: AssignmentDraft(dueAt: DateTime(2099, 12, 30)),
        ),
        Assignment(
          id: 'date',
          draft: AssignmentDraft(dueAt: DateTime(2100, 1, 3)),
        ),
      ], now);
      expect(plan, hasLength(2));
      expect(plan.last.at, DateTime(2100, 1, 3, 23));
      expect(plan.first.at, DateTime(2100, 1, 3));
    },
  );
}
