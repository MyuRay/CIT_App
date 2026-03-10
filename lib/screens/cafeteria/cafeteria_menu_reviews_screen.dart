import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/cafeteria_review_provider.dart';
import '../../core/providers/cafeteria_menu_provider.dart';
import '../../models/cafeteria/cafeteria_review_model.dart';
import '../../models/cafeteria/cafeteria_menu_item_model.dart';
import 'cafeteria_review_form_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/cafeteria_favorite_provider.dart';
import '../../services/cafeteria/cafeteria_favorite_service.dart';

class CafeteriaMenuReviewsScreen extends ConsumerStatefulWidget {
  const CafeteriaMenuReviewsScreen({
    super.key,
    required this.cafeteriaId,
    required this.menuName,
  });

  final String cafeteriaId;
  final String menuName;

  @override
  ConsumerState<CafeteriaMenuReviewsScreen> createState() => _CafeteriaMenuReviewsScreenState();
}

class _CafeteriaMenuReviewsScreenState extends ConsumerState<CafeteriaMenuReviewsScreen> {
  Offset? _fabPosition;
  bool _isDragging = false;
  final GlobalKey _fabKey = GlobalKey();
  Size? _fabSize; // ボタンの実際のサイズを保持
  
  Offset _getDefaultPosition(Size bodySize, EdgeInsets padding, Size? fabSize) {
    // FloatingActionButtonのデフォルト位置（右下）
    const buttonPadding = 16.0;
    
    // ボタンのサイズを取得（未測定の場合は推定サイズを使用）
    final fabWidth = fabSize?.width ?? 240.0;
    final fabHeight = fabSize?.height ?? 56.0;
    
    // 右端を画面の右端に合わせて位置を計算
    double left = bodySize.width - fabWidth - buttonPadding - padding.right;
    
    // 左端が画面外に出る場合は、右端を画面の右端に合わせる
    if (left < padding.left) {
      left = bodySize.width - fabWidth - padding.right;
    }
    
    // 下の位置
    final top = bodySize.height - fabHeight - buttonPadding - padding.bottom;
    
    return Offset(left, top);
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size bodySize, EdgeInsets padding) {
    setState(() {
      final currentPosition = _fabPosition ?? _getDefaultPosition(bodySize, padding, _fabSize);
      final newPosition = currentPosition + details.delta;
      
      // ボタンのサイズを取得（未測定の場合は推定サイズを使用）
      final fabWidth = _fabSize?.width ?? 240.0;
      final fabHeight = _fabSize?.height ?? 56.0;
      const buttonPadding = 16.0;
      
      // 位置を計算（右端が画面外に出ないように）
      double left = newPosition.dx.clamp(padding.left, bodySize.width - fabWidth - padding.right);
      
      // 右端が画面外に出る場合は、右端を画面の右端に合わせる
      if (left + fabWidth + padding.right > bodySize.width) {
        left = bodySize.width - fabWidth - padding.right;
      }
      
      _fabPosition = Offset(
        left,
        newPosition.dy.clamp(padding.top, bodySize.height - fabHeight - buttonPadding - padding.bottom),
      );
    });
  }
  
