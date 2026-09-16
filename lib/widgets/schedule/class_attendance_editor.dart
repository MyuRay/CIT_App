import 'package:flutter/material.dart';
import '../../models/schedule/attendance_session.dart';
import 'attendance_status_chip.dart';

/// Saves one date at a time. Failed writes leave the existing record selected.
class ClassAttendanceEditor extends StatefulWidget {
  const ClassAttendanceEditor({
    super.key,
    required this.loadSessions,
    required this.onSave,
    required this.onSaved,
    required this.onSavingChanged,
    this.enabled = true,
  });
  final Future<List<AttendanceSession>> Function() loadSessions;
  final Future<void> Function(AttendanceSession, String?) onSave;
  final VoidCallback onSaved;
  final ValueChanged<bool> onSavingChanged;
  final bool enabled;

  @override
  State<ClassAttendanceEditor> createState() => _ClassAttendanceEditorState();
}

class _ClassAttendanceEditorState extends State<ClassAttendanceEditor> {
  List<AttendanceSession>? _sessions;
  int _selected = 0;
  bool _loading = true, _saving = false;
  String? _error, _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessions = await widget.loadSessions();
      if (!mounted) return;
      final today = DateUtils.dateOnly(DateTime.now());
      final last = sessions.lastIndexWhere(
        (session) => !session.date.isAfter(today),
      );
      setState(() {
        _sessions = List.of(sessions);
        _selected = last < 0 ? 0 : last;
      });
    } catch (_) {
      if (mounted) setState(() => _error = '出欠を読み込めませんでした。もう一度お試しください。');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(String? status) async {
    if (_saving || !widget.enabled) return;
    final session = _sessions![_selected];
    if (session.status == status) return;
    setState(() {
      _saving = true;
      _error = null;
      _message = null;
    });
    widget.onSavingChanged(true);
    try {
      await widget.onSave(session, status);
      if (!mounted) return;
      setState(() {
        _sessions![_selected] = session.withSavedStatus(status);
        _message =
            '${_dateLabel(session)}を${AttendanceStatusStyle.fromValue(status).label}に更新しました';
      });
      widget.onSaved();
    } catch (_) {
      if (mounted) {
        setState(() => _error = '保存できませんでした。変更前の記録を表示しています。もう一度選択してください。');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        widget.onSavingChanged(false);
      }
    }
  }

  String _dateLabel(AttendanceSession session) =>
      '${session.date.month}/${session.date.day}（第${session.week}週）';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      );
    }
    if (_sessions == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          TextButton(onPressed: _load, child: const Text('出欠を再読み込み')),
        ],
      );
    }
    if (_sessions!.isEmpty) {
      return const Text('編集できる講義日がありません。講義期間の設定を確認してください。');
    }
    final session = _sessions![_selected];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('日付を選び、出欠をタップして保存', style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          key: ValueKey('attendance-date-$_selected'),
          initialValue: _selected,
          isExpanded: true,
          isDense: false,
          itemHeight: null,
          decoration: InputDecoration(
            labelText: '講義日（${session.date.year}年）',
            border: const OutlineInputBorder(),
          ),
          items: [
            for (var i = 0; i < _sessions!.length; i++)
              DropdownMenuItem(
                value: i,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${_dateLabel(_sessions![i])} · ${AttendanceStatusStyle.fromValue(_sessions![i].status).label}',
                  ),
                ),
              ),
          ],
          onChanged:
              _saving || !widget.enabled
                  ? null
                  : (index) {
                    if (index != null) {
                      setState(() {
                        _selected = index;
                        _error = null;
                        _message = null;
                      });
                    }
                  },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final status in AttendanceStatusStyle.values)
              AttendanceStatusChip(
                key: ValueKey(
                  'attendance-edit-${status.value ?? 'unrecorded'}',
                ),
                status: status,
                selected:
                    AttendanceStatusStyle.fromValue(session.status) == status,
                onSelected:
                    _saving || !widget.enabled
                        ? null
                        : () => _save(status.value),
              ),
          ],
        ),
        if (_saving) const LinearProgressIndicator(),
        if (_error != null || _message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error ?? _message!,
                style: TextStyle(
                  color:
                      _error == null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.error,
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'CIT App内の記録です。大学側の出欠登録は変更されません。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
