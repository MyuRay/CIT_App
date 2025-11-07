import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firebase/firebase_menu_service.dart';
import '../services/cache_service.dart';
import '../services/performance_monitor.dart';

// Firebase Storage から今日のメニュー画像URLを取得（キャッシュ・パフォーマンス監視付き）
final firebaseTodayMenuProvider = FutureProvider.family<String?, String>((
  ref,
  campus,
) async {
  final monitor = PerformanceMonitor();
  final cache = CacheService();

  return await monitor.trackAsync('firebase_today_menu_$campus', () async {
    // 強制リフレッシュの場合はキャッシュをスキップ
    final forceRefresh =
        ref.exists(forceRefreshProvider) && ref.read(forceRefreshProvider);

    if (!forceRefresh) {
      // キャッシュから確認（15分TTL）
      final cacheKey = 'firebase_today_menu_$campus';
      final cachedUrl = await cache.getPersistentCache<String>(cacheKey);

      if (cachedUrl != null) {
        final isValid = await FirebaseMenuService.isValidDownloadUrl(cachedUrl);
        if (isValid) {
          return cachedUrl;
        }
        await cache.removePersistentCache(cacheKey);
      }
    }

    // キャッシュが無い場合またはforceRefreshの場合はFirebaseから取得
    final url = await FirebaseMenuService.getTodayMenuImageUrl(campus);

    // URLが取得できた場合はキャッシュに保存
    if (url != null) {
      final cacheKey = 'firebase_today_menu_$campus';
      await cache.setPersistentCache(
        cacheKey,
        url,
        ttl: const Duration(minutes: 15),
      );
    }

    return url;
  });
});

// Firebase Storage から今週のメニュー画像URLsを取得（キャッシュ・パフォーマンス監視付き）
final firebaseWeeklyMenuProvider =
    FutureProvider.family<Map<String, String?>, String>((ref, campus) async {
      final monitor = PerformanceMonitor();
      final cache = CacheService();

      return await monitor.trackAsync('firebase_weekly_menu_$campus', () async {
        // 強制リフレッシュの場合はキャッシュをスキップ
        final forceRefresh =
            ref.exists(forceRefreshProvider) && ref.read(forceRefreshProvider);

        if (!forceRefresh) {
          // キャッシュから確認（1時間TTL）
          final cacheKey = 'firebase_weekly_menu_$campus';
          final cachedUrls = await cache
              .getPersistentCache<Map<String, String?>>(cacheKey);

          if (cachedUrls != null) {
            return cachedUrls;
          }
        }

        // キャッシュが無い場合またはforceRefreshの場合はFirebaseから取得
        final urls = await FirebaseMenuService.getWeeklyMenuImageUrls(campus);

        // URLsが取得できた場合はキャッシュに保存
        if (urls.isNotEmpty) {
          final cacheKey = 'firebase_weekly_menu_$campus';
          await cache.setPersistentCache(
            cacheKey,
            urls,
            ttl: const Duration(hours: 1),
          );
        }

        return urls;
      });
    });

// Firebase Storage 上の全メニュー画像を取得（デバッグ用）
final firebaseMenuListProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return await FirebaseMenuService.listAllMenuImages();
});

// Firebase Storage 接続テストプロバイダー
final firebaseStorageConnectionProvider = FutureProvider<bool>((ref) async {
  return await FirebaseMenuService.testConnection();
});

// 津田沼キャンパスの今日のメニュー（Firebase版）
final firebaseTsudanumaTodayMenuProvider = Provider((ref) {
  return ref.watch(firebaseTodayMenuProvider('td'));
});

// 新習志野キャンパスの今日のメニュー（Firebase版）
final firebaseNarashinoTodayMenuProvider = Provider((ref) {
  return ref.watch(firebaseTodayMenuProvider('sd1'));
});

// 津田沼キャンパスの週間メニュー（Firebase版）
final firebaseTsudanumaWeeklyMenuProvider = Provider((ref) {
  return ref.watch(firebaseWeeklyMenuProvider('td'));
});

// 新習志野キャンパスの週間メニュー（Firebase版）
final firebaseNarashinoWeeklyMenuProvider = Provider((ref) {
  return ref.watch(firebaseWeeklyMenuProvider('sd1'));
});

// メニュー画像更新管理用StateNotifier
class MenuUpdateNotifier extends StateNotifier<AsyncValue<void>> {
  MenuUpdateNotifier() : super(const AsyncValue.data(null));

  /// 週間メニュー画像を手動更新
  Future<void> updateWeeklyImages() async {
    state = const AsyncValue.loading();

    try {
      await FirebaseMenuService.updateWeeklyMenuImages();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 古い画像を削除
  Future<void> cleanOldImages() async {
    state = const AsyncValue.loading();

    try {
      await FirebaseMenuService.cleanOldImages();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final menuUpdateNotifierProvider =
    StateNotifierProvider<MenuUpdateNotifier, AsyncValue<void>>((ref) {
      return MenuUpdateNotifier();
    });

// 強制リフレッシュフラグのプロバイダー
final forceRefreshProvider = StateProvider<bool>((ref) => false);

// Firebase Storage統計情報プロバイダー
final firebaseStorageStatsProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  try {
    final images = await FirebaseMenuService.listAllMenuImages();

    final stats = <String, int>{};
    stats['total_images'] = images.length;
    stats['td_images'] =
        images.where((img) => img['name'].toString().startsWith('td_')).length;
    stats['sd1_images'] =
        images.where((img) => img['name'].toString().startsWith('sd1_')).length;

    // サイズの合計計算
    int totalSize = 0;
    for (final img in images) {
      totalSize += (img['size'] as int?) ?? 0;
    }
    stats['total_size_mb'] = (totalSize / (1024 * 1024)).round();

    return stats;
  } catch (e) {
    return {'error': 1};
  }
});

// Firebase Storage からバス時刻表画像URLを取得（キャッシュ・パフォーマンス監視付き）
final firebaseBusTimetableProvider = FutureProvider<String?>((ref) async {
  final monitor = PerformanceMonitor();
  final cache = CacheService();

  return await monitor.trackAsync('firebase_bus_timetable', () async {
    // 強制リフレッシュの場合はキャッシュをスキップ
    final forceRefresh =
        ref.exists(forceRefreshProvider) && ref.read(forceRefreshProvider);

    if (!forceRefresh) {
      // キャッシュから確認（1日TTL - 時刻表は頻繁に変わらないため長め）
      const cacheKey = 'firebase_bus_timetable';
      final cachedUrl = await cache.getPersistentCache<String>(cacheKey);

      if (cachedUrl != null) {
        return cachedUrl;
      }
    }

    // キャッシュが無い場合またはforceRefreshの場合はFirebaseから取得
    final url = await FirebaseMenuService.getBusTimetableImageUrl();

    // URLが取得できた場合はキャッシュに保存
    if (url != null) {
      const cacheKey = 'firebase_bus_timetable';
      await cache.setPersistentCache(
        cacheKey,
        url,
        ttl: const Duration(days: 1),
      );
    }

    return url;
  });
});
