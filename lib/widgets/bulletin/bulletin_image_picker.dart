import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../../models/bulletin/bulletin_image_draft.dart';
import '../../services/firebase/storage_upload_helper.dart';
import 'bulletin_thumbnail.dart';
import 'bulletin_thumbnail_editor.dart';

class BulletinImagePicker extends StatefulWidget {
  const BulletinImagePicker({
    super.key,
    required this.draft,
    this.enabled = true,
    this.pickImages,
    this.onPickingChanged,
  });
  final BulletinImageDraft draft;
  final bool enabled;
  final Future<List<XFile>> Function(ImageSource source)? pickImages;
  final ValueChanged<bool>? onPickingChanged;
  @override
  State<BulletinImagePicker> createState() => _BulletinImagePickerState();
}

class _BulletinImagePickerState extends State<BulletinImagePicker> {
  bool _picking = false;
  ImageProvider _provider(BulletinImageAttachment image) =>
      image.bytes != null
          ? MemoryImage(image.bytes!)
          : NetworkImage(image.url!);

  Future<void> _addImages() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('写真をまとめて選択'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('カメラで撮影'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
    );
    if (source == null || !mounted) return;
    setState(() => _picking = true);
    widget.onPickingChanged?.call(true);
    try {
      final picker = ImagePicker();
      final remaining =
          BulletinImageDraft.maxImages - widget.draft.images.length;
      final files =
          widget.pickImages != null
              ? await widget.pickImages!(source)
              : source == ImageSource.camera
              ? [
                await picker.pickImage(
                  source: source,
                  maxWidth: 2048,
                  maxHeight: 2048,
                  imageQuality: 85,
                ),
              ].whereType<XFile>().toList()
              : await picker.pickMultiImage(
                maxWidth: 2048,
                maxHeight: 2048,
                imageQuality: 85,
              );
      final additions = <BulletinImageAttachment>[];
      for (final file in files.take(remaining)) {
        final bytes = await StorageUploadHelper.readValidatedXFileBytes(file);
        final mime =
            lookupMimeType(file.name, headerBytes: bytes) ?? 'image/jpeg';
        additions.add(
          BulletinImageAttachment(
            id: '${DateTime.now().microsecondsSinceEpoch}_${additions.length}',
            bytes: bytes,
            contentType: mime,
            extension: extensionFromMime(mime) ?? 'jpg',
          ),
        );
      }
      if (!mounted) return;
      widget.draft.add(additions);
      if (files.length > remaining) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('画像は最大10枚です。先頭から追加しました。')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('画像を選択できませんでした。写真のアクセス権と画像サイズ（1枚10MBまで）を確認してください。'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _picking = false);
        widget.onPickingChanged?.call(false);
      }
    }
  }

  Future<void> _editCrop() async {
    final cover = widget.draft.cover;
    if (cover == null) return;
    final crop = await showDialog<BulletinCrop>(
      context: context,
      builder:
          (_) => BulletinThumbnailEditor(
            image: _provider(cover),
            initialCrop: widget.draft.crop,
          ),
    );
    if (crop != null && mounted && widget.draft.coverId == cover.id) {
      widget.draft.setCrop(crop);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.draft,
    builder: (context, _) {
      final images = widget.draft.images;
      final cover = widget.draft.cover;
      final enabled = widget.enabled && !_picking;
      final colors = Theme.of(context).colorScheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '投稿画像 ${images.length}/${BulletinImageDraft.maxImages}枚',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (images.isNotEmpty) ...[
            const Text('画像をタップしてサムネイルに設定。長押しで並べ替えできます。'),
            const SizedBox(height: 8),
            SizedBox(
              height: 130,
              child: ReorderableListView(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                onReorderItem: (oldIndex, newIndex) {
                  if (enabled) widget.draft.reorder(oldIndex, newIndex);
                },
                children: [
                  for (var i = 0; i < images.length; i++)
                    ReorderableDelayedDragStartListener(
                      key: ValueKey(images[i].id),
                      index: i,
                      enabled: enabled,
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Material(
                                color: colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap:
                                      enabled
                                          ? () => widget.draft.selectCover(
                                            images[i].id,
                                          )
                                          : null,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Image(
                                          image: _provider(images[i]),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder:
                                              (_, __, ___) => const Icon(
                                                Icons.broken_image_outlined,
                                              ),
                                        ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(5),
                                        color:
                                            images[i].id == widget.draft.coverId
                                                ? colors.primaryContainer
                                                : colors
                                                    .surfaceContainerHighest,
                                        child: Text(
                                          images[i].id == widget.draft.coverId
                                              ? 'サムネイル'
                                              : '${i + 1}枚目',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color:
                                                images[i].id ==
                                                        widget.draft.coverId
                                                    ? colors.onPrimaryContainer
                                                    : colors.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: IconButton.filled(
                                tooltip: '${i + 1}枚目を削除',
                                onPressed:
                                    enabled
                                        ? () =>
                                            widget.draft.remove(images[i].id)
                                        : null,
                                icon: const Icon(Icons.close, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed:
                enabled && images.length < BulletinImageDraft.maxImages
                    ? _addImages
                    : null,
            icon:
                _picking
                    ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_picking ? '画像を読み込み中…' : '画像を追加'),
          ),
          if (cover != null) ...[
            const SizedBox(height: 12),
            Text('一覧のサムネイル', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            InkWell(
              onTap: enabled ? _editCrop : null,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BulletinThumbnail(
                    image: _provider(cover),
                    crop: widget.draft.crop,
                  ),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: enabled ? _editCrop : null,
              icon: const Icon(Icons.crop),
              label: const Text('表示範囲を調整'),
            ),
          ],
        ],
      );
    },
  );
}
