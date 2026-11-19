import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/contact_chat_provider.dart';

class ContactChatImage extends ConsumerStatefulWidget {
  const ContactChatImage({super.key, required this.userId, required this.path});
  final String userId, path;
  @override
  ConsumerState<ContactChatImage> createState() => _ContactChatImageState();
}

class _ContactChatImageState extends ConsumerState<ContactChatImage> {
  Future<Uint8List>? _bytes;
  @override
  Widget build(BuildContext context) {
    _bytes ??= ref
        .read(contactChatImageServiceProvider)
        .read(widget.userId, widget.path);
    return SizedBox(
      width: double.infinity,
      height: 188,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FutureBuilder<Uint8List>(
          future: _bytes,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _bytes = null),
                  icon: const Icon(Icons.refresh),
                  label: const Text('画像を再読み込み'),
                ),
              );
            final bytes = snapshot.data;
            if (bytes == null)
              return const Center(child: CircularProgressIndicator());
            return Semantics(
              label: '添付画像を拡大',
              button: true,
              child: InkWell(
                onTap:
                    () => showDialog<void>(
                      context: context,
                      builder:
                          (context) => Dialog.fullscreen(
                            backgroundColor: Colors.black,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: InteractiveViewer(
                                    minScale: 1,
                                    maxScale: 5,
                                    child: Image.memory(
                                      bytes,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (_, __, ___) => const Center(
                                            child: Text(
                                              '画像を表示できませんでした',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                                SafeArea(
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: IconButton(
                                      tooltip: '閉じる',
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.black54,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: 180,
                    errorBuilder:
                        (_, __, ___) =>
                            const Center(child: Text('画像を表示できませんでした')),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
