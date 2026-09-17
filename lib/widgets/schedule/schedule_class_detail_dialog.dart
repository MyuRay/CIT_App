import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/schedule/attendance_session.dart';
import '../../models/schedule/schedule_model.dart';
import '../../services/schedule/attendance_service.dart';
import 'attendance_status_chip.dart';
import 'class_attendance_editor.dart';

/// A bounded, scrollable detail view with independently owned editing state.
class ScheduleClassDetailDialog extends StatefulWidget {
  const ScheduleClassDetailDialog({
    super.key,
    required this.lesson,
    required this.dayLabel,
    required this.periodRange,
    required this.timeRange,
    this.onSaveNotes,
    this.onOpenRoom,
    this.onAttendance,
    this.loadAttendance,
    this.loadAttendanceSessions,
    this.onSaveAttendance,
    this.onAddAssignment,
  });
  final ScheduleClass lesson;
  final String dayLabel, periodRange, timeRange;
  final Future<bool> Function(String?)? onSaveNotes;
  final VoidCallback? onOpenRoom;
  final Future<void> Function()? onAttendance;
  final Future<AttendanceClassSummary> Function()? loadAttendance;
  final Future<List<AttendanceSession>> Function()? loadAttendanceSessions;
  final Future<void> Function(AttendanceSession, String?)? onSaveAttendance;
  final Future<void> Function()? onAddAssignment;

  @override
  State<ScheduleClassDetailDialog> createState() =>
      _ScheduleClassDetailDialogState();
}

