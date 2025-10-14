import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/cafeteria_review_provider.dart';
import '../../core/providers/cafeteria_menu_provider.dart';
import '../../models/cafeteria/cafeteria_review_model.dart';
import '../../models/cafeteria/cafeteria_menu_item_model.dart';
import 'cafeteria_review_form_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CafeteriaMenuReviewsScreen extends ConsumerWidget {
  const CafeteriaMenuReviewsScreen({
    super.key,
    required this.cafeteriaId,
    required this.menuName,
  });

  final String cafeteriaId;
  final String menuName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(cafeteriaReviewsProvider(cafeteriaId));
    final itemsAsync = ref.watch(cafeteriaMenuItemsProvider(cafeteriaId));

    return reviewsAsync.when(
      data: (reviews) {
        final normalized = menuName.trim().toLowerCase();
        final filtered = reviews
            .where((r) => (r.menuName ?? '').trim().toLowerCase() == normalized)
            .toList();

        final currentUser = FirebaseAuth.instance.currentUser;
        final existing = currentUser == null
            ? null
            : filtered.cast<CafeteriaReview?>().firstWhere(
                  (r) => r?.userId == currentUser.uid,
                  orElse: () => null,
                );

        // Aggregates
        final count = filtered.length;
        final double avgTaste = count == 0
            ? 0.0
            : filtered.map((e) => e.taste).reduce((a, b) => a + b) / count;
        final double avgVolume = count == 0
            ? 0.0
            : filtered.map((e) => e.volume).reduce((a, b) => a + b) / count;
        final double avgRecommend = count == 0
            ? 0.0
            : filtered.map((e) => e.recommend).reduce((a, b) => a + b) / count;

        // Gender-based volume averages
        final male = filtered.where((r) => r.volumeGender == 'male').toList();
        final female = filtered.where((r) => r.volumeGender == 'female').toList();
        final double avgVolumeMale = male.isEmpty
            ? 0.0
            : male.map((e) => e.volume).reduce((a, b) => a + b) / male.length;
        final double avgVolumeFemale = female.isEmpty
            ? 0.0
            : female.map((e) => e.volume).reduce((a, b) => a + b) / female.length;

        CafeteriaMenuItem? menuItem;
        itemsAsync.whenData((map) {
          menuItem = map[normalized];
        });

        return Scaffold(
          appBar: AppBar(
            title: Text(menuName),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CafeteriaReviewFormScreen(
                    initialCafeteriaId: cafeteriaId,
                    initialMenuName: menuName,
                    fixed: true,
                    editingReview: existing,
                  ),
                ),
              );
              if (result == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(existing == null ? 'レビューを投稿しました' : 'レビューを更新しました')),
                );
              }
            },
            icon: const Icon(Icons.rate_review),
            label: Text(existing == null ? '${menuName}のレビューを作成' : '${menuName}のレビューを編集'),
          ),
          body: Column(
            children: [
              _Header(
                cafeteriaId: cafeteriaId,
                menuName: menuName,
                menuItem: menuItem,
                avgTaste: avgTaste,
                avgVolume: avgVolume,
                avgRecommend: avgRecommend,
                avgVolumeMale: avgVolumeMale,
                avgVolumeFemale: avgVolumeFemale,
                count: count,
              ),
              const Divider(height: 0),
              Expanded(
                child: count == 0
                    ? const Center(child: Text('まだレビューがありません'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _ReviewCard(review: filtered[index]),
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('レビューの読み込みに失敗しました: $e'))),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.cafeteriaId,
    required this.menuName,
    required this.menuItem,
    required this.avgTaste,
    required this.avgVolume,
    required this.avgRecommend,
    required this.avgVolumeMale,
    required this.avgVolumeFemale,
    required this.count,
  });

  final String cafeteriaId;
  final String menuName;
  final CafeteriaMenuItem? menuItem;
  final double avgTaste;
  final double avgVolume;
  final double avgRecommend;
  final double avgVolumeMale;
  final double avgVolumeFemale;
  final int count;

  String _formatPrice(int? p) => p == null ? '価格未設定' : '¥${p.toString()}';

  @override
  Widget build(BuildContext context) {
    final placeholder = menuName.isNotEmpty ? menuName.substring(0, 1) : '?';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Big image at the very top
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: GestureDetector(
              onTap: () => _openFullScreenImage(
                context,
                placeholder: placeholder,
                imageUrl: menuItem?.photoUrl,
              ),
              child: Hero(
                tag: menuItem?.photoUrl ?? placeholder,
                child: _buildMenuImage(
                  imageUrl: menuItem?.photoUrl,
                  placeholder: placeholder,
                  fontSize: 64,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            menuName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          count == 0 ? 'レビューなし' : '(${count}件)',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatPrice(menuItem?.price),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(Cafeterias.displayName(cafeteriaId), style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              _AverageRow(label: 'おすすめ', rating: avgRecommend),
              const SizedBox(height: 8),
              _AverageRow(label: '美味しさ', rating: avgTaste),
              const SizedBox(height: 8),
              _AverageRow(label: '量（男性）', rating: avgVolumeMale),
              const SizedBox(height: 8),
              _AverageRow(label: '量（女性）', rating: avgVolumeFemale),
            ],
          ),
        ),
      ],
    );
  }
}

