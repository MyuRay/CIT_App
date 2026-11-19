import 'package:flutter/material.dart';
import '../../models/schedule/academic_term.dart';

class AcademicTermSelector extends StatelessWidget {
  const AcademicTermSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.optional = false,
  });
  final AcademicTerm? value;
  final ValueChanged<AcademicTerm?> onChanged;
  final bool optional;
  @override
  Widget build(BuildContext context) {
    final selected = value ?? AcademicTerm(AcademicTerm.currentYear(), false);
    final years =
        {
            for (
              var y = AcademicTerm.currentYear() - 5;
              y <= AcademicTerm.currentYear() + 5;
              y++
            )
              y,
            selected.year,
          }.toList()
          ..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (optional)
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('年度・学期を設定（任意）'),
            value: value != null,
            onChanged: (enabled) => onChanged(enabled ? selected : null),
          ),
        if (!optional || value != null)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<int>(
                  key: ValueKey(selected.year),
                  initialValue: selected.year,
                  decoration: const InputDecoration(
                    labelText: '年度',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final year in years)
                      DropdownMenuItem(value: year, child: Text('${year}年度')),
                  ],
                  onChanged: (year) {
                    if (year != null)
                      onChanged(AcademicTerm(year, selected.isFall));
                  },
                ),
              ),
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<bool>(
                  key: ValueKey(selected.isFall),
                  initialValue: selected.isFall,
                  decoration: const InputDecoration(
                    labelText: '学期',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: false, child: Text('前期')),
                    DropdownMenuItem(value: true, child: Text('後期')),
                  ],
                  onChanged: (fall) {
                    if (fall != null)
                      onChanged(AcademicTerm(selected.year, fall));
                  },
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        const Text('設定すると出欠管理に対応した日付が表示されます。'),
      ],
    );
  }
}
