import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/schedule/academic_calendar_event_model.dart';

/// A horizontal calendar whose height includes every week and scaled label.
class AcademicCalendarPager extends StatelessWidget {
  const AcademicCalendarPager({
    super.key,
    required this.months,
    required this.controller,
    required this.events,
    required this.startsOnSunday,
    required this.onPageChanged,
    this.selectedDate,
    this.onDateSelected,
    this.today,
    this.showTitle = true,
    this.compact = false,
    this.visibleMonthIndex,
  });

  final List<DateTime> months;
  final PageController controller;
  final List<AcademicCalendarEvent> events;
  final bool startsOnSunday;
  final ValueChanged<int> onPageChanged;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final DateTime? today;
  final bool showTitle;
  final bool compact;
  final int? visibleMonthIndex;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final calendars = [
        for (final month in months)
          AcademicMonthCalendar(
            month: month,
            events: events,
            startsOnSunday: startsOnSunday,
            selectedDate: selectedDate,
            onDateSelected: onDateSelected,
            today: today,
            showTitle: showTitle,
            compact: compact,
          ),
      ];
      final heights =
          calendars
              .map(
                (calendar) =>
                    calendar._layout(context, constraints.maxWidth).height,
              )
              .toList();
      final height =
          visibleMonthIndex == null
              ? heights.reduce(math.max)
              : heights[visibleMonthIndex!];
      final pager = SizedBox(
        height: height,
        child: PageView.builder(
          controller: controller,
          itemCount: calendars.length,
          onPageChanged: onPageChanged,
          // Let neighboring six-week months lay out at their own height. The
          // viewport resizes to the selected month without flex overflow.
          itemBuilder:
              (_, index) =>
                  visibleMonthIndex == null
                      ? calendars[index]
                      : OverflowBox(
                        alignment: Alignment.topCenter,
                        minHeight: 0,
                        maxHeight: double.infinity,
                        child: calendars[index],
                      ),
        ),
      );
      return visibleMonthIndex == null
          ? pager
          : AnimatedSize(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            child: pager,
          );
    },
  );
}

class AcademicMonthCalendar extends StatelessWidget {
  const AcademicMonthCalendar({
    super.key,
    required this.month,
    required this.events,
    required this.startsOnSunday,
    this.selectedDate,
    this.onDateSelected,
    this.today,
    this.showTitle = true,
    this.compact = false,
  });

  final DateTime month;
  final List<AcademicCalendarEvent> events;
  final bool startsOnSunday;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final DateTime? today;
  final bool showTitle;
  final bool compact;

  int get _leading =>
      startsOnSunday
          ? DateTime(month.year, month.month).weekday % 7
          : DateTime(month.year, month.month).weekday - 1;
  int get _days => DateUtils.getDaysInMonth(month.year, month.month);
  int get _rows => (_leading + _days + 6) ~/ 7;
  String get _title => '${month.year}年${month.month}月';

  TextStyle _titleStyle(BuildContext context) => Theme.of(
    context,
  ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700);
  TextStyle _dayStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!;

