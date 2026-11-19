import 'dart:async';
import '../../core/providers/in_app_ad_provider.dart';
import '../../core/providers/analytics_provider.dart';
import '../../services/ads/ad_event_service.dart';
import 'ad_slot_position.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/analytics_service.dart';
import '../../models/ads/in_app_ad_model.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../screens/bulletin/bulletin_post_detail_screen.dart';
import '../../core/providers/bulletin_provider.dart';
import 'in_app_ad_creative.dart';

class InAppAdCard extends ConsumerStatefulWidget {
  const InAppAdCard({
    super.key,
    required this.ad,
    required this.placement,
    this.margin,
    this.slotIndex,
  });

  final InAppAd ad;
  final AdPlacement placement;
  final EdgeInsetsGeometry? margin;
  final int? slotIndex;

  @override
  ConsumerState<InAppAdCard> createState() => _InAppAdCardState();
}

class _InAppAdCardState extends ConsumerState<InAppAdCard> {
  bool _impressionLogged = false;
  Timer? _visibilityTimer;
  @override
  void dispose() {
    _visibilityTimer?.cancel();
    super.dispose();
  }

  void _record(String kind) {
    if (!ref.read(analyticsCollectionEnabledProvider)) return;
    final AdEventService service;
    try {
      service = ref.read(adEventServiceProvider);
    } catch (_) {
      return;
    }
    final grade = service.viewerGrade;
    if (!widget.ad.matchesGrade(grade)) return;
    final slot = widget.slotIndex ?? AdSlotPosition.of(context);
    try {
      unawaited(
        service
            .record(
              ad: widget.ad,
              placement: widget.placement,
              grade: grade,
              kind: kind,
              slotIndex: slot,
            )
            .catchError((Object _) {}),
      );
    } catch (_) {
      /* Recording must never block the ad destination. */
    }
    try {
      unawaited(
        ref
            .read(analyticsServiceProvider)
            .logEvent(
              'in_app_ad_$kind',
              parameters: {
                'ad_id': widget.ad.id,
                'placement': widget.placement.name,
                'action_type': widget.ad.actionType.name,
                'grade': grade,
                'slot_index': slot,
              },
            )
            .catchError((Object _) {}),
      );
    } catch (_) {
      /* SDK initialization can fail independently of Firestore. */
    }
  }

  @override
  void didUpdateWidget(covariant InAppAdCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ad.id != widget.ad.id ||
        oldWidget.placement != widget.placement) {
      _impressionLogged = false;
      _visibilityTimer?.cancel();
      _visibilityTimer = null;
      _logImpressionIfNeeded();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logImpressionIfNeeded();
  }

  void _logImpressionIfNeeded() {
    if (_impressionLogged) return;
    void check() {
      if (!mounted || _impressionLogged) return;
      if (!TickerMode.valuesOf(context).enabled ||
          ModalRoute.of(context)?.isCurrent != true ||
          (WidgetsBinding.instance.lifecycleState != null &&
              WidgetsBinding.instance.lifecycleState !=
                  AppLifecycleState.resumed)) {
        return;
      }
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      var viewport = Offset.zero & MediaQuery.sizeOf(context);
      final scrollBox = Scrollable.maybeOf(context)?.context.findRenderObject();
      if (scrollBox is RenderBox && scrollBox.hasSize) {
        viewport = viewport.intersect(
          scrollBox.localToGlobal(Offset.zero) & scrollBox.size,
        );
      }
      final visible = rect.intersect(viewport);
      if (visible.isEmpty ||
          visible.width * visible.height < rect.width * rect.height * .5) {
        return;
      }
      if (!widget.ad.matchesGrade(ref.read(adViewerGradeProvider)) ||
          !widget.ad.isEligible(DateTime.now())) {
        return;
      }
      final hit = HitTestResult();
      WidgetsBinding.instance.hitTestInView(
        hit,
        visible.center,
        View.of(context).viewId,
      );
      if (!hit.path.any((entry) => identical(entry.target, box))) return;
      _impressionLogged = true;
      _visibilityTimer?.cancel();
      _record('impression');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => check());
    _visibilityTimer ??= Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => check(),
    );
  }

  Future<void> _onTap() async {
    if (!widget.ad.matchesGrade(ref.read(adViewerGradeProvider)) ||
        !widget.ad.isEligible(DateTime.now())) {
      return;
    }
    debugPrint(
      '🔸 Ad tapped | id=${widget.ad.id}, action=${widget.ad.actionType}, payload=${widget.ad.actionPayload}',
    );

    try {
      _record('click');

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
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
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
    if (!widget.ad.matchesGrade(ref.watch(adViewerGradeProvider))) {
      return const SizedBox.shrink();
    }
    return InAppAdCreative(ad: widget.ad, margin: widget.margin, onTap: _onTap);
  }
}
