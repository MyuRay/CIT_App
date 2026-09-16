import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ストアレビュー管理サービス
class AppReviewService {
  static const String _keyLaunchCount = 'app_review_launch_count';
  static const String _keyLastReviewRequestDate =
      'app_review_last_request_date';
  static const String _keyReviewCompleted = 'app_review_completed';

  // レビューを促す起動回数の閾値
  static const int _launchCountThreshold = 5;
  // レビューを再表示するまでの日数（90日）
  static const int _daysUntilNextRequest = 90;

  /// 起動回数をカウント
  static Future<void> incrementLaunchCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_keyLaunchCount) ?? 0;
      await prefs.setInt(_keyLaunchCount, currentCount + 1);

      if (kDebugMode) {
        debugPrint('📱 アプリ起動回数: ${currentCount + 1}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 起動回数カウントエラー: $e');
      }
    }
  }

  /// レビューを促すべきかチェック
  static Future<bool> shouldRequestReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // レビューを完了済みの場合は表示しない
      final reviewCompleted = prefs.getBool(_keyReviewCompleted) ?? false;
      if (reviewCompleted) {
        if (kDebugMode) {
          debugPrint('📝 レビューは既に完了済みです');
        }
        return false;
      }

      // 起動回数を確認
      final launchCount = prefs.getInt(_keyLaunchCount) ?? 0;
      if (launchCount < _launchCountThreshold) {
        if (kDebugMode) {
          debugPrint('📱 起動回数が不足しています: $launchCount / $_launchCountThreshold');
        }
        return false;
      }

      // 最後にレビューを促した日時を確認
      final lastRequestDateString = prefs.getString(_keyLastReviewRequestDate);
      if (lastRequestDateString != null) {
        final lastRequestDate = DateTime.parse(lastRequestDateString);
        final daysSinceLastRequest =
            DateTime.now().difference(lastRequestDate).inDays;

        if (daysSinceLastRequest < _daysUntilNextRequest) {
          if (kDebugMode) {
            debugPrint(
              '⏰ 前回のレビューリクエストから$daysSinceLastRequest日経過（$_daysUntilNextRequest日必要）',
            );
          }
          return false;
        }
      }

      if (kDebugMode) {
        debugPrint('✅ レビューを促す条件を満たしています');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ レビュー条件チェックエラー: $e');
      }
      return false;
    }
  }

  /// ストアレビューを表示
  static Future<void> requestReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // レビュー機能が利用可能か確認
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        // 最後にレビューを促した日時を記録
        await prefs.setString(
          _keyLastReviewRequestDate,
          DateTime.now().toIso8601String(),
        );

        if (kDebugMode) {
          debugPrint('⭐ ストアレビューを表示します');
        }

        // レビューを表示
        await inAppReview.requestReview();

        if (kDebugMode) {
          debugPrint('✅ ストアレビュー表示完了');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ ストアレビュー機能が利用できません');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ストアレビュー表示エラー: $e');
      }
    }
  }

  /// レビュー完了を記録（ユーザーがレビューを完了した場合）
  static Future<void> markReviewCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyReviewCompleted, true);

      if (kDebugMode) {
        debugPrint('✅ レビュー完了を記録しました');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ レビュー完了記録エラー: $e');
      }
    }
  }

  /// レビュー状態をリセット（デバッグ用）
  static Future<void> resetReviewState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLaunchCount);
      await prefs.remove(_keyLastReviewRequestDate);
      await prefs.remove(_keyReviewCompleted);

      if (kDebugMode) {
        debugPrint('🔄 レビュー状態をリセットしました');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ レビュー状態リセットエラー: $e');
      }
    }
  }
}
