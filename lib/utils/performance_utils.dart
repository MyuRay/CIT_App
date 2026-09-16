import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// パフォーマンス最適化のためのユーティリティクラス
class PerformanceUtils {
  /// デバッグ用のビルド時間測定
  static T measureBuildTime<T>(String widgetName, T Function() buildFunction) {
    if (!kDebugMode) {
      return buildFunction();
    }

    final stopwatch = Stopwatch()..start();
    final result = buildFunction();
    stopwatch.stop();

    debugPrint('🏁 $widgetName ビルド時間: ${stopwatch.elapsedMilliseconds}ms');

    return result;
  }

  /// フレームスキップの監視
  static void monitorFrameSkips(String screenName) {
    if (!kDebugMode) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now().millisecondsSinceEpoch;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final elapsed = DateTime.now().millisecondsSinceEpoch - now;
        if (elapsed > 16) {
          // 60FPS = 16.67ms per frame
          debugPrint('⚠️ $screenName フレームスキップ検出: ${elapsed}ms');
        }
      });
    });
  }

  /// メモリ使用量の監視
  static void monitorMemoryUsage(String context) {
    if (!kDebugMode) return;

    // Note: メモリ監視はdart:ioのProcessInfoを使用
    // ここではログ出力のみ実装
    debugPrint('📊 $context メモリ使用量チェック');
  }

  /// ウィジェットの再構築を検知
  static Widget buildCounterWrapper(String widgetName, Widget child) {
    if (!kDebugMode) {
      return child;
    }

    return _BuildCounter(widgetName: widgetName, child: child);
  }
}

/// ビルド回数をカウントするウィジェット（デバッグ用）
class _BuildCounter extends StatefulWidget {
  final String widgetName;
  final Widget child;

  const _BuildCounter({required this.widgetName, required this.child});

  @override
  State<_BuildCounter> createState() => _BuildCounterState();
}

class _BuildCounterState extends State<_BuildCounter> {
  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    _buildCount++;

    if (_buildCount > 1) {
      debugPrint('🔄 ${widget.widgetName} 再構築 #$_buildCount');
    }

    return widget.child;
  }
}

/// 最適化されたコンストバリスト
class OptimizedConstraints {
  /// 一般的な制約のキャッシュ
  static const BoxConstraints tightConstraints = BoxConstraints.tightFor();
  static const BoxConstraints expandedConstraints = BoxConstraints.expand();
  static const BoxConstraints unboundedConstraints = BoxConstraints();

  /// アイコンサイズの制約
  static const BoxConstraints smallIcon = BoxConstraints.tightFor(
    width: 16,
    height: 16,
  );
  static const BoxConstraints mediumIcon = BoxConstraints.tightFor(
    width: 24,
    height: 24,
  );
  static const BoxConstraints largeIcon = BoxConstraints.tightFor(
    width: 32,
    height: 32,
  );

  /// ボタンサイズの制約
  static const BoxConstraints smallButton = BoxConstraints(
    minWidth: 64,
    minHeight: 32,
    maxHeight: 32,
  );
  static const BoxConstraints mediumButton = BoxConstraints(
    minWidth: 88,
    minHeight: 40,
    maxHeight: 40,
  );
  static const BoxConstraints largeButton = BoxConstraints(
    minWidth: 112,
    minHeight: 48,
    maxHeight: 48,
  );
}

/// 最適化されたパディング定数
class OptimizedPadding {
  static const EdgeInsets zero = EdgeInsets.zero;
  static const EdgeInsets all4 = EdgeInsets.all(4.0);
  static const EdgeInsets all8 = EdgeInsets.all(8.0);
  static const EdgeInsets all12 = EdgeInsets.all(12.0);
  static const EdgeInsets all16 = EdgeInsets.all(16.0);
  static const EdgeInsets all20 = EdgeInsets.all(20.0);
  static const EdgeInsets all24 = EdgeInsets.all(24.0);

  static const EdgeInsets horizontal8 = EdgeInsets.symmetric(horizontal: 8.0);
  static const EdgeInsets horizontal16 = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets horizontal24 = EdgeInsets.symmetric(horizontal: 24.0);

  static const EdgeInsets vertical8 = EdgeInsets.symmetric(vertical: 8.0);
  static const EdgeInsets vertical16 = EdgeInsets.symmetric(vertical: 16.0);
  static const EdgeInsets vertical24 = EdgeInsets.symmetric(vertical: 24.0);
}

/// 最適化されたボーダーラディアス定数
class OptimizedBorderRadius {
  static const BorderRadius zero = BorderRadius.zero;
  static const BorderRadius circular4 = BorderRadius.all(Radius.circular(4.0));
  static const BorderRadius circular8 = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius circular12 = BorderRadius.all(
    Radius.circular(12.0),
  );
  static const BorderRadius circular16 = BorderRadius.all(
    Radius.circular(16.0),
  );
  static const BorderRadius circular20 = BorderRadius.all(
    Radius.circular(20.0),
  );
  static const BorderRadius circular24 = BorderRadius.all(
    Radius.circular(24.0),
  );

  static const BorderRadius topCircular8 = BorderRadius.vertical(
    top: Radius.circular(8.0),
  );
  static const BorderRadius topCircular12 = BorderRadius.vertical(
    top: Radius.circular(12.0),
  );
  static const BorderRadius topCircular16 = BorderRadius.vertical(
    top: Radius.circular(16.0),
  );

  static const BorderRadius bottomCircular8 = BorderRadius.vertical(
    bottom: Radius.circular(8.0),
  );
  static const BorderRadius bottomCircular12 = BorderRadius.vertical(
    bottom: Radius.circular(12.0),
  );
  static const BorderRadius bottomCircular16 = BorderRadius.vertical(
    bottom: Radius.circular(16.0),
  );
}

/// パフォーマンス用のカスタムキー
class PerformanceKeys {
  static const ValueKey<String> homeScreen = ValueKey('home_screen');
  static const ValueKey<String> scheduleWidget = ValueKey('schedule_widget');
  static const ValueKey<String> notificationBadge = ValueKey(
    'notification_badge',
  );
  static const ValueKey<String> cafeteriaInfo = ValueKey('cafeteria_info');
  static const ValueKey<String> campusMap = ValueKey('campus_map');
  static const ValueKey<String> convenienceLinks = ValueKey(
    'convenience_links',
  );
}
