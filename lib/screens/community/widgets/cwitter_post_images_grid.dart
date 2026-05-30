import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../widgets/common/interactive_fullscreen_image_viewer.dart';

/// Cwitter 投稿画像（1〜4枚）の Twitter 風グリッド
class CwitterPostImagesGrid extends StatelessWidget {
  const CwitterPostImagesGrid({
    super.key,
    required this.imageUrls,
    this.localXFiles,
    this.heroTagPrefix = 'cwitterPost',
    this.gap = 2,
  });

  final List<String> imageUrls;
  final List<XFile>? localXFiles;
  final String heroTagPrefix;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final count = imageUrls.isNotEmpty
        ? imageUrls.length
        : (localXFiles?.length ?? 0);
    if (count == 0) return const SizedBox.shrink();

    final urls = imageUrls;
    final files = localXFiles;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _aspectRatioForCount(count),
        child: _buildLayout(context, count, urls, files),
      ),
    );
  }

  double _aspectRatioForCount(int count) {
    switch (count) {
      case 1:
        return 16 / 9;
      case 2:
        return 2 / 1;
      case 3:
        return 4 / 3;
      default:
        return 1;
    }
  }

  Widget _buildLayout(
    BuildContext context,
    int count,
    List<String> urls,
    List<XFile>? files,
  ) {
    switch (count) {
      case 1:
        return _cell(context, 0, urls, files);
      case 2:
        return Row(
          children: [
            Expanded(child: _cell(context, 0, urls, files)),
            SizedBox(width: gap),
            Expanded(child: _cell(context, 1, urls, files)),
          ],
        );
      case 3:
        return Row(
          children: [
            Expanded(child: _cell(context, 0, urls, files)),
            SizedBox(width: gap),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _cell(context, 1, urls, files)),
                  SizedBox(height: gap),
                  Expanded(child: _cell(context, 2, urls, files)),
                ],
              ),
            ),
          ],
        );
      default:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _cell(context, 0, urls, files)),
                  SizedBox(width: gap),
                  Expanded(child: _cell(context, 1, urls, files)),
                ],
              ),
            ),
            SizedBox(height: gap),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _cell(context, 2, urls, files)),
                  SizedBox(width: gap),
                  Expanded(child: _cell(context, 3, urls, files)),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _cell(
    BuildContext context,
    int index,
    List<String> urls,
    List<XFile>? files,
  ) {
    final hasUrl = index < urls.length && urls[index].isNotEmpty;
    final fileList = files;
    final hasFile = fileList != null && index < fileList.length;

    Widget image;
    if (hasUrl) {
      image = CachedNetworkImage(
        imageUrl: urls[index],
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => ColoredBox(
          color: Colors.grey.shade200,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => ColoredBox(
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image_outlined),
        ),
      );
    } else if (hasFile) {
      image = _LocalXFileImage(file: fileList[index]);
    } else {
      image = ColoredBox(color: Colors.grey.shade300);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasUrl
            ? () => showInteractiveFullscreenNetworkImageGallery(
                  context,
                  imageUrls: urls,
                  initialIndex: index,
                )
            : null,
        child: image,
      ),
    );
  }
}

class _LocalXFileImage extends StatelessWidget {
  const _LocalXFileImage({required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ColoredBox(
            color: Colors.grey.shade200,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return Image.memory(
          Uint8List.fromList(snapshot.data!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      },
    );
  }
}
