import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/convenience_link/convenience_link_model.dart';

class ConvenienceLinkService {
  static const String _keyPrefix = 'convenience_links_';
  static const String _versionKey = 'convenience_links_version';
  static const int _currentVersion = 2; // 順番変更を反映するためのバージョン
  
  /// ユーザー固有のキーを生成
  static String _getUserKey(String userId) => '${_keyPrefix}$userId';
  
  /// 旧形式のキーを生成（移行用）
  static String _getLegacyUserKey(String emailAddress) => '${_keyPrefix}${emailAddress.split('@').first}';
  
  /// 旧形式データからの移行
  static Future<List<ConvenienceLink>?> _migrateLegacyData(String userId, String? userEmail) async {
    if (userEmail == null) return null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyKey = _getLegacyUserKey(userEmail);
      final legacyJsonString = prefs.getString(legacyKey);
      
      if (legacyJsonString != null && legacyJsonString.isNotEmpty) {
        print('便利リンク: 旧形式データからの移行開始 ($legacyKey -> ${_getUserKey(userId)})');
        
        final jsonList = json.decode(legacyJsonString) as List;
        final links = jsonList
            .map((json) => ConvenienceLink.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // 新しいUID形式で保存
        await saveUserLinks(userId, links);
        
        // 旧データを削除
        await prefs.remove(legacyKey);
        
        print('便利リンク: 移行完了 (${links.length}件)');
        return links;
      }
    } catch (e) {
      print('便利リンク: 旧データ移行エラー: $e');
    }
    
    return null;
  }
  
  /// ユーザーの便利リンクを取得
  static Future<List<ConvenienceLink>> getUserLinks(String userId, {String? userEmail}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getUserKey(userId);
      String? jsonString = prefs.getString(key);
      
      // バージョンチェックと自動更新
      final currentVersionSaved = prefs.getInt(_versionKey) ?? 1;
      
      if (jsonString == null || jsonString.isEmpty) {
        // 旧形式データからの移行を試行
        final migratedLinks = await _migrateLegacyData(userId, userEmail);
        if (migratedLinks != null) {
          await prefs.setInt(_versionKey, _currentVersion);
          return migratedLinks;
        }
        
        // 初回はプリセットリンクを返し、バージョンを保存
        await prefs.setInt(_versionKey, _currentVersion);
        return PresetLinks.defaultLinks;
      }
      
      final jsonList = json.decode(jsonString) as List;
      final links = jsonList
          .map((json) => ConvenienceLink.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // バージョンが古い場合は順番を更新
      if (currentVersionSaved < _currentVersion) {
        print('便利リンクのバージョンを $currentVersionSaved から $_currentVersion に更新中...');
        await _updateLinksToNewOrderInternal(userId, links);
        await prefs.setInt(_versionKey, _currentVersion);
        
        // 更新後のリンクを再取得
        final updatedJsonString = prefs.getString(key);
        if (updatedJsonString != null) {
          final updatedJsonList = json.decode(updatedJsonString) as List;
          final updatedLinks = updatedJsonList
              .map((json) => ConvenienceLink.fromJson(json as Map<String, dynamic>))
              .toList();
          updatedLinks.sort((a, b) => a.order.compareTo(b.order));
          return updatedLinks;
        }
      }
      
      // order順でソート
      links.sort((a, b) => a.order.compareTo(b.order));
      
      return links;
    } catch (e) {
      print('便利リンク取得エラー: $e');
      return PresetLinks.defaultLinks;
    }
  }
  
  /// ユーザーの便利リンクを保存
  static Future<void> saveUserLinks(String userId, List<ConvenienceLink> links) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getUserKey(userId);
      
