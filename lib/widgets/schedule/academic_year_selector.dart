import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/schedule/academic_year_model.dart';
import '../../core/providers/schedule_provider.dart';

class AcademicYearSelector extends ConsumerWidget {
  final VoidCallback? onChanged;
  
  const AcademicYearSelector({
    super.key,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedYear = ref.watch(selectedAcademicYearProvider);
    final academicYearsAsync = ref.watch(currentUserAcademicYearsProvider);
    
    return academicYearsAsync.when(
      data: (academicYears) {
        if (academicYears.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    '時間割データがありません',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '年度・学期',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<AcademicYear>(
                          value: selectedYear,
                          isExpanded: true,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          items: academicYears.map((year) {
                            return DropdownMenuItem<AcademicYear>(
                              value: year,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(year.displayName),
                                  ),
                                  if (year == AcademicYear.current())
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.green.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        '現在',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (newYear) {
                            if (newYear != null) {
                              ref.read(selectedAcademicYearProvider.notifier).state = newYear;
                              onChanged?.call();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                '年度情報を読み込み中...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '年度情報の読み込みに失敗',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.refresh(currentUserAcademicYearsProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AcademicYearSelectorDialog extends ConsumerWidget {
  const AcademicYearSelectorDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedYear = ref.watch(selectedAcademicYearProvider);
    final academicYearsAsync = ref.watch(currentUserAcademicYearsProvider);
    
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.blue),
          SizedBox(width: 8),
          Text('年度・学期選択'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: academicYearsAsync.when(
          data: (academicYears) {
            if (academicYears.isEmpty) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('時間割データがありません'),
                ],
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('時間割を表示する年度・学期を選択してください'),
                const SizedBox(height: 16),
                ...academicYears.map((year) {
                  final isSelected = year == selectedYear;
                  final isCurrent = year == AcademicYear.current();
                  
                  return Card(
                    elevation: isSelected ? 2 : 0,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: ListTile(
                      leading: Radio<AcademicYear>(
                        value: year,
                        groupValue: selectedYear,
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(selectedAcademicYearProvider.notifier).state = value;
                          }
                        },
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(year.displayName)),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '現在',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: _buildYearSubtitle(year),
                      onTap: () {
                        ref.read(selectedAcademicYearProvider.notifier).state = year;
                      },
                    ),
                  );
                }).toList(),
              ],
            );
          },
          loading: () => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('年度情報を読み込み中...'),
            ],
          ),
          error: (error, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラー: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(currentUserAcademicYearsProvider);
                },
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('選択'),
        ),
      ],
    );
  }

  Widget? _buildYearSubtitle(AcademicYear year) {
    String subtitle = '';
    switch (year.semester) {
      case AcademicSemester.firstSemester:
        subtitle = '4月〜9月';
        break;
      case AcademicSemester.secondSemester:
        subtitle = '10月〜3月';
        break;
      case AcademicSemester.fullYear:
        subtitle = '4月〜3月（通年）';
        break;
    }
    
    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
  }
}