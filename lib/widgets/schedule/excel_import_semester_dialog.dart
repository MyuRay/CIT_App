import 'package:flutter/material.dart';

import '../../models/schedule/schedule_model.dart';
import '../../services/schedule/excel_import_semester.dart';
import '../../services/schedule/excel_schedule_import_service.dart';

class ExcelImportSelection {
  const ExcelImportSelection({required this.source, required this.target});
  final SemesterScheduleImport source;
  final Schedule target;
}

Future<ExcelImportSelection?> showExcelImportSemesterDialog(
  BuildContext context, {
  required ScheduleWorkbookImport workbook,
  required List<Schedule> schedules,
  String? selectedScheduleId,
}) => showDialog<ExcelImportSelection>(
  context: context,
  builder:
      (_) => ExcelImportSemesterDialog(
        workbook: workbook,
        schedules: schedules,
        selectedScheduleId: selectedScheduleId,
      ),
);

class ExcelImportSemesterDialog extends StatefulWidget {
  const ExcelImportSemesterDialog({
    super.key,
    required this.workbook,
    required this.schedules,
    this.selectedScheduleId,
  });

  final ScheduleWorkbookImport workbook;
  final List<Schedule> schedules;
  final String? selectedScheduleId;

  @override
  State<ExcelImportSemesterDialog> createState() =>
      _ExcelImportSemesterDialogState();
}

class _ExcelImportSemesterDialogState extends State<ExcelImportSemesterDialog> {
  SemesterScheduleImport? _source;
  Schedule? _target;

  @override
  void initState() {
    super.initState();
    _target =
        widget.schedules
            .where((s) => s.id == widget.selectedScheduleId)
            .firstOrNull ??
        widget.schedules.firstOrNull;
    if (widget.workbook.semesters.length == 1) {
      _selectSource(widget.workbook.semesters.single);
    }
  }

  String _label(Schedule schedule) =>
      schedule.name?.trim().isNotEmpty == true
          ? schedule.name!.trim()
          : schedule.semester;

  void _selectSource(SemesterScheduleImport source) {
    _source = source;
    // Freeform names such as "3s" remain selectable; suggest a destination only
    // when its printed year and semester unambiguously match the source.
    final matches =
        widget.schedules.where((schedule) {
          final term = ExcelImportSemester.fromHeader(_label(schedule));
          return source.semester.semester != null &&
              term.semester == source.semester.semester &&
              term.year == source.semester.year;
        }).toList();
    if (matches.length == 1) _target = matches.single;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('取り込む学期を選択'),
      scrollable: true,
      content: SizedBox(
        width: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.workbook.semesters.length == 1
                  ? 'Excelから次の学期を検出しました。'
                  : 'Excelに複数の学期が含まれています。取り込む学期を選んでください。',
            ),
            const SizedBox(height: 16),
            for (final source in widget.workbook.semesters)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  selected: _source == source,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _selectSource(source)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                      backgroundColor:
                          _source == source ? colors.primaryContainer : null,
                      foregroundColor:
                          _source == source
                              ? colors.onPrimaryContainer
                              : colors.onSurface,
                      side: BorderSide(
                        color:
                            _source == source
                                ? colors.primary
                                : colors.outlineVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _source == source
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                source.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${source.draft.entries.length}講義・${source.sourceSheetNames.length}シート',
                              ),
                              if (source.draft.entries.isEmpty)
                                const Text('曜日・時限のある講義がありません'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_target?.id),
              initialValue: _target?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: '取り込み先の時間割',
                border: OutlineInputBorder(),
              ),
              items:
                  widget.schedules
                      .map(
                        (schedule) => DropdownMenuItem(
                          value: schedule.id,
                          child: Text(
                            _label(schedule),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
              onChanged:
                  (id) => setState(() {
                    _target =
                        widget.schedules.where((s) => s.id == id).firstOrNull;
                  }),
            ),
            const SizedBox(height: 12),
            const Text('次の画面で講義内容を確認できます。この時点では保存されません。'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed:
              _source == null || _target == null
                  ? null
                  : () => Navigator.of(context).pop(
                    ExcelImportSelection(source: _source!, target: _target!),
                  ),
          child: const Text('内容を確認'),
        ),
      ],
    );
  }
}
