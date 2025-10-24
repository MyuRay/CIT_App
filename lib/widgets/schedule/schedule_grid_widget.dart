import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/schedule/schedule_model.dart';

class ScheduleGridWidget extends StatelessWidget {
  final Schedule schedule;
  final Function(String, int, ScheduleClass?) onClassTap;
  final Function(String, int) onEmptySlotTap;
  final bool isEditMode;
  final bool showSaturday;
  final bool forceFullHeight;

  const ScheduleGridWidget({
    super.key,
    required this.schedule,
    required this.onClassTap,
    required this.onEmptySlotTap,
    this.isEditMode = false,
    this.showSaturday = true,
    this.forceFullHeight = false,
  });

  List<Weekday> get displayWeekdays => showSaturday 
      ? Weekday.values 
      : Weekday.values.where((w) => w != Weekday.saturday).toList();

  @override
  Widget build(BuildContext context) {
    final columnCount = displayWeekdays.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final timeColumnWidth = 35.0; // 時限列の幅を縮小
    final cellWidth = (screenWidth - timeColumnWidth - 32) / columnCount;
    final baseCellHeight = forceFullHeight ? 60.0 : 65.0; // 共有時はセル高を調整
    final emptyCellHeight = (!isEditMode && !forceFullHeight) ? 24.0 : baseCellHeight;

    final rowHeights = List<double>.generate(10, (index) {
      final period = index + 1;
      final hasClass = displayWeekdays.any((weekday) => schedule.timetable[weekday.name]?[period] != null);
      return hasClass ? baseCellHeight : emptyCellHeight;
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
                ..._buildClassCells(context, timeColumnWidth, cellWidth, rowHeights, cumulativeHeights),
              ],
            ),
          ),
        ],
      );

    // 共有時は全体表示、通常時はスクロール可能
    return forceFullHeight 
        ? content 
        : SingleChildScrollView(child: content);
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

    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMultiPeriod ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          // 科目名
          Flexible(
            flex: isMultiPeriod ? (is4PeriodClass ? 3 : 2) : 4,
            child: Text(
              scheduleClass.subjectName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: isMultiPeriod ? (is4PeriodClass ? 14 : 12) : 9.5,
                height: 1.15,
              ),
              maxLines: isMultiPeriod ? (is4PeriodClass ? 6 : 4) : 4,
              overflow: TextOverflow.ellipsis,
              textAlign: isMultiPeriod ? TextAlign.center : TextAlign.start,
            ),
          ),

          if (!isMultiPeriod) const SizedBox(height: 1),
          
          // 教室（単一時限の場合のみ）
          if (!isMultiPeriod)
            Flexible(
              flex: 1,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: showSaturday
                    // 土曜表示時は、最小4文字分が折り返さないよう自動縮小
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          scheduleClass.classroom,
                          maxLines: 1,
                          softWrap: false,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black,
                                fontSize: 8,
                                height: 1.0,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    // 平日表示時は従来のサイズ
                    : Text(
                        scheduleClass.classroom,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black,
                              fontSize: 7.5,
                              height: 1.0,
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
              child: showSaturday
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        scheduleClass.classroom,
                        maxLines: 1,
                        softWrap: false,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black,
                              fontSize: is4PeriodClass ? 10 : 9, // ベースから自動縮小
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Text(
                      scheduleClass.classroom,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black,
                            fontSize: is4PeriodClass ? 9 : 8,
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Color(int.parse('0xff${scheduleClass.color.substring(1)}')),
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
            _buildDetailRow(context, Icons.schedule, '時間',
                '${weekdayNames[weekdayKey] ?? weekdayKey} $periodRange\n$timeRange'),
            const SizedBox(height: 12),
            _buildDetailRow(context, Icons.location_on, '教室', scheduleClass.classroom),
            const SizedBox(height: 12),
            _buildDetailRow(context, Icons.person, '担当教員', scheduleClass.instructor),
            if (scheduleClass.duration > 1) ...[
              const SizedBox(height: 12),
              _buildDetailRow(context, Icons.timer, '講義時間', '${scheduleClass.duration}時間連続'),
            ],
            if (scheduleClass.notes != null && scheduleClass.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRowLinkified(context, Icons.note, 'メモ', scheduleClass.notes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
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
}
