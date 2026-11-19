import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/schedule/excel_schedule_import_service.dart';
import '../../services/schedule/excel_timetable_layout.dart';

String _weekdayLabel(String key) => ExcelTimetableLayout.dayLabels[key] ?? key;

Future<ExcelImportReviewResult?> showExcelImportReviewDialog(
  BuildContext context,
  ScheduleImportDraft draft, {
  String? sourceSemesterLabel,
  String? targetScheduleLabel,
  required Future<ImportedScheduleEntry?> Function(
    BuildContext,
    ImportedScheduleEntry,
  )
  onEditEntry,
}) {
  final entries = List<ImportedScheduleEntry>.from(draft.entries);
  bool clearExisting = false;
  bool autoColorAdjacent = true;
  bool provideTrainingData = true;
  final warnings = List<String>.from(draft.warnings);

  return showDialog<ExcelImportReviewResult>(
    context: context,
    barrierDismissible: false,
    builder:
        (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Excel取り込みの確認'),
              scrollable: true,
              content: SizedBox(
                width: 640,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sourceSemesterLabel != null)
                      Text('Excelの学期: $sourceSemesterLabel'),
                    if (targetScheduleLabel != null)
                      Text('取り込み先: $targetScheduleLabel'),
                    if (sourceSemesterLabel != null ||
                        targetScheduleLabel != null)
                      const SizedBox(height: 8),
                    Text('抽出件数: ${entries.length}件'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: clearExisting,
                          onChanged: (value) {
                            setDialogState(() {
                              clearExisting = value ?? false;
                            });
                          },
                        ),
                        const Expanded(child: Text('既存の時間割をクリアしてから適用する')),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: autoColorAdjacent,
                          onChanged: (value) {
                            setDialogState(() {
                              autoColorAdjacent = value ?? true;
                            });
                          },
                        ),
                        const Expanded(child: Text('上下左右で隣接する講義を自動色分けする')),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4, bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: provideTrainingData,
                            onChanged: (value) {
                              setDialogState(() {
                                provideTrainingData = value ?? false;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text(
                              '抽出精度の改善に協力する（任意）\n'
                              '時間割部分のExcel・抽出結果・修正内容・解析時の警告を、運営へ提供します。'
                              '氏名・学籍番号の欄と元のファイル名は除きますが、提供者のユーザーID（UID）と紐付けて保存します。\n'
                              'チェックを外しても時間割を取り込めます。',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (warnings.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Text(
                          warnings.join('\n'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ...List<Widget>.generate(entries.length, (index) {
                      final e = entries[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${_weekdayLabel(e.weekdayKey)} ${e.startPeriod}限 (${e.duration}コマ) ${e.subjectName}',
                        ),
                        subtitle: Text(
                          '講師: ${e.instructor.isEmpty ? '未設定' : e.instructor} / 教室: ${e.classroom.isEmpty ? '未設定' : e.classroom}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () async {
                                final edited = await onEditEntry(
                                  dialogContext,
                                  e,
                                );
                                if (edited == null || !dialogContext.mounted) {
                                  return;
                                }
                                setDialogState(() {
                                  entries[index] = edited;
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: AppColors.accent(context, Colors.red),
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  entries.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed:
                      entries.isEmpty
                          ? null
                          : () {
                            Navigator.of(dialogContext).pop(
                              ExcelImportReviewResult(
                                entries: entries,
                                clearExisting: clearExisting,
                                autoColorAdjacent: autoColorAdjacent,
                                provideTrainingData: provideTrainingData,
                              ),
                            );
                          },
                  child: Text(provideTrainingData ? '提供して取り込む' : '提供せず取り込む'),
                ),
              ],
            );
          },
        ),
  );
}

class ExcelImportReviewResult {
  const ExcelImportReviewResult({
    required this.entries,
    required this.clearExisting,
    required this.autoColorAdjacent,
    required this.provideTrainingData,
  });

  final List<ImportedScheduleEntry> entries;
  final bool clearExisting;
  final bool autoColorAdjacent;
  final bool provideTrainingData;
}
