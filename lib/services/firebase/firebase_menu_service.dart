import 'package:cit_app/core/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'storage_direct_url.dart';
import 'storage_url_validator.dart';

class FirebaseMenuService {
  static final _storage = FirebaseStorage.instance;
  static final _firestore = FirebaseFirestore.instance;
  static const String _menuImagesPath = 'menu_images';
  static const String _menuNotesCollection = 'cafeteria_menu_notes';
  static const Duration _timeout = Duration(seconds: 30);

  // CIT公式のメニュー画像URL生成
  static const String _baseImageUrl =
      'https://www.cit-s.com/wp/wp-content/themes/cit/menu/';
  static const Map<String, String> _campusFileNames = {
    'td': 'td', // 津田沼
    'sd1': 'sd1', // 新習志野1
    'sd2': 'sd2', // 新習志野2
  };

  /// 管理者用: 指定キャンパスのメニュー画像（PNG）をアップロードして保存
  /// 保存先: menu_images/{campusCode}.png
  /// 既存があれば上書き保存する
  static Future<String?> uploadMenuImage(
    String campus,
    Uint8List imageBytes,
  ) async {
    try {
      final campusCode = _campusFileNames[campus] ?? campus;
      final ref = _storage.ref().child('$_menuImagesPath/$campusCode.png');
      String? existingNote;
      try {
        final existingMeta = await ref.getMetadata();
        existingNote = existingMeta.customMetadata?['note'];
      } catch (_) {}

      final token = StorageDirectUrl.newDownloadToken();
      final metadata = SettableMetadata(
        contentType: 'image/png',
        customMetadata: {
          'campus': campusCode,
          'uploaded_at': DateTime.now().toIso8601String(),
          'uploaded_by': 'admin_manual_upload',
          'firebaseStorageDownloadTokens': token,
          if (existingNote != null && existingNote.trim().isNotEmpty)
            'note': existingNote.trim(),
        },
      );

      await ref.putData(imageBytes, metadata);
      final url = StorageDirectUrl.mediaWithToken(ref.fullPath, token);
      SecureLogger.debug('✅ メニュー画像をアップロードしました: $campusCode → $url');
      return url;
    } catch (e) {
      SecureLogger.debug('❌ メニュー画像アップロード失敗: $e');
      return null;
    }
  }

