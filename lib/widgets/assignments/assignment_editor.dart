import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/assignment_provider.dart';
import '../../core/providers/schedule_provider.dart';
import '../../models/assignments/assignment.dart';
import '../../models/schedule/schedule_model.dart';

Future<void> showAssignmentEditor(
  BuildContext context,
  WidgetRef ref, {
  Assignment? assignment,
  Schedule? schedule,
  ScheduleClass? lesson,
}) async {
  final uid = ref.read(assignmentUserIdProvider);
  if (uid == null) return;
  final repository = ref.read(assignmentRepositoryProvider);
  final id = assignment?.id ?? repository.newId(uid);
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => Consumer(
          builder: (context, ref, _) {
            final active = ref.watch(assignmentUserIdProvider) == uid;
            final schedules =
                active
                    ? ref.watch(scheduleListProvider(uid))
                    : const AsyncData<List<Schedule>>([]);
            final selectedId = ref.watch(selectedScheduleIdProvider);
            final ownedSchedules =
                schedules.valueOrNull?.where((s) => s.userId == uid).toList();
            // Match the timetable tab's selection, including its first-sheet
            // fallback. A caller's sheet is only a loading/error fallback.
            final selected =
                ownedSchedules == null
                    ? (schedule?.userId == uid &&
                            (selectedId == null || schedule?.id == selectedId)
                        ? schedule
                        : null)
                    : ownedSchedules
                            .where((s) => s.id == selectedId)
                            .firstOrNull ??
                        ownedSchedules.firstOrNull;
            final courses = AssignmentCourse.fromSchedules([
              if (active && selected != null) selected,
            ]);
            final initialCourse =
                assignment?.draft.course ??
                courses
                    .where(
                      (course) =>
                          course.scheduleId == schedule?.id &&
                          course.classId == lesson?.id,
                    )
                    .firstOrNull;
            return AssignmentEditor(
              assignment: assignment,
              initialCourse: initialCourse,
              courses: courses,
              enabled: active,
              courseLoadError: schedules.hasError,
              onRetryCourses: () => ref.invalidate(scheduleListProvider(uid)),
              onSave:
                  (draft) => repository.save(
                    uid,
                    id,
                    draft,
                    creating: assignment == null,
                  ),
            );
          },
        ),
  );
}

class AssignmentEditor extends StatefulWidget {
  const AssignmentEditor({
    super.key,
    this.assignment,
    this.initialCourse,
    required this.courses,
    required this.onSave,
    this.enabled = true,
    this.courseLoadError = false,
    this.onRetryCourses,
  });
  final Assignment? assignment;
  final AssignmentCourse? initialCourse;
  final List<AssignmentCourse> courses;
  final Future<void> Function(AssignmentDraft) onSave;
  final bool enabled, courseLoadError;
  final VoidCallback? onRetryCourses;
  @override
  State<AssignmentEditor> createState() => _AssignmentEditorState();
}

