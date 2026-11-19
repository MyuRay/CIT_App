import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/community/cwitter_post.dart';

/// Read liked posts in batches. Deleted or uncached single posts must not fail
/// the entire history, and results retain the order of the like timestamps.
class CwitterLikedPostsReader {
  CwitterLikedPostsReader(this.firestore);
  final FirebaseFirestore firestore;
  Stream<List<CwitterPost>> watch(String uid, {int limit = 50}) => firestore
      .collection('users')
      .doc(uid)
      .collection('cwitter_likes')
      .orderBy('likedAt', descending: true)
      .limit(limit)
      .snapshots()
      .asyncMap((likes) async {
        if (likes.docs.isEmpty) return <CwitterPost>[];
        final ids = likes.docs.map((doc) => doc.id).toList();
        final posts = <String, CwitterPost>{};
        for (var offset = 0; offset < ids.length; offset += 30) {
          final query = firestore
              .collection('cwitter_posts')
              .where(
                FieldPath.documentId,
                whereIn: ids.skip(offset).take(30).toList(),
              );
          QuerySnapshot<Map<String, dynamic>>? snapshot;
          for (var attempt = 0; attempt < 3; attempt++) {
            try {
              snapshot = await query.get();
              break;
            } on FirebaseException catch (error) {
              if (!['unavailable', 'deadline-exceeded'].contains(error.code))
                rethrow;
              if (attempt < 2) {
                await Future<void>.delayed(
                  Duration(milliseconds: 250 * (attempt + 1)),
                );
              } else {
                final cached = await query.get(
                  const GetOptions(source: Source.cache),
                );
                if (cached.docs.isEmpty) rethrow;
                snapshot = cached;
              }
            }
          }
          for (final doc in snapshot!.docs) {
            posts[doc.id] = CwitterPost.fromFirestore(doc);
          }
        }
        return [
          for (final id in ids)
            if (posts.containsKey(id)) posts[id]!,
        ];
      });
}
