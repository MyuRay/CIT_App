import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'user_service.dart';

class ProfileImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  static Reference _avatarRef(String uid) =>
      _storage.ref().child('profile_images').child(uid).child('avatar.jpg');

  /// ギャラリーまたはカメラから画像を選択してアップロード
  static Future<String> pickAndUpload({
    required String uid,
    required ImageSource source,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) {
      throw ProfileImageCancelledException();
    }
    return uploadFromFile(uid: uid, file: picked);
  }

  static Future<String> uploadFromFile({
    required String uid,
    required XFile file,
  }) async {
    final ref = _avatarRef(uid);
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      await ref.putData(bytes, metadata);
    } else {
      await ref.putFile(File(file.path), metadata);
    }

    final url = await ref.getDownloadURL();
    await _saveProfileImageUrl(uid, url);

    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null && authUser.uid == uid) {
      await authUser.updatePhotoURL(url);
      await authUser.reload();
    }

    return url;
  }

  /// プロフィール画像を削除
  static Future<void> removeProfileImage(String uid) async {
    try {
      await _avatarRef(uid).delete();
    } catch (_) {
      // ファイルが無い場合は無視
    }

    await _saveProfileImageUrl(uid, null);

    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null && authUser.uid == uid) {
      await authUser.updatePhotoURL(null);
      await authUser.reload();
    }
  }

  static Future<void> _saveProfileImageUrl(String uid, String? url) async {
    final existing = await UserService.getUser(uid);
    if (existing == null) {
      throw Exception('ユーザーが見つかりません');
    }

    await UserService.updateUser(
      existing.copyWith(
        profileImageUrl: url,
        updatedAt: DateTime.now(),
      ),
    );
  }
}

class ProfileImageCancelledException implements Exception {
  @override
  String toString() => '画像の選択がキャンセルされました';
}
