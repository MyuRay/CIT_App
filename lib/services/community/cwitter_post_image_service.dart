import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class CwitterPostImageService {
  static const int maxImagesPerPost = 4;

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Reference _postImageRef({
    required String userId,
    required String postId,
    required int index,
  }) {
    return _storage
        .ref()
        .child('cwitter_post_images')
        .child(userId)
        .child(postId)
        .child('$index.jpg');
  }

  static Reference _replyImageRef({
    required String userId,
    required String postId,
    required String replyId,
    required int index,
  }) {
    return _storage
        .ref()
        .child('cwitter_reply_images')
        .child(userId)
        .child(postId)
        .child(replyId)
        .child('$index.jpg');
  }

  static Future<List<String>> uploadPostImages({
    required String userId,
    required String postId,
    required List<XFile> files,
  }) async {
    return _uploadImages(
      files: files,
      refBuilder: (index) =>
          _postImageRef(userId: userId, postId: postId, index: index),
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
      refBuilder: (index) => _replyImageRef(
        userId: userId,
        postId: postId,
        replyId: replyId,
        index: index,
      ),
    );
  }

  static Future<List<String>> _uploadImages({
    required List<XFile> files,
    required Reference Function(int index) refBuilder,
  }) async {
    if (files.isEmpty) return const [];
    if (files.length > maxImagesPerPost) {
      throw ArgumentError('画像は最大$maxImagesPerPost枚までです');
    }

    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final ref = refBuilder(i);
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final file = files[i];

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
      futures.add(
        _postImageRef(userId: userId, postId: postId, index: i)
            .delete()
            .catchError((_) {}),
      );
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
      futures.add(
        _replyImageRef(
          userId: userId,
          postId: postId,
          replyId: replyId,
          index: i,
        )
            .delete()
            .catchError((_) {}),
      );
    }
    await Future.wait(futures);
  }
}
