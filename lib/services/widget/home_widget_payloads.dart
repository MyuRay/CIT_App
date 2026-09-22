import '../../models/bus/bus_model.dart';
import '../../models/schedule/schedule_model.dart';

/// Shared snapshots: native widgets advance time without waking Flutter.
/// Account IDs, private notes and attendance never leave the app.
class HomeWidgetPayloads {
  /// Export every period, including empty cells. Missing definitions use the
  /// same defaults as the in-app timetable; configured times take precedence.
  static List<TimeSlot> _timeSlots(List<TimeSlot> configured) => [
    for (final fallback in DefaultTimeSlots.citTimeSlots)
      configured.firstWhere(
        (slot) => slot.period == fallback.period,
        orElse: () => fallback,
      ),
  ];

  static String _displayTime(String value) {
    final minutes = _minutes(value.trim());
    if (minutes == null) return '';
    return '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
        '${(minutes % 60).toString().padLeft(2, '0')}';
  }

  static const weekdays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
  ];
  static DateTime japanTime(DateTime now) =>
      now.toUtc().add(const Duration(hours: 9));
  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static List<Map<String, dynamic>> classes(
    Map<int, ScheduleClass?> day,
    List<TimeSlot> slots,
  ) {
    final times = {for (final slot in _timeSlots(slots)) slot.period: slot};
    final result = <Map<String, dynamic>>[];
    for (var period = 1; period <= 10; period++) {
      final lesson = day[period];
      if (lesson == null ||
          (!lesson.isStartCell && day[period - 1]?.id == lesson.id)) {
        continue;
      }
      final end = (period + lesson.duration.clamp(1, 10) - 1).clamp(period, 10);
      result.add({
        'period': period,
        'endPeriod': end,
        'duration': end - period + 1,
        'subject':
            lesson.subjectName.trim().isEmpty ? '科目名未設定' : lesson.subjectName,
        'classroom': lesson.classroom,
        'color': lesson.color,
        'startTime': _displayTime(times[period]?.startTime ?? ''),
        'endTime': _displayTime(times[end]?.endTime ?? ''),
      });
    }
    return result;
  }

  static Map<String, dynamic> weekly(
    Schedule? schedule, {
    required DateTime now,
    String? title,
  }) => {
    'schemaVersion': 2,
    'updatedAt': now.millisecondsSinceEpoch,
    'timeZone': 'Asia/Tokyo',
    'hasSchedule': schedule != null,
    // Additive schema-v2 field: old widgets ignore it, updated widgets can
    // still read previously cached snapshots without this field.
    'timeSlots': [
      if (schedule != null)
        for (final slot in _timeSlots(schedule.timeSlots))
          {
            'period': slot.period,
            'startTime': _displayTime(slot.startTime),
            'endTime': _displayTime(slot.endTime),
          },
    ],
    'scheduleTitle':
        title ??
        (schedule?.name?.trim().isNotEmpty == true
            ? schedule!.name
            : schedule?.semester) ??
        '時間割',
    for (final day in weekdays)
      day: classes(schedule?.timetable[day] ?? {}, schedule?.timeSlots ?? []),
  };

  static Map<String, dynamic> today(Map<String, dynamic> weekly, DateTime now) {
    final japan = japanTime(now);
    final entries =
        japan.weekday == DateTime.sunday
            ? <dynamic>[]
            : (weekly[weekdays[japan.weekday - 1]] as List? ?? []);
    final minutes = japan.hour * 60 + japan.minute;
    int? currentPeriod;
    for (final entry in entries) {
      final start = _minutes(entry['startTime'] as String? ?? '');
      final end = _minutes(entry['endTime'] as String? ?? '');
      if (start != null && end != null && minutes >= start && minutes < end) {
        currentPeriod = entry['period'] as int?;
      }
    }
    return {
      'schemaVersion': 2,
      'updatedAt': weekly['updatedAt'],
      'hasSchedule': weekly['hasSchedule'] ?? false,
      'scheduleTitle': weekly['scheduleTitle'],
      'timeSlots': weekly['timeSlots'] ?? <dynamic>[],
      'dateKey': dateKey(japan),
      'date': '${japan.month}/${japan.day}',
      'weekday': ['月', '火', '水', '木', '金', '土', '日'][japan.weekday - 1],
      'currentPeriod': currentPeriod,
      'classes': entries,
    };
  }

  static int? _minutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }

  static Map<String, dynamic> bus(
    BusInformation info, {
    required DateTime now,
    String preferredCampus = 'tsudanuma',
  }) {
    final japan = japanTime(now);
    final dayType =
        japan.weekday == DateTime.sunday
            ? 'sunday'
            : japan.weekday == DateTime.saturday
            ? 'saturday'
            : 'weekday';
    final routes = info.operatingRoutesAt(now);
    final campus = preferredCampus == 'narashino' ? '新習志野' : '津田沼';
    bool preferred(BusRoute route) =>
        route.name.split('→').first.contains(campus);
    routes.sort(
      (a, b) =>
          preferred(a) == preferred(b)
              ? a.sortOrder.compareTo(b.sortOrder)
              : preferred(a)
              ? -1
              : 1,
    );
    return {
      'schemaVersion': 2,
      'updatedAt': now.millisecondsSinceEpoch,
      'dateKey': dateKey(japan),
      'timeZone': 'Asia/Tokyo',
      'expiresAt':
          DateTime.utc(
            japan.year,
            japan.month,
            japan.day + 1,
          ).subtract(const Duration(hours: 9)).millisecondsSinceEpoch,
      'routes':
          routes.take(2).map((route) {
            final entries =
                route.timeEntries
                    .where(
                      (entry) =>
                          entry.isActive &&
                          entry.dayType == dayType &&
                          entry.hour >= 0 &&
                          entry.hour < 24 &&
                          entry.minute >= 0 &&
                          entry.minute < 60,
                    )
                    .toList()
                  ..sort(
                    (a, b) => (a.hour * 60 + a.minute).compareTo(
                      b.hour * 60 + b.minute,
                    ),
                  );
            return {
              'name': route.name,
              'departures':
                  entries
                      .map(
                        (entry) => {
                          'time': entry.timeString,
                          'note': entry.note ?? '',
                          'departureAt':
                              DateTime.utc(
                                    japan.year,
                                    japan.month,
                                    japan.day,
                                    entry.hour,
                                    entry.minute,
                                  )
                                  .subtract(const Duration(hours: 9))
                                  .millisecondsSinceEpoch,
                        },
                      )
                      .toList(),
            };
          }).toList(),
    };
  }
}
