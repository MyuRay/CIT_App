import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/community/post_image_utils.dart';
import '../firebase/storage_upload_helper.dart';

class CwitterPostImageService {
  static const int maxImagesPerPost = 4;

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Reference _postImageRef({
    required String userId,
    required String postId,
    required int index,
    required String extension,
  }) {
    return _storage
        .ref()
        .child('cwitter_post_images')
        .child(userId)
        .child(postId)
        .child('$index.$extension');
  }

  static Reference _replyImageRef({
    required String userId,
    required String postId,
    required String replyId,
    required int index,
    required String extension,
  }) {
    return _storage
        .ref()
        .child('cwitter_reply_images')
        .child(userId)
        .child(postId)
        .child(replyId)
        .child('$index.$extension');
  }

  static Future<List<String>> uploadPostImages({
    required String userId,
    required String postId,
    required List<XFile> files,
  }) async {
    return _uploadImages(
      userId: userId,
      files: files,
      refBuilder:
          (index, file) => _postImageRef(
            userId: userId,
            postId: postId,
            index: index,
            extension: imageUploadExtension(file),
          ),
    );
  }

  static Future<List<String>> uploadReplyImages({
    required String userId,
    required String postId,
    required String replyId,
    required List<XFile> files,
  }) async {
    return _uploadImages(
      userId: userId,
      files: files,
      refBuilder:
          (index, file) => _replyImageRef(
            userId: userId,
            postId: postId,
            replyId: replyId,
            index: index,
            extension: imageUploadExtension(file),
          ),
    );
  }

  static Future<List<String>> _uploadImages({
    required String userId,
    required List<XFile> files,
    required Reference Function(int index, XFile file) refBuilder,
  }) async {
    if (files.isEmpty) return const [];
    if (files.length > maxImagesPerPost) {
      throw ArgumentError('画像は最大$maxImagesPerPost枚までです');
    }

    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      if (isHeicXFile(file)) {
        throw ArgumentError(
          'HEIC形式は未対応です。JPEG/PNG/GIF を選ぶか、カメラ設定を「互換性優先」にしてください',
        );
      }

      final ref = refBuilder(i, file);
      try {
        final url = await StorageUploadHelper.uploadXFile(
          ref: ref,
          file: file,
          userId: userId,
          contentType: imageUploadContentType(file),
        );
        urls.add(url);
      } on FirebaseException catch (e) {
        throw StorageUploadHelper.wrapStorageUploadError(e);
      }
    }
    return urls;
  }

  static Future<void> deletePostImages({
    required String userId,
    required String postId,
    List<String>? imageUrls,
    int maxIndex = maxImagesPerPost,
  }) async {
    final futures = <Future<void>>[];
    for (var i = 0; i < maxIndex; i++) {
      for (final ext in const ['jpg', 'gif', 'png', 'webp']) {
        futures.add(
          _postImageRef(
            userId: userId,
            postId: postId,
            index: i,
            extension: ext,
          ).delete().catchError((_) {}),
        );
      }
    }
    await Future.wait(futures);
  }

  static Future<void> deleteReplyImages({
    required String userId,
    required String postId,
    required String replyId,
    int maxIndex = maxImagesPerPost,
  }) async {
    final futures = <Future<void>>[];
    for (var i = 0; i < maxIndex; i++) {
      for (final ext in const ['jpg', 'gif', 'png', 'webp']) {
        futures.add(
          _replyImageRef(
            userId: userId,
            postId: postId,
            replyId: replyId,
            index: i,
            extension: ext,
          ).delete().catchError((_) {}),
        );
      }
    }
    await Future.wait(futures);
  }
}
