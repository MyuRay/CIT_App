import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseCampusService {
  static final _storage = FirebaseStorage.instance;
  static const String _campusMapPath = 'campus_maps';
  static const String _floorMapPath = 'floor_maps';
  
  /// キャンパスマップ画像を取得
  static Future<String?> getCampusMapUrl(String campus) async {
    try {
      final fileName = _generateCampusMapFileName(campus);
      final fullPath = '$_campusMapPath/$fileName';
      debugPrint('🗺️ キャンパスマップ取得開始 | campus=$campus, fileName=$fileName, path=$fullPath');

      final ref = _storage.ref().child(fullPath);
      debugPrint('🗺️ Storage reference created | fullPath=${ref.fullPath}');

      final downloadUrl = await ref.getDownloadURL();
      debugPrint('✅ キャンパスマップURL取得成功 | campus=$campus, url=$downloadUrl');
      return downloadUrl;

    } catch (e, stackTrace) {
      debugPrint('❌ キャンパスマップ取得エラー | campus=$campus, error=$e');
      debugPrint('❌ StackTrace: $stackTrace');
      return null;
    }
  }
  
  /// フロアマップ画像を取得
  static Future<String?> getFloorMapUrl(String campus, String building, int floor) async {
    try {
      final fileName = _generateFloorMapFileName(campus, building, floor);
      final fullPath = '$_floorMapPath/$fileName';
      debugPrint('🏢 フロアマップ取得開始 | campus=$campus, building=$building, floor=$floor, fileName=$fileName, path=$fullPath');

      final ref = _storage.ref().child(fullPath);
      debugPrint('🏢 Storage reference created | fullPath=${ref.fullPath}');

      final downloadUrl = await ref.getDownloadURL();
      debugPrint('✅ フロアマップURL取得成功 | campus=$campus, building=$building, floor=$floor, url=$downloadUrl');
      return downloadUrl;

    } catch (e, stackTrace) {
      debugPrint('❌ フロアマップ取得エラー | campus=$campus, building=$building, floor=$floor, error=$e');
      debugPrint('❌ StackTrace: $stackTrace');
      return null;
    }
  }
  
  /// 利用可能なフロアマップ一覧を取得
  static Future<List<Map<String, dynamic>>> getAvailableFloorMaps(String campus) async {
    try {
      final ref = _storage.ref().child(_floorMapPath);
      final result = await ref.listAll();
      
      final floorMaps = <Map<String, dynamic>>[];
      
      for (final item in result.items) {
        final fileName = item.name;
        
        // ファイル名から情報を抽出 (例: tsudanuma_1_3F.png)
        if (fileName.startsWith('${campus}_')) {
          final parts = fileName.split('_');
          if (parts.length >= 3) {
            final building = parts[1];
            final floorStr = parts[2].replaceAll('.png', '');
            final floor = int.tryParse(floorStr.replaceAll('F', '')) ?? 1;
            
            final downloadUrl = await item.getDownloadURL();
            
            floorMaps.add({
              'campus': campus,
              'building': building,
              'floor': floor,
              'floor_name': floorStr,
              'file_name': fileName,
              'download_url': downloadUrl,
            });
          }
        }
      }
      
      // フロア順でソート
      floorMaps.sort((a, b) => a['floor'].compareTo(b['floor']));
      
      debugPrint('利用可能フロアマップ: ${floorMaps.length}件');
      return floorMaps;
      
    } catch (e) {
      debugPrint('フロアマップ一覧取得エラー: $e');
      return [];
    }
  }
  
  /// キャンパス一覧とそれぞれの利用可能なマップを取得
  static Future<Map<String, dynamic>> getAllCampusMaps() async {
    final campuses = ['tsudanuma', 'narashino']; // 津田沼、新習志野
    final campusMaps = <String, dynamic>{};
    
    for (final campus in campuses) {
      try {
        final campusMap = await getCampusMapUrl(campus);
        final floorMaps = await getAvailableFloorMaps(campus);
        
        campusMaps[campus] = {
          'campus_map': campusMap,
          'floor_maps': floorMaps,
        };
        
      } catch (e) {
        debugPrint('$campus キャンパスマップ取得エラー: $e');
        campusMaps[campus] = {
          'campus_map': null,
          'floor_maps': [],
        };
      }
    }
    
    return campusMaps;
  }
  
  // =========== プライベートメソッド ===========
  
  /// キャンパスマップファイル名を生成
  static String _generateCampusMapFileName(String campus) {
    return '${campus}_campus_map.png';
  }
  
  /// フロアマップファイル名を生成
  static String _generateFloorMapFileName(String campus, String building, int floor) {
    return '${campus}_${building}_${floor}F.png';
  }
  
  /// キャンパス表示名を取得
  static String getCampusDisplayName(String campus) {
    switch (campus) {
      case 'tsudanuma':
        return '津田沼キャンパス';
      case 'narashino':
        return '新習志野キャンパス';
      default:
        return campus;
    }
  }
}