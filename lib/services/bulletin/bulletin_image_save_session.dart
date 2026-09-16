import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/bulletin/bulletin_image_draft.dart';
import '../firebase/storage_upload_helper.dart';

class SavedBulletinImages {
  const SavedBulletinImages(this.urls, this.coverUrl, this.crop);
  final List<String> urls;
  final String coverUrl;
  final BulletinCrop crop;
}

/// Keep uploads across retries. Never delete existing images before the post
/// write succeeds (a network error may also hide a successful server write).
class BulletinImageSaveSession {
  BulletinImageSaveSession({required this.upload, required this.delete});
  final Future<String> Function(BulletinImageAttachment image) upload;
  final Future<void> Function(String url) delete;
  final _uploaded = <String, String>{};

  factory BulletinImageSaveSession.firebase() => BulletinImageSaveSession(
    upload: (image) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('ログインが必要です');
      final name =
          '${user.uid}_${DateTime.now().microsecondsSinceEpoch}_${image.id.hashCode}.${image.extension}';
      final ref = FirebaseStorage.instance.ref('bulletin_images/$name');
      return StorageUploadHelper.uploadXFile(
        ref: ref,
        file: XFile.fromData(
          image.bytes!,
          name: name,
          mimeType: image.contentType,
        ),
        userId: user.uid,
        contentType: image.contentType,
      );
    },
    delete: (url) => FirebaseStorage.instance.refFromURL(url).delete(),
  );

  Future<void> save({
    required BulletinImageDraft draft,
    required Future<void> Function(SavedBulletinImages images) persist,
    List<String> previousUrls = const [],
    void Function(int completed, int total)? onProgress,
  }) async {
    final images = draft.images;
    final coverId = draft.coverId;
    final crop = draft.crop;
    final urls = <String>[];
    var coverUrl = '';
    for (final image in images) {
      final url = image.url ?? _uploaded[image.id] ?? await upload(image);
      if (image.url == null) _uploaded[image.id] = url;
      urls.add(url);
      if (image.id == coverId) coverUrl = url;
      onProgress?.call(urls.length, images.length);
    }
    await persist(SavedBulletinImages(urls, coverUrl, crop));
    for (final url in {
      ...previousUrls,
      ..._uploaded.values,
    }.difference(urls.toSet())) {
      try {
        await delete(url);
      } catch (e) {
        debugPrint('Unused bulletin image cleanup failed: ${e.runtimeType}');
      }
    }
  }
}