  _MonthLayout _layout(BuildContext context, double width) {
    final cellWidth = (width - 6 * 4) / 7;
    final textWidth = math.max(1.0, cellWidth - 8);
    double textHeight(String text, TextStyle style, double maxWidth) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
      )..layout(maxWidth: maxWidth);
      final height = painter.height.ceilToDouble();
      painter.dispose();
      return height;
    }

    final regularDay = _dayStyle(context);
    final boldDay = regularDay.copyWith(fontWeight: FontWeight.w700);
    // Fallback fonts can give digits and weights different line heights.
    // Measure every digit in both styles so every date fits, selected or not.
    final dayHeight = math.max(
      textHeight('0123456789', regularDay, double.infinity),
      textHeight('0123456789', boldDay, double.infinity),
    );
    final weekdayHeight = [
      '日',
      '月',
      '火',
      '水',
      '木',
      '金',
      '土',
    ].map((day) => textHeight(day, boldDay, cellWidth)).reduce(math.max);
    // Reserve space for six markers even when narrow cells wrap them.
    final dotsPerRow = ((textWidth + 1.5) / 5.5).floor().clamp(1, 6);
    final dotRows = (6 / dotsPerRow).ceil();
    final markersHeight = dotRows * 4 + (dotRows - 1) * 1.5;
    final cellHeight =
        math
            .max(
              (cellWidth / 1.25).clamp(
                compact || onDateSelected == null ? 36.0 : 44.0,
                52.0,
              ),
              dayHeight + 2 + markersHeight + 8,
            )
            .ceilToDouble();
    return _MonthLayout(
      titleHeight:
          showTitle ? textHeight(_title, _titleStyle(context), width) + 8 : 0,
      weekdayHeight: weekdayHeight,
      cellHeight: cellHeight,
      rows: _rows,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final layout = _layout(context, constraints.maxWidth);
      final scheme = Theme.of(context).colorScheme;
      final weekdays =
          startsOnSunday
              ? const ['日', '月', '火', '水', '木', '金', '土']
              : const ['月', '火', '水', '木', '金', '土', '日'];
      final byDay = <int, List<AcademicCalendarEvent>>{};
      for (final event in events) {
        if (event.date.year == month.year && event.date.month == month.month) {
          byDay.putIfAbsent(event.date.day, () => []).add(event);
        }
      }
      final now = today ?? DateTime.now();
      final currentMonth = month.year == now.year && month.month == now.month;
      final todayColumn = startsOnSunday ? now.weekday % 7 : now.weekday - 1;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle)
            SizedBox(
              height: layout.titleHeight,
              child: Text(_title, style: _titleStyle(context)),
            ),
          SizedBox(
            height: layout.weekdayHeight,
            child: Row(
              children: [
                for (var index = 0; index < 7; index++) ...[
                  if (index > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Center(
                      child: Text(
                        weekdays[index],
                        style: _dayStyle(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color:
                              currentMonth && index == todayColumn
                                  ? scheme.primary
                                  : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            padding: EdgeInsets.zero,
            primary: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rows * 7,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              mainAxisExtent: layout.cellHeight,
            ),
            itemBuilder: (context, index) {
              final day = index - _leading + 1;
              if (day < 1 || day > _days) return const SizedBox.shrink();
              final dayEvents = byDay[day] ?? const <AcademicCalendarEvent>[];
              final today = currentMonth && day == now.day;
              final date = DateTime(month.year, month.month, day);
              final selected = DateUtils.isSameDay(date, selectedDate);
              final background =
                  selected
                      ? scheme.primaryContainer
                      : today
                      ? scheme.primary.withValues(alpha: 0.2)
                      : dayEvents.isNotEmpty
                      ? _eventColor(dayEvents.first).withValues(alpha: 0.2)
                      : scheme.surfaceContainerHighest;
              return Semantics(
                button: onDateSelected != null,
                selected: selected,
                excludeSemantics: true,
                onTap:
                    onDateSelected == null ? null : () => onDateSelected!(date),
                label:
                    '${month.year}年${month.month}月$day日${today ? '、今日' : ''}、予定${dayEvents.length}件',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap:
                        onDateSelected == null
                            ? null
                            : () => onDateSelected!(date),
                    borderRadius: BorderRadius.circular(6),
                    child: Ink(
                      key: ValueKey(
                        'academic-day-${month.year}-${month.month}-$day',
                      ),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(6),
                        // Equal borders keep every date's text constraints identical.
                        border: Border.all(
                          color:
                              today || selected
                                  ? scheme.primary
                                  : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$day',
                              maxLines: 1,
                              softWrap: false,
                              style: _dayStyle(context).copyWith(
                                color:
                                    selected
                                        ? scheme.onPrimaryContainer
                                        : today
                                        ? scheme.primary
                                        : null,
                                fontWeight:
                                    today || selected ? FontWeight.bold : null,
                              ),
                            ),
                          ),
                          if (dayEvents.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 1.5,
                              runSpacing: 1.5,
                              children: [
                                for (final event in dayEvents.take(6))
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _eventColor(event),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    },
  );

  static Color _eventColor(AcademicCalendarEvent event) {
    final raw = event.colorHex.replaceAll('#', '');
    return Color(
      int.tryParse(raw.length == 6 ? 'FF$raw' : raw, radix: 16) ?? 0xFFE53935,
    );
  }
}

class _MonthLayout {
  const _MonthLayout({
    required this.titleHeight,
    required this.weekdayHeight,
    required this.cellHeight,
    required this.rows,
  });
  final double titleHeight, weekdayHeight, cellHeight;
  final int rows;
  double get height =>
      titleHeight + weekdayHeight + 6 + rows * cellHeight + (rows - 1) * 4;
}
