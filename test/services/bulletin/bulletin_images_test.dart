import 'package:cit_app/models/bulletin/bulletin_model.dart';
import 'package:cit_app/models/bulletin/bulletin_image_draft.dart';
import 'package:cit_app/services/bulletin/bulletin_image_save_session.dart';
import 'package:cit_app/widgets/bulletin/bulletin_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BulletinPost post({List<String> urls = const [], String cover = 'old'}) =>
    BulletinPost(
      id: 'post',
      title: 'テスト投稿',
      description: '本文',
      imageUrl: cover,
      imageUrls: urls,
      category: BulletinCategories.event,
      createdAt: DateTime(2026, 9, 16),
      expiresAt: null,
      authorId: 'owner',
      authorName: '投稿者',
      thumbAlignX: .25,
      thumbAlignY: -.5,
      thumbScale: 2,
    );

void main() {
  test('legacy one-image posts keep their image and alignment', () {
    final decoded = BulletinPost.fromJson({
      'imageUrl': 'old',
      'thumbAlignX': .25,
      'thumbAlignY': -.5,
    });
    expect(decoded.galleryImageUrls, ['old']);
    expect(decoded.thumbScale, 1);
    final draft = BulletinImageDraft(post: decoded);
    expect(draft.cover!.url, 'old');
    expect(draft.crop.y, -.5);
  });
  test('multiple images, selected thumbnail and zoom round trip', () {
    final decoded = BulletinPost.fromJson(
      post(urls: ['first', 'second'], cover: 'second').toJson(),
    );
    expect(decoded.galleryImageUrls, ['first', 'second']);
    expect(decoded.imageUrl, 'second');
    expect(decoded.thumbScale, 2);
    expect(decoded.thumbAlignY, -.5);
  });
  test('invalid thumbnail fields use bounded fallbacks', () {
    final decoded = BulletinPost.fromJson({
      'imageUrls': ['first', '', null, 1, 'first', 'second'],
      'imageUrl': 'missing',
      'thumbScale': double.nan,
      'thumbAlignX': 8,
    });
    expect(decoded.galleryImageUrls, ['first', 'second']);
    expect(decoded.imageUrl, 'first');
    expect(decoded.thumbScale, 1);
    expect(decoded.thumbAlignX, 1);
    expect(BulletinPost.fromJson({}).galleryImageUrls, isEmpty);
  });
  test('reordering keeps cover and crop; removing the cover resets crop', () {
    final draft = BulletinImageDraft(post: post(urls: ['old', 'b', 'c']));
    draft.reorder(0, 2);
    expect(draft.images.map((image) => image.url), ['b', 'c', 'old']);
    expect(draft.coverId, 'old');
    expect(draft.crop.scale, 2);
    draft.selectCover('c');
    expect(draft.crop.scale, 1);
    draft.setCrop(const BulletinCrop(x: .5, scale: 3));
    draft.remove('b');
    expect(draft.crop.scale, 3);
    draft.remove('c');
    expect(draft.coverId, 'old');
    expect(draft.crop.scale, 1);
    draft.remove('old');
    expect(draft.cover, isNull);
  });
  test('ten-image limit rejects additions without changing draft', () {
    final draft = BulletinImageDraft();
    draft.add(
      List.generate(10, (i) => BulletinImageAttachment(id: '$i', url: '$i')),
    );
    expect(
      () => draft.add([const BulletinImageAttachment(id: 'extra')]),
      throwsArgumentError,
    );
    expect(draft.images, hasLength(10));
  });
  test(
    'save preserves order and removes originals only after persistence',
    () async {
      final events = <String>[];
      final draft = BulletinImageDraft(post: post(urls: ['old', 'keep']));
      draft.remove('old');
      draft.add([const BulletinImageAttachment(id: 'new')]);
      draft.selectCover('new');
      final session = BulletinImageSaveSession(
        upload: (_) async {
          events.add('upload');
          return 'new-url';
        },
        delete: (url) async {
          events.add('delete:$url');
        },
      );
      await session.save(
        draft: draft,
        previousUrls: ['old', 'keep'],
        persist: (images) async {
          expect(images.urls, ['keep', 'new-url']);
          expect(images.coverUrl, 'new-url');
          events.add('save');
        },
      );
      expect(events, ['upload', 'save', 'delete:old']);
    },
  );
  test('failed save keeps originals and reuses uploads on retry', () async {
    final events = <String>[];
    final draft =
        BulletinImageDraft()..add([const BulletinImageAttachment(id: 'new')]);
    final session = BulletinImageSaveSession(
      upload: (_) async {
        events.add('upload');
        return 'new-url';
      },
      delete: (url) async {
        events.add('delete:$url');
      },
    );
    await expectLater(
      session.save(
        draft: draft,
        previousUrls: ['old'],
        persist: (_) async {
          throw StateError('network');
        },
      ),
      throwsStateError,
    );
    expect(events, ['upload']);
    await session.save(
      draft: draft,
      previousUrls: ['old'],
      persist: (_) async {
        events.add('save');
      },
    );
    expect(events, ['upload', 'save', 'delete:old']);
  });
  test('partial upload failure never writes a partial post', () async {
    final draft =
        BulletinImageDraft()..add([
          const BulletinImageAttachment(id: 'a'),
          const BulletinImageAttachment(id: 'b'),
        ]);
    var saved = false;
    final session = BulletinImageSaveSession(
      upload: (image) async {
        if (image.id == 'b') throw StateError('network');
        return 'a-url';
      },
      delete: (_) async => fail('must not delete originals'),
    );
    await expectLater(
      session.save(
        draft: draft,
        persist: (_) async {
          saved = true;
        },
      ),
      throwsStateError,
    );
    expect(saved, isFalse);
  });
  test('empty gallery removes images only after persisting', () async {
    var saved = false;
    final deleted = <String>[];
    final session = BulletinImageSaveSession(
      upload: (_) async => throw StateError('unexpected'),
      delete: (url) async {
        expect(saved, isTrue);
        deleted.add(url);
      },
    );
    await session.save(
      draft: BulletinImageDraft(),
      previousUrls: ['a', 'b'],
      persist: (images) async {
        expect(images.urls, isEmpty);
        expect(images.coverUrl, '');
        saved = true;
      },
    );
    expect(deleted, ['a', 'b']);
  });
  test(
    'crop movement follows pixels and clamps edges for different aspect ratios',
    () {
      const viewport = Size(320, 180);
      for (final image in [
        const Size(600, 1200),
        const Size(1200, 600),
        const Size(1600, 900),
      ]) {
        final moved = bulletinCropFromOffset(
          viewport,
          image,
          2,
          const Offset(20, 15),
        );
        final displayed = bulletinCropOffset(viewport, image, moved);
        expect(displayed.dx, closeTo(20, .001));
        expect(displayed.dy, closeTo(15, .001));
        final edge = bulletinCropFromOffset(
          viewport,
          image,
          1,
          const Offset(10000, -10000),
        );
        expect(edge.x.abs(), lessThanOrEqualTo(1));
        expect(edge.y.abs(), lessThanOrEqualTo(1));
      }
    },
  );
}
