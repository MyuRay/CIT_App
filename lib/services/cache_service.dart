import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bulletin/bulletin_model.dart';

class CacheService {
  static const String _bulletinPostsKey = 'bulletin_posts_cache';
  static const String _lastUpdateKey = 'bulletin_posts_last_update';
  static const String _menuImageKey = 'menu_image_cache';
  static const String _menuImageUpdateKey = 'menu_image_last_update';
  
  // キャッシュ有効期限
  static const Duration bulletinCacheExpiry = Duration(hours: 1); // 掲示板: 1時間
  static const Duration menuImageCacheExpiry = Duration(minutes: 30); // メニュー画像: 30分
  
  /// 掲示板投稿をキャッシュに保存
  static Future<void> saveBulletinPosts(List<BulletinPost> posts) async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final jsonList = posts.map((post) => post.toJson()).toList();
      await prefs.setString(_bulletinPostsKey, jsonEncode(jsonList));
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      
      print('💾 掲示板データをキャッシュに保存: ${posts.length}件');
    } catch (e) {
      print('❌ キャッシュ保存エラー: $e');
    }
  }
  
  /// キャッシュから掲示板投稿を取得
  static Future<List<BulletinPost>?> getCachedBulletinPosts() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      // 有効期限チェック
      final lastUpdate = prefs.getInt(_lastUpdateKey);
      if (lastUpdate == null) return null;
      
      final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      if (DateTime.now().difference(lastUpdateTime) > bulletinCacheExpiry) {
        print('⏰ 掲示板キャッシュが期限切れ');
        return null;
      }
      
      // キャッシュデータ取得
      final jsonString = prefs.getString(_bulletinPostsKey);
      if (jsonString == null) return null;
      
      final jsonList = jsonDecode(jsonString) as List;
      final posts = jsonList.map((json) => BulletinPost.fromJson(json as Map<String, dynamic>)).toList();
      
      print('📦 キャッシュから掲示板データを読み込み: ${posts.length}件');
      return posts;
    } catch (e) {
      print('❌ キャッシュ読み込みエラー: $e');
      await clearBulletinCache(); // 破損したキャッシュをクリア
      return null;
    }
  }
  
  /// メニュー画像URLをキャッシュに保存
  static Future<void> saveMenuImageUrls(Map<String, String> menuImages) async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      await prefs.setString(_menuImageKey, jsonEncode(menuImages));
      await prefs.setInt(_menuImageUpdateKey, DateTime.now().millisecondsSinceEpoch);
      
      print('💾 メニュー画像URLをキャッシュに保存: ${menuImages.length}件');
    } catch (e) {
      print('❌ メニュー画像キャッシュ保存エラー: $e');
    }
  }
  
  /// キャッシュからメニュー画像URLを取得
  static Future<Map<String, String>?> getCachedMenuImageUrls() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      // 有効期限チェック
      final lastUpdate = prefs.getInt(_menuImageUpdateKey);
      if (lastUpdate == null) return null;
      
      final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      if (DateTime.now().difference(lastUpdateTime) > menuImageCacheExpiry) {
        print('⏰ メニュー画像キャッシュが期限切れ');
        return null;
      }
      
      // キャッシュデータ取得
      final jsonString = prefs.getString(_menuImageKey);
      if (jsonString == null) return null;
      
      final menuImages = Map<String, String>.from(jsonDecode(jsonString));
      
      print('📦 キャッシュからメニュー画像URLを読み込み: ${menuImages.length}件');
      return menuImages;
    } catch (e) {
      print('❌ メニュー画像キャッシュ読み込みエラー: $e');
      await clearMenuImageCache();
      return null;
    }
  }
  
  /// 掲示板キャッシュをクリア
  static Future<void> clearBulletinCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bulletinPostsKey);
    await prefs.remove(_lastUpdateKey);
    print('🗑️ 掲示板キャッシュをクリア');
  }
  
  /// メニュー画像キャッシュをクリア
  static Future<void> clearMenuImageCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_menuImageKey);
    await prefs.remove(_menuImageUpdateKey);
    print('🗑️ メニュー画像キャッシュをクリア');
  }
  
  /// 全キャッシュをクリア
  static Future<void> clearAllCache() async {
    await clearBulletinCache();
    await clearMenuImageCache();
    print('🗑️ 全キャッシュをクリア');
  }
  
  /// キャッシュサイズを取得（デバッグ用）
  static Future<String> getCacheInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    final bulletinData = prefs.getString(_bulletinPostsKey);
    final menuData = prefs.getString(_menuImageKey);
    
    final bulletinSize = bulletinData?.length ?? 0;
    final menuSize = menuData?.length ?? 0;
    final totalSize = bulletinSize + menuSize;
    
    return '''
キャッシュ情報:
- 掲示板: ${(bulletinSize / 1024).toStringAsFixed(1)}KB
- メニュー画像: ${(menuSize / 1024).toStringAsFixed(1)}KB  
- 合計: ${(totalSize / 1024).toStringAsFixed(1)}KB
    ''';
  }
}