import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/schedule_provider.dart';
import '../../models/schedule/schedule_model.dart';
import 'memoized_consumer.dart';

/// 最適化されたスケジュールウィジェット
/// 不要な再構築を避け、パフォーマンスを向上させる
class OptimizedScheduleWidget extends ConsumerWidget {
  final String userId;
  final bool compact;
  
  const OptimizedScheduleWidget({
    super.key,
    required this.userId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MemoizedAsyncConsumer<List<ScheduleClass?>>(
      provider: todayScheduleProvider(userId),
      builder: (context, asyncValue, child) {
        return asyncValue.when(
          data: (classes) => _ScheduleContent(
            classes: classes,
            userId: userId,
            compact: compact,
          ),
          loading: () => _LoadingWidget(compact: compact),
          error: (error, stack) => _ErrorWidget(
            error: error,
            compact: compact,
          ),
        );
      },
    );
  }
}

/// メモ化されたスケジュールコンテンツ
class _ScheduleContent extends StatelessWidget {
  final List<ScheduleClass?> classes;
  final String userId;
  final bool compact;
  
  const _ScheduleContent({
    required this.classes,
    required this.userId,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final validClasses = classes
        .asMap()
        .entries
        .where((entry) => entry.value != null)
        .toList();

    if (validClasses.isEmpty) {
      return _EmptyScheduleWidget(compact: compact);
    }

    if (compact) {
      return _CompactScheduleList(classes: validClasses);
    }

    return _DetailedScheduleList(classes: validClasses);
  }
}

/// コンパクトなスケジュール表示
class _CompactScheduleList extends StatelessWidget {
  final List<MapEntry<int, ScheduleClass?>> classes;
  
  const _CompactScheduleList({required this.classes});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: classes.take(3).map((entry) {
        final period = entry.key + 1;
        final classData = entry.value!;
        
        return _CompactClassCard(
          period: period,
          classData: classData,
        );
      }).toList(),
    );
  }
}

/// 詳細なスケジュール表示  
class _DetailedScheduleList extends StatelessWidget {
  final List<MapEntry<int, ScheduleClass?>> classes;
  
  const _DetailedScheduleList({required this.classes});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: classes.map((entry) {
        final period = entry.key + 1;
        final classData = entry.value!;
        
        return _DetailedClassCard(
          period: period,
          classData: classData,
        );
      }).toList(),
    );
  }
}

/// メモ化されたコンパクトクラスカード
class _CompactClassCard extends StatelessWidget {
  final int period;
  final ScheduleClass classData;
  
  const _CompactClassCard({
    required this.period,
    required this.classData,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('0xff${classData.color.substring(1)}'));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$period',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classData.subjectName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${classData.classroom} - ${classData.instructor}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// メモ化された詳細クラスカード  
class _DetailedClassCard extends StatelessWidget {
  final int period;
  final ScheduleClass classData;
  
  const _DetailedClassCard({
    required this.period,
    required this.classData,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('0xff${classData.color.substring(1)}'));
    final startTime = _getPeriodStartTime(period);
    final endTime = _getPeriodEndTime(period, classData.duration);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$period限',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$startTime - $endTime',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    classData.subjectName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        classData.classroom,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        classData.instructor,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 空のスケジュール表示
class _EmptyScheduleWidget extends StatelessWidget {
  final bool compact;
  
  const _EmptyScheduleWidget({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: compact ? 32 : 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: compact ? 8 : 16),
          Text(
            '授業がありません',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: compact ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// ローディングウィジェット
class _LoadingWidget extends StatelessWidget {
  final bool compact;
  
  const _LoadingWidget({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: compact ? 24 : 32,
            height: compact ? 24 : 32,
            child: const CircularProgressIndicator(),
          ),
          SizedBox(height: compact ? 8 : 16),
          Text(
            'スケジュールを読み込み中...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: compact ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// エラー表示ウィジェット
class _ErrorWidget extends StatelessWidget {
  final Object error;
  final bool compact;
  
  const _ErrorWidget({
    required this.error,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: compact ? 32 : 48,
            color: Colors.red[400],
          ),
          SizedBox(height: compact ? 8 : 16),
          Text(
            'スケジュールの読み込みに失敗しました',
            style: TextStyle(
              color: Colors.red[600],
              fontSize: compact ? 12 : 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ヘルパー関数
String _getPeriodStartTime(int period) {
  const times = ['9:00', '10:40', '13:00', '14:40', '16:20', '18:00'];
  return period <= times.length ? times[period - 1] : '?:??';
}

String _getPeriodEndTime(int period, int duration) {
  const endTimes = ['10:30', '12:10', '14:30', '16:10', '17:50', '19:30'];
  final endIndex = period - 1 + duration - 1;
  return endIndex < endTimes.length ? endTimes[endIndex] : '?:??';
}