  /// 管理者用: 指定キャンパスのメニュー画像を削除
  static Future<bool> deleteMenuImage(String campus) async {
    try {
      final campusCode = _campusFileNames[campus] ?? campus;
      final ref = _storage.ref().child('$_menuImagesPath/$campusCode.png');
      await ref.delete();
      SecureLogger.debug('🗑️ メニュー画像を削除しました: $campusCode');
      return true;
    } catch (e) {
      SecureLogger.debug('❌ メニュー画像削除失敗: $e');
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

  /// ホーム表示用: 指定キャンパスの備考を取得
  static Future<String?> getMenuNote(String campus) async {
    try {
      final campusCode = _campusFileNames[campus] ?? campus;
      final doc =
          await _firestore
              .collection(_menuNotesCollection)
              .doc(campusCode)
              .get();
      final data = doc.data();
      final note = (data?['note'] as String?)?.trim();
      if (note != null && note.isNotEmpty) {
        return note;
      }
    } catch (_) {}

    try {
      final campusCode = _campusFileNames[campus] ?? campus;
      final ref = _storage.ref().child('$_menuImagesPath/$campusCode.png');
      final metadata = await ref.getMetadata();
      final note = metadata.customMetadata?['note']?.trim();
      if (note == null || note.isEmpty) return null;
      return note;
    } catch (_) {
      return null;
    }
  }

  /// 管理者用: 指定キャンパスの備考を更新
  /// 画像未登録の場合は false を返す
  static Future<bool> updateMenuNote(String campus, String note) async {
    try {
      final campusCode = _campusFileNames[campus] ?? campus;
      final trimmedNote = note.trim();

      // まずFirestoreへ保存（画像の有無に依存せず備考管理できる）
      await _firestore.collection(_menuNotesCollection).doc(campusCode).set({
        'campus': campusCode,
        'note': trimmedNote,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 画像がある場合はStorage metadataにも反映（互換用）
      try {
        final ref = _storage.ref().child('$_menuImagesPath/$campusCode.png');
        final metadata = await ref.getMetadata();
        final customMetadata = <String, String>{
          ...?metadata.customMetadata,
          'campus': campusCode,
          'note_updated_at': DateTime.now().toIso8601String(),
        };
        if (trimmedNote.isEmpty) {
          customMetadata.remove('note');
        } else {
          customMetadata['note'] = trimmedNote;
        }
        await ref.updateMetadata(
          SettableMetadata(customMetadata: customMetadata),
        );
      } catch (_) {}

      return true;
    } catch (e) {
      SecureLogger.debug('❌ 備考更新失敗: $e');
      return false;
    }
  }

  /// 画像 URL が HTTP 上で取得可能か確認する。
  static Future<bool> isValidDownloadUrl(String url) async {
    return StorageUrlValidator.isReachable(url);
  }

  /// メニュー画像をFirebase Storageから取得
  static Future<String?> getMenuImageUrl(String campus, DateTime date) async {
    final fileName = _generateFileName(campus, date);
    final storagePath = '$_menuImagesPath/$fileName';

    final publicUrl = StorageDirectUrl.publicGcsUrl(storagePath);
    if (await StorageUrlValidator.isReachable(publicUrl)) {
      SecureLogger.debug('Firebase Storage 公開URL確認成功: $publicUrl');
      return publicUrl;
    }

    try {
      SecureLogger.debug('Firebase Storage画像取得開始: fileName=$fileName');
      final ref = _storage.ref().child(storagePath);
      final metadata = await ref.getMetadata();
      SecureLogger.debug('Firebase Storage ファイル存在確認成功: ${metadata.name}');

      final token =
          metadata.customMetadata?['firebaseStorageDownloadTokens']
              ?.split(',')
              .first
              .trim();
      if (token != null && token.isNotEmpty) {
        final tokenUrl = StorageDirectUrl.mediaWithToken(ref.fullPath, token);
        if (await StorageUrlValidator.isReachable(tokenUrl)) {
          SecureLogger.debug('Firebase Storage トークンURL確認成功: $tokenUrl');
          return tokenUrl;
        }
      }

      final downloadUrl = await ref.getDownloadURL();
      SecureLogger.debug('Firebase Storage URL取得成功: $downloadUrl');
      if (await StorageUrlValidator.isReachable(downloadUrl)) {
        SecureLogger.debug('Firebase Storage URL確認成功');
        return downloadUrl;
      }
      throw Exception('Firebase Storage URLが無効');
    } catch (e) {
      SecureLogger.debug('Firebase Storage画像取得エラー: $e');

      // Firebase Storageにない場合は、スクレイピングしてアップロード
      return await _scrapeAndUploadImage(campus, date);
    }
  }

  /// CIT公式サイトから画像をスクレイピングしてFirebase Storageにアップロード
  static Future<String?> _scrapeAndUploadImage(
    String campus,
    DateTime date,
  ) async {
    try {
      SecureLogger.debug('メニュー画像をスクレイピング開始: $campus, $date');

      // 公式サイトのURL生成
      final sourceUrl = _generateSourceUrl(campus, date);
      SecureLogger.debug('スクレイピング元URL: $sourceUrl');

      // 画像をダウンロード
      final response = await http
          .get(
            Uri.parse(sourceUrl),
            headers: {'User-Agent': 'CIT App Menu Scraper'},
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        SecureLogger.debug('画像ダウンロード失敗: ${response.statusCode}');
        return null;
      }

      final imageBytes = response.bodyBytes;
      SecureLogger.debug('画像ダウンロード成功: ${imageBytes.length} bytes');

      // Firebase Storageにアップロード
      final fileName = _generateFileName(campus, date);
      final ref = _storage.ref().child('$_menuImagesPath/$fileName');

      try {
        final token = StorageDirectUrl.newDownloadToken();
        final uploadMetadata = SettableMetadata(
          contentType: 'image/png',
          customMetadata: {
            'campus': campus,
            'date': date.toIso8601String(),
            'source_url': sourceUrl,
            'scraped_at': DateTime.now().toIso8601String(),
            'firebaseStorageDownloadTokens': token,
          },
        );

        await ref.putData(imageBytes, uploadMetadata);
        final downloadUrl = StorageDirectUrl.mediaWithToken(
          ref.fullPath,
          token,
        );

        SecureLogger.debug('Firebase Storage保存成功: $downloadUrl');
        return downloadUrl;
      } catch (storageError) {
        SecureLogger.debug('Firebase Storage保存失敗。公式URLを使用: $storageError');
        return sourceUrl;
      }
    } catch (e) {
      SecureLogger.debug('画像スクレイピング・アップロードエラー: $e');
      return null;
    }
  }

  /// 今週の全メニュー画像を更新（Firebase Functions等で定期実行）
  static Future<void> updateWeeklyMenuImages() async {
    SecureLogger.debug('=== 週間メニュー画像更新開始 ===');

    for (final campus in _campusFileNames.keys) {
      try {
        SecureLogger.debug('$campus キャンパスの画像更新開始');

        // 今週の月曜日から金曜日まで
        final monday = _getMondayOfCurrentWeek();
        for (int i = 0; i < 5; i++) {
          final date = monday.add(Duration(days: i));
          await _scrapeAndUploadImage(campus, date);

          // レート制限対策で少し待機
          await Future.delayed(const Duration(seconds: 2));
        }

        SecureLogger.debug('$campus キャンパスの画像更新完了');
      } catch (e) {
        SecureLogger.debug('$campus キャンパスの画像更新でエラー: $e');
      }
    }

    SecureLogger.debug('=== 週間メニュー画像更新完了 ===');
  }

  /// 古い画像を削除（1週間以上前）
  static Future<void> cleanOldImages() async {
    try {
      SecureLogger.debug('古いメニュー画像の削除開始');

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
              SecureLogger.debug('古い画像を削除: ${item.name}');
            }
          }
        } catch (e) {
          SecureLogger.debug('画像削除でエラー: ${item.name}, $e');
        }
      }
    } catch (e) {
      SecureLogger.debug('古い画像削除でエラー: $e');
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
          SecureLogger.debug('画像情報取得エラー: ${item.name}, $e');
        }
      }

