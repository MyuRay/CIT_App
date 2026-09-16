import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/theme/app_colors.dart';

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      suffixIcon:
          controller.text.isEmpty
              ? null
              : IconButton(
                tooltip: '検索をクリア',
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
    ),
  );
}

class AdminStatusPill extends StatelessWidget {
  const AdminStatusPill(this.text, {super.key, this.color = Colors.blue});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.tintedSurface(context, color),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: AppColors.accent(context, color),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// The controls and results share one scroll area, including enlarged text.
class AdminCollectionScaffold<T> extends StatelessWidget {
  const AdminCollectionScaffold({
    super.key,
    required this.title,
    required this.toolbar,
    required this.items,
    required this.itemBuilder,
    required this.onRefresh,
    this.showAppBar = true,
    this.emptyText = '条件に一致する項目がありません',
  });
  final String title, emptyText;
  final bool showAppBar;
  final Widget toolbar;
  final AsyncValue<List<T>> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar:
        showAppBar
            ? AppBar(
              title: Text(title),
              actions: [
                IconButton(
                  tooltip: '再読み込み',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            )
            : null,
    body: SafeArea(
      top: !showAppBar,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(padding: const EdgeInsets.all(16), child: toolbar),
            ),
            items.when(
              data:
                  (values) =>
                      values.isEmpty
                          ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                emptyText,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                          : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            sliver: SliverList.builder(
                              itemCount: values.length,
                              itemBuilder:
                                  (context, index) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: itemBuilder(context, values[index]),
                                  ),
                            ),
                          ),
              loading:
                  () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              error:
                  (_, __) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text('読み込めませんでした。通信状態を確認して再試行してください。'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: onRefresh,
                            child: const Text('再読み込み'),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    ),
  );
}
