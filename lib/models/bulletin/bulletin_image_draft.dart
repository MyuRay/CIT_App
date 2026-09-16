import 'package:flutter/foundation.dart';
import 'bulletin_model.dart';

class BulletinCrop {
  const BulletinCrop({this.x = 0, this.y = 0, this.scale = 1});
  final double x;
  final double y;
  final double scale;
}

class BulletinImageAttachment {
  const BulletinImageAttachment({
    required this.id,
    this.url,
    this.bytes,
    this.contentType = 'image/jpeg',
    this.extension = 'jpg',
  });
  final String id;
  final String? url;
  final Uint8List? bytes;
  final String contentType;
  final String extension;
}

class BulletinImageDraft extends ChangeNotifier {
  BulletinImageDraft({BulletinPost? post}) {
    if (post != null) {
      _images.addAll(
        post.galleryImageUrls.map(
          (url) => BulletinImageAttachment(id: url, url: url),
        ),
      );
      _coverId =
          _images.any((image) => image.id == post.imageUrl)
              ? post.imageUrl
              : _images.firstOrNull?.id;
      _crop = BulletinCrop(
        x: post.thumbAlignX,
        y: post.thumbAlignY,
        scale: post.thumbScale,
      );
    }
  }

  static const maxImages = 10;
  final _images = <BulletinImageAttachment>[];
  String? _coverId;
  BulletinCrop _crop = const BulletinCrop();
  List<BulletinImageAttachment> get images => List.unmodifiable(_images);
  String? get coverId => _coverId;
  BulletinCrop get crop => _crop;
  BulletinImageAttachment? get cover =>
      _images.where((image) => image.id == _coverId).firstOrNull;

  void add(List<BulletinImageAttachment> images) {
    final additions =
        images
            .where((image) => !_images.any((old) => old.id == image.id))
            .toList();
    if (_images.length + additions.length > maxImages) {
      throw ArgumentError('画像は最大$maxImages枚です');
    }
    _images.addAll(additions);
    _coverId ??= _images.firstOrNull?.id;
    notifyListeners();
  }

  void selectCover(String id) {
    if (id == _coverId || !_images.any((image) => image.id == id)) return;
    _coverId = id;
    _crop = const BulletinCrop();
    notifyListeners();
  }

  void setCrop(BulletinCrop crop) {
    _crop = crop;
    notifyListeners();
  }

  void remove(String id) {
    _images.removeWhere((image) => image.id == id);
    if (_coverId == id) {
      _coverId = _images.firstOrNull?.id;
      _crop = const BulletinCrop();
    }
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    _images.insert(newIndex, _images.removeAt(oldIndex));
    notifyListeners();
  }
}