      // 作成日時でソート
      images.sort((a, b) {
        final bTime = b['created'] as DateTime?;
        final aTime = a['created'] as DateTime?;
        if (bTime == null || aTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      SecureLogger.debug('Firebase Storage上のメニュー画像: ${images.length}件');
      return images;
    } catch (e) {
      SecureLogger.debug('画像リスト取得エラー: $e');
      return [];
    }
  }

  // =========== プライベートメソッド ===========

  /// ファイル名を生成
  static String _generateFileName(String campus, DateTime date) {
    final campusCode = _campusFileNames[campus] ?? campus;
    final fileName = '$campusCode.png';

    SecureLogger.debug(
      'FirebaseMenuService._generateFileName: campus=$campus → fileName=$fileName',
    );
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
    SecureLogger.debug('FirebaseMenuService.getTodayMenuImageUrl: campus=$campus');

    try {
      final result = await getMenuImageUrl(campus, DateTime.now());
      if (result != null) {
        SecureLogger.debug(
          'FirebaseMenuService.getTodayMenuImageUrl: Firebase経由成功 result=$result',
        );
        return result;
      }
      SecureLogger.debug('FirebaseMenuService.getTodayMenuImageUrl: Firebase経由はnull');
    } catch (e) {
      SecureLogger.debug('FirebaseMenuService.getTodayMenuImageUrl: Firebase経由失敗 $e');
    }

    // Web版では CORS制限のため直接アクセス不可
    if (kIsWeb) {
      SecureLogger.debug(
        'FirebaseMenuService.getTodayMenuImageUrl: Web版のためCORS制限でFirebaseのみ利用可能',
      );
      return null;
    }

    // モバイル版のみ: 直接CIT公式サイトから取得を試みる
    try {
      final directUrl = _generateSourceUrl(campus, DateTime.now());
      SecureLogger.debug(
        'FirebaseMenuService.getTodayMenuImageUrl: モバイル版で直接URL試行 $directUrl',
      );

      final response = await http
          .get(Uri.parse(directUrl), headers: const {'Range': 'bytes=0-0'})
          .timeout(_timeout);
      if (response.statusCode == 200 || response.statusCode == 206) {
        SecureLogger.debug('FirebaseMenuService.getTodayMenuImageUrl: 直接URL成功');
        return directUrl;
      } else {
        SecureLogger.debug(
          'FirebaseMenuService.getTodayMenuImageUrl: 直接URL失敗 ${response.statusCode}',
        );
      }
    } catch (directError) {
      SecureLogger.debug(
        'FirebaseMenuService.getTodayMenuImageUrl: 直接URL例外 $directError',
      );
    }

    SecureLogger.debug('FirebaseMenuService.getTodayMenuImageUrl: 全て失敗, null返却');
    return null;
  }

  /// 今週の全メニュー画像URL取得
  static Future<Map<String, String?>> getWeeklyMenuImageUrls(
    String campus,
  ) async {
    final urls = <String, String?>{};
    final monday = _getMondayOfCurrentWeek();

    for (int i = 0; i < 5; i++) {
      final date = monday.add(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final url = await getMenuImageUrl(campus, date);
      urls[dateKey] = url;
    }

    return urls;
  }

  /// Firebase Storage接続テスト
  static Future<bool> testConnection() async {
    try {
      SecureLogger.debug('=== Firebase Storage接続テスト開始 ===');
      SecureLogger.debug('Storage instance: $_storage');

      // まず簡単な参照取得テスト
      final ref = _storage.ref().child('test/connection_test.txt');
      SecureLogger.debug('Reference created: $ref');

      // 文字列をアップロード
      SecureLogger.debug('Uploading test string...');
      await ref.putString('Firebase Storage接続テスト: ${DateTime.now()}');
      SecureLogger.debug('Upload successful');

      // ダウンロードURL取得
      SecureLogger.debug('Getting download URL...');
      final downloadUrl = await ref.getDownloadURL();
      SecureLogger.debug('Download URL: $downloadUrl');

      // テストファイル削除
      SecureLogger.debug('Deleting test file...');
      await ref.delete();
      SecureLogger.debug('Test file deleted');

      SecureLogger.debug('Firebase Storage接続テスト成功: $downloadUrl');
      return true;
    } catch (e, stackTrace) {
      SecureLogger.debug('Firebase Storage接続テスト失敗: $e');
      SecureLogger.debug('Stack trace: $stackTrace');

      // エラーの詳細分析
      if (e.toString().contains('storage/unauthorized')) {
        SecureLogger.debug('権限エラー: Storage Rulesを確認してください');
      } else if (e.toString().contains('storage/unknown')) {
        SecureLogger.debug('不明なエラー: Firebase設定を確認してください');
      } else if (e.toString().contains('network')) {
        SecureLogger.debug('ネットワークエラー: インターネット接続を確認してください');
      }

      return false;
    }
  }

  /// バス時刻表画像URLを取得
  static Future<String?> getBusTimetableImageUrl() async {
    const fileName = 'bus_timetable.png';
    const storagePath = 'bus_timetable/$fileName';

    final publicUrl = StorageDirectUrl.publicGcsUrl(storagePath);
    if (await StorageUrlValidator.isReachable(publicUrl)) {
      SecureLogger.debug('Firebase Storage バス時刻表公開URL確認成功: $publicUrl');
      return publicUrl;
    }

    try {
      SecureLogger.debug('Firebase Storage バス時刻表画像取得開始: fileName=$fileName');
      final ref = _storage.ref().child(storagePath);
      final metadata = await ref.getMetadata();
      SecureLogger.debug('Firebase Storage バス時刻表ファイル存在確認成功: ${metadata.name}');

      final token =
          metadata.customMetadata?['firebaseStorageDownloadTokens']
              ?.split(',')
              .first
              .trim();
      if (token != null && token.isNotEmpty) {
        final tokenUrl = StorageDirectUrl.mediaWithToken(ref.fullPath, token);
        if (await StorageUrlValidator.isReachable(tokenUrl)) {
          SecureLogger.debug('Firebase Storage バス時刻表トークンURL確認成功: $tokenUrl');
          return tokenUrl;
        }
      }

      final downloadUrl = await ref.getDownloadURL();
      SecureLogger.debug('Firebase Storage バス時刻表URL取得成功: $downloadUrl');
      if (await StorageUrlValidator.isReachable(downloadUrl)) {
        SecureLogger.debug('Firebase Storage バス時刻表URL確認成功');
        return downloadUrl;
      }
      throw Exception('バス時刻表URL無効');
    } catch (e) {
      SecureLogger.debug('Firebase Storage バス時刻表画像取得エラー: $e');
      return null;
    }
  }

  /// バス時刻表画像をFirebase Storageにアップロード
  static Future<bool> uploadBusTimetableImage(Uint8List imageBytes) async {
    try {
      const fileName = 'bus_timetable.png';
      SecureLogger.debug('Firebase Storage バス時刻表画像アップロード開始: fileName=$fileName');

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
      SecureLogger.debug('Firebase Storage バス時刻表画像アップロード完了');

      return true;
    } catch (e) {
      SecureLogger.debug('Firebase Storage バス時刻表画像アップロードエラー: $e');
      return false;
    }
  }
}
