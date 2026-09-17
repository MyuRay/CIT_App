import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'dart:async';

import 'package:go_router/go_router.dart';

import 'schedule_class_detail_dialog.dart';
import '../../models/schedule/schedule_model.dart';
import '../../models/schedule/attendance_session.dart';
import '../../services/schedule/attendance_service.dart';
import '../../services/schedule/schedule_class_edit.dart';

class _DraggedScheduleClass {
  const _DraggedScheduleClass(
    this.scheduleId,
    this.day,
    this.period,
    this.lesson,
  );
  final String scheduleId;
  final String day;
  final int period;
  final ScheduleClass lesson;
}

class ScheduleGridWidget extends StatefulWidget {
  final Schedule schedule;
  final Function(String, int, ScheduleClass?) onClassTap;
  final Function(String, int) onEmptySlotTap;
  final void Function(String, int, ScheduleClass)? onClassLongPress;
  final Future<void> Function(String, int, ScheduleClass, String, int)?
  onClassMove;
  final Future<bool> Function(String, int, ScheduleClass, String?)?
  onClassNotesSave;
  final Future<void> Function(String, int, ScheduleClass)? onClassAttendanceTap;
  final Future<void> Function(ScheduleClass)? onAddAssignment;
  final Future<AttendanceClassSummary> Function(String, int, ScheduleClass)?
  onLoadAttendanceSummary;
  final Future<List<AttendanceSession>> Function(String, int, ScheduleClass)?
  onLoadAttendanceSessions;
  final Future<void> Function(
    String,
    int,
    ScheduleClass,
    AttendanceSession,
    String?,
  )?
  onSaveAttendanceStatus;

  /// false のとき QR 出席ボタンを出さない（講義期間外など）
  final bool showAttendanceActions;
  final bool isEditMode;
  final bool showSaturday;
  final bool forceFullHeight;
  final bool enableScroll;

  const ScheduleGridWidget({
    super.key,
    required this.schedule,
    required this.onClassTap,
    required this.onEmptySlotTap,
    this.onClassLongPress,
    this.onClassMove,
    this.onClassNotesSave,
    this.onClassAttendanceTap,
    this.onAddAssignment,
    this.onLoadAttendanceSummary,
    this.onLoadAttendanceSessions,
    this.onSaveAttendanceStatus,
    this.showAttendanceActions = true,
    this.isEditMode = false,
    this.showSaturday = true,
    this.forceFullHeight = false,
    this.enableScroll = true,
  });

  @override
  State<ScheduleGridWidget> createState() => _ScheduleGridWidgetState();
}

class _ScheduleGridWidgetState extends State<ScheduleGridWidget> {
  Schedule get schedule => widget.schedule;
  bool get isEditMode => widget.isEditMode;
  bool get showSaturday => widget.showSaturday;
  bool get forceFullHeight => widget.forceFullHeight;
  bool get enableScroll => widget.enableScroll;
  bool get showAttendanceActions => widget.showAttendanceActions;
  Function(String, int, ScheduleClass?) get onClassTap => widget.onClassTap;
  Function(String, int) get onEmptySlotTap => widget.onEmptySlotTap;
  void Function(String, int, ScheduleClass)? get onClassLongPress =>
      widget.onClassLongPress;
  Future<bool> Function(String, int, ScheduleClass, String?)?
  get onClassNotesSave => widget.onClassNotesSave;
  Future<void> Function(String, int, ScheduleClass)? get onClassAttendanceTap =>
      widget.onClassAttendanceTap;
  Future<AttendanceClassSummary> Function(String, int, ScheduleClass)?
  get onLoadAttendanceSummary => widget.onLoadAttendanceSummary;
  Future<List<AttendanceSession>> Function(String, int, ScheduleClass)?
  get onLoadAttendanceSessions => widget.onLoadAttendanceSessions;
  Future<void> Function(String, int, ScheduleClass, AttendanceSession, String?)?
  get onSaveAttendanceStatus => widget.onSaveAttendanceStatus;

