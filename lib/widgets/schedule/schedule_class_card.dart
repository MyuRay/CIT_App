import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/schedule/schedule_model.dart';

class ScheduleClassCard extends StatelessWidget {
  final ScheduleClass scheduleClass;
  final TimeSlot timeSlot;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isNext;
  final List<TimeSlot>? allTimeSlots; // 連続講義の終了時間計算用

  const ScheduleClassCard({
    super.key,
    required this.scheduleClass,
    required this.timeSlot,
    this.onTap,
    this.isActive = false,
    this.isNext = false,
    this.allTimeSlots,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('0xff${scheduleClass.color.substring(1)}'));
    
    // 連続講義の時間表示を計算
    String timeDisplay;
    String periodDisplay;
    
    if (scheduleClass.duration > 1 && allTimeSlots != null) {
      // 連続講義の場合
      final endTime = _getEndTime();
      timeDisplay = '${timeSlot.startTime}-$endTime';
      periodDisplay = '${timeSlot.period}-${timeSlot.period + scheduleClass.duration - 1}限';
    } else {
      // 通常の講義
      timeDisplay = timeSlot.startTime;
      periodDisplay = '${timeSlot.period}限';
    }
    
    return Card(
      elevation: isActive || isNext ? 8 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive 
                  ? Theme.of(context).colorScheme.primary
                  : isNext 
                      ? Theme.of(context).colorScheme.secondary
                      : color.withOpacity(0.3),
              width: isActive || isNext ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // 時間表示
              Container(
                width: scheduleClass.duration > 1 ? 80 : 60, // 連続講義の場合は幅を広げる
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      periodDisplay,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: scheduleClass.duration > 1 ? 11 : 12,
                      ),
                    ),
                    Text(
                      timeDisplay,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontSize: scheduleClass.duration > 1 ? 9 : 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 科目情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 科目名
                    Text(
                      scheduleClass.subjectName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isActive 
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 教室と教員
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          scheduleClass.classroom,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                        if (scheduleClass.instructor.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              scheduleClass.instructor,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // メモがある場合
                    if (scheduleClass.notes != null && scheduleClass.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.note,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: RichText(
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ) ?? const TextStyle(fontSize: 12),
                                children: _linkifyText(context, scheduleClass.notes!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // 色インディケーター
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // ステータスインディケーター
              if (isActive || isNext) ...[
                const SizedBox(width: 8),
                Icon(
                  isActive ? Icons.play_circle_filled : Icons.schedule,
                  color: isActive 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getEndTime() {
    if (allTimeSlots == null) return timeSlot.endTime;
    
    final endPeriod = timeSlot.period + scheduleClass.duration - 1;
    final endTimeSlot = allTimeSlots!.firstWhere(
      (slot) => slot.period == endPeriod,
      orElse: () => TimeSlot(
        period: endPeriod,
        startTime: '${endPeriod + 8}:00',
        endTime: '${endPeriod + 9}:00',
      ),
    );
    return endTimeSlot.endTime;
  }
}

// URLを検出してクリック可能なTextSpanに変換
List<TextSpan> _linkifyText(BuildContext context, String text) {
  final spans = <TextSpan>[];
  final urlRegex = RegExp(r'(https?:\/\/[^\s)]+)');
  int start = 0;
  final matches = urlRegex.allMatches(text);
  for (final m in matches) {
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

// 今日の時間割リスト用ウィジェット
class TodayScheduleList extends StatelessWidget {
  final List<ScheduleClass?> todayClasses;
  final List<TimeSlot> timeSlots;
  final int? currentPeriod;
  final Function(ScheduleClass, TimeSlot)? onClassTap;

  const TodayScheduleList({
    super.key,
    required this.todayClasses,
    required this.timeSlots,
    this.currentPeriod,
    this.onClassTap,
  });

  @override
  Widget build(BuildContext context) {
    // 授業がある時限のみをフィルタリング
    final scheduledClasses = <int, ScheduleClass>{};
    for (int i = 0; i < todayClasses.length; i++) {
      if (todayClasses[i] != null) {
        scheduledClasses[i + 1] = todayClasses[i]!;
      }
    }

    if (scheduledClasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.free_breakfast,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '今日は授業がありません',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: scheduledClasses.length,
      itemBuilder: (context, index) {
        final period = scheduledClasses.keys.elementAt(index);
        final scheduleClass = scheduledClasses[period]!;
        final timeSlot = timeSlots.firstWhere(
          (slot) => slot.period == period,
          orElse: () => TimeSlot(
            period: period,
            startTime: '${period + 8}:00',
            endTime: '${period + 9}:00',
          ),
        );

        final isActive = currentPeriod == period;
        final isNext = currentPeriod != null && period == currentPeriod! + 1;

        return ScheduleClassCard(
          scheduleClass: scheduleClass,
          timeSlot: timeSlot,
          isActive: isActive,
          isNext: isNext,
          allTimeSlots: timeSlots,
          onTap: onClassTap != null 
              ? () => onClassTap!(scheduleClass, timeSlot)
              : null,
        );
      },
    );
  }
}

// 空のコマ用ウィジェット
class EmptySlotCard extends StatelessWidget {
  final TimeSlot timeSlot;
  final VoidCallback? onTap;

  const EmptySlotCard({
    super.key,
    required this.timeSlot,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 時間表示
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Text(
                      '${timeSlot.period}限',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      timeSlot.startTime,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '空きコマ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '科目を追加',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
