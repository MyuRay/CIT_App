import 'package:cit_app/core/providers/assignment_provider.dart';
import 'package:cit_app/models/assignments/assignment.dart';
import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/services/assignments/assignment_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  late FakeFirebaseFirestore db;
  late AssignmentRepository repository;
  String? uid;
  final draft = AssignmentDraft(
    title: 'レポート',
    dueAt: DateTime(2026, 9, 20),
    notes: '提出フォームを確認',
  );
  setUp(() {
    db = FakeFirebaseFirestore();
    uid = 'owner';
    repository = AssignmentRepository(db, currentUserId: () => uid);
  });
  test(
    'create, stream, edit, completion and deletion persist per user',
    () async {
      final id = repository.newId('owner');
      await repository.save('owner', id, draft, creating: true);
      var tasks = await repository.watch('owner').first;
      expect(tasks.single.draft.title, 'レポート');
      await repository.setCompleted('owner', id, true);
      await repository.save(
        'owner',
        id,
        AssignmentDraft(title: '修正版', dueAt: draft.dueAt),
        creating: false,
      );
      tasks = await repository.watch('owner').first;
      expect(tasks.single.isCompleted, isTrue);
      expect(tasks.single.draft.title, '修正版');
      await repository.setCompleted('owner', id, false);
      expect(
        (await repository.watch('owner').first).single.isCompleted,
        isFalse,
      );
      await repository.delete('owner', id);
      expect(await repository.watch('owner').first, isEmpty);
    },
  );
  test('retries use the same ID and retain createdAt and completion', () async {
    await repository.save('owner', 'same', draft, creating: true);
    final before =
        (await db.doc('users/owner/assignments/same').get())
            .data()!['createdAt'];
    await repository.setCompleted('owner', 'same', true);
    await repository.save('owner', 'same', draft, creating: true);
    final saved = await db.collection('users/owner/assignments').get();
    expect(saved.docs, hasLength(1));
    expect(saved.docs.single.data()['createdAt'], before);
    expect(saved.docs.single.data()['isCompleted'], true);
  });
  test(
    'editing a task deleted on another device does not recreate it',
    () async {
      await expectLater(
        repository.save('owner', 'deleted', draft, creating: false),
        throwsStateError,
      );
      expect(
        (await db.doc('users/owner/assignments/deleted').get()).exists,
        isFalse,
      );
    },
  );
  test('stale account cannot save, complete, delete or subscribe', () async {
    uid = 'other';
    await expectLater(
      repository.save('owner', 'id', draft, creating: true),
      throwsStateError,
    );
    await expectLater(
      repository.setCompleted('owner', 'id', true),
      throwsStateError,
    );
    await expectLater(repository.delete('owner', 'id'), throwsStateError);
    expect(() => repository.watch('owner'), throwsStateError);
  });
  test('blank names default to 課題 while length limits still apply', () async {
    for (final title in ['', ' \t\n　']) {
      await repository.save(
        'owner',
        'default-title',
        AssignmentDraft(title: title, dueAt: draft.dueAt),
        creating: true,
      );
      expect((await repository.watch('owner').first).single.draft.title, '課題');
    }
    for (final invalid in [
      AssignmentDraft(title: 'a' * 121, dueAt: draft.dueAt),
      AssignmentDraft(title: 'ok', dueAt: draft.dueAt, notes: 'a' * 4001),
    ]) {
      await expectLater(
        repository.save('owner', 'invalid', invalid, creating: true),
        throwsArgumentError,
      );
    }
    expect(
      (await db.doc('users/owner/assignments/invalid').get()).exists,
      isFalse,
    );
  });
  test(
    'date-only deadlines remain valid until the end of the selected day',
    () {
      final task = Assignment(id: 'date', draft: draft);
      expect(task.isOverdue(DateTime(2026, 9, 20, 23, 59, 59)), isFalse);
      expect(task.isOverdue(DateTime(2026, 9, 21)), isTrue);
      final timed = Assignment(
        id: 'time',
        draft: AssignmentDraft(
          title: '提出',
          dueAt: DateTime(2026, 9, 20, 17),
          hasDueTime: true,
        ),
      );
      expect(timed.isOverdue(DateTime(2026, 9, 20, 17)), isTrue);
      expect(assignmentDueLabel(timed, DateTime(2026, 9, 20, 10)), '今日 17:00');
      expect(assignmentDueLabel(task, DateTime(2026, 9, 19)), '明日 まで');
    },
  );
  test(
    'deadline sorting is stable and completed tasks follow pending ones',
    () {
      final tasks = [
        Assignment(id: 'c', draft: draft, isCompleted: true),
        Assignment(id: 'b', draft: draft),
        Assignment(id: 'a', draft: draft),
        Assignment(
          id: 'earlier',
          draft: AssignmentDraft(title: '早い', dueAt: DateTime(2026, 9, 18)),
        ),
      ];
      tasks.sort(Assignment.compare);
      expect(tasks.map((t) => t.id), ['earlier', 'a', 'b', 'c']);
    },
  );
  test(
    'home hides no pending tasks but manual visibility and errors stay visible',
    () {
      expect(
        showAssignmentHomeCard(const AsyncData([]), alwaysShow: false),
        false,
      );
      expect(
        showAssignmentHomeCard(const AsyncData([]), alwaysShow: true),
        true,
      );
      expect(
        showAssignmentHomeCard(
          AsyncData([Assignment(id: '1', draft: draft)]),
          alwaysShow: false,
        ),
        true,
      );
      expect(
        showAssignmentHomeCard(
          AsyncData([Assignment(id: '1', draft: draft, isCompleted: true)]),
          alwaysShow: false,
        ),
        false,
      );
      expect(
        showAssignmentHomeCard(
          AsyncError(StateError('offline'), StackTrace.current),
          alwaysShow: false,
        ),
        true,
      );
    },
  );
  test(
    'continuous lessons deduplicate while different semesters retain their link',
    () {
      const lesson = ScheduleClass(
        id: 'class',
        subjectName: '情報工学',
        classroom: '',
        instructor: '',
        color: '#000000',
      );
      final courses = AssignmentCourse.fromSchedules([
        for (final id in ['spring', 'fall'])
          Schedule(
            id: id,
            userId: 'owner',
            semester: id,
            timetable: {
              'monday': {1: lesson, 2: lesson},
            },
          ),
      ]);
      expect(courses, hasLength(2));
      expect(courses[0].key, isNot(courses[1].key));
    },
  );
  test(
    'provider drops previous account data immediately on account change',
    () async {
      final active = StateProvider<String?>((_) => 'owner');
      final container = ProviderContainer(
        overrides: [
          assignmentUserIdProvider.overrideWith((ref) => ref.watch(active)),
          userAssignmentsProvider('owner').overrideWith(
            (_) => Stream.value([Assignment(id: 'private', draft: draft)]),
          ),
          userAssignmentsProvider(
            'other',
          ).overrideWith((_) => const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);
      container.listen(assignmentsProvider, (_, __) {});
      await container.read(userAssignmentsProvider('owner').future);
      expect(
        container.read(assignmentsProvider).valueOrNull?.single.id,
        'private',
      );
      container.read(active.notifier).state = 'other';
      expect(container.read(assignmentsProvider).valueOrNull, isNull);
      container.read(active.notifier).state = null;
      expect(container.read(assignmentsProvider).valueOrNull, isEmpty);
    },
  );
}
