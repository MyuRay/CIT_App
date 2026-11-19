import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../../models/contact/contact_chat.dart';

/// Decode, orient, resize and remove camera/location metadata before upload.
Uint8List prepareContactChatImage(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
    throw ArgumentError('画像は10MB以下のものを選んでください');
  }
  final decoder = img.findDecoderForData(bytes);
  final info = decoder?.startDecode(bytes);
  if (info == null || info.width * info.height > 40000000) {
    throw ArgumentError('この画像を読み込めません。別の画像を選んでください');
  }
  final decoded = decoder!.decodeFrame(0);
  if (decoded == null) throw ArgumentError('画像を読み込めませんでした');
  var image = img.bakeOrientation(decoded);
  if (image.width > 2048 || image.height > 2048) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? 2048 : null,
      height: image.height > image.width ? 2048 : null,
    );
  }
  image.exif = img.ExifData();
  return Uint8List.fromList(img.encodeJpg(image, quality: 85));
}

String contactChatImagePath(
  String uid,
  String sender,
  String messageId,
  int index,
) => 'contact_chat_images/$uid/$sender/$messageId/$index.jpg';

class ContactChatImageService {
  ContactChatImageService({required this.auth, FirebaseStorage? storage})
    : _providedStorage = storage;
  final FirebaseAuth auth;
  final FirebaseStorage? _providedStorage;
  FirebaseStorage get _storage => _providedStorage ?? FirebaseStorage.instance;

  Future<Uint8List> prepare(XFile file) async {
    if (await file.length() > 10 * 1024 * 1024)
      throw ArgumentError('画像は10MB以下のものを選んでください');
    return compute(prepareContactChatImage, await file.readAsBytes());
  }

  Future<List<String>> upload({
    required String userId,
    required String messageId,
    required List<Uint8List> images,
  }) async {
    final user = auth.currentUser;
    if (user == null || !user.emailVerified) throw StateError('ログインが必要です');
    if (images.length > contactChatMaxImages)
      throw ArgumentError('画像は4枚まで添付できます');
    final paths = <String>[];
    for (var i = 0; i < images.length; i++) {
      if (auth.currentUser?.uid != user.uid) throw StateError('ログイン状態が変わりました');
      final bytes = images[i];
      if (bytes.isEmpty || bytes.length > contactChatMaxImageBytes)
        throw ArgumentError('画像のサイズが大きすぎます');
      final path = contactChatImagePath(userId, user.uid, messageId, i);
      final ref = _storage.ref(path);
      final digest = base64Encode(md5.convert(bytes).bytes);
      // Immutable objects. A retry reuses an identical completed upload.
      try {
        final metadata = await ref.getMetadata();
        if (metadata.md5Hash != digest) throw StateError('画像の送信内容が変わりました');
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') rethrow;
        await ref.putData(
          bytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            cacheControl: 'private, no-store',
          ),
        );
      }
      paths.add(path);
    }
    return paths;
  }

  /// Authenticated SDK reads only; never issue public download-token URLs.
  Future<Uint8List> read(String userId, String path) async {
    if (!path.startsWith('contact_chat_images/$userId/') ||
        path.split('/').length != 5) {
      throw ArgumentError('画像を開けませんでした');
    }
    final bytes = await _storage.ref(path).getData(contactChatMaxImageBytes);
    if (bytes == null) throw StateError('画像が見つかりません');
    return bytes;
  }
}
