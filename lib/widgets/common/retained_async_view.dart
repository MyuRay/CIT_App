import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Retains the last successful view while making a failed refresh visible.
class RetainedAsyncView<T> extends StatelessWidget {
  const RetainedAsyncView({
    super.key,
    required this.value,
    required this.data,
    required this.loading,
    required this.error,
    required this.onRetry,
  });
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final Widget Function() loading;
  final Widget Function(Object, StackTrace) error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => value.when(
    skipError: true,
    data:
        (previous) => Column(
          children: [
            if (value.isLoading) const LinearProgressIndicator(),
            if (value.hasError)
              MaterialBanner(
                content: const Text('更新できませんでした。前回取得した時間割を表示しています。'),
                actions: [
                  TextButton(onPressed: onRetry, child: const Text('再試行')),
                ],
              ),
            Expanded(child: data(previous)),
          ],
        ),
    loading: loading,
    error: error,
  );
}