  final _bodyKey = GlobalKey();
  _DraggedScheduleClass? _drag;
  ({String day, int period})? _hover;
  Offset? _pointer;
  Offset _feedbackAnchor = Offset.zero;
  Timer? _scrollTimer;
  bool _moved = false;
  bool _saving = false;
  double _cellWidth = 0;
  List<double> _rowEdges = const [];

  @override
  void dispose() {
    _scrollTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ScheduleGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isEditMode || schedule.id != oldWidget.schedule.id) {
      _scrollTimer?.cancel();
      _drag = null;
      _hover = null;
    }
  }

  ({String day, int period})? _targetAtPointer() {
    final box = _bodyKey.currentContext?.findRenderObject();
    if (box is! RenderBox ||
        _pointer == null ||
        _cellWidth <= 0 ||
        _rowEdges.isEmpty) {
      return null;
    }
    final point = box.globalToLocal(_pointer!);
    if (point.dx < 35 ||
        point.dx >= box.size.width ||
        point.dy < 0 ||
        point.dy >= _rowEdges.last) {
      return null;
    }
    final dayIndex = ((point.dx - 35) / _cellWidth).floor();
    if (dayIndex >= displayWeekdays.length) return null;
    final period = _rowEdges.indexWhere((edge) => edge > point.dy);
    return (day: displayWeekdays[dayIndex].name, period: period);
  }

  void _updateHover() {
    if (!mounted || _drag == null) return;
    final next = _targetAtPointer();
    if (next != _hover) setState(() => _hover = next);
  }

  StateError? _dropError(
    _DraggedScheduleClass drag,
    ({String day, int period}) target,
  ) {
    try {
      applyScheduleClassMove(
        schedule: schedule,
        fromWeekdayKey: drag.day,
        fromPeriod: drag.period,
        toWeekdayKey: target.day,
        toPeriod: target.period,
        expectedClass: drag.lesson,
      );
      return null;
    } on StateError catch (error) {
      return error;
    }
  }

  void _autoScroll() {
    if (!mounted || _drag == null || !_moved || _pointer == null) return;
    final bodyContext = _bodyKey.currentContext;
    if (bodyContext == null) return;
    final scrollable = Scrollable.maybeOf(bodyContext);
    final box = scrollable?.context.findRenderObject();
    if (scrollable == null ||
        box is! RenderBox ||
        !scrollable.position.hasContentDimensions) {
      return;
    }
    final origin = box.localToGlobal(Offset.zero);
    final viewport = origin & box.size;
    if (_pointer!.dx < viewport.left || _pointer!.dx >= viewport.right) return;
    final y = _pointer!.dy;
    if (y < viewport.top || y > viewport.bottom) return;
    const edge = 56.0;
    final delta =
        y < viewport.top + edge
            ? -12.0
            : y > viewport.bottom - edge
            ? 12.0
            : 0.0;
    final position = scrollable.position;
    final next = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (next != position.pixels) {
      position.jumpTo(next);
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateHover());
    }
  }

  void _endDrag() {
    _scrollTimer?.cancel();
    if (mounted) {
      setState(() {
        _drag = null;
        _hover = null;
        _pointer = null;
      });
    }
  }

  void _showMoveError(Object error) {
    final message =
        error is ScheduleClassOverlap
            ? '重複：${error.message}。元の位置に戻しました'
            : error is StateError
            ? '${error.message}。元の位置に戻しました'
            : '移動を保存できませんでした。元の位置に戻しました。通信状況を確認して再度お試しください';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _drop(_DraggedScheduleClass drag) async {
    if (!_moved || _saving || !isEditMode || drag.scheduleId != schedule.id) {
      return;
    }
    final target = _targetAtPointer();
    if (target == null ||
        (target.day == drag.day && target.period == drag.period)) {
      return;
    }
    final error = _dropError(drag, target);
    if (error != null) {
      _showMoveError(error);
      return;
    }
    final save = widget.onClassMove;
    if (save == null) return;
    setState(() => _saving = true);
    try {
      await save(drag.day, drag.period, drag.lesson, target.day, target.period);
    } catch (error) {
      if (mounted) _showMoveError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildDropPreview(BuildContext context) {
    final target = _hover!;
    final error = _dropError(_drag!, target);
    final scheme = Theme.of(context).colorScheme;
    final color = error == null ? scheme.primary : scheme.error;
    final end = (target.period - 1 + _drag!.lesson.duration).clamp(0, 10);
    return Positioned(
      left:
          35 +
          displayWeekdays.indexWhere((day) => day.name == target.day) *
              _cellWidth,
      top: _rowEdges[target.period - 1],
      width: _cellWidth,
      height: _rowEdges[end] - _rowEdges[target.period - 1],
      child: IgnorePointer(
        child: Container(
          key: ValueKey(
            error is ScheduleClassOverlap
                ? 'schedule-drop-overlap'
                : 'schedule-drop-preview',
          ),
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .2),
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            color: error == null ? scheme.primary : scheme.error,
            child: FittedBox(
              child: Text(
                error is ScheduleClassOverlap
                    ? '重複'
                    : error != null
                    ? '移動不可'
                    : '${target.period}限へ',
                style: TextStyle(
                  color: error == null ? scheme.onPrimary : scheme.onError,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Weekday> get displayWeekdays =>
      showSaturday
          ? Weekday.values
          : Weekday.values.where((w) => w != Weekday.saturday).toList();

  @override
  Widget build(BuildContext context) {
    final columnCount = displayWeekdays.length;
    final timeColumnWidth = 35.0; // 時限列の幅は固定
    final baseCellHeight = forceFullHeight ? 60.0 : 65.0; // 共有時はセル高を調整
    final emptyCellHeight =
        (!isEditMode && !forceFullHeight)
            ? 40.0
            : baseCellHeight; // 空行でも時限/時間が読める高さ

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;
        final remainingWidth = (availableWidth - timeColumnWidth).clamp(
          0.0,
          double.infinity,
        );
        final cellWidth = remainingWidth / columnCount;

        final rowHeights = List<double>.generate(10, (index) {
          final period = index + 1;
          final hasClass = displayWeekdays.any(
            (weekday) => schedule.timetable[weekday.name]?[period] != null,
          );
          if (!hasClass) {
            return emptyCellHeight;
          }

          // 改行時に科目名/教室名が隠れないように行高を拡張
          final additionalHeight = _additionalHeightForClassContent(period);
          return baseCellHeight + additionalHeight;
        });

        final cumulativeHeights = List<double>.filled(11, 0);
        for (var i = 0; i < 10; i++) {
          cumulativeHeights[i + 1] = cumulativeHeights[i] + rowHeights[i];
        }
        final totalHeight = cumulativeHeights.last;
        _cellWidth = cellWidth;
        _rowEdges = cumulativeHeights;

        final Widget content = Column(
          children: [
            // ヘッダー行
            _buildHeaderRow(context, timeColumnWidth, cellWidth),

            // グリッドボディ（スタック方式で連続講義を表現）
            SizedBox(
              key: _bodyKey,
              height: totalHeight,
              child: DragTarget<_DraggedScheduleClass>(
                onWillAcceptWithDetails:
                    (details) =>
                        isEditMode &&
                        !_saving &&
                        details.data.scheduleId == schedule.id &&
                        widget.onClassMove != null,
                onMove: (details) {
                  _pointer = details.offset + _feedbackAnchor;
                  if (_moved) _updateHover();
                },
                onLeave: (_) {
                  if (mounted && _hover != null) setState(() => _hover = null);
                },
                onAcceptWithDetails: (details) => _drop(details.data),
                builder:
                    (context, candidates, rejected) => IgnorePointer(
                      ignoring: _saving,
                      child: Stack(
                        children: [
                          // 背景グリッド
                          _buildBackgroundGrid(
                            context,
                            timeColumnWidth,
                            cellWidth,
                            rowHeights,
                          ),

                          // 時限列
                          _buildTimeColumn(
                            context,
                            timeColumnWidth,
                            rowHeights,
                          ),

                          // 講義セル（連続講義対応）
                          ..._buildClassCells(
                            context,
                            timeColumnWidth,
                            cellWidth,
                            rowHeights,
                            cumulativeHeights,
                          ),
                          if (_drag != null && _hover != null)
                            _buildDropPreview(context),
                          if (_saving)
                            const Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              child: LinearProgressIndicator(
                                semanticsLabel: '講義の移動を保存中',
                              ),
                            ),
                        ],
                      ),
                    ),
              ),
            ),
          ],
        );

        // 共有時は全体表示、通常時はスクロール可能
        final shouldAllowScroll = !forceFullHeight && enableScroll;
        return shouldAllowScroll
            ? SingleChildScrollView(child: content)
            : content;
      },
    );
  }

  Widget _buildHeaderRow(
    BuildContext context,
    double timeColumnWidth,
    double cellWidth,
  ) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      // Paint the border without subtracting it from the column layout width.
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          // 時限ヘッダー
          Container(
            width: timeColumnWidth,
            alignment: Alignment.center,
            child: Text(
              '時限',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          // 曜日ヘッダー
          ...displayWeekdays.map((weekday) {
            return Container(
              width: cellWidth,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Text(
                weekday.shortName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBackgroundGrid(
    BuildContext context,
    double timeColumnWidth,
    double cellWidth,
    List<double> rowHeights,
  ) {
    return Positioned.fill(
      child: Column(
        children: List.generate(10, (periodIndex) {
          return Container(
            height: rowHeights[periodIndex],
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                bottom:
                    periodIndex == 9
                        ? BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        )
                        : BorderSide.none,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: timeColumnWidth,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
                ...displayWeekdays.map((weekday) {
                  return Container(
                    width: cellWidth,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        right:
                            weekday == displayWeekdays.last
                                ? BorderSide(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                )
                                : BorderSide.none,
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeColumn(
    BuildContext context,
    double timeColumnWidth,
    List<double> rowHeights,
  ) {
    return Positioned(
      left: 0,
      top: 0,
      child: Column(
        children: List.generate(10, (periodIndex) {
          final period = periodIndex + 1;
          final timeSlot = schedule.timeSlots.firstWhere(
            (slot) => slot.period == period,
            orElse:
                () => TimeSlot(
                  period: period,
                  startTime: '${period + 8}:00',
                  endTime: '${period + 9}:00',
                ),
          );

          return Container(
            width: timeColumnWidth,
            height: rowHeights[periodIndex],
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$period',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${timeSlot.startTime}\n${timeSlot.endTime}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.1,
                        fontSize: 8,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildClassCells(
    BuildContext context,
    double timeColumnWidth,
    double cellWidth,
    List<double> rowHeights,
    List<double> cumulativeHeights,
  ) {
    final List<Widget> cells = [];
    final Set<String> processedCells = {}; // 既に処理済みのセル（連続講義対応）

    for (int periodIndex = 0; periodIndex < 10; periodIndex++) {
      final period = periodIndex + 1;

      for (
        int weekdayIndex = 0;
        weekdayIndex < displayWeekdays.length;
        weekdayIndex++
      ) {
        final weekday = displayWeekdays[weekdayIndex];
        final weekdayKey = weekday.name;
        final cellKey = '$weekdayKey-$period';

        // 既に処理済みのセルはスキップ
        if (processedCells.contains(cellKey)) continue;

        final scheduleClass = schedule.timetable[weekdayKey]?[period];
        if (scheduleClass == null) {
          // 空のセル
          cells.add(
            _buildEmptyClassCell(
              context,
              weekdayKey,
              period,
              timeColumnWidth + (weekdayIndex * cellWidth),
              cumulativeHeights[periodIndex],
              cellWidth,
              rowHeights[periodIndex],
            ),
          );
        } else if (scheduleClass.isStartCell) {
          // 講義セル（開始セル）
          final duration = scheduleClass.duration;
          final cellHeightEffective =
              cumulativeHeights[periodIndex + duration] -
              cumulativeHeights[periodIndex];

          // 連続する時限を処理済みとしてマーク
          for (int i = 0; i < duration; i++) {
            processedCells.add('$weekdayKey-${period + i}');
          }

          cells.add(
            _buildFilledClassCell(
              context,
              scheduleClass,
              weekdayKey,
              period,
              timeColumnWidth + (weekdayIndex * cellWidth),
              cumulativeHeights[periodIndex],
              cellWidth,
              cellHeightEffective,
            ),
          );
        }
        // isStartCell = false の場合は何も描画しない（既に開始セルで描画済み）
      }
    }

    return cells;
  }

  Widget _buildEmptyClassCell(
    BuildContext context,
    String weekdayKey,
    int period,
    double left,
    double top,
    double width,
    double height,
  ) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        key: ValueKey('schedule-empty-$weekdayKey-$period'),
        onTap: () {
          if (isEditMode) {
            onEmptySlotTap(weekdayKey, period);
          }
        },
        child: Container(
          margin: const EdgeInsets.all(1),
          child:
              isEditMode
                  ? Center(
                    child: Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  )
                  : null,
        ),
      ),
    );
  }

  Widget _buildFilledClassCell(
    BuildContext context,
    ScheduleClass scheduleClass,
    String weekdayKey,
    int period,
    double left,
    double top,
    double width,
    double height,
  ) {
    final color = Color(int.parse('0xff${scheduleClass.color.substring(1)}'));
    final canDrag = isEditMode && widget.onClassMove != null && !_saving;
    final cell = GestureDetector(
      key: ValueKey('schedule-class-$weekdayKey-$period'),
      onLongPress:
          !canDrag && isEditMode && onClassLongPress != null
              ? () => onClassLongPress!(weekdayKey, period, scheduleClass)
              : null,
      onTap: () {
        if (isEditMode) {
          onClassTap(weekdayKey, period, scheduleClass);
        } else {
          _showClassDetails(context, scheduleClass, weekdayKey, period);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          // Preserve the selected color; adapt the text instead of fading it.
          color: color,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: _buildClassContent(
          context,
          scheduleClass,
          scheduleClass.duration > 1,
          AppColors.onColor(color),
        ),
      ),
    );
    final drag = _DraggedScheduleClass(
      schedule.id,
      weekdayKey,
      period,
      scheduleClass,
    );
    final feedbackHeight = 40 + MediaQuery.textScalerOf(context).scale(24);
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child:
          canDrag
              ? LongPressDraggable<_DraggedScheduleClass>(
                data: drag,
                maxSimultaneousDrags: _drag == null ? 1 : 0,
                rootOverlay: true,
                dragAnchorStrategy: (_, _, pointer) {
                  _pointer = pointer;
                  _feedbackAnchor = Offset(72, feedbackHeight + 12);
                  return _feedbackAnchor;
                },
                onDragStarted: () {
                  setState(() {
                    _drag = drag;
                    _moved = false;
                    _hover = null;
                  });
                  _scrollTimer = Timer.periodic(
                    const Duration(milliseconds: 32),
                    (_) => _autoScroll(),
                  );
                },
                onDragUpdate: (details) {
                  _moved = true;
                  _pointer = details.globalPosition;
                  _updateHover();
                },
                onDragEnd: (_) => _endDrag(),
                feedback: Material(
                  elevation: 8,
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 144,
                    height: feedbackHeight,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              scheduleClass.subjectName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.onColor(color),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '${scheduleClass.duration}コマを移動',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.onColor(color),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(opacity: .3, child: cell),
                child: Semantics(
                  customSemanticsActions:
                      onClassLongPress == null
                          ? null
                          : {
                            const CustomSemanticsAction(label: '曜日と時限を選んで移動'):
                                () => onClassLongPress!(
                                  weekdayKey,
                                  period,
                                  scheduleClass,
                                ),
                          },
                  child: cell,
                ),
              )
              : cell,
    );
  }

  Widget _buildClassContent(
    BuildContext context,
    ScheduleClass scheduleClass,
    bool isMultiPeriod,
    Color foregroundColor,
  ) {
    // 4限連続かどうかで更に表示を調整
    final is4PeriodClass = scheduleClass.duration >= 4;
    final singlePeriodClassroomLines =
        (!isMultiPeriod) ? _estimateClassroomLines(scheduleClass.classroom) : 1;
    final subjectFlex =
        isMultiPeriod
            ? (is4PeriodClass ? 3 : 2)
            : (singlePeriodClassroomLines >= 3 ? 3 : 4);
    final classroomFlex =
        (!isMultiPeriod)
            ? (singlePeriodClassroomLines <= 2
                ? 1
                : (singlePeriodClassroomLines - 1).clamp(2, 5))
            : 1;

    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMultiPeriod ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          // 科目名
          Flexible(
            flex: subjectFlex,
            child: Text(
              scheduleClass.subjectName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: foregroundColor,
                fontSize: isMultiPeriod ? (is4PeriodClass ? 14 : 12) : 9.5,
                height: 1.15,
              ),
              maxLines:
                  isMultiPeriod
                      ? (is4PeriodClass ? 6 : 4)
                      : (singlePeriodClassroomLines >= 3 ? 3 : 4),
              overflow: TextOverflow.ellipsis,
              textAlign: isMultiPeriod ? TextAlign.center : TextAlign.start,
            ),
          ),

          if (!isMultiPeriod) const SizedBox(height: 1),

          // 教室（単一時限の場合のみ）
          if (!isMultiPeriod)
            Flexible(
              flex: classroomFlex,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  scheduleClass.classroom.trim(),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 8.6,
                    height: 1.05,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // 連続講義の場合、教室のみを中央に表示
          if (isMultiPeriod) ...[
            SizedBox(height: is4PeriodClass ? 10 : 6),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                scheduleClass.classroom.trim(),
                softWrap: true,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: is4PeriodClass ? 10.2 : 9.4,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _additionalHeightForClassContent(int period) {
    int maxClassroomLines = 1;
    int maxSubjectLines = 1;
    for (final weekday in displayWeekdays) {
      final scheduleClass = schedule.timetable[weekday.name]?[period];
      if (scheduleClass == null || !scheduleClass.isStartCell) {
        continue;
      }
      final classroomLines = _estimateClassroomLines(scheduleClass.classroom);
      if (classroomLines > maxClassroomLines) {
        maxClassroomLines = classroomLines;
      }

      if (scheduleClass.duration == 1) {
        final subjectLines = _estimateSubjectLines(scheduleClass.subjectName);
        if (subjectLines > maxSubjectLines) {
          maxSubjectLines = subjectLines;
        }
      }
    }

    // 2行でも実表示では不足しやすいため、2行目から追加する
    final classroomExtra =
        maxClassroomLines <= 1 ? 0.0 : (maxClassroomLines - 1) * 11.0;
    // 科目名も2行目から追加（単一時限セルのみ）
    final subjectExtra =
        maxSubjectLines <= 1 ? 0.0 : (maxSubjectLines - 1) * 9.0;

    final additional = classroomExtra + subjectExtra;
    if (additional < 0) {
      return 0;
    }
    return additional;
  }

  int _estimateClassroomLines(String classroom) {
    final text = classroom.trim();
    if (text.isEmpty) {
      return 1;
    }
    // 土曜表示時のセル幅に合わせた概算（全角/半角混在を考慮してやや小さめ）
    const charsPerLine = 6;
    final lines = (text.length / charsPerLine).ceil();
    return lines.clamp(1, 8);
  }

  int _estimateSubjectLines(String subject) {
    final text = subject.trim();
    if (text.isEmpty) {
      return 1;
    }
    // 5日表示の方が列幅が広いので、1行あたり文字数を少し多めに見積もる
    final charsPerLine = showSaturday ? 8 : 10;
    final lines = (text.length / charsPerLine).ceil();
    return lines.clamp(1, 6);
  }

  void _showClassDetails(
    BuildContext hostContext,
    ScheduleClass scheduleClass,
    String weekdayKey,
    int period,
  ) {
    final Map<String, String> weekdayNames = {
      'monday': '月曜日',
      'tuesday': '火曜日',
      'wednesday': '水曜日',
      'thursday': '木曜日',
      'friday': '金曜日',
      'saturday': '土曜日',
    };

    // 連続講義の場合、開始時限を見つける
    int startPeriod = period;
    if (!scheduleClass.isStartCell) {
      // 開始セルを探す
      for (int p = period - 1; p >= 1; p--) {
        final prevClass = schedule.timetable[weekdayKey]?[p];
        if (prevClass?.id == scheduleClass.id &&
            prevClass?.isStartCell == true) {
          startPeriod = p;
          break;
        }
      }
    }

    final timeRange = ScheduleUtils.getClassTimeRange(
      schedule,
      startPeriod,
      scheduleClass.duration,
    );
    final periodRange = ScheduleUtils.getClassPeriodRange(
      startPeriod,
      scheduleClass.duration,
    );
    final canTapAttendance =
        onClassAttendanceTap != null &&
        showAttendanceActions &&
        _isAttendanceTapAvailable(
          weekdayKey: weekdayKey,
          startPeriod: startPeriod,
        );
    showDialog<void>(
      context: hostContext,
      barrierDismissible: false,
      builder:
          (dialogContext) => ScheduleClassDetailDialog(
            lesson: scheduleClass,
            onAddAssignment: widget.onAddAssignment == null ? null : () => widget.onAddAssignment!(scheduleClass),
            dayLabel: weekdayNames[weekdayKey] ?? weekdayKey,
            periodRange: periodRange,
            timeRange: timeRange,
            onSaveNotes:
                onClassNotesSave == null
                    ? null
                    : (notes) => onClassNotesSave!(
                      weekdayKey,
                      startPeriod,
                      scheduleClass,
                      notes,
                    ),
            loadAttendance:
                onLoadAttendanceSummary == null
                    ? null
                    : () => onLoadAttendanceSummary!(
                      weekdayKey,
                      startPeriod,
                      scheduleClass,
                    ),
            loadAttendanceSessions:
                onLoadAttendanceSessions == null
                    ? null
                    : () => onLoadAttendanceSessions!(
                      weekdayKey,
                      startPeriod,
                      scheduleClass,
                    ),
            onSaveAttendance:
                onSaveAttendanceStatus == null
                    ? null
                    : (session, status) => onSaveAttendanceStatus!(
                      weekdayKey,
                      startPeriod,
                      scheduleClass,
                      session,
                      status,
                    ),
            onAttendance:
                !canTapAttendance
                    ? null
                    : () => onClassAttendanceTap!(
                      weekdayKey,
                      startPeriod,
                      scheduleClass,
                    ),
            onOpenRoom:
                scheduleClass.classroom.trim().isEmpty
                    ? null
                    : () {
                      final uri = Uri(
                        path: '/classroom-map',
                        queryParameters: {'q': scheduleClass.classroom.trim()},
                      );
                      Navigator.of(dialogContext).pop();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (hostContext.mounted) {
                          GoRouter.of(hostContext).push(uri.toString());
                        }
                      });
                    },
          ),
    );
  }

  Color _getCellColor(BuildContext context, ScheduleClass? scheduleClass) {
    if (scheduleClass != null) {
      final baseColor = Color(
        int.parse('0xff${scheduleClass.color.substring(1)}'),
      );
      return baseColor.withValues(alpha: 0.8);
    }

    return Colors.transparent;
  }

  bool _isAttendanceTapAvailable({
    required String weekdayKey,
    required int startPeriod,
  }) {
    final now = DateTime.now();
    final todayKey = _weekdayKeyFromDate(now);
    if (todayKey == null || todayKey != weekdayKey) return false;

    final startSlot = schedule.timeSlots.firstWhere(
      (slot) => slot.period == startPeriod,
      orElse:
          () => TimeSlot(
            period: startPeriod,
            startTime: '${startPeriod + 8}:00',
            endTime: '${startPeriod + 9}:00',
          ),
    );
    final parts = startSlot.startTime.split(':');
    final lectureStart = DateTime(
      now.year,
      now.month,
      now.day,
      int.tryParse(parts[0]) ?? 9,
      int.tryParse(parts[1]) ?? 0,
    );
    final availableFrom = lectureStart.subtract(const Duration(minutes: 20));
    final availableUntil = lectureStart.add(const Duration(hours: 1));
    return !now.isBefore(availableFrom) && !now.isAfter(availableUntil);
  }

  String? _weekdayKeyFromDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      default:
        return null;
    }
  }
}
