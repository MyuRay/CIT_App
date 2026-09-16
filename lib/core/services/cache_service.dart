import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

/// 高機能キャッシュサービス
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Duration> _cacheTTL = {};

  /// キャッシュサービスを初期化
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _cleanExpiredCache();

      if (kDebugMode) {
        debugPrint('💾 Cache Service initialized');
        await _printCacheStats();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cache Service initialization failed: $e');
      }
    }
  }

  /// メモリキャッシュに保存
  void setMemoryCache<T>(String key, T data, {Duration? ttl}) {
    _memoryCache[key] = data;
    _cacheTimestamps[key] = DateTime.now();

    if (ttl != null) {
      _cacheTTL[key] = ttl;
    }

    if (kDebugMode) {
      debugPrint(
        '💾 Memory cache set: $key (TTL: ${ttl?.inMinutes ?? "∞"}min)',
      );
    }
  }

  /// メモリキャッシュから取得
  T? getMemoryCache<T>(String key) {
    if (!_memoryCache.containsKey(key)) return null;

    // TTLチェック
    if (_cacheTTL.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      final ttl = _cacheTTL[key];

      if (timestamp != null && ttl != null) {
        final isExpired = DateTime.now().difference(timestamp) > ttl;
        if (isExpired) {
          _removeMemoryCache(key);
          if (kDebugMode) {
            debugPrint('⏰ Memory cache expired: $key');
          }
          return null;
        }
      }
    }

    if (kDebugMode) {
      debugPrint('💾 Memory cache hit: $key');
    }

    return _memoryCache[key] as T?;
  }

  /// メモリキャッシュから削除
  void _removeMemoryCache(String key) {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    _cacheTTL.remove(key);
  }

  /// 永続キャッシュに保存
  Future<void> setPersistentCache<T>(
    String key,
    T data, {
    Duration? ttl,
  }) async {
    if (_prefs == null) return;

    try {
      final cacheData = CacheData<T>(
        data: data,
        timestamp: DateTime.now(),
        ttl: ttl,
      );

      final jsonString = jsonEncode(cacheData.toJson());
      await _prefs!.setString(_getCacheKey(key), jsonString);

      if (kDebugMode) {
        debugPrint(
          '💽 Persistent cache set: $key (TTL: ${ttl?.inMinutes ?? "∞"}min)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Persistent cache set error: $e');
      }
    }
  }

  /// 永続キャッシュから取得
  Future<T?> getPersistentCache<T>(String key) async {
    if (_prefs == null) return null;

    try {
      final jsonString = _prefs!.getString(_getCacheKey(key));
      if (jsonString == null) return null;

      final cacheData = CacheData<T>.fromJson(jsonDecode(jsonString));

      // TTLチェック
      if (cacheData.ttl != null) {
        final isExpired =
            DateTime.now().difference(cacheData.timestamp) > cacheData.ttl!;
        if (isExpired) {
          await removePersistentCache(key);
          if (kDebugMode) {
            debugPrint('⏰ Persistent cache expired: $key');
          }
          return null;
        }
      }

      if (kDebugMode) {
        debugPrint('💽 Persistent cache hit: $key');
      }

      return cacheData.data;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Persistent cache get error: $e');
      }
      return null;
    }
  }

  /// 永続キャッシュから削除
  Future<void> removePersistentCache(String key) async {
    if (_prefs == null) return;
    await _prefs!.remove(_getCacheKey(key));
  }

  /// ファイルキャッシュに保存（画像など大きなデータ用）
  Future<void> setFileCache(String key, List<int> data, {Duration? ttl}) async {
    if (kIsWeb) return;
    try {
      final directory = await getTemporaryDirectory();
      final cacheDir = Directory('${directory.path}/cache');

      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final file = File('${cacheDir.path}/${_hashKey(key)}.cache');
      await file.writeAsBytes(data);

      // TTL情報を別ファイルに保存
      if (ttl != null) {
        final metaFile = File('${cacheDir.path}/${_hashKey(key)}.meta');
        final metaData = {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'ttl': ttl.inMilliseconds,
        };
        await metaFile.writeAsString(jsonEncode(metaData));
      }

      if (kDebugMode) {
        final sizeKB = data.length / 1024;
        debugPrint(
          '📁 File cache set: $key (${sizeKB.toStringAsFixed(1)}KB, TTL: ${ttl?.inMinutes ?? "∞"}min)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ File cache set error: $e');
      }
    }
  }

  /// ファイルキャッシュから取得
  Future<List<int>?> getFileCache(String key) async {
    if (kIsWeb) return null;
    try {
      final directory = await getTemporaryDirectory();
      final cacheDir = Directory('${directory.path}/cache');
      final file = File('${cacheDir.path}/${_hashKey(key)}.cache');

      if (!await file.exists()) return null;

      // TTLチェック
      final metaFile = File('${cacheDir.path}/${_hashKey(key)}.meta');
      if (await metaFile.exists()) {
        final metaContent = await metaFile.readAsString();
        final metaData = jsonDecode(metaContent);

        final timestamp = DateTime.fromMillisecondsSinceEpoch(
          metaData['timestamp'],
        );
        final ttl = Duration(milliseconds: metaData['ttl']);

        if (DateTime.now().difference(timestamp) > ttl) {
          await removeFileCache(key);
          if (kDebugMode) {
            debugPrint('⏰ File cache expired: $key');
          }
          return null;
        }
      }

      final data = await file.readAsBytes();

      if (kDebugMode) {
        final sizeKB = data.length / 1024;
        debugPrint('📁 File cache hit: $key (${sizeKB.toStringAsFixed(1)}KB)');
      }

      return data;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ File cache get error: $e');
      }
      return null;
    }
  }

  /// ファイルキャッシュから削除
  Future<void> removeFileCache(String key) async {
    if (kIsWeb) return;
    try {
      final directory = await getTemporaryDirectory();
      final cacheDir = Directory('${directory.path}/cache');

      final file = File('${cacheDir.path}/${_hashKey(key)}.cache');
      final metaFile = File('${cacheDir.path}/${_hashKey(key)}.meta');

      if (await file.exists()) await file.delete();
      if (await metaFile.exists()) await metaFile.delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ File cache remove error: $e');
      }
    }
  }

  /// 期限切れキャッシュをクリーンアップ
  Future<void> _cleanExpiredCache() async {
    if (_prefs == null) return;

    try {
      final keys =
          _prefs!.getKeys().where((key) => key.startsWith('cache_')).toList();

      int removedCount = 0;

      for (final key in keys) {
        final jsonString = _prefs!.getString(key);
        if (jsonString != null) {
          try {
            final data = jsonDecode(jsonString);
            if (data['ttl'] != null) {
              final timestamp = DateTime.fromMillisecondsSinceEpoch(
                data['timestamp'],
              );
              final ttl = Duration(milliseconds: data['ttl']);

              if (DateTime.now().difference(timestamp) > ttl) {
                await _prefs!.remove(key);
                removedCount++;
              }
            }
          } catch (e) {
            // 無効なキャッシュデータは削除
            await _prefs!.remove(key);
            removedCount++;
          }
        }
      }

      // ファイルキャッシュもクリーンアップ
      await _cleanExpiredFileCache();

      if (kDebugMode && removedCount > 0) {
        debugPrint('🧹 Cleaned $removedCount expired cache entries');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cache cleanup error: $e');
      }
    }
  }

  /// 期限切れファイルキャッシュをクリーンアップ
  Future<void> _cleanExpiredFileCache() async {
    if (kIsWeb) return;
    try {
      final directory = await getTemporaryDirectory();
      final cacheDir = Directory('${directory.path}/cache');

      if (!await cacheDir.exists()) return;

      final files = await cacheDir.list().toList();
      int removedCount = 0;

      for (final file in files) {
        if (file is File && file.path.endsWith('.meta')) {
          try {
            final metaContent = await file.readAsString();
            final metaData = jsonDecode(metaContent);

            final timestamp = DateTime.fromMillisecondsSinceEpoch(
              metaData['timestamp'],
            );
            final ttl = Duration(milliseconds: metaData['ttl']);

            if (DateTime.now().difference(timestamp) > ttl) {
              // メタファイルと対応するキャッシュファイルを削除
              final cacheFile = File(file.path.replaceAll('.meta', '.cache'));

              await file.delete();
              if (await cacheFile.exists()) {
                await cacheFile.delete();
              }
              removedCount++;
            }
          } catch (e) {
            // 無効なメタファイルは削除
            await file.delete();
            removedCount++;
          }
        }
      }

      if (kDebugMode && removedCount > 0) {
        debugPrint('🧹 Cleaned $removedCount expired file cache entries');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ File cache cleanup error: $e');
      }
    }
  }

  /// キャッシュ統計を出力
  Future<void> _printCacheStats() async {
    try {
      final memoryCount = _memoryCache.length;

      final persistentKeys =
          _prefs?.getKeys().where((key) => key.startsWith('cache_')).length ??
          0;

      int fileCount = 0;
      int totalSizeKB = 0;

      if (!kIsWeb) {
        final directory = await getTemporaryDirectory();
        final cacheDir = Directory('${directory.path}/cache');
        if (await cacheDir.exists()) {
          final files = await cacheDir.list().toList();
          fileCount = files.where((f) => f.path.endsWith('.cache')).length;

          for (final file in files) {
            if (file is File && file.path.endsWith('.cache')) {
              final stat = await file.stat();
              totalSizeKB += (stat.size / 1024).round();
            }
          }
        }
      }

      debugPrint('📊 Cache Stats:');
      debugPrint('   Memory: $memoryCount items');
      debugPrint('   Persistent: $persistentKeys items');
      debugPrint('   File: $fileCount items (${totalSizeKB}KB)');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cache stats error: $e');
      }
    }
  }

  /// 全キャッシュをクリア
  Future<void> clearAllCache() async {
    // メモリキャッシュをクリア
    _memoryCache.clear();
    _cacheTimestamps.clear();
    _cacheTTL.clear();

    // 永続キャッシュをクリア
    if (_prefs != null) {
      final keys =
          _prefs!.getKeys().where((key) => key.startsWith('cache_')).toList();

      for (final key in keys) {
        await _prefs!.remove(key);
      }
    }

    // ファイルキャッシュをクリア（Webにはファイルシステムがない）
    if (!kIsWeb) {
      try {
        final directory = await getTemporaryDirectory();
        final cacheDir = Directory('${directory.path}/cache');

        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ File cache clear error: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('🧹 All cache cleared');
    }
  }

  /// キャッシュキーにプレフィックスを追加
  String _getCacheKey(String key) => 'cache_$key';

  /// キーをハッシュ化（ファイル名として安全にする）
  String _hashKey(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

/// キャッシュデータのラッパークラス
class CacheData<T> {
  final T data;
  final DateTime timestamp;
  final Duration? ttl;

  CacheData({required this.data, required this.timestamp, this.ttl});

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'ttl': ttl?.inMilliseconds,
    };
  }

  factory CacheData.fromJson(Map<String, dynamic> json) {
    return CacheData<T>(
      data: json['data'] as T,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      ttl: json['ttl'] != null ? Duration(milliseconds: json['ttl']) : null,
    );
  }
}

/// キャッシュ戦略の列挙型
enum CacheStrategy {
  memoryFirst, // メモリ → 永続 → ネットワーク
  persistentFirst, // 永続 → メモリ → ネットワーク
  networkFirst, // ネットワーク → キャッシュ
  cacheOnly, // キャッシュのみ
}
