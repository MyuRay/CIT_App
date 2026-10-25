import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../models/user/profile_avatar_crop.dart';
import '../firebase/storage_upload_helper.dart';
import 'user_service.dart';

class ProfileImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  static Reference _avatarRef(String uid) =>
      _storage.ref().child('profile_images').child(uid).child('avatar.jpg');

  /// ギャラリーまたはカメラから画像を選択（アップロードは別途）。
  static Future<XFile> pickAvatarImage({required ImageSource source}) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 92,
    );
    if (picked == null) {
      throw ProfileImageCancelledException();
    }
    return picked;
  }

  /// ギャラリーまたはカメラから画像を選択してアップロード（従来フロー）。
  static Future<String> pickAndUpload({
    required String uid,
    required ImageSource source,
  }) async {
    final picked = await pickAvatarImage(source: source);
    return uploadFromFile(uid: uid, file: picked);
  }

  static const int avatarOutputSize = 512;

  /// 円形枠に合わせた正方形 JPEG を生成する。
  static Future<Uint8List> renderCroppedAvatarJpeg({
    required XFile file,
    required ProfileAvatarCrop crop,
    int outputSize = avatarOutputSize,
  }) async {
    final raw = await StorageUploadHelper.readValidatedXFileBytes(file);
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      throw StateError('画像を読み込めませんでした');
    }

    final iw = decoded.width.toDouble();
    final ih = decoded.height.toDouble();
    final viewport = Size.square(outputSize.toDouble());
    final imageSize = Size(iw, ih);
    final src = profileAvatarSourceSquareRect(imageSize, viewport, crop);

    final cropped = img.copyCrop(
      decoded,
      x: src.left.round(),
      y: src.top.round(),
      width: src.width.round(),
      height: src.height.round(),
    );
    final square = img.copyResize(
      cropped,
      width: outputSize,
      height: outputSize,
    );
    return Uint8List.fromList(img.encodeJpg(square, quality: 88));
  }

  static Future<String> uploadAvatarBytes({
    required String uid,
    required Uint8List jpegBytes,
  }) async {
    if (jpegBytes.isEmpty) {
      throw StateError('画像データが空です');
    }
    final ref = _avatarRef(uid);
    await StorageUploadHelper.ensureAuthenticatedUploadUser(uid);
    final url = await StorageUploadHelper.uploadValidatedBytes(
      ref: ref,
      bytes: jpegBytes,
      contentType: 'image/jpeg',
    );
    await _saveProfileImageUrl(uid, url);

    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null && authUser.uid == uid) {
      await authUser.updatePhotoURL(url);
      await authUser.reload();
    }
    return url;
  }

  static Future<String> uploadFromFile({
    required String uid,
    required XFile file,
  }) async {
    final ref = _avatarRef(uid);
    final url = await StorageUploadHelper.uploadXFile(
      ref: ref,
      file: file,
      userId: uid,
      contentType: 'image/jpeg',
    );
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
      existing.copyWith(profileImageUrl: url, updatedAt: DateTime.now()),
    );
  }
}

class ProfileImageCancelledException implements Exception {
  @override
  String toString() => '画像の選択がキャンセルされました';
}