      final jsonList = links.map((link) => link.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await prefs.setString(key, jsonString);
    } catch (e) {
      print('便利リンク保存エラー: $e');
      throw Exception('便利リンクの保存に失敗しました');
    }
  }
  
  /// リンクを追加
  static Future<void> addLink(String userId, ConvenienceLink link) async {
    final links = await getUserLinks(userId);
    
    // 新しいorderを設定（最大値+1）
    final maxOrder = links.isEmpty ? 0 : links.map((l) => l.order).reduce((a, b) => a > b ? a : b);
    final newLink = link.copyWith(
      order: maxOrder + 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    links.add(newLink);
    await saveUserLinks(userId, links);
  }
  
  /// リンクを更新
  static Future<void> updateLink(String userId, ConvenienceLink updatedLink) async {
    final links = await getUserLinks(userId);
    final index = links.indexWhere((l) => l.id == updatedLink.id);
    
    if (index == -1) {
      throw Exception('リンクが見つかりません');
    }
    
    links[index] = updatedLink.copyWith(updatedAt: DateTime.now());
    await saveUserLinks(userId, links);
  }
  
  /// リンクを削除
  static Future<void> deleteLink(String userId, String linkId) async {
    final links = await getUserLinks(userId);
    links.removeWhere((l) => l.id == linkId);
    await saveUserLinks(userId, links);
  }
  
  /// リンクの順序を更新
  static Future<void> reorderLinks(String userId, List<ConvenienceLink> reorderedLinks) async {
    // 新しいorder値を設定
    for (int i = 0; i < reorderedLinks.length; i++) {
      reorderedLinks[i] = reorderedLinks[i].copyWith(
        order: i + 1,
        updatedAt: DateTime.now(),
      );
    }
    
    await saveUserLinks(userId, reorderedLinks);
  }
  
  /// リンクの有効/無効を切り替え
  static Future<void> toggleLinkEnabled(String userId, String linkId) async {
    final links = await getUserLinks(userId);
    final index = links.indexWhere((l) => l.id == linkId);
    
    if (index == -1) {
      throw Exception('リンクが見つかりません');
    }
    
    links[index] = links[index].copyWith(
      isEnabled: !links[index].isEnabled,
      updatedAt: DateTime.now(),
    );
    
    await saveUserLinks(userId, links);
  }
  
  /// プリセットリンクをリセット
  static Future<void> resetToDefaults(String userId) async {
    await saveUserLinks(userId, PresetLinks.defaultLinks);
  }
  
  /// 既存リンクの順番を新しいプリセット順に更新（内部用）
  static Future<void> _updateLinksToNewOrderInternal(String userId, List<ConvenienceLink> links) async {
    try {
      // プリセットリンクのIDとtitleで新しい順番を決定するマップ
      final newOrderMap = {
        'preset_official': 1,      // 千葉工大公式HP
        'preset_library': 2,       // 図書館
        'preset_manaba': 3,        // manaba
        'preset_portal': 4,        // CITポータル
      };
      
      // titleベースでも対応（カスタムリンクの可能性）
      final titleOrderMap = {
        '千葉工大公式HP': 1,
        '図書館': 2,
        'manaba': 3,
        'CITポータル': 4,
      };
      
      // 順番を更新
      final updatedLinks = <ConvenienceLink>[];
      for (final link in links) {
        int newOrder = link.order; // デフォルトは既存の順番
        
        // IDで一致する場合
        if (newOrderMap.containsKey(link.id)) {
          newOrder = newOrderMap[link.id]!;
        } 
        // titleで一致する場合（カスタムリンク）
        else if (titleOrderMap.containsKey(link.title)) {
          newOrder = titleOrderMap[link.title]!;
        }
        
        updatedLinks.add(link.copyWith(
          order: newOrder,
          updatedAt: DateTime.now(),
        ));
      }
      
      // 他のカスタムリンクは既存の順番を維持、プリセット以降に配置
      int maxPresetOrder = 4;
      for (final link in updatedLinks) {
        if (!newOrderMap.containsKey(link.id) && !titleOrderMap.containsKey(link.title)) {
          if (link.order <= maxPresetOrder) {
            final newLink = link.copyWith(
              order: link.order + maxPresetOrder,
              updatedAt: DateTime.now(),
            );
            final index = updatedLinks.indexOf(link);
            updatedLinks[index] = newLink;
          }
        }
      }
      
      await saveUserLinks(userId, updatedLinks);
      print('便利リンクの順番を新しいプリセット順に更新しました');
    } catch (e) {
      print('便利リンク順番更新エラー: $e');
      // エラーが発生してもアプリの動作は続行
    }
  }
  
  /// 既存リンクの順番を新しいプリセット順に更新（公開用）
  static Future<void> updateLinksToNewOrder(String userId) async {
    try {
      final links = await getUserLinks(userId);
      if (links.isEmpty) return;
      await _updateLinksToNewOrderInternal(userId, links);
    } catch (e) {
      print('便利リンク順番更新エラー: $e');
    }
  }
  
  /// URLの妥当性をチェック
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  /// 一意のIDを生成
  static String generateId() {
    return 'link_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}