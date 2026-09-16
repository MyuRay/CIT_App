import 'package:flutter/material.dart';
import '../../models/bus/bus_timetable_draft.dart';
import '../../services/bus/bus_timetable_admin_service.dart';

String busTimetableSaveError(Object error) => switch (error) {
  FormatException() => error.message,
  BusTimetableConflict() => error.toString(),
  _ => '保存できませんでした。通信状態と管理者権限を確認して再試行してください。',
};

class BusDepartureDialog extends StatefulWidget {
  const BusDepartureDialog({
    super.key,
    this.entry,
    required this.dayType,
    required this.onSave,
  });
  final BusDepartureData? entry;
  final String dayType;
  final Future<void> Function(BusDepartureData) onSave;

  @override
  State<BusDepartureDialog> createState() => _BusDepartureDialogState();
}

class _BusDepartureDialogState extends State<BusDepartureDialog> {
  late final _time = TextEditingController(
    text:
        widget.entry == null
            ? ''
            : formatBusMinute(busDepartureMinute(widget.entry!)),
  );
  late final _note = TextEditingController(
    text: widget.entry?['note'] as String? ?? '',
  );
  late String _day =
      widget.entry == null ? widget.dayType : busDepartureDay(widget.entry!);
  late bool _active = widget.entry?['isActive'] as bool? ?? true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _time.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final minute = parseBusTime(_time.text);
      final entry = {
        ...?widget.entry,
        ...newBusDeparture(minute, _day, note: _note.text, active: _active),
        if (widget.entry?.containsKey('id') == true) 'id': widget.entry!['id'],
      };
      await widget.onSave(entry);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = busTimetableSaveError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(widget.entry == null ? '1便追加' : '便を編集'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('departure_time'),
                controller: _time,
                enabled: !_saving,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: '出発時刻',
                  hintText: '08:30 または 830',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _day,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'ダイヤ',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final day in busDayLabels.entries)
                    DropdownMenuItem(value: day.key, child: Text(day.value)),
                ],
                onChanged:
                    _saving ? null : (value) => setState(() => _day = value!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _note,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: '備考（任意）',
                  hintText: '最終便など',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile.adaptive(
                key: const Key('departure_active'),
                contentPadding: EdgeInsets.zero,
                title: const Text('運行する'),
                subtitle: const Text('オフにすると、この便を運休として残します'),
                value: _active,
                onChanged:
                    _saving ? null : (value) => setState(() => _active = value),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          key: const Key('departure_save'),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '保存中…' : '確定'),
        ),
      ],
    ),
  );
}
