import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/bulletin/bulletin_model.dart';

class BulletinFeedBatch {
  const BulletinFeedBatch({required this.posts, required this.hasMore});
  final List<BulletinPost> posts;
  final bool hasMore;
}

class BulletinFeedService {
  BulletinFeedService(this.firestore);
  final FirebaseFirestore firestore;

  /// Pinned posts have their own uncapped query. The recent-post window grows
  /// on demand, so live edits cannot leave gaps between old pagination cursors.
  Stream<BulletinFeedBatch> watchFeed({required int recentLimit}) {
    assert(recentLimit > 0);
    return Stream.multi((controller) {
      QuerySnapshot<Map<String, dynamic>>? recent;
      QuerySnapshot<Map<String, dynamic>>? pinned;
      Timer? expiryTimer;
      var cancelled = false;

      void emit() {
        if (cancelled || recent == null || pinned == null) return;
        expiryTimer?.cancel();
        final now = DateTime.now();
        final posts = <String, BulletinPost>{};
        for (final doc in [
          // Never resurrect a stale pinned copy from the recent-post query.
          ...recent!.docs
              .take(recentLimit)
              .where((doc) => doc.data()['isPinned'] != true),
          ...pinned!.docs,
        ]) {
          try {
            final post = BulletinPost.fromJson({...doc.data(), 'id': doc.id});
            if (post.isPublishedAt(now)) posts[post.id] = post;
          } catch (_) {
            // A malformed document must not prevent the remaining feed loading.
          }
        }
        final sorted =
            posts.values.toList()..sort((a, b) {
              if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
              final date = b.createdAt.compareTo(a.createdAt);
              return date != 0 ? date : b.id.compareTo(a.id);
            });
        controller.add(
          BulletinFeedBatch(
            posts: List.unmodifiable(sorted),
            hasMore: recent!.docs.length > recentLimit,
          ),
        );

        // Expiry is time-based; it need not produce a Firestore update.
        DateTime? nextExpiry;
        for (final post in sorted) {
          final expiry = post.expiresAt;
          if (expiry != null &&
              (nextExpiry == null || expiry.isBefore(nextExpiry))) {
            nextExpiry = expiry;
          }
        }
        if (nextExpiry != null) {
          expiryTimer = Timer(nextExpiry.difference(now), emit);
        }
      }

      final collection = firestore.collection('bulletin_posts');
      final subscriptions = [
        collection
            .where('approvalStatus', isEqualTo: 'approved')
            .orderBy('createdAt', descending: true)
            .limit(recentLimit + 1)
            .snapshots()
            .listen(
              (snapshot) {
                recent = snapshot;
                emit();
              },
              onError: (Object error, StackTrace stack) {
                if (cancelled) return;
                recent = null;
                expiryTimer?.cancel();
                controller.addError(error, stack);
              },
            ),
        // One equality filter uses the existing single-field index; no new
        // composite-index deployment is required for old pinned posts.
        collection
            .where('isPinned', isEqualTo: true)
            .snapshots()
            .listen(
              (snapshot) {
                pinned = snapshot;
                emit();
              },
              onError: (Object error, StackTrace stack) {
                if (cancelled) return;
                pinned = null;
                expiryTimer?.cancel();
                controller.addError(error, stack);
              },
            ),
      ];
      controller.onCancel = () async {
        cancelled = true;
        expiryTimer?.cancel();
        await Future.wait(
          subscriptions.map((subscription) => subscription.cancel()),
        );
      };
    });
  }
}
