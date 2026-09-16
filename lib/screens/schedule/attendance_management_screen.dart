import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../models/schedule/lecture_period_model.dart';
import '../../models/schedule/schedule_model.dart';
import '../../models/schedule/attendance_session.dart';
import '../../widgets/schedule/attendance_status_chip.dart';
import '../../services/schedule/attendance_service.dart';
import '../../services/schedule/lecture_period_service.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({super.key, required this.schedule});

  final Schedule schedule;

  @override
  State<AttendanceManagementScreen> createState() =>
      _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState
    extends State<AttendanceManagementScreen> {
  static const int _weekCount = AttendanceSession.weekCount;
  LecturePeriodSettings? _lecturePeriod;

  @override
  void initState() {
    super.initState();
    _loadLecturePeriod();
  }

  Future<void> _loadLecturePeriod() async {
    final settings = await LecturePeriodService.getLecturePeriod();
    if (!mounted) return;
    setState(() => _lecturePeriod = settings);
  }

  @override
  Widget build(BuildContext context) {
    final semesterStartDate = _resolveSemesterStartDate();
    final weeks = List<int>.generate(_weekCount, (index) => index);
    final classes = _collectClassRows(widget.schedule);
    final endDate = semesterStartDate.add(
      Duration(days: ((_weekCount - 1) * 7) + 6),
    );

    return Scaffold(
      appBar: AppBar(title: Text('出欠管理 (${widget.schedule.semester})')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AttendanceService.watchScheduleAttendanceRecords(
          userId: widget.schedule.userId,
          scheduleId: widget.schedule.id,
          startDate: semesterStartDate,
          endDate: endDate,
        ),
        builder: (context, snapshot) {
          final records = snapshot.data ?? const <Map<String, dynamic>>[];
          final recordMapByClass = <String, _AttendanceCellRecord>{};
          final recordMapBySlot = <String, _AttendanceCellRecord>{};
          for (final record in records) {
            final recordId = record['id'] as String? ?? '';
            final classId = record['classId'] as String? ?? '';
            final date = record['attendanceDate'] as DateTime?;
            final status = record['status'] as String? ?? '';
            final weekdayKey = record['weekdayKey'] as String? ?? '';
            final startPeriod = record['startPeriod'] as int?;
            if (recordId.isEmpty ||
                classId.isEmpty ||
                date == null ||
                status.isEmpty)
              continue;
            final localDate = date.toLocal();
            final dateKey = _dateKey(localDate);
            final cellRecord = _AttendanceCellRecord(
              recordId: recordId,
              status: status,
            );
            recordMapByClass['$classId|$dateKey'] = cellRecord;
            if (weekdayKey.isNotEmpty && startPeriod != null) {
              recordMapBySlot['$weekdayKey|$startPeriod|$dateKey'] = cellRecord;
            }
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: const Text(
                  '注意: この出欠管理はCIT Appから出欠登録した記録を表示するもので、あくまで参考情報です。実際の出欠状況は必ずCITポータルで確認してください。',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width + 80,
                    ),
                    child: SingleChildScrollView(
                      child: DataTable(
                        horizontalMargin: 14,
                        columnSpacing: 18,
                        dataRowMinHeight: 58,
                        dataRowMaxHeight: 72,
                        headingRowHeight: 52,
                        columns: [
                          const DataColumn(label: Text('講義')),
                          ...List.generate(
                            _weekCount,
                            (i) => DataColumn(label: Text('${i + 1}週')),
                          ),
                        ],
                        rows:
                            classes.map((row) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 220,
                                      child: Text(
                                        '${_weekdayLabel(row.weekdayKey)}${row.period}限\n${row.subjectName}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ),
                                  ...weeks.map((weekIndex) {
                                    final targetDate =
                                        _targetDateForWeekAndClass(
                                          semesterStartDate: semesterStartDate,
                                          weekdayKey: row.weekdayKey,
                                          weekIndex: weekIndex,
                                        );
                                    final key =
                                        '${row.classId}|${_dateKey(targetDate)}';
                                    final slotKey =
                                        '${row.weekdayKey}|${row.period}|${_dateKey(targetDate)}';
                                    final cellRecord =
                                        recordMapByClass[key] ??
                                        recordMapBySlot[slotKey];
                                    final status = cellRecord?.status;
                                    return DataCell(
                                      _statusCell(context, status),
                                      onTap: () async {
                                        await _editAttendanceCell(
                                          context: context,
                                          row: row,
                                          attendanceDate: targetDate,
                                          currentStatus: status,
                                          existingRecordId:
                                              cellRecord?.recordId,
                                        );
                                      },
                                    );
                                  }),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final status in AttendanceStatusStyle.values)
                      _LegendDot(color: status.color, text: status.label),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  DateTime _resolveSemesterStartDate() {
    final semester = widget.schedule.semester;
    final isFall = semester.contains('後期');
    final base =
        isFall
            ? _lecturePeriod?.fallStartDate
            : _lecturePeriod?.springStartDate ??
                _lecturePeriod?.lectureStartDate;
    final date = base ?? DateTime.now();
    return DateTime(date.year, date.month, date.day);
  }

  List<_AttendanceClassRow> _collectClassRows(Schedule schedule) {
    const order = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
    };
    final rows = <_AttendanceClassRow>[];
    for (final dayEntry in schedule.timetable.entries) {
      for (final periodEntry in dayEntry.value.entries) {
        final c = periodEntry.value;
        if (c == null || !c.isStartCell) continue;
        rows.add(
          _AttendanceClassRow(
            classId: c.id,
            weekdayKey: dayEntry.key,
            period: periodEntry.key,
            duration: c.duration,
            subjectName: c.subjectName,
          ),
        );
      }
    }
    rows.sort((a, b) {
      final da = order[a.weekdayKey] ?? 99;
      final db = order[b.weekdayKey] ?? 99;
      if (da != db) return da.compareTo(db);
      return a.period.compareTo(b.period);
    });
    return rows;
  }

  Widget _statusCell(BuildContext context, String? status) {
    final style = AttendanceStatusStyle.fromValue(status);
    return Icon(
      style.icon,
      color: AppColors.accent(context, style.color),
      size: 18,
    );
  }

  String _dateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime d) {
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }

  DateTime _targetDateForWeekAndClass({
    required DateTime semesterStartDate,
    required String weekdayKey,
    required int weekIndex,
  }) {
    final firstClassDate = _firstClassDateOnOrAfter(
      semesterStartDate: semesterStartDate,
      weekdayKey: weekdayKey,
    );
    return firstClassDate.add(Duration(days: 7 * weekIndex));
  }

  DateTime _firstClassDateOnOrAfter({
    required DateTime semesterStartDate,
    required String weekdayKey,
  }) {
    final targetWeekday = _weekdayNumber(weekdayKey);
    final diff = (targetWeekday - semesterStartDate.weekday + 7) % 7;
    return semesterStartDate.add(Duration(days: diff));
  }

  int _weekdayNumber(String weekdayKey) {
    switch (weekdayKey) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      default:
        return DateTime.monday;
    }
  }

  Future<void> _editAttendanceCell({
    required BuildContext context,
    required _AttendanceClassRow row,
    required DateTime attendanceDate,
    required String? currentStatus,
    String? existingRecordId,
  }) async {
    final selected = await showDialog<String?>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(
              '${row.subjectName}\n${_formatDate(attendanceDate)} の出欠を編集',
            ),
            content: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final status in AttendanceStatusStyle.values)
                  AttendanceStatusChip(
                    status: status,
                    selected: AttendanceStatusStyle.fromValue(currentStatus) == status,
                    onSelected: () => Navigator.of(dialogContext).pop(status.value ?? ''),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(null),
                child: const Text('キャンセル'),
              ),
            ],
          ),
    );

    if (selected == null) return;
    final normalizedStatus = selected.isEmpty ? null : selected;
    if (normalizedStatus == currentStatus) return;

    try {
      await AttendanceService.upsertAttendanceStatus(
        userId: widget.schedule.userId,
        scheduleId: widget.schedule.id,
        classId: row.classId,
        subjectName: row.subjectName,
        weekdayKey: row.weekdayKey,
        startPeriod: row.period,
        duration: row.duration,
        attendanceDate: attendanceDate,
        status: normalizedStatus,
        existingRecordId: existingRecordId,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('出欠を更新しました')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
    }
  }

  String _weekdayLabel(String key) {
    switch (key) {
      case 'monday':
        return '月';
      case 'tuesday':
        return '火';
      case 'wednesday':
        return '水';
      case 'thursday':
        return '木';
      case 'friday':
        return '金';
      case 'saturday':
        return '土';
      default:
        return '?';
    }
  }
}

class _AttendanceClassRow {
  const _AttendanceClassRow({
    required this.classId,
    required this.weekdayKey,
    required this.period,
    required this.duration,
    required this.subjectName,
  });

  final String classId;
  final String weekdayKey;
  final int period;
  final int duration;
  final String subjectName;
}

class _AttendanceCellRecord {
  const _AttendanceCellRecord({required this.recordId, required this.status});

  final String recordId;
  final String status;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
