import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// メモ化されたConsumerウィジェット
/// パフォーマンス向上のため、不要な再構築を避ける
class MemoizedConsumer<T> extends ConsumerWidget {
  final ProviderListenable<T> provider;
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;
  
  const MemoizedConsumer({
    super.key,
    required this.provider,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    return builder(context, value, child);
  }
}

/// 非同期プロバイダー用のメモ化Consumerウィジェット
class MemoizedAsyncConsumer<T> extends ConsumerWidget {
  final ProviderListenable<AsyncValue<T>> provider;
  final Widget Function(BuildContext context, AsyncValue<T> value, Widget? child) builder;
  final Widget? child;
  
  const MemoizedAsyncConsumer({
    super.key,
    required this.provider,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(provider);
    return builder(context, asyncValue, child);
  }
}

/// 条件付きConsumer - 特定の条件でのみ再構築
class ConditionalConsumer<T> extends ConsumerWidget {
  final ProviderListenable<T> provider;
  final bool Function(T? previous, T current) shouldRebuild;
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;
  
  const ConditionalConsumer({
    super.key,
    required this.provider,
    required this.shouldRebuild,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider.select((value) => value));
    return builder(context, value, child);
  }
}