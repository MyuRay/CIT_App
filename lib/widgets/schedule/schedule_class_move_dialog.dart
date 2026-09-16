import 'package:flutter/material.dart';

import '../../models/schedule/schedule_model.dart';
import '../../services/schedule/schedule_class_edit.dart';

class ScheduleClassMoveDialog extends StatefulWidget {
  const ScheduleClassMoveDialog({
    super.key,
    required this.schedule,
    required this.weekdayKey,
    required this.period,
    required this.scheduleClass,
    required this.onMove,
  });

  final Schedule schedule;
  final String weekdayKey;
  final int period;
  final ScheduleClass scheduleClass;
  final Future<void> Function(String weekdayKey, int period) onMove;

  @override
  State<ScheduleClassMoveDialog> createState() =>
      _ScheduleClassMoveDialogState();
}

class _ScheduleClassMoveDialogState extends State<ScheduleClassMoveDialog> {
  late String _day = widget.weekdayKey;
  late int _period = widget.period;
  bool _saving = false;
  String? _saveError;

  String? get _conflict {
    try {
      applyScheduleClassMove(
        schedule: widget.schedule,
        fromWeekdayKey: widget.weekdayKey,
        fromPeriod: widget.period,
        toWeekdayKey: _day,
        toPeriod: _period,
        expectedClass: widget.scheduleClass,
      );
      return null;
    } on StateError catch (error) {
      return error.message;
    }
  }

  Future<void> _move() async {
    if (_saving || _conflict != null) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onMove(_day, _period);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _saveError =
                  error is StateError
                      ? error.message
                      : '移動を保存できませんでした。通信状況を確認して、もう一度お試しください。',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final error = _saveError ?? _conflict;
    final unchanged = _day == widget.weekdayKey && _period == widget.period;
    final sourceDay = Weekday.values.firstWhere(
      (day) => day.name == widget.weekdayKey,
    );
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: const Text('講義を移動'),
        scrollable: true,
        content: SizedBox(
          width: 360,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.scheduleClass.subjectName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                '現在：${sourceDay.shortName}曜日 ${widget.period}限'
                '${widget.scheduleClass.duration > 1 ? 'から${widget.scheduleClass.duration}コマ連続' : ''}',
              ),
              const SizedBox(height: 20),
              const Text(
                '移動先の曜日',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final day in Weekday.values)
                    ChoiceChip(
                      label: Text('${day.shortName}曜'),
                      selected: _day == day.name,
                      onSelected:
                          _saving
                              ? null
                              : (_) => setState(() {
                                _day = day.name;
                                _saveError = null;
                              }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.scheduleClass.duration > 1 ? '開始する時限' : '移動先の時限',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (var period = 1; period <= 10; period++)
                    ChoiceChip(
                      label: Text('$period限'),
                      selected: _period == period,
                      onSelected:
                          _saving
                              ? null
                              : (_) => setState(() {
                                _period = period;
                                _saveError = null;
                              }),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.scheduleClass.duration > 1
                    ? '${widget.scheduleClass.duration}コマをまとめて移動します。講義の内容・色・メモは引き継がれます。'
                    : '講義の内容・色・メモはそのまま移動します。',
              ),
              if (_day == Weekday.saturday.name) ...[
                const SizedBox(height: 8),
                const Text('土曜日が非表示の場合は、移動後に表示します。'),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error, style: TextStyle(color: colorScheme.error)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed:
                !_saving && !unchanged && _conflict == null ? _move : null,
            child: Text(_saving ? '移動中…' : 'ここに移動'),
          ),
        ],
      ),
    );
  }
}
