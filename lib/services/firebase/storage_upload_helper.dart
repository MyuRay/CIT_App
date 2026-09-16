import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'storage_direct_url.dart';

/// Firebase Storage への画像アップロード共通処理。
class StorageUploadHelper {
  static const int maxUploadBytes = 10 * 1024 * 1024;

  static Future<void> ensureAuthenticatedUploadUser(String userId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('ログイン状態が無効です。一度ログアウトして再ログインしてください');
    }
    if (user.uid != userId) {
      throw Exception('認証ユーザーが一致しません');
    }
    await user.getIdToken(true);
  }

  static Future<Uint8List> readValidatedXFileBytes(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError('画像ファイルが空です');
    }
    if (bytes.length > maxUploadBytes) {
      throw ArgumentError('画像が大きすぎます（最大${maxUploadBytes ~/ (1024 * 1024)}MB）');
    }
    return bytes;
  }

  /// トークン付き URL を返す。`unknown` 時は getDownloadURL へフォールバックする。
  static Future<String> uploadXFile({
    required Reference ref,
    required XFile file,
    required String userId,
    required String contentType,
  }) async {
    await ensureAuthenticatedUploadUser(userId);
    final bytes = await readValidatedXFileBytes(file);
    return _uploadBytes(ref: ref, bytes: bytes, contentType: contentType);
  }

  /// [File] 向け。掲示板など既存の putFile 呼び出しを置き換える。
  static Future<String> uploadFile({
    required Reference ref,
    required File file,
    required String userId,
    required String contentType,
  }) async {
    await ensureAuthenticatedUploadUser(userId);
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError('画像ファイルが空です');
    }
    if (bytes.length > maxUploadBytes) {
      throw ArgumentError('画像が大きすぎます（最大${maxUploadBytes ~/ (1024 * 1024)}MB）');
    }
    return _uploadBytes(ref: ref, bytes: bytes, contentType: contentType);
  }

  static Future<String> _uploadBytes({
    required Reference ref,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final token = StorageDirectUrl.newDownloadToken();
    final metadataWithToken = SettableMetadata(
      contentType: contentType,
      customMetadata: {'firebaseStorageDownloadTokens': token},
    );

    try {
      await ref.putData(bytes, metadataWithToken);
      return StorageDirectUrl.mediaWithToken(ref.fullPath, token);
    } on FirebaseException catch (e) {
      if (e.code != 'unknown') {
        throw wrapStorageUploadError(e);
      }
      debugPrint(
        'StorageUploadHelper: token付きアップロード失敗(unknown)。getDownloadURL で再試行: ${ref.fullPath}',
      );
    }

    try {
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw wrapStorageUploadError(e);
    }
  }

  static Exception wrapStorageUploadError(FirebaseException e) {
    switch (e.code) {
      case 'unauthenticated':
        return Exception('ログイン状態が無効です。再ログインしてください');
      case 'unauthorized':
        return Exception('画像のアップロード権限がありません');
      case 'unknown':
        return Exception(
          '画像のアップロードに失敗しました。'
          'Firebase Console → App Check → Cloud Storage が Enforced の場合、'
          'debug ビルドでは debug トークンの登録が必要です（ログに表示されます）。'
          ' または Storage の App Check を一時的に Unenforced にしてください。',
        );
      default:
        return Exception(
          '画像のアップロードに失敗しました (${e.code}): ${e.message ?? e.plugin}',
        );
    }
  }
}
