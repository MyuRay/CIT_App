import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/analytics_service.dart';
import '../../models/ads/in_app_ad_model.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../screens/bulletin/bulletin_post_detail_screen.dart';
import '../../core/providers/bulletin_provider.dart';

class InAppAdCard extends ConsumerStatefulWidget {
  const InAppAdCard({
    super.key,
    required this.ad,
    required this.placement,
    this.margin,
  });

  final InAppAd ad;
  final AdPlacement placement;
  final EdgeInsetsGeometry? margin;

  @override
  ConsumerState<InAppAdCard> createState() => _InAppAdCardState();
}

class _InAppAdCardState extends ConsumerState<InAppAdCard> {
  bool _impressionLogged = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logImpressionIfNeeded();
  }

  Future<void> _logImpressionIfNeeded() async {
    if (_impressionLogged) return;
    _impressionLogged = true;
    await ref
        .read(analyticsServiceProvider)
        .logEvent(
          'in_app_ad_impression',
          parameters: {
            'ad_id': widget.ad.id,
            'placement': widget.placement.name,
          },
        );
  }

  Future<void> _onTap() async {
    debugPrint(
      '🔸 Ad tapped | id=${widget.ad.id}, action=${widget.ad.actionType}, payload=${widget.ad.actionPayload}',
    );

    try {
      await ref
          .read(analyticsServiceProvider)
          .logEvent(
            'in_app_ad_click',
            parameters: {
              'ad_id': widget.ad.id,
              'placement': widget.placement.name,
              'action_type': widget.ad.actionType.name,
            },
          );

      debugPrint('🔸 Analytics logged, processing action...');

      switch (widget.ad.actionType) {
        case AdActionType.external:
          debugPrint('🔸 Opening external URL...');
          await _openExternalUrl(widget.ad.actionPayload);
          break;
        case AdActionType.bulletin:
          debugPrint('🔸 Opening bulletin post...');
          await _openBulletinPost(widget.ad.actionPayload);
          break;
      }

      debugPrint('🔸 Action completed');
    } catch (e, stackTrace) {
      debugPrint('🔸 Error in _onTap: $e');
      debugPrint('🔸 StackTrace: $stackTrace');
    }
  }

  Future<void> _openExternalUrl(String url) async {
    debugPrint('🌐 _openExternalUrl called with: $url');
    final uri = Uri.tryParse(url);
    if (uri == null) {
      debugPrint('🌐 URI parsing failed for: $url');
      _showMessage('リンクが無効です');
      return;
    }
    debugPrint('🌐 Parsed URI: $uri');
    debugPrint('🌐 Attempting to launch URL...');
    try {
      final result = await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('🌐 launchUrl result: $result');
      if (!result) {
        debugPrint('🌐 launchUrl returned false');
        _showMessage('リンクを開けませんでした');
      } else {
        debugPrint('🌐 URL launched successfully');
      }
    } catch (e) {
      debugPrint('🌐 Error launching URL: $e');
      _showMessage('リンクを開けませんでした: $e');
    }
  }

  Future<void> _openBulletinPost(String postId) async {
    debugPrint('📝 _openBulletinPost called with: "$postId"');
    final trimmed = postId.trim();
    if (trimmed.isEmpty) {
      debugPrint('📝 postId is empty after trim');
      _showMessage('掲示板投稿が見つかりませんでした');
      return;
    }
    debugPrint('📝 Trimmed postId: "$trimmed"');

    final navigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    debugPrint('📝 Navigators obtained');

    var dialogOpen = true;
    rootNavigator
        .push<void>(
          PageRouteBuilder(
            opaque: false,
            barrierDismissible: false,
            barrierColor: Colors.black45,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder:
                (_, __, ___) => const Material(
                  color: Colors.transparent,
                  child: Center(child: CircularProgressIndicator()),
                ),
          ),
        )
        .whenComplete(() => dialogOpen = false);

    void dismissLoader() {
      if (!mounted || !dialogOpen) return;
      rootNavigator.pop();
      dialogOpen = false;
    }

    try {
      debugPrint(
        '📝 Loading bulletin post payload="$postId" (trimmed="$trimmed")',
      );

      final post = await _resolveBulletinPost(trimmed);
      if (post == null) {
        dismissLoader();
        _showMessage('掲示板投稿が削除されています');
        return;
      }

      dismissLoader();
      if (!mounted) return;
      await navigator.push(
        MaterialPageRoute(builder: (_) => BulletinPostDetailScreen(post: post)),
      );
    } catch (e) {
      dismissLoader();
      _showMessage('掲示板投稿を開けませんでした: $e');
    }
  }

  Future<BulletinPost?> _resolveBulletinPost(String trimmed) async {
    BulletinPost? post;
    var targetPath = trimmed;
    if (!trimmed.contains('/')) {
      targetPath = 'bulletin_posts/$trimmed';
    }
    final id = targetPath.split('/').last;

    final postsState = ref.read(bulletinPostsProvider);
    if (postsState.hasValue) {
      try {
        post = postsState.value!.firstWhere((p) => p.id == id);
      } catch (_) {
        post = null;
      }
    }

    if (post == null) {
      final doc = await FirebaseFirestore.instance.doc(targetPath).get();
      final data = doc.data();
      if (doc.exists && data != null) {
        try {
          post = BulletinPost.fromJson({'id': doc.id, ...data});
        } catch (_) {
          post = null;
        }
      }
    }

    if (post != null) {
      debugPrint(
        '📌 Ad Bulletin Post resolved from provider | id=${post.id}, title=${post.title}, author=${post.authorName}',
      );
      return post;
    }

    final doc = await FirebaseFirestore.instance.doc(targetPath).get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      return null;
    }

    debugPrint(
      '📌 Ad Bulletin Post fetched from Firestore | id=${doc.id}, title=${data['title']}, author=${data['authorName']}, active=${data['isActive']}',
    );
    return BulletinPost.fromJson({'id': doc.id, ...data});
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🎨 Building InAppAdCard | id=${widget.ad.id}, title=${widget.ad.title}, action=${widget.ad.actionType}, payload=${widget.ad.actionPayload}',
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasImage =
        widget.ad.imageUrl != null && widget.ad.imageUrl!.trim().isNotEmpty;

    return Card(
      margin:
          widget.margin ??
          const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    widget.ad.imageUrl!.trim(),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        debugPrint('🖼️ Ad image loaded successfully | url=${widget.ad.imageUrl}');
                        return child;
                      }
                      debugPrint(
                        '🖼️ Ad image loading... | url=${widget.ad.imageUrl}, '
                        'downloaded=${loadingProgress.cumulativeBytesLoaded}, '
                        'total=${loadingProgress.expectedTotalBytes}',
                      );
                      return Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('❌ Ad image load error | url=${widget.ad.imageUrl}');
                      debugPrint('❌ Error: $error');
                      debugPrint('❌ StackTrace: $stackTrace');
                      return Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, size: 24),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '広告',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.ad.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.ad.body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.85,
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.primary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
