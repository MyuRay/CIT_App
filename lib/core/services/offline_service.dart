import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'cache_service.dart';

/// オフライン対応サービス
class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final Connectivity _connectivity = Connectivity();
  final CacheService _cache = CacheService();
  
  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  final List<OfflineAction> _pendingActions = [];
  SharedPreferences? _prefs;

  /// オフラインサービスを初期化
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPendingActions();
    await _checkInitialConnectivity();
    _startConnectivityMonitoring();
    
    if (kDebugMode) {
      print('📡 Offline Service initialized (Online: $_isOnline)');
    }
  }

  /// 接続状態のStream
  Stream<bool> get connectionStream => _connectionController.stream;
  
  /// 現在の接続状態
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  /// 初期接続状態をチェック
  Future<void> _checkInitialConnectivity() async {
    try {
      final ConnectivityResult result = await _connectivity.checkConnectivity();
      _updateConnectionStatus([result]);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Initial connectivity check failed: $e');
      }
      _isOnline = false;
    }
  }

  /// 接続監視を開始
  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (result) => _updateConnectionStatus([result]),
      onError: (error) {
        if (kDebugMode) {
          print('❌ Connectivity monitoring error: $error');
        }
      },
    );
  }

  /// 接続状態を更新
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    
    // WiFi、モバイルデータ、イーサネットのいずれかがあればオンライン
    _isOnline = results.any((result) => 
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);
    
    if (wasOnline != _isOnline) {
      _connectionController.add(_isOnline);
      
      if (kDebugMode) {
        print('📡 Connection status changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
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
        final success = await _executeAction(action);
        if (success) {
          successfulActions.add(action);
          if (kDebugMode) {
            print('✅ Offline action executed: ${action.type}');
          }
        } else {
          if (kDebugMode) {
            print('❌ Offline action failed: ${action.type}');
          }
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

  /// アクションを実行
  Future<bool> _executeAction(OfflineAction action) async {
    try {
      switch (action.type) {
        case 'createPost':
          return await _executeCreatePost(action.data);
        case 'createComment':
          return await _executeCreateComment(action.data);
        case 'updateProfile':
          return await _executeUpdateProfile(action.data);
        case 'deletePost':
          return await _executeDeletePost(action.data);
        default:
          if (kDebugMode) {
            print('⚠️ Unknown offline action type: ${action.type}');
          }
          return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Action execution error: $e');
      }
      return false;
    }
  }

  /// 投稿作成アクションを実行
  Future<bool> _executeCreatePost(Map<String, dynamic> data) async {
    // TODO: 実際のAPIコールを実装
    // 例: await postService.createPost(data);
    await Future.delayed(const Duration(seconds: 1)); // 仮実装
    return true;
  }

  /// コメント作成アクションを実行
  Future<bool> _executeCreateComment(Map<String, dynamic> data) async {
    // TODO: 実際のAPIコールを実装
    await Future.delayed(const Duration(seconds: 1)); // 仮実装
    return true;
  }

  /// プロフィール更新アクションを実行
  Future<bool> _executeUpdateProfile(Map<String, dynamic> data) async {
    // TODO: 実際のAPIコールを実装
    await Future.delayed(const Duration(seconds: 1)); // 仮実装
    return true;
  }

  /// 投稿削除アクションを実行
  Future<bool> _executeDeletePost(Map<String, dynamic> data) async {
    // TODO: 実際のAPIコールを実装
    await Future.delayed(const Duration(seconds: 1)); // 仮実装
    return true;
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
    _connectivitySubscription?.cancel();
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
mixin OfflineSupportMixin {
  final OfflineService _offlineService = OfflineService();

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