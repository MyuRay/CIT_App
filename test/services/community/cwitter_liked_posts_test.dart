import 'package:cit_app/services/community/cwitter_liked_posts_reader.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'deleted posts do not break like history and like order survives batching',
    () async {
      final db = FakeFirebaseFirestore();
      for (var i = 0; i < 35; i++) {
        await db.doc('users/u/cwitter_likes/p$i').set({
          'likedAt': Timestamp.fromMillisecondsSinceEpoch(i * 1000),
        });
        if (i != 33) await db.doc('cwitter_posts/p$i').set({'body': '投稿$i'});
      }
      final posts = await CwitterLikedPostsReader(db).watch('u').first;
      expect(posts, hasLength(34));
      expect(posts.first.id, 'p34');
      expect(posts[1].id, 'p32');
      expect(posts.last.id, 'p0');
    },
  );
  test('a user with no likes returns an empty list', () async {
    expect(
      await CwitterLikedPostsReader(FakeFirebaseFirestore()).watch('u').first,
      isEmpty,
    );
  });
}
