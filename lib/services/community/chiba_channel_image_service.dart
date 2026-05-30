import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ChibaChannelImageService {
  static const int maxImagesPerComment = 4;

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Reference _commentImageRef({
    required String userId,
    required String threadId,
    required String commentId,
    required int index,
  }) {
    return _storage
        .ref()
        .child('chiba_channel_comment_images')
        .child(userId)
        .child(threadId)
        .child(commentId)
        .child('$index.jpg');
  }

  static Future<List<String>> uploadCommentImages({
    required String userId,
    required String threadId,
    required String commentId,
    required List<XFile> files,
  }) async {
    if (files.isEmpty) return const [];
    if (files.length > maxImagesPerComment) {
      throw ArgumentError('画像は最大$maxImagesPerComment枚までです');
    }

    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final ref = _commentImageRef(
        userId: userId,
        threadId: threadId,
        commentId: commentId,
        index: i,
      );
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

  static Future<void> deleteCommentImages({
    required String userId,
    required String threadId,
    required String commentId,
    int maxIndex = maxImagesPerComment,
  }) async {
    final futures = <Future<void>>[];
    for (var i = 0; i < maxIndex; i++) {
      futures.add(
        _commentImageRef(
          userId: userId,
          threadId: threadId,
          commentId: commentId,
          index: i,
        ).delete().catchError((_) {}),
      );
    }
    await Future.wait(futures);
  }
}
