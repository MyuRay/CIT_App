import 'package:flutter/services.dart';

/// アプリ全体の軽い操作フィードバック（触覚のみ）
class UiFeedbackService {
  UiFeedbackService._();

  static DateTime? _lastFeedbackAt;

  static const _minInterval = Duration(milliseconds: 70);

  /// ボタン・タブ・リスト項目など一般的なタップ
  static Future<void> tap() async {
    _emit(HapticFeedback.selectionClick);
  }

  /// タブ・ボトムナビ切り替え（触覚を少し強め）
  static Future<void> tabSwitch() async {
    _emit(HapticFeedback.lightImpact);
  }

  static Future<void> _emit(Future<void> Function() haptic) async {
    final now = DateTime.now();
    if (_lastFeedbackAt != null &&
        now.difference(_lastFeedbackAt!) < _minInterval) {
      return;
    }
    _lastFeedbackAt = now;

    try {
      await haptic();
    } catch (_) {}
  }
}
