import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import '../../models/schedule/academic_term.dart';
import '../../models/schedule/lecture_period_model.dart';
import '../../services/schedule/lecture_period_service.dart';
import '../../widgets/schedule/academic_term_selector.dart';

class LecturePeriodSettingsScreen extends ConsumerStatefulWidget {
  const LecturePeriodSettingsScreen({super.key});
  @override
  ConsumerState<LecturePeriodSettingsScreen> createState() =>
      _LecturePeriodSettingsScreenState();
}

class _LecturePeriodSettingsScreenState
    extends ConsumerState<LecturePeriodSettingsScreen> {
  late final _periods = LecturePeriodService.watchLecturePeriod();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('講義期間設定')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _edit(),
      icon: const Icon(Icons.add),
      label: const Text('期間を追加'),
    ),
    body: StreamBuilder<LecturePeriodSettings?>(
      stream: _periods,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text('講義期間を読み込めませんでした: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final settings = snapshot.data;
        final entries = <String, LecturePeriod>{...?settings?.periods};
        for (final fall in [false, true]) {
          final start =
              fall ? settings?.fallStartDate : settings?.springStartDate;
          if (start == null) continue;
          final term = AcademicTerm(start.year, fall);
          entries.putIfAbsent(
            term.key,
            () => settings!.periodForSemester(term.label)!,
          );
        }
        final periods =
            entries.values.toList()
              ..sort((a, b) => b.term.key.compareTo(a.term.key));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            const Text(
              '年度・前期／後期ごとに講義の開始日・終了日を設定します。有効な期間が出欠管理の日付とホームの週表示に反映されます。',
            ),
            const SizedBox(height: 16),
            if (periods.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('講義期間がありません。「期間を追加」から設定してください。'),
              ),
            for (final period in periods)
              Card(
                child: ListTile(
                  isThreeLine: true,
                  title: Text(period.term.label),
                  subtitle: Text(
                    '${_date(period.startDate)} 〜 ${_date(period.endDate)}\n${period.isActive ? '有効' : '無効'}',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _edit(period),
                ),
              ),
          ],
        );
      },
    ),
  );
  String _date(DateTime? date) =>
      date == null ? '未設定' : '${date.year}/${date.month}/${date.day}';
  Future<void> _edit([LecturePeriod? original]) async {
    var term =
        original?.term ?? AcademicTerm(AcademicTerm.currentYear(), false);
    var start = original?.startDate;
    var end = original?.endDate;
    var active = original?.isActive ?? true;
    var saving = false;
    String? error;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, update) {
              Future<void> pick(bool first) async {
                final minimum = DateTime(term.year, 4, 1),
                    maximum = DateTime(term.year + 1, 3, 31);
                final initial =
                    (first ? start : end) ??
                    (term.isFall ? DateTime(term.year, 9, 1) : minimum);
                final selected = await showDatePicker(
                  context: ctx,
                  initialDate:
                      initial.isBefore(minimum) || initial.isAfter(maximum)
                          ? minimum
                          : initial,
                  firstDate: minimum,
                  lastDate: maximum,
                );
                if (selected != null)
                  update(() {
                    if (first) {
                      start = selected;
                    } else {
                      end = selected;
                    }
                    error = null;
                  });
              }

              return PopScope(
                canPop: !saving,
                child: AlertDialog(
                  title: Text(
                    original == null ? '講義期間を追加' : '${term.label}の期間',
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (original == null)
                          AcademicTermSelector(
                            value: term,
                            onChanged:
                                saving
                                    ? (_) {}
                                    : (value) => update(() {
                                      term = value!;
                                      start = null;
                                      end = null;
                                    }),
                          ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: saving ? null : () => pick(true),
                          icon: const Icon(Icons.calendar_today),
                          label: Text('開始日: ${_date(start)}'),
                        ),
                        OutlinedButton.icon(
                          onPressed: saving ? null : () => pick(false),
                          icon: const Icon(Icons.event),
                          label: Text('終了日: ${_date(end)}'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('この講義期間を有効にする'),
                          value: active,
                          onChanged:
                              saving
                                  ? null
                                  : (value) => update(() => active = value),
                        ),
                        if (error != null)
                          Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(ctx).colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: saving ? null : () => Navigator.pop(ctx),
                      child: const Text('キャンセル'),
                    ),
                    FilledButton(
                      onPressed:
                          saving
                              ? null
                              : () async {
                                final period = LecturePeriod(
                                  year: term.year,
                                  isFall: term.isFall,
                                  startDate: start,
                                  endDate: end,
                                  isActive: active,
                                );
                                if (!period.isValid) {
                                  update(
                                    () =>
                                        error =
                                            '開始日と終了日を年度内（4月〜翌3月）で正しく設定してください',
                                  );
                                  return;
                                }
                                update(() {
                                  saving = true;
                                  error = null;
                                });
                                try {
                                  await LecturePeriodService.savePeriod(
                                    period,
                                    createOnly: original == null,
                                    updatedBy:
                                        ref
                                            .read(authStateProvider)
                                            .asData
                                            ?.value
                                            ?.uid,
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (failure) {
                                  if (ctx.mounted)
                                    update(() {
                                      saving = false;
                                      error =
                                          failure is StateError
                                              ? failure.message.toString()
                                              : '保存できませんでした。もう一度お試しください。';
                                    });
                                }
                              },
                      child: Text(saving ? '保存中…' : '保存'),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
