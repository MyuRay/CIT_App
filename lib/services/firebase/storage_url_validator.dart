import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

bool isFirebaseStorageUrl(String url) {
  final lower = url.toLowerCase();
  return lower.contains('firebasestorage.googleapis.com') ||
      lower.contains('storage.googleapis.com/cit-app-2de1c');
}

/// Storage 画像 URL が利用可能か確認する。
/// App Check Enforced 時は firebasestorage URL の HTTP HEAD が失敗するため SDK で確認する。
class StorageUrlValidator {
  static const Duration _timeout = Duration(seconds: 15);

  static Future<bool> isReachable(String url) async {
    if (url.trim().isEmpty) return false;

    if (isFirebaseStorageUrl(url) &&
        url.contains('firebasestorage.googleapis.com')) {
      try {
        await FirebaseStorage.instance.refFromURL(url).getMetadata();
        return true;
      } catch (e) {
        debugPrint('StorageUrlValidator SDK metadata failed: $url → $e');
        return false;
      }
    }

    try {
      final response = await http
          .get(Uri.parse(url), headers: const {'Range': 'bytes=0-0'})
          .timeout(_timeout);
      return response.statusCode == 200 || response.statusCode == 206;
    } catch (e) {
      debugPrint('StorageUrlValidator GET(Range) failed: $url → $e');
      return false;
    }
  }
}
