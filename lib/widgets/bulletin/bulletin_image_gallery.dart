import 'package:flutter/material.dart';
import '../common/interactive_fullscreen_image_viewer.dart';
import '../common/safe_cached_network_image.dart';

class BulletinImageGallery extends StatefulWidget {
  const BulletinImageGallery({
    super.key,
    required this.imageUrls,
    this.imageBuilder,
  });
  final List<String> imageUrls;
  final Widget Function(String url)? imageBuilder;
  @override
  State<BulletinImageGallery> createState() => _BulletinImageGalleryState();
}

class _BulletinImageGalleryState extends State<BulletinImageGallery> {
  int _index = 0;
  final _pages = PageController();
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: widget.imageUrls.length,
                    onPageChanged: (index) => setState(() => _index = index),
                    itemBuilder:
                        (context, index) => Semantics(
                          label:
                              '投稿画像 ${index + 1}/${widget.imageUrls.length}。タップで拡大',
                          button: true,
                          child: GestureDetector(
                            onTap:
                                () =>
                                    showInteractiveFullscreenNetworkImageGallery(
                                      context,
                                      imageUrls: widget.imageUrls,
                                      initialIndex: index,
                                    ),
                            child:
                                widget.imageBuilder?.call(
                                  widget.imageUrls[index],
                                ) ??
                                SafeCachedNetworkImage(
                                  imageUrl: widget.imageUrls[index],
                                  fit: BoxFit.contain,
                                ),
                          ),
                        ),
                  ),
                ),
              ),
              if (widget.imageUrls.length > 1)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Text(
                        '${_index + 1}/${widget.imageUrls.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              if (widget.imageUrls.length > 1)
                IconButton(
                  tooltip: '前の画像',
                  onPressed:
                      _index > 0
                          ? () => _pages.previousPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          )
                          : null,
                  icon: const Icon(Icons.chevron_left),
                ),
              Expanded(
                child: Text(
                  widget.imageUrls.length > 1 ? '左右にスワイプ・タップで拡大' : 'タップで画像を拡大',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (widget.imageUrls.length > 1)
                IconButton(
                  tooltip: '次の画像',
                  onPressed:
                      _index < widget.imageUrls.length - 1
                          ? () => _pages.nextPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          )
                          : null,
                  icon: const Icon(Icons.chevron_right),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
