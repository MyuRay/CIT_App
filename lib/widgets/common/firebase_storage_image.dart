import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/firebase/storage_url_validator.dart';

/// Firebase Storage 画像用。
/// App Check Enforced 時は Image.network が失敗するため、SDK(getData) にフォールバックする。
class FirebaseStorageImage extends StatefulWidget {
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
  State<FirebaseStorageImage> createState() => _FirebaseStorageImageState();
}

class _FirebaseStorageImageState extends State<FirebaseStorageImage> {
  static const int _maxDownloadBytes = 10 * 1024 * 1024;

  Uint8List? _sdkBytes;
  bool _sdkLoadFailed = false;
  bool _sdkLoadStarted = false;

  bool get _shouldUseSdkFirst => isFirebaseStorageUrl(widget.imageUrl);

  @override
  Widget build(BuildContext context) {
    if (_sdkBytes != null) {
      return Image.memory(
        _sdkBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        gaplessPlayback: true,
      );
    }

    if (_sdkLoadFailed) {
      return widget.errorWidget ?? _defaultError();
    }

    if (_shouldUseSdkFirst && !_sdkLoadStarted) {
      _startSdkLoad();
      return widget.placeholder ?? _defaultPlaceholder();
    }

    return Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return widget.placeholder ?? _defaultPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint(
          'FirebaseStorageImage network error: ${widget.imageUrl} → $error',
        );
        if (!_sdkLoadStarted) {
          _startSdkLoad();
          return widget.placeholder ?? _defaultPlaceholder();
        }
        return widget.errorWidget ?? _defaultError();
      },
    );
  }

  void _startSdkLoad() {
    if (_sdkLoadStarted || !isFirebaseStorageUrl(widget.imageUrl)) return;
    _sdkLoadStarted = true;
    _loadViaSdk();
  }

  Future<void> _loadViaSdk() async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(widget.imageUrl);
      final bytes = await ref.getData(_maxDownloadBytes);
      if (!mounted) return;
      if (bytes == null || bytes.isEmpty) {
        setState(() => _sdkLoadFailed = true);
        return;
      }
      setState(() => _sdkBytes = bytes);
    } catch (e, stackTrace) {
      debugPrint('FirebaseStorageImage SDK error: ${widget.imageUrl} → $e');
      debugPrint('$stackTrace');
      if (mounted) {
        setState(() => _sdkLoadFailed = true);
      }
    }
  }

  Widget _defaultPlaceholder() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _defaultError() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ColoredBox(
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}