class _AssignmentEditorState extends State<AssignmentEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title, _notes;
  late DateTime _date;
  TimeOfDay? _time;
  AssignmentCourse? _course;
  bool _saving = false, _dirty = false;
  bool _courseEdited = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final draft = widget.assignment?.draft;
    _title = TextEditingController(text: draft?.title ?? '');
    _notes = TextEditingController(text: draft?.notes ?? '');
    final now = DateTime.now();
    _date = draft?.dueAt ?? DateTime(now.year, now.month, now.day + 1);
    _time = draft?.hasDueTime == true ? TimeOfDay.fromDateTime(_date) : null;
    _course = widget.initialCourse ?? draft?.course;
    _title.addListener(_changed);
    _notes.addListener(_changed);
  }

  void _changed() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void didUpdateWidget(covariant AssignmentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.assignment != null) return;
    if (_course != null && !widget.courses.any((c) => c.key == _course!.key)) {
      _course = null;
    }
    // A lecture preselection may arrive after the timetable finishes loading.
    if (!_courseEdited &&
        widget.initialCourse != null &&
        widget.courses.any((c) => c.key == widget.initialCourse!.key)) {
      _course = widget.initialCourse;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_saving) return;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('入力内容を破棄しますか？'),
              content: const Text('保存していない変更があります。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('編集を続ける'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('破棄する'),
                ),
              ],
            ),
      );
      if (discard != true || !mounted) return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    if (_saving || !widget.enabled || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        AssignmentDraft(
          title: _title.text,
          notes: _notes.text,
          course: _course,
          hasDueTime: _time != null,
          dueAt: DateTime(
            _date.year,
            _date.month,
            _date.day,
            _time?.hour ?? 0,
            _time?.minute ?? 0,
          ),
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _error = '保存できませんでした。入力内容は残っています。通信状態を確認して再度お試しください。');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final courses = <String, AssignmentCourse>{
      for (final course in widget.courses) course.key: course,
    };
    final editable = widget.enabled && !_saving;
    return PopScope(
      canPop: !_saving && !_dirty,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) _close();
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.assignment == null ? '課題を登録' : '課題を編集',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: '閉じる',
                        onPressed: _saving ? null : _close,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!widget.enabled)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'ログイン状態が変わりました。閉じてから開き直してください。',
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  TextFormField(
                    key: const ValueKey('assignment-title'),
                    controller: _title,
                    enabled: editable,
                    maxLength: 120,
                    maxLines: 2,
                    minLines: 1,
                    decoration: const InputDecoration(
                      labelText: '課題名（任意）',
                      hintText: '未入力の場合は「課題」',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('assignment-course-${_course?.key}'),
                    initialValue: _course?.key ?? '',
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '講義'),
                    items: [
                      // Preserve a saved link to an older/deleted timetable
                      // without offering it as a selectable new course.
                      if (_course != null && !courses.containsKey(_course!.key))
                        DropdownMenuItem(
                          value: _course!.key,
                          enabled: false,
                          child: Text(
                            _course!.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const DropdownMenuItem(
                        value: '',
                        child: Text('講義に紐づけない'),
                      ),
                      for (final course in courses.values)
                        DropdownMenuItem(
                          value: course.key,
                          child: Text(
                            course.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged:
                        !editable
                            ? null
                            : (key) => setState(() {
                              _course = courses[key];
                              _courseEdited = true;
                              _dirty = true;
                            }),
                  ),
                  if (widget.courseLoadError)
                    TextButton.icon(
                      onPressed: widget.onRetryCourses,
                      icon: const Icon(Icons.refresh),
                      label: const Text('講義の読み込みを再試行'),
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: const ValueKey('assignment-date'),
                    onPressed:
                        !editable
                            ? null
                            : () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100, 12, 31),
                                helpText: '締切日',
                              );
                              if (date != null && mounted) {
                                setState(() {
                                  _date = date;
                                  _dirty = true;
                                });
                              }
                            },
                    icon: const Icon(Icons.event_outlined),
                    label: Text('締切 ${_date.year}/${_date.month}/${_date.day}'),
                  ),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed:
                            !editable
                                ? null
                                : () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime:
                                        _time ??
                                        const TimeOfDay(hour: 23, minute: 59),
                                    helpText: '締切時刻',
                                  );
                                  if (time != null && mounted) {
                                    setState(() {
                                      _time = time;
                                      _dirty = true;
                                    });
                                  }
                                },
                        icon: const Icon(Icons.schedule),
                        label: Text(
                          _time == null
                              ? '時刻を指定（任意）'
                              : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                      if (_time != null)
                        TextButton(
                          onPressed:
                              !editable
                                  ? null
                                  : () => setState(() {
                                    _time = null;
                                    _dirty = true;
                                  }),
                          child: const Text('時刻指定を解除'),
                        ),
                    ],
                  ),
                  if (_time == null)
                    Text(
                      '時刻を指定しない場合は、その日の終わりが締切です。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('assignment-notes'),
                    controller: _notes,
                    enabled: editable,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 4000,
                    decoration: const InputDecoration(
                      labelText: 'メモ（任意）',
                      hintText: '提出方法や取り組む内容など',
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(color: scheme.error),
                        semanticsLabel: _error,
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const ValueKey('assignment-save'),
                    onPressed: editable ? _save : null,
                    icon:
                        _saving
                            ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.check),
                    label: Text(
                      _saving
                          ? '保存中…'
                          : widget.assignment == null
                          ? '登録する'
                          : '変更を保存',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
