import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/services/simple_offline_service.dart';

/// オフライン対応ウィジェット
class OfflineAwareWidget extends ConsumerWidget {
  final Widget child;
  final Widget? offlineWidget;
  final bool showOfflineIndicator;
  final VoidCallback? onRetry;

  const OfflineAwareWidget({
    super.key,
    required this.child,
    this.offlineWidget,
    this.showOfflineIndicator = true,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<bool>(
      stream: SimpleOfflineService().connectionStream,
      initialData: SimpleOfflineService().isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        return Stack(
          children: [
            // メインコンテンツ
            AnimatedOpacity(
              opacity: isOnline ? 1.0 : 0.7,
              duration: const Duration(milliseconds: 300),
              child: isOnline ? child : (offlineWidget ?? child),
            ),
            
            // オフラインインジケーター
            if (showOfflineIndicator && !isOnline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: OfflineIndicator(onRetry: onRetry),
              ),
          ],
        );
      },
    );
  }
}

/// オフラインインジケーター
class OfflineIndicator extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineIndicator({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Colors.orange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'オフラインモード',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    '再試行',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// オフライン対応のFutureBuilder
class OfflineAwareFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext, T) dataBuilder;
  final Widget Function(BuildContext, Object?)? errorBuilder;
  final Widget Function(BuildContext)? loadingBuilder;
  final Widget Function(BuildContext)? offlineBuilder;
  final T? cachedData;

  const OfflineAwareFutureBuilder({
    super.key,
    required this.future,
    required this.dataBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.offlineBuilder,
    this.cachedData,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = SimpleOfflineService().isOnline;

    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        // オンラインの場合は通常の処理
        if (isOnline) {
          if (snapshot.hasData) {
            return dataBuilder(context, snapshot.data as T);
          } else if (snapshot.hasError) {
            return errorBuilder?.call(context, snapshot.error) ??
                _defaultErrorBuilder(context, snapshot.error);
          } else {
            return loadingBuilder?.call(context) ??
                _defaultLoadingBuilder(context);
          }
        }

        // オフラインの場合
        if (cachedData != null) {
          return Stack(
            children: [
              dataBuilder(context, cachedData!),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'キャッシュ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // オフラインでキャッシュデータも無い場合
        return offlineBuilder?.call(context) ??
            _defaultOfflineBuilder(context);
      },
    );
  }

  Widget _defaultLoadingBuilder(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _defaultErrorBuilder(BuildContext context, Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('エラー: $error'),
        ],
      ),
    );
  }

  Widget _defaultOfflineBuilder(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'オフラインです',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'インターネット接続を確認してください',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// キューに溜まったオフラインアクションの表示ウィジェット
class PendingActionsIndicator extends ConsumerWidget {
  const PendingActionsIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineService = SimpleOfflineService();
    final pendingCount = offlineService.pendingActionCount;

    if (pendingCount == 0) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<bool>(
      stream: offlineService.connectionStream,
      initialData: offlineService.isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isOnline ? Colors.blue : Colors.orange,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isOnline ? Icons.cloud_upload : Icons.schedule,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isOnline 
                      ? '${pendingCount}件のアクションを同期中...'
                      : '${pendingCount}件のアクションが保留中',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isOnline)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// パフォーマンス監視付きウィジェット
class PerformanceAwareWidget extends StatefulWidget {
  final Widget child;
  final String? performanceLabel;
  final bool enableFrameRateMonitoring;

  const PerformanceAwareWidget({
    super.key,
    required this.child,
    this.performanceLabel,
    this.enableFrameRateMonitoring = false,
  });

  @override
  State<PerformanceAwareWidget> createState() => _PerformanceAwareWidgetState();
}

class _PerformanceAwareWidgetState extends State<PerformanceAwareWidget>
    with SingleTickerProviderStateMixin {
  final _monitor = PerformanceMonitor();
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.performanceLabel != null) {
      _monitor.startTimer('${widget.performanceLabel}_init');
    }
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    
    if (widget.performanceLabel != null) {
      _monitor.startTimer('${widget.performanceLabel}_build_$_buildCount');
    }

    final child = widget.child;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.performanceLabel != null) {
        _monitor.stopTimer('${widget.performanceLabel}_build_$_buildCount');
        
        if (_buildCount == 1) {
          _monitor.stopTimer('${widget.performanceLabel}_init');
        }
      }
    });

    return child;
  }

  @override
  void dispose() {
    if (widget.performanceLabel != null && _buildCount > 5) {
      print('⚠️ ${widget.performanceLabel} had $_buildCount rebuilds');
    }
    super.dispose();
  }
}