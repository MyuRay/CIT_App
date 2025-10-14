import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class MenuImageService {
  static const String _userAgent = 'CIT App Mobile Client';
  static const Duration _timeout = Duration(seconds: 30);
  
  // CITメニュー画像のベースURL
  static const String _baseImageUrl = 'https://www.cit-s.com/wp/wp-content/themes/cit/menu/';
  
  // キャッシュディレクトリ名
  static const String _cacheDirectory = 'menu_images';
  
  // 津田沼・新習志野キャンパス（実際のファイル名に合わせて修正）
  static const Map<String, String> campusFileNames = {
    'td': 'td',      // 津田沼
    'ns': 'sd1',     // 新習志野（実際はsd1）
  };

  /// 現在の週の月曜日から金曜日のメニュー画像URLを生成
  static List<String> getCurrentWeekImageUrls(String campus) {
    final urls = <String>[];
    final now = DateTime.now();
    
    // 実際のファイル名形式に合わせる: td_202508_2.png, sd1_202508_2.png
    final campusCode = campusFileNames[campus] ?? campus;
    final yearMonth = '${now.year}${now.month.toString().padLeft(2, '0')}';
    
    // 8月は固定で2を使用（実際のサイトに合わせて）
    final weekNumber = 2; // 現在8月は2で固定
    
    // URL形式: td_202508_2.png
    final filename = '${campusCode}_${yearMonth}_$weekNumber.png';
    final fullUrl = '$_baseImageUrl$filename';
    
    debugPrint('Generated menu image URL: $fullUrl for campus: $campus');
    urls.add(fullUrl);
    
    return urls;
  }

  /// 今週のメニュー画像を一括ダウンロード
  static Future<Map<String, String?>> downloadWeeklyMenuImages(String campus) async {
    final results = <String, String?>{};
    final urls = getCurrentWeekImageUrls(campus);
    final monday = _getMondayOfCurrentWeek();

    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];
      final date = monday.add(Duration(days: i));
      final dateKey = _getDateKey(date);
      
      try {
        final localPath = await _downloadAndCacheImage(url, campus, date);
        results[dateKey] = localPath;
        debugPrint('Downloaded menu image for $dateKey: $localPath');
      } catch (e) {
        debugPrint('Failed to download menu image for $dateKey: $e');
        results[dateKey] = null;
      }
    }

    return results;
  }

  /// 特定の日のメニュー画像を取得
  static Future<String?> getMenuImageForDate(String campus, DateTime date) async {
    final dateKey = _getDateKey(date);
    final cachedPath = await _getCachedImagePath(campus, date);
    
    // キャッシュされた画像が存在するかチェック
    if (cachedPath != null && await File(cachedPath).exists()) {
      // ファイルが1週間以内のものかチェック
      final file = File(cachedPath);
      final lastModified = await file.lastModified();
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      
      if (lastModified.isAfter(weekAgo)) {
        return cachedPath;
      }
    }

    // キャッシュがない場合は新たにダウンロード
    try {
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final filename = '${campus}_${month}_${day}.png';
      final url = '$_baseImageUrl$filename';
      
      return await _downloadAndCacheImage(url, campus, date);
    } catch (e) {
      debugPrint('Failed to download menu image for $dateKey: $e');
      return null;
    }
  }

  /// 今日のメニュー画像を取得
  static Future<String?> getTodayMenuImage(String campus) async {
    return await getMenuImageForDate(campus, DateTime.now());
  }

  /// 週初め（月曜日）に全てのメニュー画像を更新
  static Future<void> updateWeeklyMenuImages() async {
    for (final campus in campusFileNames.keys) {
      try {
        await downloadWeeklyMenuImages(campus);
        debugPrint('Updated weekly menu images for $campus');
      } catch (e) {
        debugPrint('Failed to update weekly menu images for $campus: $e');
      }
    }
  }

  /// 画像をダウンロードしてローカルにキャッシュ
  static Future<String> _downloadAndCacheImage(String url, String campus, DateTime date) async {
    debugPrint('Downloading menu image from: $url');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': _userAgent},
      ).timeout(_timeout);

      debugPrint('HTTP Response: ${response.statusCode} for URL: $url');

      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode} from $url');
      }

      final bytes = response.bodyBytes;
      debugPrint('Downloaded ${bytes.length} bytes from: $url');
      
      final cachePath = await _getCachedImagePath(campus, date);
      
      if (cachePath != null) {
        final file = File(cachePath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
        debugPrint('Cached image to: $cachePath');
        return cachePath;
      }
      
      throw Exception('Failed to create cache path for: $url');
    } catch (e) {
      debugPrint('Error downloading menu image from $url: $e');
      rethrow;
    }
  }

  /// キャッシュされた画像のパスを取得
  static Future<String?> _getCachedImagePath(String campus, DateTime date) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/$_cacheDirectory');
      
      // キャッシュディレクトリの場所をログ出力
      debugPrint('=== メニュー画像キャッシュ場所 ===');
      debugPrint('アプリディレクトリ: ${appDir.path}');
      debugPrint('キャッシュディレクトリ: ${cacheDir.path}');
      
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final filename = '${campus}_${month}_${day}.png';
      final fullPath = '${cacheDir.path}/$filename';
      
      debugPrint('ファイルパス: $fullPath');
      
      return fullPath;
    } catch (e) {
      debugPrint('Failed to get cache path: $e');
      return null;
    }
  }

  /// 現在の週の月曜日を取得
  static DateTime _getMondayOfCurrentWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// 日付キーを生成（YYYY-MM-DD形式）
  static String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 週の曜日名を取得
  static String getWeekdayName(DateTime date) {
    const weekdays = ['', '月', '火', '水', '木', '金', '土', '日'];
    return weekdays[date.weekday];
  }

  /// 今週の全ての日付とキャッシュパスを取得
  static Future<Map<String, String?>> getWeeklyMenuPaths(String campus) async {
    final paths = <String, String?>{};
    final monday = _getMondayOfCurrentWeek();
    
    // キャッシュディレクトリの内容を確認
    await _debugCacheDirectory();
    
    for (int i = 0; i < 5; i++) {
      final date = monday.add(Duration(days: i));
      final dateKey = _getDateKey(date);
      final path = await _getCachedImagePath(campus, date);
      
      // ファイルが存在するかチェック
      if (path != null && await File(path).exists()) {
        paths[dateKey] = path;
      } else {
        paths[dateKey] = null;
      }
    }
    
    return paths;
  }

  /// キャッシュディレクトリの内容をデバッグ出力
  static Future<void> _debugCacheDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/$_cacheDirectory');
      
      debugPrint('=== キャッシュディレクトリの確認 ===');
      debugPrint('ディレクトリ: ${cacheDir.path}');
      debugPrint('存在: ${await cacheDir.exists()}');
      
      if (await cacheDir.exists()) {
        final files = await cacheDir.list().toList();
        debugPrint('ファイル数: ${files.length}');
        
        for (var file in files) {
          if (file is File) {
            final stat = await file.stat();
            debugPrint('- ${file.uri.pathSegments.last} (${stat.size} bytes)');
          }
        }
      } else {
        debugPrint('キャッシュディレクトリが存在しません');
      }
    } catch (e) {
      debugPrint('キャッシュディレクトリの確認でエラー: $e');
    }
  }

  /// 古いキャッシュファイルを削除
  static Future<void> cleanOldCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/$_cacheDirectory');
      
      if (await cacheDir.exists()) {
        final files = await cacheDir.list().toList();
        final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
        
        for (final file in files) {
          if (file is File) {
            final lastModified = await file.lastModified();
            if (lastModified.isBefore(twoWeeksAgo)) {
              await file.delete();
              debugPrint('Deleted old cache file: ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to clean old cache: $e');
    }
  }
}