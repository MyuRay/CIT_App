import 'package:cit_app/models/ads/in_app_ad_model.dart';
import 'package:cit_app/models/bulletin/bulletin_model.dart';
import 'package:cit_app/models/bulletin/bulletin_management_query.dart';
import 'package:cit_app/services/bulletin/bulletin_admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/sponsor_fixtures.dart';

void main() {
  test(
    'legacy posts and ads remain standard; sponsor data round-trips',
    () async {
      final oldPost =
          sponsorTestPost().toJson()
            ..remove('isSponsored')
            ..remove('sponsorName');
      expect(BulletinPost.fromJson(oldPost).isSponsored, isFalse);
      expect(
        BulletinPost.fromJson(sponsorTestPost().toJson()).sponsorName,
        '津田沼カフェ',
      );
      final db = FakeFirebaseFirestore();
      await db
          .doc('in_app_ads/old')
          .set(
            sponsorTestAd().toFirestore()
              ..remove('isSponsored')
              ..remove('sponsorName'),
          );
      expect(
        InAppAd.fromFirestore(await db.doc('in_app_ads/old').get()).isSponsored,
        isFalse,
      );
      await db.doc('in_app_ads/new').set(sponsorTestAd().toFirestore());
      expect(
        InAppAd.fromFirestore(await db.doc('in_app_ads/new').get()).sponsorName,
        '津田沼カフェ',
      );
    },
  );

  test('published status excludes pending, hidden and expired posts', () {
    final posts = [
      sponsorTestPost(id: 'public'),
      sponsorTestPost(id: 'pending', approval: 'pending'),
      sponsorTestPost(id: 'hidden', active: false),
      sponsorTestPost(id: 'expired', expiry: sponsorTestNow),
    ];
    expect(
      queryManagedBulletins(
        posts,
        now: sponsorTestNow,
        status: BulletinStatusFilter.published,
      ).map((p) => p.id),
      ['public'],
    );
  });

  test(
    'search covers sponsor names, filters compose and export follows visible order',
    () {
      final posts = [
        sponsorTestPost(id: 'one', name: '津田沼商店', views: 10),
        sponsorTestPost(id: 'two', name: '津田沼商店', views: 99),
        sponsorTestPost(id: 'three', name: '新習志野商店', views: 500),
      ];
      final visible = queryManagedBulletins(
        posts,
        now: sponsorTestNow,
        search: ' 津田沼商店 ',
        status: BulletinStatusFilter.sponsored,
        categoryId: 'coupon',
        sort: BulletinSort.views,
      );
      expect(visible.map((p) => p.id), ['two', 'one']);
      final csv = bulletinManagementCsv(visible);
      expect(csv, isNot(contains('three')));
      expect(csv.indexOf('"two"'), lessThan(csv.indexOf('"one"')));
      expect(
        bulletinManagementCsv([sponsorTestPost(title: '=HYPERLINK("x")')]),
        contains('\'=HYPERLINK'),
      );
    },
  );

  test('expiry sorting places undated posts last', () {
    final posts = [
      sponsorTestPost(id: 'none'),
      sponsorTestPost(
        id: 'later',
        expiry: sponsorTestNow.add(const Duration(days: 8)),
      ),
      sponsorTestPost(
        id: 'soon',
        expiry: sponsorTestNow.add(const Duration(days: 1)),
      ),
    ];
    expect(
      queryManagedBulletins(
        posts,
        now: sponsorTestNow,
        sort: BulletinSort.expiry,
      ).map((p) => p.id),
      ['soon', 'later', 'none'],
    );
  });

  test(
    'settings save, clear and persist without resetting approval or counts',
    () async {
      final db = FakeFirebaseFirestore();
      final service = BulletinAdminService(db);
      await db.doc('bulletin_posts/sponsor').set(sponsorTestPost().toJson());
      await service.saveSettings(
        'sponsor',
        isSponsored: true,
        sponsorName: '  新スポンサー  ',
        isActive: true,
        isPinned: true,
        allowComments: false,
        expiresAt: sponsorTestNow,
      );
      var saved = (await db.doc('bulletin_posts/sponsor').get()).data()!;
      expect(saved['sponsorName'], '新スポンサー');
      expect(saved['viewCount'], 120);
      expect(saved['approvalStatus'], 'approved');
      expect(saved['expiresAt'], Timestamp.fromDate(sponsorTestNow));
      await service.saveSettings(
        'sponsor',
        isSponsored: false,
        sponsorName: '',
        isActive: true,
        isPinned: false,
        allowComments: true,
        expiresAt: null,
      );
      saved = (await db.doc('bulletin_posts/sponsor').get()).data()!;
      expect(saved['isSponsored'], isFalse);
      expect(saved['sponsorName'], '');
      expect(saved['expiresAt'], isNull);
      expect(
        () => service.saveSettings(
          'sponsor',
          isSponsored: true,
          sponsorName: ' ',
          isActive: true,
          isPinned: false,
          allowComments: true,
          expiresAt: null,
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'bulk updates touch selected posts only and revive expired deadlines',
    () async {
      final db = FakeFirebaseFirestore();
      final service = BulletinAdminService(db);
      for (final id in ['a', 'b']) {
        await db
            .doc('bulletin_posts/$id')
            .set(
              sponsorTestPost(
                id: id,
                expiry: sponsorTestNow.subtract(const Duration(days: 30)),
              ).toJson(),
            );
      }
      await service.bulkUpdate(['a'], {'isActive': false});
      await service.extendExpiry(['a'], sponsorTestNow);
      final a = (await db.doc('bulletin_posts/a').get()).data()!;
      final b = (await db.doc('bulletin_posts/b').get()).data()!;
      expect(a['isActive'], isFalse);
      expect(b['isActive'], isTrue);
      expect(
        a['expiresAt'],
        Timestamp.fromDate(sponsorTestNow.add(const Duration(days: 7))),
      );
      await expectLater(
        service.bulkUpdate(List.generate(401, (i) => '$i'), {
          'isActive': false,
        }),
        throwsArgumentError,
      );
    },
  );

  test(
    'clearing advertisement dates, image and button is persisted by update',
    () async {
      final db = FakeFirebaseFirestore();
      await db
          .doc('in_app_ads/ad')
          .set(
            sponsorTestAd()
                .copyWith(
                  startAt: sponsorTestNow,
                  endAt: sponsorTestNow.add(const Duration(days: 30)),
                  imageUrl: 'https://example.com/photo.png',
                  ctaText: '旧ラベル',
                )
                .toFirestore(),
          );
      const cleared = InAppAd(
        id: 'ad',
        title: '広告',
        body: '本文',
        placement: AdPlacement.homeTop,
        actionType: AdActionType.external,
        actionPayload: 'https://example.com',
        isActive: true,
      );
      await db.doc('in_app_ads/ad').update(cleared.toFirestore());
      final saved = InAppAd.fromFirestore(await db.doc('in_app_ads/ad').get());
      expect(saved.startAt, isNull);
      expect(saved.endAt, isNull);
      expect(saved.imageUrl, isNull);
      expect(saved.ctaText, isNull);
      expect(saved.isSponsored, isFalse);
    },
  );
}
