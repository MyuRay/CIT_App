import 'package:flutter/material.dart';

import '../../models/schedule/academic_calendar_event_model.dart';
import '../../services/schedule/academic_calendar_service.dart';
import 'academic_month_calendar.dart';

typedef AcademicEventsLoader =
    Stream<List<AcademicCalendarEvent>> Function(DateTime start, DateTime end);

/// The stream and page position survive unrelated home-card rebuilds.
class AcademicCalendarCard extends StatefulWidget {
  const AcademicCalendarCard({
    super.key,
    required this.startsOnSunday,
    required this.onOpenAnnualImages,
    this.loadEvents,
    this.today,
  });

  final bool startsOnSunday;
  final VoidCallback onOpenAnnualImages;
  final AcademicEventsLoader? loadEvents;
  final DateTime? today;

  @override
  State<AcademicCalendarCard> createState() => _AcademicCalendarCardState();
}

class _AcademicCalendarCardState extends State<AcademicCalendarCard> {
  late int _year;
  late int _monthIndex;
  late List<DateTime> _months;
  late PageController _controller;
  late Stream<List<AcademicCalendarEvent>> _eventsStream;
  DateTime? _selectedDate;

  DateTime get _today => DateUtils.dateOnly(widget.today ?? DateTime.now());
  DateTime get _month => _months[_monthIndex];
  static int _academicYear(DateTime date) =>
      date.month < 4 ? date.year - 1 : date.year;

  @override
  void initState() {
    super.initState();
    _setYear(_today);
  }

  void _setYear(DateTime date) {
    _year = _academicYear(date);
    _months = List.generate(12, (index) => DateTime(_year, 4 + index));
    _monthIndex = (date.month - 4) % 12;
    _controller = PageController(initialPage: _monthIndex);
    _eventsStream = _loadEvents();
  }

  Stream<List<AcademicCalendarEvent>> _loadEvents() {
    final end = DateTime(_year + 1, 3, 31);
    return widget.loadEvents?.call(_months.first, end) ??
        AcademicCalendarService.watchEventsInRange(
          startDate: _months.first,
          endDate: end,
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToMonth(DateTime month) {
    final changedYear = _academicYear(month) != _year;
    final previousController = _controller;
    setState(() {
      _selectedDate = null;
      if (changedYear) {
        _setYear(month);
      } else {
        _monthIndex = (month.month - 4) % 12;
      }
    });
    if (changedYear) {
      // The old pager detaches during the next frame.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => previousController.dispose(),
      );
    } else {
      _controller.jumpToPage(_monthIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('academic-calendar-card'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<List<AcademicCalendarEvent>>(
          key: ValueKey(_year),
          stream: _eventsStream,
          builder: (context, snapshot) {
            final events = snapshot.data ?? const <AcademicCalendarEvent>[];
            final monthEvents =
                events
                    .where((event) => DateUtils.isSameMonth(event.date, _month))
                    .toList()
                  ..sort((a, b) => a.date.compareTo(b.date));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Row(
                  children: [
                    IconButton(
                      tooltip: '前の月',
                      onPressed:
                          () => _goToMonth(
                            DateTime(_month.year, _month.month - 1),
                          ),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final style = theme.textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                          );
                          final label = '${_month.year}年${_month.month}月';
                          final painter = TextPainter(
                            text: TextSpan(text: label, style: style),
                            textDirection: Directionality.of(context),
                            textScaler: MediaQuery.textScalerOf(context),
                          )..layout();
                          final wrap = painter.width > constraints.maxWidth;
                          painter.dispose();
                          return Text(
                            wrap ? '${_month.year}年\n${_month.month}月' : label,
                            textAlign: TextAlign.center,
                            style: style,
                          );
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: '次の月',
                      onPressed:
                          () => _goToMonth(
                            DateTime(_month.year, _month.month + 1),
                          ),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AcademicCalendarPager(
                  key: ValueKey('academic-pager-$_year'),
                  months: _months,
                  controller: _controller,
                  events: events,
                  startsOnSunday: widget.startsOnSunday,
                  today: _today,
                  showTitle: false,
                  compact: true,
                  visibleMonthIndex: _monthIndex,
                  selectedDate: _selectedDate,
                  onDateSelected:
                      (date) => setState(() {
                        _selectedDate =
                            DateUtils.isSameDay(date, _selectedDate)
                                ? null
                                : date;
                      }),
                  onPageChanged:
                      (index) => setState(() {
                        _monthIndex = index;
                        if (!DateUtils.isSameMonth(_selectedDate, _month)) {
                          _selectedDate = null;
                        }
                      }),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '予定',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _goToMonth(_today),
                      child: const Text('当月に戻る'),
                    ),
                  ],
                ),
                if (snapshot.hasError)
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('予定を取得できませんでした'),
                      TextButton(
                        onPressed:
                            () => setState(() => _eventsStream = _loadEvents()),
                        child: const Text('再読み込み'),
                      ),
                    ],
                  )
                else if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(semanticsLabel: '予定を読み込み中'),
                  )
                else if (monthEvents.isEmpty)
                  Text(
                    'この月の予定はありません',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  for (final event in monthEvents)
                    _EventRow(
                      event: event,
                      selected: DateUtils.isSameDay(event.date, _selectedDate),
                      onTap: () => _showEvent(event),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_month, size: 24, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text('学年暦', style: theme.textTheme.titleMedium),
      ],
    );
    final imagesButton = TextButton.icon(
      key: const ValueKey('academic-annual-images'),
      onPressed: widget.onOpenAnnualImages,
      icon: const Icon(Icons.image_outlined, size: 18),
      label: const Text('年間画像'),
    );
    double textWidth(String label, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final requiredWidth =
        textWidth('学年暦', theme.textTheme.titleMedium!) +
        textWidth('年間画像', theme.textTheme.labelLarge!) +
        98;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < requiredWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              Align(alignment: Alignment.centerRight, child: imagesButton),
            ],
          );
        }
        return Row(children: [title, const Spacer(), imagesButton]);
      },
    );
  }

  Future<void> _showEvent(AcademicCalendarEvent event) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder:
          (context) => SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.75,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${event.date.month}月${_dateLabel(event.date)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: '閉じる',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (event.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        event.note,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

String _dateLabel(DateTime date) {
  const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
  return '${date.day}日（${weekdays[date.weekday - 1]}）';
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.selected,
    required this.onTap,
  });

  final AcademicCalendarEvent event;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hex = event.colorHex.replaceAll('#', '');
    final color = Color(
      int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16) ?? 0xFFE53935,
    );
    return Semantics(
      key: ValueKey('academic-event-${event.id}'),
      selected: selected,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topCenter,
        child: Material(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: selected ? scheme.primary : Colors.transparent,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: selected ? 44 : 0),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: selected ? 8 : 4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.outline),
                        ),
                        child: const SizedBox(width: 6, height: 6),
                      ),
                    ),
                    Text(
                      _dateLabel(event.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            selected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                        fontWeight: selected ? FontWeight.bold : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event.title,
                            maxLines: selected ? null : 1,
                            overflow: selected ? null : TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  selected
                                      ? scheme.onPrimaryContainer
                                      : scheme.onSurface,
                              fontWeight:
                                  selected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          if (selected && event.note.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              event.note,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
