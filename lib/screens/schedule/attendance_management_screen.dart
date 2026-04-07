import 'package:flutter/material.dart';

import '../../models/schedule/lecture_period_model.dart';
import '../../models/schedule/schedule_model.dart';
import '../../services/schedule/attendance_service.dart';
import '../../services/schedule/lecture_period_service.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({
    super.key,
    required this.schedule,
  });

  final Schedule schedule;

  @override
  State<AttendanceManagementScreen> createState() =>
      _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen> {
  static const int _weekCount = 15;
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
      appBar: AppBar(
        title: Text('出欠管理 (${widget.schedule.semester})'),
      ),
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
            if (recordId.isEmpty || classId.isEmpty || date == null || status.isEmpty) continue;
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
                  color: Colors.orange.withOpacity(0.12),
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
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ),
                                  ...weeks.map((weekIndex) {
                                    final targetDate = _targetDateForWeekAndClass(
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
                                          existingRecordId: cellRecord?.recordId,
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
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(
                  children: [
                    _LegendDot(color: Colors.green, text: '出席'),
                    SizedBox(width: 12),
                    _LegendDot(color: Colors.orange, text: '遅刻'),
                    SizedBox(width: 12),
                    _LegendDot(color: Colors.red, text: '欠席'),
                    SizedBox(width: 12),
                    _LegendDot(color: Colors.pink, text: '休講'),
                    SizedBox(width: 12),
                    _LegendDot(color: Colors.grey, text: '未記録'),
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
            : _lecturePeriod?.springStartDate ?? _lecturePeriod?.lectureStartDate;
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
    if (status == 'present') {
      return const Icon(Icons.check_circle, color: Colors.green, size: 18);
    }
    if (status == 'late') {
      return const Icon(Icons.access_time_filled, color: Colors.orange, size: 18);
    }
    if (status == 'cancelled') {
      return const Icon(Icons.event_busy, color: Colors.pink, size: 18);
    }
    // present/late以外で値がある場合は欠席として扱う
    if (status != null && status.isNotEmpty) {
      return const Icon(Icons.cancel, color: Colors.red, size: 18);
    }
    return Icon(
      Icons.radio_button_unchecked,
      color: Theme.of(context).colorScheme.outline,
      size: 17,
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
            title: Text('${row.subjectName}\n${_formatDate(attendanceDate)} の出欠を編集'),
            content: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _statusButton(
                  context: dialogContext,
                  label: '出席',
                  color: Colors.green,
                  isSelected: currentStatus == 'present',
                  onTap: () => Navigator.of(dialogContext).pop('present'),
                ),
                _statusButton(
                  context: dialogContext,
                  label: '遅刻',
                  color: Colors.orange,
                  isSelected: currentStatus == 'late',
                  onTap: () => Navigator.of(dialogContext).pop('late'),
                ),
                _statusButton(
                  context: dialogContext,
                  label: '欠席',
                  color: Colors.red,
                  isSelected: currentStatus == 'absent',
                  onTap: () => Navigator.of(dialogContext).pop('absent'),
                ),
                _statusButton(
                  context: dialogContext,
                  label: '休講',
                  color: Colors.pink,
                  isSelected: currentStatus == 'cancelled',
                  onTap: () => Navigator.of(dialogContext).pop('cancelled'),
                ),
                _statusButton(
                  context: dialogContext,
                  label: '未記録',
                  color: Colors.grey,
                  isSelected: currentStatus == null || currentStatus.isEmpty,
                  onTap: () => Navigator.of(dialogContext).pop(''),
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

  Widget _statusButton({
    required BuildContext context,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(isSelected ? 0.28 : 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
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
  const _AttendanceCellRecord({
    required this.recordId,
    required this.status,
  });

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
