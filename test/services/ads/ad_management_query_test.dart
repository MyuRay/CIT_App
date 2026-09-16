import 'package:cit_app/models/ads/ad_management_query.dart';
import 'package:cit_app/models/ads/in_app_ad_model.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/sponsor_fixtures.dart';

void main() {
  final now = sponsorTestNow;
  final running = sponsorTestAd().copyWith(id: 'running');
  final scheduled = running.copyWith(
    id: 'scheduled',
    startAt: now.add(const Duration(days: 2)),
  );
  final ended = running.copyWith(
    id: 'ended',
    endAt: now.subtract(const Duration(days: 1)),
  );
  final paused = running.copyWith(
    id: 'paused',
    isActive: false,
    isSponsored: false,
    sponsorName: '',
    placement: AdPlacement.cafeteria,
  );

  test(
    'status agrees with eligibility at both time boundaries and pause takes precedence',
    () {
      expect(adDeliveryStatus(running, now), AdDeliveryStatus.running);
      expect(adDeliveryStatus(scheduled, now), AdDeliveryStatus.scheduled);
      expect(adDeliveryStatus(ended, now), AdDeliveryStatus.ended);
      expect(
        adDeliveryStatus(ended.copyWith(isActive: false), now),
        AdDeliveryStatus.paused,
      );
      for (final ad in [scheduled, ended]) {
        final edge = ad.startAt ?? ad.endAt!;
        expect(
          adDeliveryStatus(ad, edge) == AdDeliveryStatus.running,
          ad.isEligible(edge),
        );
      }
    },
  );
  test(
    'search matches title body sponsor and link, combined with status and placement',
    () {
      final ads = [running, scheduled, ended, paused];
      expect(
        queryManagedAds(
          ads,
          now: now,
          search: ' 津田沼 EXAMPLE ',
          sponsoredOnly: true,
          status: AdDeliveryStatus.running,
          placement: AdPlacement.homeTop,
        ),
        [running],
      );
      expect(queryManagedAds(ads, now: now, placement: AdPlacement.cafeteria), [
        paused,
      ]);
      expect(queryManagedAds(ads, now: now, search: '見つからない広告'), isEmpty);
    },
  );
  test(
    'status and expiry sorting keep no-expiry last without mutating the input',
    () {
      final ads = [paused, ended, scheduled, running];
      expect(queryManagedAds(ads, now: now).map((ad) => ad.id), [
        'running',
        'scheduled',
        'paused',
        'ended',
      ]);
      final byExpiry = queryManagedAds(
        ads,
        now: now,
        sort: AdManagementSort.endingSoon,
      );
      expect(byExpiry.first, ended);
      expect(ads.first, paused);
      expect(ads.last, running);
    },
  );
}
