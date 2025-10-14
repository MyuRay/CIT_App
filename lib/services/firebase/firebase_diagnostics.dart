import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseDiagnostics {
  /// Firebase全体の診断
  static Future<Map<String, dynamic>> runFullDiagnostics() async {
    final results = <String, dynamic>{};
    
    try {
      // 1. Firebase Core の状態確認
      results['firebase_core'] = await _checkFirebaseCore();
      
      // 2. Firebase Storage の状態確認
      results['firebase_storage'] = await _checkFirebaseStorage();
      
      // 3. ネットワーク接続確認
      results['network'] = await _checkNetworkConnectivity();
      
      // 4. ブラウザ環境確認
      results['browser_environment'] = _checkBrowserEnvironment();
      
      debugPrint('=== Firebase診断結果 ===');
      results.forEach((key, value) {
        debugPrint('$key: $value');
      });
      
    } catch (e) {
      debugPrint('診断実行エラー: $e');
      results['diagnostics_error'] = e.toString();
    }
    
    return results;
  }
  
  /// Firebase Core の確認
  static Future<Map<String, dynamic>> _checkFirebaseCore() async {
    final result = <String, dynamic>{};
    
    try {
      // Firebase アプリの確認
      final apps = Firebase.apps;
      result['apps_count'] = apps.length;
      result['apps_names'] = apps.map((app) => app.name).toList();
      
      if (apps.isNotEmpty) {
        final defaultApp = Firebase.app();
        result['default_app'] = {
          'name': defaultApp.name,
          'project_id': defaultApp.options.projectId,
          'storage_bucket': defaultApp.options.storageBucket,
        };
      }
      
      result['status'] = 'initialized';
      
    } catch (e) {
      result['status'] = 'error';
      result['error'] = e.toString();
    }
    
    return result;
  }
  
  /// Firebase Storage の確認
  static Future<Map<String, dynamic>> _checkFirebaseStorage() async {
    final result = <String, dynamic>{};
    
    try {
      final storage = FirebaseStorage.instance;
      result['bucket'] = storage.bucket;
      result['max_download_retry_time'] = storage.maxDownloadRetryTime.inMilliseconds;
      result['max_upload_retry_time'] = storage.maxUploadRetryTime.inMilliseconds;
      
      // 簡単な参照作成テスト
      final ref = storage.ref().child('diagnostics/test.txt');
      result['reference_creation'] = 'success';
      result['reference_path'] = ref.fullPath;
      
      result['status'] = 'available';
      
    } catch (e) {
      result['status'] = 'error';
      result['error'] = e.toString();
    }
    
    return result;
  }
  
  /// ネットワーク接続の確認
  static Future<Map<String, dynamic>> _checkNetworkConnectivity() async {
    final result = <String, dynamic>{};
    
    try {
      // Firebase Storage エンドポイントへの接続テスト
      // Note: Web環境では制限があるため、簡易チェックのみ
      result['status'] = 'check_attempted';
      result['note'] = 'Web環境では詳細なネットワークチェックは制限される';
      
    } catch (e) {
      result['status'] = 'error';
      result['error'] = e.toString();
    }
    
    return result;
  }
  
  /// ブラウザ環境の確認
  static Map<String, dynamic> _checkBrowserEnvironment() {
    final result = <String, dynamic>{};
    
    try {
      result['is_web'] = kIsWeb;
      result['user_agent'] = kIsWeb ? 'web_platform' : 'native_platform';
      
      if (kIsWeb) {
        result['firebase_sdk_loaded'] = 'web環境でのSDK状態は確認困難';
      }
      
      result['status'] = 'checked';
      
    } catch (e) {
      result['status'] = 'error';
      result['error'] = e.toString();
    }
    
    return result;
  }
  
  /// Storage ルールのテスト
  static Future<Map<String, dynamic>> testStorageRules() async {
    final result = <String, dynamic>{};
    
    try {
      final storage = FirebaseStorage.instance;
      
      // 読み取りテスト
      try {
        final ref = storage.ref().child('test/read_test.txt');
        await ref.getDownloadURL(); // 存在しないファイルでもルール確認可能
        result['read_permission'] = 'allowed_or_file_not_found';
      } catch (e) {
        if (e.toString().contains('storage/unauthorized')) {
          result['read_permission'] = 'denied';
        } else {
          result['read_permission'] = 'unknown_error: ${e.toString()}';
        }
      }
      
      // 書き込みテスト
      try {
        final ref = storage.ref().child('test/write_test.txt');
        await ref.putString('test');
        result['write_permission'] = 'allowed';
        
        // 削除
        await ref.delete();
      } catch (e) {
        if (e.toString().contains('storage/unauthorized')) {
          result['write_permission'] = 'denied';
        } else {
          result['write_permission'] = 'unknown_error: ${e.toString()}';
        }
      }
      
    } catch (e) {
      result['test_error'] = e.toString();
    }
    
    return result;
  }
  
  /// 既存画像の確認
  static Future<Map<String, dynamic>> checkExistingImages() async {
    final result = <String, dynamic>{};
    final images = ['td_202508_2.png', 'sd1_202508_2.png'];
    
    try {
      final storage = FirebaseStorage.instance;
      
      for (final imageName in images) {
        try {
          final ref = storage.ref().child('menu_images/$imageName');
          final url = await ref.getDownloadURL();
          result[imageName] = {
            'status': 'exists',
            'url': url,
          };
        } catch (e) {
          result[imageName] = {
            'status': 'error',
            'error': e.toString(),
          };
        }
      }
      
    } catch (e) {
      result['check_error'] = e.toString();
    }
    
    return result;
  }
}