  // ボタンのサイズを測定
  void _measureFabSize(Size bodySize, EdgeInsets padding) {
    if (_fabKey.currentContext != null) {
      final RenderBox? renderBox = _fabKey.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null && mounted) {
        final newSize = renderBox.size;
        // サイズが変更された場合のみ更新
        if (_fabSize != newSize) {
          setState(() {
            _fabSize = newSize;
            // サイズが測定された後、位置を再計算して右端に合わせる
            if (_fabPosition == null) {
              _fabPosition = _getDefaultPosition(bodySize, padding, newSize);
            }
          });
        }
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(cafeteriaReviewsProvider(widget.cafeteriaId));
    final itemsAsync = ref.watch(cafeteriaMenuItemsProvider(widget.cafeteriaId));

    return reviewsAsync.when(
      data: (reviews) {
        final normalized = widget.menuName.trim().toLowerCase();
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
            title: Text(widget.menuName),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final mediaQuery = MediaQuery.of(context);
              final bodySize = Size(constraints.maxWidth, constraints.maxHeight);
              final safePadding = mediaQuery.padding;
              
              // ボタンのサイズを測定（初回のみ）
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _measureFabSize(bodySize, safePadding);
              });
              
              // 位置を計算（サイズが測定済みの場合はそれを使用）
              final fabWidth = _fabSize?.width ?? 240.0;
              final fabHeight = _fabSize?.height ?? 56.0;
              final currentPosition = _fabPosition ?? _getDefaultPosition(bodySize, safePadding, _fabSize);
              
              // 右端が画面外に出る場合は、右端を画面の右端に合わせる
              double finalLeft = currentPosition.dx;
              final rightEdge = finalLeft + fabWidth;
              final maxRight = bodySize.width - safePadding.right;
              
              if (rightEdge > maxRight) {
                finalLeft = maxRight - fabWidth;
              }
              
              // 左端も画面内に収める
              finalLeft = finalLeft.clamp(safePadding.left, bodySize.width - fabWidth - safePadding.right);
              
              return Stack(
                children: [
                  Column(
                    children: [
                      _Header(
                        cafeteriaId: widget.cafeteriaId,
                        menuName: widget.menuName,
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
                  // ドラッグ可能なFloatingActionButton
                  Positioned(
                    left: finalLeft,
                    top: currentPosition.dy,
                    child: GestureDetector(
                      key: _fabKey,
                      onPanStart: _onPanStart,
                      onPanUpdate: (details) => _onPanUpdate(details, bodySize, safePadding),
                      onPanEnd: _onPanEnd,
                      child: Material(
                        elevation: _isDragging ? 8 : 6,
                        borderRadius: BorderRadius.circular(28),
                        color: Theme.of(context).colorScheme.secondary,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: _isDragging ? null : () async {
                            final result = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => CafeteriaReviewFormScreen(
                                  initialCafeteriaId: widget.cafeteriaId,
                                  initialMenuName: widget.menuName,
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.rate_review, color: Colors.white),
                                const SizedBox(width: 8),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: bodySize.width * 0.6, // 画面幅の60%を最大幅とする
                                  ),
                                  child: Text(
                                    existing == null 
                                        ? '${widget.menuName}のレビューを作成' 
                                        : '${widget.menuName}のレビューを編集',
                                    style: const TextStyle(color: Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          count == 0 ? 'レビューなし' : '(${count}件)',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatPrice(menuItem?.price),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (FirebaseAuth.instance.currentUser != null) ...[
                    const SizedBox(width: 8),
                    _FavoriteButton(
                      cafeteriaId: cafeteriaId,
                      menuItem: menuItem,
                      menuName: menuName,
                    ),
                  ],
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
  late final TransformationController _transformationController;
  double _currentScale = 1.0; // 現在のスケールを追跡
  static const double _zoomedScale = 2.5;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    // スケール変更を監視
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (_currentScale != scale) {
      setState(() {
        _currentScale = scale;
        // スケールが1.0に戻ったら、ドラッグオフセットもリセット
        if (scale <= 1.0 && _dragOffset != 0) {
          _dragOffset = 0;
        }
      });
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final isCurrentlyZoomed = scale > 1.1;

    if (isCurrentlyZoomed) {
      // 拡大中の場合、元のサイズに戻す
      _transformationController.value = Matrix4.identity();
    } else {
      // 縮小時の場合、タップした位置を中心に拡大（X風の挙動）
      final tapPosition = details.localPosition;
      final translationCorrection = _zoomedScale - 1;

      _transformationController.value = Matrix4.identity()
        ..translate(
          -tapPosition.dx * translationCorrection,
          -tapPosition.dy * translationCorrection,
        )
        ..scale(_zoomedScale);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    // 拡大中（スケール > 1.0）の場合は画面を閉じない
    if (_currentScale > 1.0) return;
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDismissing) return;
    // 拡大中（スケール > 1.0）の場合は画面を閉じない
    if (_currentScale > 1.0) {
      setState(() {
        _dragOffset = 0;
      });
      return;
    }
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
    // 拡大中（スケール > 1.0）の場合は画面を閉じない
    final bool canDismiss = _currentScale <= 1.0;
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(opacity),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canDismiss ? () => Navigator.of(context).pop() : null,
        onVerticalDragUpdate: canDismiss ? _handleDragUpdate : null,
        onVerticalDragEnd: canDismiss ? _handleDragEnd : null,
        child: Center(
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Hero(
              tag: widget.imageUrl ?? widget.placeholder,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTapDown: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.8,
                  maxScale: 3.0,
                  panEnabled: true, // パン（ドラッグ）を有効化
                  scaleEnabled: true, // スケール（ピンチ）を有効化
                  boundaryMargin: const EdgeInsets.all(double.infinity), // 境界マージンを設定
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
      ),
    );
  }
}

class _FavoriteButton extends ConsumerStatefulWidget {
  const _FavoriteButton({
    required this.cafeteriaId,
    required this.menuItem,
    required this.menuName,
  });

  final String cafeteriaId;
  final CafeteriaMenuItem? menuItem;
  final String menuName;

  @override
  ConsumerState<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<_FavoriteButton> {
  Future<void> _toggleFavorite() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインが必要です')),
        );
      }
      return;
    }

    try {
      if (widget.menuItem != null && widget.menuItem!.id.isNotEmpty) {
        final isFavorite = await CafeteriaFavoriteService.isFavorite(
          userId: uid,
          type: 'menu',
          menuItemId: widget.menuItem!.id,
        );
        if (isFavorite) {
          await CafeteriaFavoriteService.removeFavorite(
            userId: uid,
            type: 'menu',
            menuItemId: widget.menuItem!.id,
          );
          if (mounted) {
            ref.invalidate(isMenuFavoriteProvider(widget.menuItem!.id));
            ref.invalidate(userCafeteriaFavoritesProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('お気に入りから削除しました')),
            );
          }
        } else {
          await CafeteriaFavoriteService.addFavorite(
            userId: uid,
            type: 'menu',
            cafeteriaId: widget.cafeteriaId,
            menuItemId: widget.menuItem!.id,
            menuName: widget.menuName,
          );
          if (mounted) {
            ref.invalidate(isMenuFavoriteProvider(widget.menuItem!.id));
            ref.invalidate(userCafeteriaFavoritesProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('お気に入りに追加しました')),
            );
          }
        }
      } else {
        await CafeteriaFavoriteService.addFavorite(
          userId: uid,
          type: 'menu',
          cafeteriaId: widget.cafeteriaId,
          menuName: widget.menuName,
        );
        if (mounted) {
          ref.invalidate(userCafeteriaFavoritesProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('お気に入りに追加しました')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const SizedBox.shrink();
    }

    final isFavoriteAsync = widget.menuItem != null && widget.menuItem!.id.isNotEmpty
        ? ref.watch(isMenuFavoriteProvider(widget.menuItem!.id))
        : null;

    return IconButton(
      icon: isFavoriteAsync != null
          ? isFavoriteAsync.when(
              data: (isFavorite) => Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey,
              ),
              loading: () => const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const Icon(
                Icons.favorite_border,
                color: Colors.grey,
              ),
            )
          : const Icon(
              Icons.favorite_border,
              color: Colors.grey,
            ),
      onPressed: _toggleFavorite,
      tooltip: 'お気に入り',
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