class _ScheduleClassDetailDialogState extends State<ScheduleClassDetailDialog> {
  late final TextEditingController _notes;
  late String _savedNotes;
  Future<AttendanceClassSummary>? _attendance;
  final _linkRecognizers = <TapGestureRecognizer>[];
  bool _editing = false, _saving = false;
  bool _editingAttendance = false, _savingAttendance = false;
  bool get _busy => _saving || _savingAttendance;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _savedNotes = widget.lesson.notes ?? '';
    _notes = TextEditingController(text: _savedNotes)
      ..addListener(_onNotesChanged);
    _attendance = widget.loadAttendance?.call();
  }

  void _onNotesChanged() {
    if (mounted) setState(() {});
  }

  bool get _dirty => _editing && _notes.text.trim() != _savedNotes.trim();

  @override
  void dispose() {
    _notes.dispose();
    for (final recognizer in _linkRecognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  Future<void> _close() async {
    if (_busy) return;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('メモの変更を破棄しますか？'),
              content: const Text('保存していない内容は失われます。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('編集を続ける'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('破棄する'),
                ),
              ],
            ),
      );
      if (discard != true || !mounted) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final text = _notes.text.trim();
      final ok = await widget.onSaveNotes!(text.isEmpty ? null : text);
      if (!mounted) return;
      setState(() {
        if (ok) {
          _savedNotes = text;
          _editing = false;
        } else {
          _saveError = '保存できませんでした。入力内容を残しています。再度お試しください。';
        }
      });
    } catch (_) {
      if (mounted) setState(() => _saveError = '保存できませんでした。通信状態をご確認ください。');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color get _accent {
    final hex = widget.lesson.color.replaceFirst('#', '');
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null
        ? Theme.of(context).colorScheme.primary
        : Color(0xff000000 | parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = MediaQuery.of(context);
    final maxHeight = (media.size.height -
            media.viewInsets.bottom -
            media.padding.vertical -
            48)
        .clamp(140.0, 820.0);
    return PopScope(
      canPop: !_busy && !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        clipBehavior: Clip.antiAlias,
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
          child: SingleChildScrollView(
            key: const ValueKey('class-detail-scroll'),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '講義詳細',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '閉じる',
                      onPressed: _busy ? null : _close,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  widget.lesson.subjectName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _tag('${widget.dayLabel}・${widget.periodRange}'),
                    if (widget.lesson.duration > 1)
                      _tag('${widget.lesson.duration}コマ連続'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.timeRange,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.onAddAssignment != null) ...[
                  FilledButton.tonalIcon(
                    onPressed: _busy || _editing ? null : widget.onAddAssignment,
                    icon: const Icon(Icons.assignment_add), label: const Text('この講義の課題を登録')),
                  const SizedBox(height: 16),
                ],
                _surface(
                  child: Column(
                    children: [
                      _info(
                        Icons.place_outlined,
                        '教室',
                        widget.lesson.classroom,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      _info(
                        Icons.person_outline,
                        '担当教員',
                        widget.lesson.instructor,
                      ),
                    ],
                  ),
                ),
                if (widget.onOpenRoom != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy || _editing ? null : widget.onOpenRoom,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('教室の場所を調べる'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  children: [
                    Text(
                      'メモ',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!_editing && widget.onSaveNotes != null)
                      TextButton.icon(
                        onPressed:
                            _busy
                                ? null
                                : () => setState(() {
                                  _editing = true;
                                  _saveError = null;
                                }),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('メモを編集'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_editing) ...[
                  TextField(
                    controller: _notes,
                    minLines: 3,
                    maxLines: 7,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      hintText: '持ち物、課題、参考URLなど',
                      border: OutlineInputBorder(),
                      labelText: '講義メモ',
                    ),
                  ),
                  if (_saveError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _saveError!,
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton(
                        onPressed:
                            _busy
                                ? null
                                : () {
                                  _notes.text = _savedNotes;
                                  setState(() {
                                    _editing = false;
                                    _saveError = null;
                                  });
                                },
                        child: const Text('キャンセル'),
                      ),
                      FilledButton.icon(
                        onPressed: _busy ? null : _save,
                        icon:
                            _saving
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.check, size: 18),
                        label: Text(_saving ? '保存中…' : 'メモを保存'),
                      ),
                    ],
                  ),
                ] else
                  _surface(
                    child:
                        _savedNotes.trim().isEmpty
                            ? Text(
                              'メモはまだありません',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            )
                            : _linkedNotes(),
                  ),
                if (widget.loadAttendance != null) ...[
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '出欠',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.loadAttendanceSessions != null &&
                          widget.onSaveAttendance != null)
                        TextButton.icon(
                          key: const ValueKey('attendance-editor-toggle'),
                          onPressed:
                              _busy
                                  ? null
                                  : () => setState(
                                    () =>
                                        _editingAttendance =
                                            !_editingAttendance,
                                  ),
                          icon: Icon(
                            _editingAttendance
                                ? Icons.expand_less
                                : Icons.edit_outlined,
                            size: 18,
                          ),
                          label: Text(_editingAttendance ? '編集を閉じる' : '出欠を編集'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<AttendanceClassSummary>(
                    future: _attendance,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('出欠を取得できませんでした'),
                            TextButton(
                              onPressed:
                                  () => setState(
                                    () =>
                                        _attendance = widget.loadAttendance!(),
                                  ),
                              child: const Text('再試行'),
                            ),
                          ],
                        );
                      }
                      final summary = snapshot.data;
                      if (summary == null) {
                        return const LinearProgressIndicator();
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _count(
                            AttendanceStatusStyle.present,
                            summary.presentCount,
                          ),
                          _count(AttendanceStatusStyle.late, summary.lateCount),
                          _count(
                            AttendanceStatusStyle.absent,
                            summary.absentCount,
                          ),
                        ],
                      );
                    },
                  ),
                  if (_editingAttendance) ...[
                    const SizedBox(height: 12),
                    ClassAttendanceEditor(
                      loadSessions: widget.loadAttendanceSessions!,
                      onSave: widget.onSaveAttendance!,
                      enabled: !_saving,
                      onSavingChanged:
                          (saving) =>
                              setState(() => _savingAttendance = saving),
                      onSaved:
                          () => setState(
                            () =>
                                _attendance = Future.sync(
                                  widget.loadAttendance!,
                                ),
                          ),
                    ),
                  ],
                ],
                if (widget.onAttendance != null) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          _busy || _editing
                              ? null
                              : () async {
                                Navigator.of(context).pop();
                                await widget.onAttendance!();
                              },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('QRを読み取って出席'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );

  Widget _surface({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );

  Widget _info(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        icon,
        size: 22,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value.trim().isEmpty ? '未設定' : value,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ],
  );

  Widget _count(AttendanceStatusStyle status, int count) {
    final background = AppColors.tintedSurface(context, status.color);
    final foreground = AppColors.ensureContrast(status.color, background);
    return Container(
      key: ValueKey('attendance-count-${status.value}'),
      constraints: const BoxConstraints(minWidth: 76),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(status.label, style: TextStyle(color: foreground)),
        ],
      ),
    );
  }

  Widget _linkedNotes() {
    for (final recognizer in _linkRecognizers) {
      recognizer.dispose();
    }
    _linkRecognizers.clear();
    final spans = <TextSpan>[];
    var start = 0;
    for (final match in RegExp(r'https?://[^\s)]+').allMatches(_savedNotes)) {
      spans.add(TextSpan(text: _savedNotes.substring(start, match.start)));
      final url = match.group(0)!;
      final recognizer =
          TapGestureRecognizer()
            ..onTap = () async {
              try {
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('リンクを開けませんでした')));
                }
              }
            };
      _linkRecognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
          recognizer: recognizer,
        ),
      );
      start = match.end;
    }
    spans.add(TextSpan(text: _savedNotes.substring(start)));
    return SelectableText.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
        children: spans,
      ),
    );
  }
}
