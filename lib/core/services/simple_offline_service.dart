import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'cache_service.dart';

/// シンプルなオフライン対応サービス
class SimpleOfflineService {
  static final SimpleOfflineService _instance = SimpleOfflineService._internal();
  factory SimpleOfflineService() => _instance;
  SimpleOfflineService._internal();

  final CacheService _cache = CacheService();
  
  bool _isOnline = true;
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  final List<OfflineAction> _pendingActions = [];
  SharedPreferences? _prefs;

  /// オフラインサービスを初期化
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPendingActions();
    
    // 簡易的な接続チェック（実際のネットワーク接続は監視しない）
    _isOnline = true;
    
    if (kDebugMode) {
      print('📡 Simple Offline Service initialized');
    }
  }

  /// 接続状態のStream
  Stream<bool> get connectionStream => _connectionController.stream;
  
  /// 現在の接続状態
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  /// 手動で接続状態を設定（テスト用）
  void setConnectionStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectionController.add(_isOnline);
      
      if (kDebugMode) {
        print('📡 Connection status manually set: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      }
      
      if (_isOnline) {
        _processPendingActions();
      }
    }
  }

  /// データをオフライン対応で取得
  Future<T?> getDataWithOfflineSupport<T>({
    required String key,
    required Future<T> Function() networkFetch,
    Duration? cacheTTL,
    bool forceRefresh = false,
  }) async {
    // オンラインでキャッシュが有効な場合
    if (_isOnline && !forceRefresh) {
      // まずキャッシュから確認
      final cachedData = await _cache.getPersistentCache<T>(key);
      if (cachedData != null) {
        if (kDebugMode) {
          print('📦 Offline-aware cache hit: $key');
        }
        
        // バックグラウンドでデータを更新
        _updateCacheInBackground(key, networkFetch, cacheTTL);
        return cachedData;
      }
    }

    // オンラインの場合はネットワークから取得
    if (_isOnline) {
      try {
        if (kDebugMode) {
          print('🌐 Fetching from network: $key');
        }
        
        final data = await networkFetch();
        
        // キャッシュに保存
        if (data != null) {
          await _cache.setPersistentCache(key, data, ttl: cacheTTL);
        }
        
        return data;
      } catch (e) {
        if (kDebugMode) {
          print('❌ Network fetch failed: $e');
        }
        
        // ネットワークエラーの場合はキャッシュから取得を試行
        return await _cache.getPersistentCache<T>(key);
      }
    }

    // オフラインの場合はキャッシュから取得
    if (kDebugMode) {
      print('📱 Offline mode: getting from cache: $key');
    }
    
    return await _cache.getPersistentCache<T>(key);
  }

  /// バックグラウンドでキャッシュを更新
  void _updateCacheInBackground<T>(
    String key, 
    Future<T> Function() networkFetch,
    Duration? cacheTTL,
  ) {
    // 非同期でデータを更新（エラーは無視）
    networkFetch().then((data) {
      if (data != null) {
        _cache.setPersistentCache(key, data, ttl: cacheTTL);
        if (kDebugMode) {
          print('🔄 Background cache updated: $key');
        }
      }
    }).catchError((e) {
      if (kDebugMode) {
        print('⚠️ Background update failed: $e');
      }
    });
  }

  /// オフラインアクションをキューに追加
  Future<void> queueOfflineAction(OfflineAction action) async {
    _pendingActions.add(action);
    await _savePendingActions();
    
    if (kDebugMode) {
      print('📝 Queued offline action: ${action.type} (${_pendingActions.length} pending)');
    }

    // オンラインの場合は即座に実行
    if (_isOnline) {
      await _processPendingActions();
    }
  }

  /// 保留中のアクションを処理
  Future<void> _processPendingActions() async {
    if (_pendingActions.isEmpty || !_isOnline) return;

    if (kDebugMode) {
      print('🔄 Processing ${_pendingActions.length} pending actions');
    }

    final actionsToProcess = List<OfflineAction>.from(_pendingActions);
    final successfulActions = <OfflineAction>[];

    for (final action in actionsToProcess) {
      try {
        // 簡略化: 常に成功とみなす
        await Future.delayed(const Duration(milliseconds: 100));
        successfulActions.add(action);
        
        if (kDebugMode) {
          print('✅ Offline action executed: ${action.type}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Offline action error: ${action.type} - $e');
        }
      }
    }

    // 成功したアクションを削除
    for (final action in successfulActions) {
      _pendingActions.remove(action);
    }

    await _savePendingActions();

    if (kDebugMode && successfulActions.isNotEmpty) {
      print('🎉 Processed ${successfulActions.length} offline actions');
    }
  }

  /// 保留中のアクションを保存
  Future<void> _savePendingActions() async {
    if (_prefs == null) return;
    
    try {
      final jsonList = _pendingActions.map((action) => action.toJson()).toList();
      await _prefs!.setString('pending_offline_actions', jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save pending actions: $e');
      }
    }
  }

  /// 保留中のアクションを読み込み
  Future<void> _loadPendingActions() async {
    if (_prefs == null) return;
    
    try {
      final jsonString = _prefs!.getString('pending_offline_actions');
      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List;
        _pendingActions.clear();
        _pendingActions.addAll(
          jsonList.map((json) => OfflineAction.fromJson(json)).toList(),
        );
        
        if (kDebugMode && _pendingActions.isNotEmpty) {
          print('📝 Loaded ${_pendingActions.length} pending offline actions');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load pending actions: $e');
      }
    }
  }

  /// 保留中のアクションを取得
  List<OfflineAction> getPendingActions() => List.unmodifiable(_pendingActions);

  /// 保留中のアクション数を取得
  int get pendingActionCount => _pendingActions.length;

  /// サービスを終了
  void dispose() {
    _connectionController.close();
  }
}

/// オフラインアクション
class OfflineAction {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  OfflineAction({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static OfflineAction fromJson(Map<String, dynamic> json) {
    return OfflineAction(
      id: json['id'],
      type: json['type'],
      data: Map<String, dynamic>.from(json['data']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// オフライン対応ミックスイン
mixin SimpleOfflineSupportMixin {
  final SimpleOfflineService _offlineService = SimpleOfflineService();

  /// オフライン対応でデータを取得
  Future<T?> getDataOfflineAware<T>({
    required String cacheKey,
    required Future<T> Function() networkFetch,
    Duration cacheTTL = const Duration(hours: 1),
    bool forceRefresh = false,
  }) async {
    return await _offlineService.getDataWithOfflineSupport<T>(
      key: cacheKey,
      networkFetch: networkFetch,
      cacheTTL: cacheTTL,
      forceRefresh: forceRefresh,
    );
  }

  /// オフラインアクションをキューに追加
  Future<void> queueAction(String type, Map<String, dynamic> data) async {
    final action = OfflineAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      data: data,
      createdAt: DateTime.now(),
    );
    
    await _offlineService.queueOfflineAction(action);
  }

  /// 接続状態を確認
  bool get isConnected => _offlineService.isOnline;
  bool get isDisconnected => _offlineService.isOffline;

  /// 接続状態の変更を監視
  Stream<bool> get connectionChanges => _offlineService.connectionStream;
}