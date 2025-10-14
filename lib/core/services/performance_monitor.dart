import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';

/// アプリのパフォーマンスを監視するサービス
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, Stopwatch> _timers = {};
  final List<PerformanceMetric> _metrics = [];
  final int _maxMetrics = 100; // 最大100件のメトリクスを保持

  /// パフォーマンス測定を開始
  void startTimer(String name) {
    if (_timers.containsKey(name)) {
      _timers[name]?.reset();
    } else {
      _timers[name] = Stopwatch();
    }
    _timers[name]?.start();
    
    if (kDebugMode) {
      print('⏱️ Performance Timer Started: $name');
    }
  }

  /// 非同期処理のパフォーマンスを測定
  Future<T> trackAsync<T>(String name, Future<T> Function() operation) async {
    startTimer(name);
    try {
      final result = await operation();
      return result;
    } finally {
      stopTimer(name);
    }
  }

  /// 同期処理のパフォーマンスを測定
  T track<T>(String name, T Function() operation) {
    startTimer(name);
    try {
      return operation();
    } finally {
      stopTimer(name);
    }
  }

  /// パフォーマンス測定を終了して結果を記録
  int stopTimer(String name) {
    final timer = _timers[name];
    if (timer == null) {
      if (kDebugMode) {
        print('⚠️ Performance Timer not found: $name');
      }
      return 0;
    }

    timer.stop();
    final elapsedMs = timer.elapsedMilliseconds;
    
    // メトリクスに記録
    _addMetric(PerformanceMetric(
      name: name,
      duration: elapsedMs,
      timestamp: DateTime.now(),
    ));

    if (kDebugMode) {
      String emoji = _getPerformanceEmoji(elapsedMs);
      print('⏱️ Performance Timer $emoji $name: ${elapsedMs}ms');
    }

    return elapsedMs;
  }

  /// メトリクスを追加
  void _addMetric(PerformanceMetric metric) {
    _metrics.add(metric);
    
    // 最大件数を超えた場合は古いものを削除
    if (_metrics.length > _maxMetrics) {
      _metrics.removeAt(0);
    }
  }

  /// パフォーマンスに応じた絵文字を取得
  String _getPerformanceEmoji(int milliseconds) {
    if (milliseconds < 50) return '🚀'; // 非常に高速
    if (milliseconds < 100) return '✅'; // 高速
    if (milliseconds < 300) return '⚡'; // 普通
    if (milliseconds < 500) return '⚠️'; // やや遅い
    return '🐌'; // 遅い
  }

  /// メモリ使用量を取得
  Future<MemoryInfo?> getMemoryInfo() async {
    try {
      if (Platform.isAndroid) {
        // Android用のメモリ情報取得（プラットフォームチャンネル経由）
        const platform = MethodChannel('com.example.cit_app/performance');
        final result = await platform.invokeMethod('getMemoryInfo');
        return MemoryInfo.fromMap(result);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Memory info error: $e');
      }
      return null;
    }
  }

  /// 現在のメトリクス統計を取得
  PerformanceStats getStats() {
    if (_metrics.isEmpty) {
      return PerformanceStats(
        totalMeasurements: 0,
        averageDuration: 0,
        minDuration: 0,
        maxDuration: 0,
        slowOperations: [],
      );
    }

    final durations = _metrics.map((m) => m.duration).toList();
    durations.sort();

    final total = durations.fold<int>(0, (sum, duration) => sum + duration);
    final average = total / durations.length;

    // 500ms以上の遅い操作を抽出
    final slowOps = _metrics
        .where((m) => m.duration >= 500)
        .toList()
      ..sort((a, b) => b.duration.compareTo(a.duration));

    return PerformanceStats(
      totalMeasurements: _metrics.length,
      averageDuration: average.round(),
      minDuration: durations.first,
      maxDuration: durations.last,
      slowOperations: slowOps.take(10).toList(), // 上位10件
    );
  }

  /// パフォーマンスレポートを出力
  void printReport() {
    if (!kDebugMode) return;

    final stats = getStats();
    print('\n📊 === Performance Report ===');
    print('📈 Total measurements: ${stats.totalMeasurements}');
    print('⏱️ Average duration: ${stats.averageDuration}ms');
    print('🚀 Fastest operation: ${stats.minDuration}ms');
    print('🐌 Slowest operation: ${stats.maxDuration}ms');
    
    if (stats.slowOperations.isNotEmpty) {
      print('\n🚨 Slow operations (>500ms):');
      for (final op in stats.slowOperations) {
        print('   ${op.name}: ${op.duration}ms at ${op.timestamp}');
      }
    }
    print('=========================\n');
  }

  /// メトリクスをクリア
  void clearMetrics() {
    _metrics.clear();
    _timers.clear();
  }

  /// フレームレート監視を開始
  void startFrameRateMonitoring() {
    if (!kDebugMode) return;

    Timer.periodic(const Duration(seconds: 5), (timer) {
      // フレームレートの簡易監視
      // 実際の実装ではより詳細な監視が必要
      print('🎬 Frame rate monitoring active');
    });
  }
}

/// パフォーマンスメトリクス
class PerformanceMetric {
  final String name;
  final int duration; // milliseconds
  final DateTime timestamp;

  PerformanceMetric({
    required this.name,
    required this.duration,
    required this.timestamp,
  });
}

/// メモリ情報
class MemoryInfo {
  final int usedMemoryMB;
  final int availableMemoryMB;
  final int totalMemoryMB;

  MemoryInfo({
    required this.usedMemoryMB,
    required this.availableMemoryMB,
    required this.totalMemoryMB,
  });

  static MemoryInfo fromMap(Map<String, dynamic> map) {
    return MemoryInfo(
      usedMemoryMB: map['usedMemory'] ?? 0,
      availableMemoryMB: map['availableMemory'] ?? 0,
      totalMemoryMB: map['totalMemory'] ?? 0,
    );
  }

  double get usagePercentage => 
      totalMemoryMB > 0 ? (usedMemoryMB / totalMemoryMB) * 100 : 0;
}

/// パフォーマンス統計
class PerformanceStats {
  final int totalMeasurements;
  final int averageDuration;
  final int minDuration;
  final int maxDuration;
  final List<PerformanceMetric> slowOperations;

  PerformanceStats({
    required this.totalMeasurements,
    required this.averageDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.slowOperations,
  });
}

/// パフォーマンス監視用のミックスイン
mixin PerformanceTrackingMixin {
  final _monitor = PerformanceMonitor();

  /// 非同期処理のパフォーマンスを測定
  Future<T> trackAsync<T>(String name, Future<T> Function() operation) async {
    _monitor.startTimer(name);
    try {
      final result = await operation();
      return result;
    } finally {
      _monitor.stopTimer(name);
    }
  }

  /// 同期処理のパフォーマンスを測定
  T track<T>(String name, T Function() operation) {
    _monitor.startTimer(name);
    try {
      return operation();
    } finally {
      _monitor.stopTimer(name);
    }
  }
}