import 'package:cit_app/widgets/common/retained_async_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('failed refresh preserves previous data and offers retry', (
    tester,
  ) async {
    var retries = 0;
    final state = AsyncValue<List<String>>.error(
      StateError('offline'),
      StackTrace.current,
    ).copyWithPrevious(const AsyncValue.data(['数学']));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RetainedAsyncView<List<String>>(
            value: state,
            onRetry: () => retries++,
            data: (value) => Text(value.single),
            loading: () => const Text('loading'),
            error: (_, __) => const Text('initial error'),
          ),
        ),
      ),
    );
    expect(find.text('数学'), findsOneWidget);
    expect(find.textContaining('前回取得した時間割'), findsOneWidget);
    await tester.tap(find.text('再試行'));
    expect(retries, 1);
    expect(find.text('initial error'), findsNothing);
  });
  testWidgets('initial failure shows the error rather than empty data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RetainedAsyncView<List<String>>(
            value: AsyncValue.error(
              StateError('permission-denied'),
              StackTrace.current,
            ),
            onRetry: () {},
            data: (_) => const Text('未登録'),
            loading: () => const Text('loading'),
            error: (_, __) => const Text('読み込みに失敗しました'),
          ),
        ),
      ),
    );
    expect(find.text('読み込みに失敗しました'), findsOneWidget);
    expect(find.text('未登録'), findsNothing);
  });
}
