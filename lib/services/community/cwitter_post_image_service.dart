import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/community/post_image_utils.dart';

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
      files: files,
      refBuilder: (index, file) => _postImageRef(
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
      files: files,
      refBuilder: (index, file) => _replyImageRef(
        userId: userId,
        postId: postId,
        replyId: replyId,
        index: index,
        extension: imageUploadExtension(file),
      ),
    );
  }

  static Future<List<String>> _uploadImages({
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
      final ref = refBuilder(i, file);
      final metadata =
          SettableMetadata(contentType: imageUploadContentType(file));

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await ref.putData(bytes, metadata);
      } else {
        await ref.putFile(File(file.path), metadata);
      }
      urls.add(await ref.getDownloadURL());
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
      for (final ext in const ['jpg', 'gif']) {
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
      for (final ext in const ['jpg', 'gif']) {
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
