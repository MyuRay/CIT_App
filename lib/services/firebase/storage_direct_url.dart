import 'dart:math';

class StorageDirectUrl {
  static const String bucket = 'cit-app-2de1c.firebasestorage.app';

  /// Cloud Functions の makePublic() 後に使える GCS 直 URL。
  /// Firebase Storage ルール / App Check の影響を受けず、Image/CachedNetworkImage から直接取得できる。
  static String publicGcsUrl(String storagePath) {
    return 'https://storage.googleapis.com/$bucket/$storagePath';
  }

  static String media(String storagePath) {
    final encodedPath = Uri.encodeComponent(storagePath);
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedPath?alt=media';
  }

  static String mediaWithToken(String storagePath, String token) {
    return '${media(storagePath)}&token=${Uri.encodeQueryComponent(token)}';
  }

  static String newDownloadToken() {
    final random = Random.secure();
    String hex(int length) {
      const chars = '0123456789abcdef';
      return List.generate(length, (_) => chars[random.nextInt(16)]).join();
    }

    return '${hex(8)}-${hex(4)}-${hex(4)}-${hex(4)}-${hex(12)}';
  }
}
