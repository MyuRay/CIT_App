import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/schedule/schedule_model.dart';
import '../../services/schedule/attendance_service.dart';

class ScheduleGridWidget extends StatelessWidget {
  final Schedule schedule;
  final Function(String, int, ScheduleClass?) onClassTap;
  final Function(String, int) onEmptySlotTap;
  final Future<bool> Function(String, int, ScheduleClass, String?)?
  onClassNotesSave;
  final Future<void> Function(String, int, ScheduleClass)? onClassAttendanceTap;
  final Future<AttendanceClassSummary> Function(String, int, ScheduleClass)?
  onLoadAttendanceSummary;
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
    this.onClassNotesSave,
    this.onClassAttendanceTap,
    this.onLoadAttendanceSummary,
    this.showAttendanceActions = true,
    this.isEditMode = false,
    this.showSaturday = true,
    this.forceFullHeight = false,
    this.enableScroll = true,
  });

  List<Weekday> get displayWeekdays => showSaturday 
      ? Weekday.values 
      : Weekday.values.where((w) => w != Weekday.saturday).toList();

  @override
  Widget build(BuildContext context) {
    final columnCount = displayWeekdays.length;
    final timeColumnWidth = 35.0; // 時限列の幅は固定
    final baseCellHeight = forceFullHeight ? 60.0 : 65.0; // 共有時はセル高を調整
    final emptyCellHeight = (!isEditMode && !forceFullHeight) ? 40.0 : baseCellHeight; // 空行でも時限/時間が読める高さ

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final remainingWidth = (availableWidth - timeColumnWidth).clamp(0.0, double.infinity);
        final cellWidth = remainingWidth / columnCount;

        final rowHeights = List<double>.generate(10, (index) {
          final period = index + 1;
          final hasClass = displayWeekdays.any((weekday) => schedule.timetable[weekday.name]?[period] != null);
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

        final Widget content = Column(
          children: [
            // ヘッダー行
            _buildHeaderRow(context, timeColumnWidth, cellWidth),

            // グリッドボディ（スタック方式で連続講義を表現）
            SizedBox(
              height: totalHeight,
              child: Stack(
                children: [
                  // 背景グリッド
                  _buildBackgroundGrid(context, timeColumnWidth, cellWidth, rowHeights),

                  // 時限列
                  _buildTimeColumn(context, timeColumnWidth, rowHeights),

                  // 講義セル（連続講義対応）
                  ..._buildClassCells(
                    context,
                    timeColumnWidth,
                    cellWidth,
                    rowHeights,
                    cumulativeHeights,
                  ),
                ],
              ),
            ),
          ],
        );

        // 共有時は全体表示、通常時はスクロール可能
        final shouldAllowScroll = !forceFullHeight && enableScroll;
        return shouldAllowScroll ? SingleChildScrollView(child: content) : content;
      },
    );
  }

  Widget _buildHeaderRow(BuildContext context, double timeColumnWidth, double cellWidth) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // 時限ヘッダー
          Container(
            width: timeColumnWidth,
            alignment: Alignment.center,
            child: Text(
              '時限',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // 曜日ヘッダー
          ...displayWeekdays.map((weekday) {
            return Container(
              width: cellWidth,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey.shade300)),
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

  Widget _buildBackgroundGrid(BuildContext context, double timeColumnWidth, double cellWidth, List<double> rowHeights) {
    return Positioned.fill(
      child: Column(
        children: List.generate(10, (periodIndex) {
          return Container(
            height: rowHeights[periodIndex],
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
                bottom: periodIndex == 9 ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: timeColumnWidth,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                ...displayWeekdays.map((weekday) {
                  return Container(
                    width: cellWidth,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey.shade300),
                        right: weekday == displayWeekdays.last 
                            ? BorderSide(color: Colors.grey.shade300) 
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

  Widget _buildTimeColumn(BuildContext context, double timeColumnWidth, List<double> rowHeights) {
    return Positioned(
      left: 0,
      top: 0,
      child: Column(
        children: List.generate(10, (periodIndex) {
          final period = periodIndex + 1;
          final timeSlot = schedule.timeSlots.firstWhere(
            (slot) => slot.period == period,
            orElse: () => TimeSlot(
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
                Text(
                  '${timeSlot.startTime}\n${timeSlot.endTime}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.1,
                    fontSize: 8,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildClassCells(BuildContext context, double timeColumnWidth, double cellWidth, List<double> rowHeights, List<double> cumulativeHeights) {
    final List<Widget> cells = [];
    final Set<String> processedCells = {}; // 既に処理済みのセル（連続講義対応）

    for (int periodIndex = 0; periodIndex < 10; periodIndex++) {
      final period = periodIndex + 1;
      
      for (int weekdayIndex = 0; weekdayIndex < displayWeekdays.length; weekdayIndex++) {
        final weekday = displayWeekdays[weekdayIndex];
        final weekdayKey = weekday.name;
        final cellKey = '$weekdayKey-$period';
        
        // 既に処理済みのセルはスキップ
        if (processedCells.contains(cellKey)) continue;
        
        final scheduleClass = schedule.timetable[weekdayKey]?[period];
        if (scheduleClass == null) {
          // 空のセル
          cells.add(_buildEmptyClassCell(
            context, 
            weekdayKey, 
            period, 
            timeColumnWidth + (weekdayIndex * cellWidth),
            cumulativeHeights[periodIndex],
            cellWidth,
            rowHeights[periodIndex]
          ));
        } else if (scheduleClass.isStartCell) {
          // 講義セル（開始セル）
          final duration = scheduleClass.duration;
          final cellHeightEffective = cumulativeHeights[periodIndex + duration] - cumulativeHeights[periodIndex];
          
          // 連続する時限を処理済みとしてマーク
          for (int i = 0; i < duration; i++) {
            processedCells.add('$weekdayKey-${period + i}');
          }
          
          cells.add(_buildFilledClassCell(
            context, 
            scheduleClass,
            weekdayKey, 
            period, 
            timeColumnWidth + (weekdayIndex * cellWidth),
            cumulativeHeights[periodIndex],
            cellWidth,
            cellHeightEffective
          ));
        }
        // isStartCell = false の場合は何も描画しない（既に開始セルで描画済み）
      }
    }
    
    return cells;
  }

  Widget _buildEmptyClassCell(BuildContext context, String weekdayKey, int period, double left, double top, double width, double height) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () {
          if (isEditMode) {
            onEmptySlotTap(weekdayKey, period);
          }
        },
        child: Container(
          margin: const EdgeInsets.all(1),
          child: isEditMode
              ? Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilledClassCell(BuildContext context, ScheduleClass scheduleClass, String weekdayKey, int period, double left, double top, double width, double height) {
    final color = Color(int.parse('0xff${scheduleClass.color.substring(1)}'));
    
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
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
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: _buildClassContent(context, scheduleClass, scheduleClass.duration > 1),
        ),
      ),
    );
  }

  Widget _buildClassContent(BuildContext context, ScheduleClass scheduleClass, bool isMultiPeriod) {
    // 4限連続かどうかで更に表示を調整
    final is4PeriodClass = scheduleClass.duration >= 4;
    final singlePeriodClassroomLines = (!isMultiPeriod)
        ? _estimateClassroomLines(scheduleClass.classroom)
        : 1;
    final subjectFlex = isMultiPeriod
        ? (is4PeriodClass ? 3 : 2)
        : (singlePeriodClassroomLines >= 3 ? 3 : 4);
    final classroomFlex = (!isMultiPeriod)
        ? (singlePeriodClassroomLines <= 2
              ? 1
              : (singlePeriodClassroomLines - 1).clamp(2, 5))
        : 1;

    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMultiPeriod ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          // 科目名
          Flexible(
            flex: subjectFlex,
            child: Text(
              scheduleClass.subjectName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: isMultiPeriod ? (is4PeriodClass ? 14 : 12) : 9.5,
                height: 1.15,
              ),
              maxLines: isMultiPeriod
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  scheduleClass.classroom.trim(),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _formatClassroomForCompactCell(scheduleClass.classroom),
                softWrap: true,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black,
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

  String _formatClassroomForCompactCell(String classroom) {
    final text = classroom.trim();
    if (text.length <= 7) {
      return text;
    }

    final separators = [' ', '　', '/', '／', '-', '－', '・'];
    final mid = text.length ~/ 2;

    int bestIndex = -1;
    int bestDistance = 1 << 30;
    for (final sep in separators) {
      var index = text.indexOf(sep);
      while (index != -1) {
        final distance = (index - mid).abs();
        if (index > 1 && index < text.length - 2 && distance < bestDistance) {
          bestDistance = distance;
          bestIndex = index;
        }
        index = text.indexOf(sep, index + 1);
      }
    }

    if (bestIndex != -1) {
      final first = text.substring(0, bestIndex).trimRight();
      final second = text.substring(bestIndex + 1).trimLeft();
      return '$first\n$second';
    }

    final split = (text.length / 2).ceil();
    return '${text.substring(0, split)}\n${text.substring(split)}';
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
    final classroomExtra = maxClassroomLines <= 1 ? 0.0 : (maxClassroomLines - 1) * 11.0;
    // 科目名も2行目から追加（単一時限セルのみ）
    final subjectExtra = maxSubjectLines <= 1 ? 0.0 : (maxSubjectLines - 1) * 9.0;

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


  void _showClassDetails(BuildContext context, ScheduleClass scheduleClass, String weekdayKey, int period) {
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
        if (prevClass?.id == scheduleClass.id && prevClass?.isStartCell == true) {
          startPeriod = p;
          break;
        }
      }
    }

    final timeRange = ScheduleUtils.getClassTimeRange(schedule, startPeriod, scheduleClass.duration);
    final periodRange = ScheduleUtils.getClassPeriodRange(startPeriod, scheduleClass.duration);
    final canTapAttendance =
        onClassAttendanceTap != null &&
        showAttendanceActions &&
        _isAttendanceTapAvailable(
          weekdayKey: weekdayKey,
          startPeriod: startPeriod,
        );
    final summaryFuture =
        onLoadAttendanceSummary?.call(weekdayKey, startPeriod, scheduleClass);

    showDialog(
      context: context,
      builder: (context) {
        final notesController = TextEditingController(
          text: scheduleClass.notes ?? '',
        );
        bool isEditingMemo = false;
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse('0xff${scheduleClass.color.substring(1)}'),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scheduleClass.subjectName,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  context,
                  Icons.schedule,
                  '時間',
                  '${weekdayNames[weekdayKey] ?? weekdayKey} $periodRange\n$timeRange',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  context,
                  Icons.location_on,
                  '教室',
                  scheduleClass.classroom,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  context,
                  Icons.person,
                  '担当教員',
                  scheduleClass.instructor,
                ),
                if (scheduleClass.duration > 1) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    Icons.timer,
                    '講義時間',
                    '${scheduleClass.duration}時間連続',
                  ),
                ],
                const SizedBox(height: 12),
                if (!isEditingMemo) ...[
                  if (scheduleClass.notes != null && scheduleClass.notes!.isNotEmpty)
                    _buildDetailRowLinkified(
                      context,
                      Icons.note,
                      'メモ',
                      scheduleClass.notes!,
                    )
                  else
                    _buildDetailRow(context, Icons.note, 'メモ', '未設定'),
                ] else ...[
                  const Text(
                    'メモ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'メモを入力',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
                if (canTapAttendance) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await onClassAttendanceTap!(
                          weekdayKey,
                          startPeriod,
                          scheduleClass,
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('QRを読み取って出席'),
                    ),
                  ),
                ],
                if (summaryFuture != null) ...[
                  const SizedBox(height: 12),
                  FutureBuilder<AttendanceClassSummary>(
                    future: summaryFuture,
                    builder: (context, snapshot) {
                      final summary = snapshot.data;
                      if (summary == null) {
                        return const SizedBox.shrink();
                      }
                      return _buildDetailRow(
                        context,
                        Icons.analytics_outlined,
                        '出欠集計',
                        '出席 ${summary.presentCount}回 / 遅刻 ${summary.lateCount}回 / 欠席 ${summary.absentCount}回',
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      children: [
                        const TextSpan(text: '※ 出欠集計を編集するには、画面右上の'),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(
                              Icons.fact_check_outlined,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const TextSpan(text: 'より編集してください。'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (onClassNotesSave != null && !isEditingMemo)
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      isEditingMemo = true;
                    });
                  },
                  child: const Text('メモを編集'),
                ),
              if (onClassNotesSave != null && isEditingMemo)
                TextButton(
                  onPressed:
                      isSaving
                          ? null
                          : () {
                            setDialogState(() {
                              isEditingMemo = false;
                            });
                          },
                  child: const Text('キャンセル'),
                ),
              if (onClassNotesSave != null && isEditingMemo)
                FilledButton(
                  onPressed:
                      isSaving
                          ? null
                          : () async {
                            setDialogState(() {
                              isSaving = true;
                            });
                            final ok = await onClassNotesSave!(
                              weekdayKey,
                              startPeriod,
                              scheduleClass,
                              notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                            );
                            if (!context.mounted) return;
                            setDialogState(() {
                              isSaving = false;
                            });
                            if (ok) {
                              Navigator.of(context).pop();
                            }
                          },
                  child:
                      isSaving
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('保存'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  // メモ用: URLをクリック可能にしたRow
  Widget _buildDetailRowLinkified(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: _linkifyText(context, value),
            ),
          ),
        ),
      ],
    );
  }

  // 共通: URLをクリック可能にしたTextSpanリストを返却
  List<TextSpan> _linkifyText(BuildContext context, String text) {
    final spans = <TextSpan>[];
    final urlRegex = RegExp(r'(https?:\/\/[^\s)]+)');
    int start = 0;
    for (final m in urlRegex.allMatches(text)) {
      if (m.start > start) {
        spans.add(TextSpan(text: text.substring(start, m.start)));
      }
      final url = text.substring(m.start, m.end);
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
          recognizer: (TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }),
        ),
      );
      start = m.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }

  Color _getCellColor(BuildContext context, ScheduleClass? scheduleClass) {
    if (scheduleClass != null) {
      final baseColor = Color(int.parse('0xff${scheduleClass.color.substring(1)}'));
      return baseColor.withOpacity(0.8);
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
