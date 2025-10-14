import 'dart:async';
import 'package:flutter/foundation.dart';
import 'menu_image_service.dart';

class MenuSchedulerService {
  static Timer? _weeklyTimer;
  static Timer? _dailyCheckTimer;
  
  /// 定期的なメニュー更新を開始
  static void startScheduledUpdates() {
    // 既存のタイマーをキャンセル
    stopScheduledUpdates();
    
    // 毎日午前6時にチェック（週初めかどうか確認）
    _dailyCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkAndUpdateIfNeeded();
    });
    
    // アプリ起動時にも初回チェック
    _checkAndUpdateIfNeeded();
    
    debugPrint('Menu scheduler started');
  }
  
  /// スケジュール更新を停止
  static void stopScheduledUpdates() {
    _weeklyTimer?.cancel();
    _dailyCheckTimer?.cancel();
    _weeklyTimer = null;
    _dailyCheckTimer = null;
    
    debugPrint('Menu scheduler stopped');
  }
  
  /// 週初め（月曜日の午前6時）かチェックして必要に応じて更新
  static void _checkAndUpdateIfNeeded() {
    final now = DateTime.now();
    
    // 月曜日の午前6-7時の間
    if (now.weekday == 1 && now.hour >= 6 && now.hour < 7) {
      _updateWeeklyMenus();
    }
    
    // または、キャッシュが古い場合も更新
    _updateIfCacheOld();
  }
  
  /// 週間メニューを更新
  static Future<void> _updateWeeklyMenus() async {
    try {
      debugPrint('Starting weekly menu update...');
      await MenuImageService.updateWeeklyMenuImages();
      await MenuImageService.cleanOldCache();
      debugPrint('Weekly menu update completed');
    } catch (e) {
      debugPrint('Weekly menu update failed: $e');
    }
  }
  
  /// キャッシュが古い場合に更新
  static Future<void> _updateIfCacheOld() async {
    try {
      // 今日のメニュー画像をチェック
      final tsudanumaPath = await MenuImageService.getTodayMenuImage('td');
      final narashinoPath = await MenuImageService.getTodayMenuImage('ns');
      
      // どちらか一方でもない場合は今週分を更新
      if (tsudanumaPath == null || narashinoPath == null) {
        debugPrint('Cache is missing, updating weekly menus...');
        await MenuImageService.updateWeeklyMenuImages();
      }
    } catch (e) {
      debugPrint('Cache check failed: $e');
    }
  }
  
  /// 手動で週間メニューを更新
  static Future<void> manualUpdate() async {
    debugPrint('Manual menu update requested');
    await _updateWeeklyMenus();
  }
  
  /// 次回の更新予定時刻を取得
  static DateTime getNextUpdateTime() {
    final now = DateTime.now();
    var nextMonday = now.add(Duration(days: (8 - now.weekday) % 7));
    
    // 現在が月曜日の午前6時前の場合は今日
    if (now.weekday == 1 && now.hour < 6) {
      nextMonday = DateTime(now.year, now.month, now.day, 6, 0);
    } else {
      // 次の月曜日の午前6時
      nextMonday = DateTime(nextMonday.year, nextMonday.month, nextMonday.day, 6, 0);
    }
    
    return nextMonday;
  }
  
  /// 最後の更新時刻を取得（仮想的な実装）
  static DateTime? getLastUpdateTime() {
    // 実際の実装では SharedPreferences などに保存した時刻を返す
    // ここでは今週の月曜日を返す
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day, 6, 0);
  }
}