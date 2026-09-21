import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/firebase/storage_url_validator.dart';

/// ダウンロード URL を優先し、取得できない場合だけ Storage SDK で再取得する。
/// 通常の画像キャッシュを共有し、再描画中に取得方法を切り替えない。
class FirebaseStorageImage extends StatelessWidget {
  const FirebaseStorageImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.alignment = Alignment.center,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      // URL（更新時の download token を含む）ごとに表示状態を分離する。
      // 別の作者や更新前の画像・SDK リクエストを引き継がない。
      key: ValueKey(imageUrl),
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        return frame != null ? child : _placeholder();
      },
      errorBuilder: (context, error, stackTrace) {
        if (!isFirebaseStorageUrl(imageUrl)) return _error();
        return _StorageImageFallback(key: ValueKey(imageUrl), image: this);
      },
    );
  }

  Widget _placeholder() {
    return placeholder ??
        SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
  }

  Widget _error() {
    return errorWidget ??
        SizedBox(
          width: width,
          height: height,
          child: ColoredBox(
            color: Colors.grey.shade300,
            child: const Icon(Icons.broken_image_outlined),
          ),
        );
  }
}

/// HTTP 取得の失敗後にだけマウントされる。再描画では同じ Future を使用し、
/// URL が変わったらキーによって破棄されるため、古い完了通知は反映されない。
class _StorageImageFallback extends StatefulWidget {
  const _StorageImageFallback({super.key, required this.image});

  final FirebaseStorageImage image;

  @override
  State<_StorageImageFallback> createState() => _StorageImageFallbackState();
}

class _StorageImageFallbackState extends State<_StorageImageFallback> {
  static const int _maxDownloadBytes = 10 * 1024 * 1024;
  late final Future<Uint8List?> _bytes = _load();

  Future<Uint8List?> _load() async {
    try {
      return await FirebaseStorage.instance
          .refFromURL(widget.image.imageUrl)
          .getData(_maxDownloadBytes);
    } catch (error) {
      // URL に含まれる download token やユーザー ID をログに出さない。
      if (kDebugMode) {
        final code =
            error is FirebaseException ? error.code : 'image-load-failed';
        debugPrint('FirebaseStorageImage fallback failed: $code');
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return image._placeholder();
        }
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) return image._error();
        return Image.memory(
          bytes,
          width: image.width,
          height: image.height,
          fit: image.fit,
          alignment: image.alignment,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            return frame != null ? child : image._placeholder();
          },
          errorBuilder: (context, error, stackTrace) => image._error(),
        );
      },
    );
  }
}
