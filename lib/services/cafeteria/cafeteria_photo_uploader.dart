import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/constants/app_constants.dart';
import '../firebase/storage_direct_url.dart';
import 'cafeteria_image_preparer.dart';

/// Uses the URL issued by Storage, rather than inventing a download token URL.
class CafeteriaPhotoUploader {
  CafeteriaPhotoUploader({required this.auth, required this.storage});
  final FirebaseAuth auth;
  final FirebaseStorage storage;

  Future<String> upload(
    Uint8List bytes, {
    required String filename,
    required String cafeteriaId,
  }) async {
    final user = auth.currentUser;
    if (user == null ||
        !user.emailVerified ||
        !AppConstants.isAllowedDomain(user.email ?? '')) {
      throw StateError('ログイン状態を確認してください');
    }
    await user.getIdToken(true).timeout(const Duration(seconds: 20));
    final image = await CafeteriaImagePreparer.prepare(
      bytes,
      filename: filename,
    );
    if (auth.currentUser?.uid != user.uid ||
        auth.currentUser?.emailVerified != true) {
      throw StateError('ログイン状態が変更されました。もう一度お試しください');
    }
    final safeId = cafeteriaId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final name =
        '${safeId}_${StorageDirectUrl.newDownloadToken()}.${image.extension}';
    final ref = storage.ref().child('cafeteria_menu_images').child(name);
    // The SDK creates the download token on the server. Reserved token metadata
    // supplied by clients can fail on some Storage/App Check configurations.
    final uploaded = await ref.putData(
      image.bytes,
      SettableMetadata(contentType: image.contentType),
    );
    return uploaded.ref.getDownloadURL();
  }
}
