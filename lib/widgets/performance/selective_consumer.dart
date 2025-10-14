import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// セレクティブConsumer - 特定の値の変更時のみ再構築
class SelectiveConsumer<T, R> extends ConsumerWidget {
  final ProviderListenable<T> provider;
  final R Function(T) selector;
  final Widget Function(BuildContext context, R value, Widget? child) builder;
  final Widget? child;
  
  const SelectiveConsumer({
    super.key,
    required this.provider,
    required this.selector,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedValue = ref.watch(provider.select(selector));
    return builder(context, selectedValue, child);
  }
}

/// 非同期プロバイダー用セレクティブConsumer
class SelectiveAsyncConsumer<T, R> extends ConsumerWidget {
  final ProviderListenable<AsyncValue<T>> provider;
  final R Function(AsyncValue<T>) selector;
  final Widget Function(BuildContext context, R value, Widget? child) builder;
  final Widget? child;
  
  const SelectiveAsyncConsumer({
    super.key,
    required this.provider,
    required this.selector,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedValue = ref.watch(provider.select(selector));
    return builder(context, selectedValue, child);
  }
}

/// 複数の値を監視する最適化Consumer
class MultiSelectiveConsumer extends ConsumerWidget {
  final Map<String, ProviderListenable> providers;
  final Widget Function(BuildContext context, Map<String, dynamic> values, Widget? child) builder;
  final Widget? child;
  
  const MultiSelectiveConsumer({
    super.key,
    required this.providers,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final values = <String, dynamic>{};
    
    for (final entry in providers.entries) {
      values[entry.key] = ref.watch(entry.value);
    }
    
    return builder(context, values, child);
  }
}

/// 条件付きリビルドConsumer
class ConditionalRebuildConsumer<T> extends ConsumerWidget {
  final ProviderListenable<T> provider;
  final bool Function(T? previous, T current) shouldRebuild;
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;
  
  const ConditionalRebuildConsumer({
    super.key,
    required this.provider,
    required this.shouldRebuild,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    return builder(context, value, child);
  }
}

/// デバウンス機能付きConsumer
class DebouncedConsumer<T> extends ConsumerStatefulWidget {
  final ProviderListenable<T> provider;
  final Duration debounceDuration;
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;
  
  const DebouncedConsumer({
    super.key,
    required this.provider,
    required this.debounceDuration,
    required this.builder,
    this.child,
  });

  @override
  ConsumerState<DebouncedConsumer<T>> createState() => _DebouncedConsumerState<T>();
}

class _DebouncedConsumerState<T> extends ConsumerState<DebouncedConsumer<T>> {
  T? _lastValue;
  bool _isDebouncing = false;

  @override
  Widget build(BuildContext context) {
    final currentValue = ref.watch(widget.provider);
    
    if (_lastValue != currentValue) {
      if (!_isDebouncing) {
        _isDebouncing = true;
        Future.delayed(widget.debounceDuration, () {
          if (mounted) {
            setState(() {
              _lastValue = currentValue;
              _isDebouncing = false;
            });
          }
        });
      }
    }
    
    final valueToUse = _lastValue ?? currentValue;
    return widget.builder(context, valueToUse, widget.child);
  }
}

/// 最適化されたリストConsumer
class OptimizedListConsumer<T> extends ConsumerWidget {
  final ProviderListenable<List<T>> provider;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? separator;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  
  const OptimizedListConsumer({
    super.key,
    required this.provider,
    required this.itemBuilder,
    this.separator,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(provider);
    
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return ListView.separated(
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return itemBuilder(context, item, index);
      },
      separatorBuilder: separator != null 
          ? (context, index) => separator!
          : (context, index) => const SizedBox.shrink(),
    );
  }
}

/// 最適化されたグリッドConsumer
class OptimizedGridConsumer<T> extends ConsumerWidget {
  final ProviderListenable<List<T>> provider;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  
  const OptimizedGridConsumer({
    super.key,
    required this.provider,
    required this.itemBuilder,
    required this.gridDelegate,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(provider);
    
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return GridView.builder(
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: gridDelegate,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return itemBuilder(context, item, index);
      },
    );
  }
}

/// パフォーマンス指標を提供するConsumer
class PerformanceMonitorConsumer<T> extends ConsumerWidget {
  final ProviderListenable<T> provider;
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final void Function(Duration buildTime)? onBuildTimeChanged;
  final Widget? child;
  
  const PerformanceMonitorConsumer({
    super.key,
    required this.provider,
    required this.builder,
    this.onBuildTimeChanged,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stopwatch = Stopwatch()..start();
    final value = ref.watch(provider);
    
    final widget = builder(context, value, child);
    
    stopwatch.stop();
    onBuildTimeChanged?.call(stopwatch.elapsed);
    
    return widget;
  }
}