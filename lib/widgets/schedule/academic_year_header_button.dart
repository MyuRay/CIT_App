import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/schedule/academic_year_model.dart';
import '../../core/providers/schedule_provider.dart';

class AcademicYearHeaderButton extends ConsumerWidget {
  const AcademicYearHeaderButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedYear = ref.watch(selectedAcademicYearProvider);
    
    return IconButton(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, size: 20),
          const SizedBox(width: 4),
          Text(
            _getShortDisplayName(selectedYear),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      tooltip: '年度・学期選択: ${selectedYear.displayName}',
      onPressed: () => _showYearSelectionDialog(context, ref),
    );
  }

  String _getShortDisplayName(AcademicYear year) {
    switch (year.semester) {
      case AcademicSemester.firstSemester:
        return '${year.year}前';
      case AcademicSemester.secondSemester:
        return '${year.year}後';
      case AcademicSemester.fullYear:
        return '${year.year}通';
    }
  }

  void _showYearSelectionDialog(BuildContext context, WidgetRef ref) {
    final selectedYear = ref.read(selectedAcademicYearProvider);
    final allYears = ref.read(allAcademicYearsProvider);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 400,
          height: 600,
          child: Column(
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '年度・学期選択',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              // 年度リスト
              Expanded(
                child: ListView.builder(
                  itemCount: allYears.length,
                  itemBuilder: (context, index) {
                    final year = allYears[index];
                    final isSelected = year == selectedYear;
                    final isCurrent = year == AcademicYear.current();
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      elevation: isSelected ? 3 : 1,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: ListTile(
                        dense: true,
                        leading: Radio<AcademicYear>(
                          value: year,
                          groupValue: selectedYear,
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(selectedAcademicYearProvider.notifier).state = value;
                              Navigator.of(context).pop();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${value.displayName}に切り替えました'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                year.displayName,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isCurrent) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
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
                                    fontSize: 10,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          ref.read(selectedAcademicYearProvider.notifier).state = year;
                          Navigator.of(context).pop();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${year.displayName}に切り替えました'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              
              // フッター
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '2023年度〜2050年度の時間割を管理できます',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
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