class _AverageRow extends StatelessWidget {
  const _AverageRow({required this.label, required this.rating});
  final String label;
  final double rating; // 0..5

  @override
  Widget build(BuildContext context) {
    // Compute description based on label and rounded rating
    final r = rating.clamp(0, 5).round();
    String desc = '';
    Color? chipBg;
    Color? chipFg;

    String tasteDesc(int v) {
      switch (v) {
        case 1:
          return 'イマイチ';
        case 2:
          return 'もう少し';
        case 3:
          return '普通';
        case 4:
          return '美味しい';
        case 5:
          return 'とても美味しい';
        default:
          return '';
      }
    }

    String recommendDesc(int v) {
      switch (v) {
        case 1:
          return 'おすすめしない';
        case 2:
          return 'あまりおすすめしない';
        case 3:
          return '普通';
        case 4:
          return 'おすすめ';
        case 5:
          return 'とてもおすすめ';
        default:
          return '';
      }
    }

    String volumeDesc(int v) {
      switch (v) {
        case 1:
          return '少ない';
        case 2:
          return 'やや少ない';
        case 3:
          return '適量';
        case 4:
          return 'やや多い';
        case 5:
          return '多い';
        default:
          return '';
      }
    }

    Color volumeColor(BuildContext context, int v) {
      switch (v) {
        case 1:
        case 2:
          return Colors.orange;
        case 3:
          return Colors.green;
        case 4:
        case 5:
          return Colors.blue;
        default:
          return Theme.of(context).colorScheme.surfaceVariant;
      }
    }

    if (r > 0) {
      if (label.contains('量')) {
        desc = volumeDesc(r);
        chipBg = volumeColor(context, r);
        chipFg = Colors.white;
      } else if (label == '美味しさ') {
        desc = tasteDesc(r);
      } else if (label == 'おすすめ') {
        desc = recommendDesc(r);
      }
    }

    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        _Stars(rating: rating.clamp(0, 5).toDouble()),
        const SizedBox(width: 8),
        Text(
          rating == 0 ? '-' : '${rating.toStringAsFixed(1)}/5',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        if (desc.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: chipBg ?? Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              desc,
              style: TextStyle(
                fontSize: 11,
                color: chipFg ?? Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});
  final double rating; // 0..5

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final hasHalf = (rating - full) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          if (i < full) {
            return const Icon(Icons.star, size: 16, color: Colors.amber);
          } else if (i == full && hasHalf) {
            return const Icon(Icons.star_half, size: 16, color: Colors.amber);
          } else {
            return Icon(Icons.star_border, size: 16, color: Colors.grey.shade400);
          }
        }),
      ],
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.review});
  final CafeteriaReview review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnReview = currentUser != null && currentUser.uid == review.userId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上段: 左に人アイコン＋表示名、右に投稿日
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    review.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(review.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),

            if (review.comment != null && review.comment!.isNotEmpty) ...[
              Text(review.comment!),
              const SizedBox(height: 6),
            ],
            Row(
              children: [
                const SizedBox(width: 60, child: Text('美味しさ', style: TextStyle(fontSize: 12, color: Colors.grey))),
                ...List.generate(5, (i) => Icon(
                      i < review.taste ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    )),
                const SizedBox(width: 8),
                Text('${review.taste}/5', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const SizedBox(width: 60, child: Text('量', style: TextStyle(fontSize: 12, color: Colors.grey))),
                ...List.generate(5, (i) {
                  final on = i < review.volume;
                  Color starColor;
                  if (i == 2) {
                    starColor = on ? Colors.green : Colors.grey.shade400;
                  } else if (i < 2) {
                    starColor = on ? Colors.orange : Colors.grey.shade400;
                  } else {
                    starColor = on ? Colors.blue : Colors.grey.shade400;
                  }
                  return Icon(Icons.star, color: starColor, size: 18);
                }),
                const SizedBox(width: 8),
                Text('${review.volume}/5', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                // 量のみ説明を表示
                if (review.volume > 0) ...[
                  const SizedBox(width: 8),
                  _VolumeDescriptionChip(value: review.volume),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const SizedBox(width: 60, child: Text('おすすめ', style: TextStyle(fontSize: 12, color: Colors.grey))),
                ...List.generate(5, (i) => Icon(
                      i < review.recommend ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    )),
                const SizedBox(width: 8),
                Text('${review.recommend}/5', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                
              ],
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';
    return '${d.month}/${d.day}';
  }
}

// いいね（グッド）関連UIは削除しました

// ==== Image viewer helpers (copied to match review cards) ====
Widget _buildMenuImage({String? imageUrl, required String placeholder, double fontSize = 28}) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Text(
          placeholder,
          style: TextStyle(fontSize: fontSize, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
  return CachedNetworkImage(
    imageUrl: imageUrl,
    fit: BoxFit.cover,
    placeholder: (context, url) => Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    ),
    errorWidget: (context, url, error) => Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(Icons.broken_image_outlined, size: fontSize + 4, color: Colors.grey.shade500),
      ),
    ),
  );
}

class _VolumeDescriptionChip extends StatelessWidget {
  const _VolumeDescriptionChip({required this.value});
  final int value; // 1..5

  String _desc(int v) {
    switch (v) {
      case 1:
        return '少ない';
      case 2:
        return 'やや少ない';
      case 3:
        return '適量';
      case 4:
        return 'やや多い';
      case 5:
        return '多い';
      default:
        return '';
    }
  }

  Color _color(int v) {
    switch (v) {
      case 1:
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      case 4:
      case 5:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _desc(value);
    if (text.isEmpty) return const SizedBox.shrink();
    final bg = _color(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _FullScreenImagePage extends StatefulWidget {
  const _FullScreenImagePage({required this.imageUrl, required this.placeholder, super.key});

  final String? imageUrl;
  final String placeholder;

  @override
  State<_FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<_FullScreenImagePage> {
  double _dragOffset = 0;
  bool _isDismissing = false;

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDismissing) return;
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragOffset.abs() > 120 || velocity.abs() > 700) {
      _isDismissing = true;
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - (_dragOffset.abs() / 400)).clamp(0.3, 1.0).toDouble();
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(opacity),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        child: Center(
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Hero(
              tag: widget.imageUrl ?? widget.placeholder,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.0,
                child: _buildMenuImage(
                  imageUrl: widget.imageUrl,
                  placeholder: widget.placeholder,
                  fontSize: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _openFullScreenImage(BuildContext context, {required String placeholder, String? imageUrl}) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _FullScreenImagePage(
        imageUrl: imageUrl,
        placeholder: placeholder,
      ),
    ),
  );
}
