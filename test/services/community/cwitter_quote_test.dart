import 'package:cit_app/models/community/cwitter_post.dart';
import 'package:cit_app/services/community/cwitter_post_writer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  final now = DateTime(2026, 9, 30, 12);
  final limited = Exception('rate limit');
  Map<String, dynamic> post(String author, {String? quote}) => {
    'authorId': author,
    'authorEmail': '$author@chibatech.ac.jp',
    'cwitterId': author,
    'displayName': author,
    'body': 'コメント',
    'createdAt': Timestamp.fromDate(now),
    'replyCount': 0,
    'likeCount': 0,
    'recweetCount': 0,
    'likedBy': <String, dynamic>{},
    if (quote != null) 'quotedPostId': quote,
  };
  Future<void> write(String id, {String? quote, String? author = 'source'}) =>
      writeCwitterPost(
        firestore: db,
        postRef: db.doc('cwitter_posts/$id'),
        data: post('writer', quote: quote),
        now: now,
        rateLimitException: limited,
        quotedAuthorId: author,
      );

  setUp(() async {
    db = FakeFirebaseFirestore();
    await db.doc('cwitter_posts/original').set(post('source'));
  });

  test(
    'quote round trips independently from original content and identity',
    () async {
      await write('quote', quote: 'original');
      final snap = await db.doc('cwitter_posts/quote').get();
      final quote = CwitterPost.fromFirestore(snap);
      expect(quote.isQuote, isTrue);
      expect(quote.quotedPostId, 'original');
      expect(quote.authorId, 'writer');
      expect(quote.toJson()['quotedPostId'], 'original');
      expect(snap.data()!.containsKey('quotedPost'), isFalse);
      expect(
        (await db.doc('cwitter_posts/original').get()).data(),
        post('source'),
      );
      expect(
        (await db.doc('users/writer/rate_limits/cwitter_post').get())
            .data()!['count'],
        1,
      );
    },
  );

  test('legacy posts still parse and serialize without a quote', () async {
    final legacy = CwitterPost.fromFirestore(
      await db.doc('cwitter_posts/original').get(),
    );
    expect(legacy.isQuote, isFalse);
    expect(legacy.toJson().containsKey('quotedPostId'), isFalse);
  });

  test('a source deleted after the composer opened cannot be quoted', () async {
    await db.doc('cwitter_posts/original').delete();
    await expectLater(
      write('quote', quote: 'original'),
      throwsA(isA<CwitterQuoteUnavailableException>()),
    );
    expect((await db.doc('cwitter_posts/quote').get()).exists, isFalse);
    expect(
      (await db.doc('users/writer/rate_limits/cwitter_post').get()).exists,
      isFalse,
    );
  });

  test(
    'a changed source owner invalidates the earlier visibility check',
    () async {
      await db.doc('cwitter_posts/original').update({'authorId': 'different'});
      await expectLater(
        write('quote', quote: 'original'),
        throwsA(isA<CwitterQuoteUnavailableException>()),
      );
      expect((await db.doc('cwitter_posts/quote').get()).exists, isFalse);
    },
  );

  test('regular posts and quotes share the same posting limit', () async {
    await write('plain');
    await write('quote', quote: 'original');
    await expectLater(
      write('third', quote: 'original'),
      throwsA(same(limited)),
    );
    expect((await db.doc('cwitter_posts/third').get()).exists, isFalse);
    expect(
      (await db.doc('users/writer/rate_limits/cwitter_post').get())
          .data()!['count'],
      2,
    );
  });

  test('deleting a quote leaves the original intact', () async {
    await write('quote', quote: 'original');
    await db.doc('cwitter_posts/quote').delete();
    expect(
      (await db.doc('cwitter_posts/original').get()).data(),
      post('source'),
    );
  });

  test(
    'nested quotes store a single reference rather than copying a tree',
    () async {
      await write('first', quote: 'original');
      await write('second', quote: 'first', author: 'writer');
      final second = CwitterPost.fromFirestore(
        await db.doc('cwitter_posts/second').get(),
      );
      expect(second.quotedPostId, 'first');
    },
  );

  test(
    'invalid paths and self references are rejected without writes',
    () async {
      for (final id in ['', '../source', 'users/a', 'bad id', 'quote']) {
        await expectLater(
          write('quote', quote: id),
          throwsA(isA<CwitterQuoteUnavailableException>()),
        );
      }
      expect((await db.doc('cwitter_posts/quote').get()).exists, isFalse);
      for (final value in [null, 1, {}, 'a/b', '']) {
        expect(parseCwitterQuotedPostId(value), isNull);
      }
    },
  );
}
