import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FirebaseMenuService {
  static final _storage = FirebaseStorage.instance;
  static const String _menuImagesPath = 'menu_images';
  static const Duration _timeout = Duration(seconds: 30);
  
  // CIT公式のメニュー画像URL生成
  static const String _baseImageUrl = 'https://www.cit-s.com/wp/wp-content/themes/cit/menu/';
  static const Map<String, String> _campusFileNames = {
    'td': 'td',      // 津田沼
    'sd1': 'sd1',    // 新習志野1
    'sd2': 'sd2',    // 新習志野2
  };

  /// 管理者用: 指定キャンパスのメニュー画像（PNG）をアップロードして保存
  /// 保存先: menu_images/{campusCode}.png
  /// 既存があれば上書き保存する
  static Future<String?> uploadMenuImage(String campus, Uint8List imageBytes) async {
    try {
      final campusCode = _campusFileNames[campus] ?? campus;
      final ref = _storage.ref().child('$_menuImagesPath/$campusCode.png');

      final metadata = SettableMetadata(
        contentType: 'image/png',
        customMetadata: {
          'campus': campusCode,
          'uploaded_at': DateTime.now().toIso8601String(),
          'uploaded_by': 'admin_manual_upload',
        },
      );

      await ref.putData(imageBytes, metadata);
      final url = await ref.getDownloadURL();
      debugPrint('✅ メニュー画像をアップロードしました: $campusCode → $url');
      return url;
    } catch (e) {
      debugPrint('❌ メニュー画像アップロード失敗: $e');
      return null;
    }
  }

  /// 管理者用: 指定キャンパスのメニュー画像を削除
  static Future<bool> deleteMenuImage(String campus) async {
    try {
      final campusCode = _campusFileNames[campus] ?? campus;
      final ref = _storage.ref().child('$_menuImagesPath/$campusCode.png');
      await ref.delete();
      debugPrint('🗑️ メニュー画像を削除しました: $campusCode');
      return true;
    } catch (e) {
      debugPrint('❌ メニュー画像削除失敗: $e');
      return false;
    }
  }

  /// 管理者用: 直接Storageから現在のメニュー画像URLを取得（存在しない場合はnull）
  static Future<String?> getMenuImageDownloadUrlDirect(String campus) async {
    try {
      final campusCode = _campusFileNames[campus] ?? campus;
      final ref = _storage.ref().child('$_menuImagesPath/$campusCode.png');
      final url = await ref.getDownloadURL();
      return url;
    } catch (_) {
      return null;
    }
  }

  /// メニュー画像をFirebase Storageから取得
  static Future<String?> getMenuImageUrl(String campus, DateTime date) async {
    try {
      final fileName = _generateFileName(campus, date);
      debugPrint('Firebase Storage画像取得開始: fileName=$fileName');
      final ref = _storage.ref().child('$_menuImagesPath/$fileName');
      
      // まずファイルの存在確認
      final metadata = await ref.getMetadata();
      debugPrint('Firebase Storage ファイル存在確認成功: ${metadata.name}');
      
      // Firebase Storage上の画像URLを取得
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('Firebase Storage URL取得成功: $downloadUrl');
      
      // URLが有効かテスト（簡単なHEADリクエスト）
      final testResponse = await http.head(Uri.parse(downloadUrl));
      if (testResponse.statusCode == 200) {
        debugPrint('Firebase Storage URL確認成功: ${testResponse.statusCode}');
        return downloadUrl;
      } else {
        debugPrint('Firebase Storage URL無効: ${testResponse.statusCode}');
        throw Exception('URL無効: ${testResponse.statusCode}');
      }
      
    } catch (e) {
      debugPrint('Firebase Storage画像取得エラー: $e');
      
      // Firebase Storageにない場合は、スクレイピングしてアップロード
      return await _scrapeAndUploadImage(campus, date);
    }
  }

  /// CIT公式サイトから画像をスクレイピングしてFirebase Storageにアップロード
  static Future<String?> _scrapeAndUploadImage(String campus, DateTime date) async {
    try {
      debugPrint('メニュー画像をスクレイピング開始: $campus, $date');
      
      // 公式サイトのURL生成
      final sourceUrl = _generateSourceUrl(campus, date);
      debugPrint('スクレイピング元URL: $sourceUrl');
      
      // 画像をダウンロード
      final response = await http.get(
        Uri.parse(sourceUrl),
        headers: {'User-Agent': 'CIT App Menu Scraper'},
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        debugPrint('画像ダウンロード失敗: ${response.statusCode}');
        return null;
      }

      final imageBytes = response.bodyBytes;
      debugPrint('画像ダウンロード成功: ${imageBytes.length} bytes');

      // Firebase Storageにアップロード
      final fileName = _generateFileName(campus, date);
      final ref = _storage.ref().child('$_menuImagesPath/$fileName');
      
      final metadata = SettableMetadata(
        contentType: 'image/png',
        customMetadata: {
          'campus': campus,
          'date': date.toIso8601String(),
          'source_url': sourceUrl,
          'scraped_at': DateTime.now().toIso8601String(),
        },
      );

      await ref.putData(imageBytes, metadata);
      final downloadUrl = await ref.getDownloadURL();
      
      debugPrint('Firebase Storage保存成功: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      debugPrint('画像スクレイピング・アップロードエラー: $e');
      return null;
    }
  }

  /// 今週の全メニュー画像を更新（Firebase Functions等で定期実行）
  static Future<void> updateWeeklyMenuImages() async {
    debugPrint('=== 週間メニュー画像更新開始 ===');
    
    for (final campus in _campusFileNames.keys) {
      try {
        debugPrint('$campus キャンパスの画像更新開始');
        
        // 今週の月曜日から金曜日まで
        final monday = _getMondayOfCurrentWeek();
        for (int i = 0; i < 5; i++) {
          final date = monday.add(Duration(days: i));
          await _scrapeAndUploadImage(campus, date);
          
          // レート制限対策で少し待機
          await Future.delayed(const Duration(seconds: 2));
        }
        
        debugPrint('$campus キャンパスの画像更新完了');
        
      } catch (e) {
        debugPrint('$campus キャンパスの画像更新でエラー: $e');
      }
    }
    
    debugPrint('=== 週間メニュー画像更新完了 ===');
  }

  /// 古い画像を削除（1週間以上前）
  static Future<void> cleanOldImages() async {
    try {
      debugPrint('古いメニュー画像の削除開始');
      
      final ref = _storage.ref().child(_menuImagesPath);
      final result = await ref.listAll();
      
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      
      for (final item in result.items) {
        try {
          final metadata = await item.getMetadata();
          final scrapedAtStr = metadata.customMetadata?['scraped_at'];
          
          if (scrapedAtStr != null) {
            final scrapedAt = DateTime.parse(scrapedAtStr);
            if (scrapedAt.isBefore(oneWeekAgo)) {
              await item.delete();
              debugPrint('古い画像を削除: ${item.name}');
            }
          }
        } catch (e) {
          debugPrint('画像削除でエラー: ${item.name}, $e');
        }
      }
      
    } catch (e) {
      debugPrint('古い画像削除でエラー: $e');
    }
  }

  /// Firebase Storage上の全メニュー画像を取得（デバッグ用）
  static Future<List<Map<String, dynamic>>> listAllMenuImages() async {
    try {
      final ref = _storage.ref().child(_menuImagesPath);
      final result = await ref.listAll();
      
      final images = <Map<String, dynamic>>[];
      
      for (final item in result.items) {
        try {
          final metadata = await item.getMetadata();
          final downloadUrl = await item.getDownloadURL();
          
          images.add({
            'name': item.name,
            'download_url': downloadUrl,
            'size': metadata.size,
            'content_type': metadata.contentType,
            'created': metadata.timeCreated,
            'updated': metadata.updated,
            'custom_metadata': metadata.customMetadata,
          });
        } catch (e) {
          debugPrint('画像情報取得エラー: ${item.name}, $e');
        }
      }
      
      // 作成日時でソート
      images.sort((a, b) {
        final bTime = b['created'] as DateTime?;
        final aTime = a['created'] as DateTime?;
        if (bTime == null || aTime == null) return 0;
        return bTime.compareTo(aTime);
      });
      
      debugPrint('Firebase Storage上のメニュー画像: ${images.length}件');
      return images;
      
    } catch (e) {
      debugPrint('画像リスト取得エラー: $e');
      return [];
    }
  }

  // =========== プライベートメソッド ===========

  /// ファイル名を生成
  static String _generateFileName(String campus, DateTime date) {
    final campusCode = _campusFileNames[campus] ?? campus;
    final fileName = '$campusCode.png';
    
    debugPrint('FirebaseMenuService._generateFileName: campus=$campus → fileName=$fileName');
    return fileName;
  }

  /// 公式サイトのURL生成
  static String _generateSourceUrl(String campus, DateTime date) {
    final fileName = _generateFileName(campus, date);
    return '$_baseImageUrl$fileName';
  }

  /// 現在の週の月曜日を取得
  static DateTime _getMondayOfCurrentWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// 今日のメニュー画像URL取得
  static Future<String?> getTodayMenuImageUrl(String campus) async {
    debugPrint('FirebaseMenuService.getTodayMenuImageUrl: campus=$campus');
    
    try {
      final result = await getMenuImageUrl(campus, DateTime.now());
      debugPrint('FirebaseMenuService.getTodayMenuImageUrl: Firebase経由成功 result=$result');
      return result;
    } catch (e) {
      debugPrint('FirebaseMenuService.getTodayMenuImageUrl: Firebase経由失敗 $e');
      
      // Web版では CORS制限のため直接アクセス不可
      if (kIsWeb) {
        debugPrint('FirebaseMenuService.getTodayMenuImageUrl: Web版のためCORS制限でFirebaseのみ利用可能');
        return null;
      }
      
      // モバイル版のみ: 直接CIT公式サイトから取得を試みる
      try {
        final directUrl = _generateSourceUrl(campus, DateTime.now());
        debugPrint('FirebaseMenuService.getTodayMenuImageUrl: モバイル版で直接URL試行 $directUrl');
        
        final response = await http.head(Uri.parse(directUrl));
        if (response.statusCode == 200) {
          debugPrint('FirebaseMenuService.getTodayMenuImageUrl: 直接URL成功');
          return directUrl;
        } else {
          debugPrint('FirebaseMenuService.getTodayMenuImageUrl: 直接URL失敗 ${response.statusCode}');
        }
      } catch (directError) {
        debugPrint('FirebaseMenuService.getTodayMenuImageUrl: 直接URL例外 $directError');
      }
    }
    
    debugPrint('FirebaseMenuService.getTodayMenuImageUrl: 全て失敗, null返却');
    return null;
  }

  /// 今週の全メニュー画像URL取得
  static Future<Map<String, String?>> getWeeklyMenuImageUrls(String campus) async {
    final urls = <String, String?>{};
    final monday = _getMondayOfCurrentWeek();
    
    for (int i = 0; i < 5; i++) {
      final date = monday.add(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final url = await getMenuImageUrl(campus, date);
      urls[dateKey] = url;
    }
    
    return urls;
  }

  /// Firebase Storage接続テスト
  static Future<bool> testConnection() async {
    try {
      debugPrint('=== Firebase Storage接続テスト開始 ===');
      debugPrint('Storage instance: $_storage');
      
      // まず簡単な参照取得テスト
      final ref = _storage.ref().child('test/connection_test.txt');
      debugPrint('Reference created: $ref');
      
      // 文字列をアップロード
      debugPrint('Uploading test string...');
      await ref.putString('Firebase Storage接続テスト: ${DateTime.now()}');
      debugPrint('Upload successful');
      
      // ダウンロードURL取得
      debugPrint('Getting download URL...');
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('Download URL: $downloadUrl');
      
      // テストファイル削除
      debugPrint('Deleting test file...');
      await ref.delete();
      debugPrint('Test file deleted');
      
      debugPrint('Firebase Storage接続テスト成功: $downloadUrl');
      return true;
      
    } catch (e, stackTrace) {
      debugPrint('Firebase Storage接続テスト失敗: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // エラーの詳細分析
      if (e.toString().contains('storage/unauthorized')) {
        debugPrint('権限エラー: Storage Rulesを確認してください');
      } else if (e.toString().contains('storage/unknown')) {
        debugPrint('不明なエラー: Firebase設定を確認してください');
      } else if (e.toString().contains('network')) {
        debugPrint('ネットワークエラー: インターネット接続を確認してください');
      }
      
      return false;
    }
  }

  /// バス時刻表画像URLを取得
  static Future<String?> getBusTimetableImageUrl() async {
    try {
      const fileName = 'bus_timetable.png';
      debugPrint('Firebase Storage バス時刻表画像取得開始: fileName=$fileName');
      final ref = _storage.ref().child('bus_timetable/$fileName');
      
      // まずファイルの存在確認
      final metadata = await ref.getMetadata();
      debugPrint('Firebase Storage バス時刻表ファイル存在確認成功: ${metadata.name}');
      
      // Firebase Storage上の画像URLを取得
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('Firebase Storage バス時刻表URL取得成功: $downloadUrl');
      
      // URLが有効かテスト（簡単なHEADリクエスト）
      final testResponse = await http.head(Uri.parse(downloadUrl)).timeout(_timeout);
      if (testResponse.statusCode == 200) {
        debugPrint('Firebase Storage バス時刻表URL確認成功: ${testResponse.statusCode}');
        return downloadUrl;
      } else {
        debugPrint('Firebase Storage バス時刻表URL無効: ${testResponse.statusCode}');
        throw Exception('バス時刻表URL無効: ${testResponse.statusCode}');
      }
      
    } catch (e) {
      debugPrint('Firebase Storage バス時刻表画像取得エラー: $e');
      return null;
    }
  }

  /// バス時刻表画像をFirebase Storageにアップロード
  static Future<bool> uploadBusTimetableImage(Uint8List imageBytes) async {
    try {
      const fileName = 'bus_timetable.png';
      debugPrint('Firebase Storage バス時刻表画像アップロード開始: fileName=$fileName');
      
      final ref = _storage.ref().child('bus_timetable/$fileName');
      
      // メタデータを設定
      final metadata = SettableMetadata(
        contentType: 'image/png',
        customMetadata: {
          'uploaded_at': DateTime.now().toIso8601String(),
          'description': 'バス時刻表画像',
        },
      );
      
      // アップロード実行
      await ref.putData(imageBytes, metadata);
      debugPrint('Firebase Storage バス時刻表画像アップロード完了');
      
      return true;
      
    } catch (e) {
      debugPrint('Firebase Storage バス時刻表画像アップロードエラー: $e');
      return false;
    }
  }
}
