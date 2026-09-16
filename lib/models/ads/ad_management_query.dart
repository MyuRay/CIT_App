import 'in_app_ad_model.dart';

enum AdDeliveryStatus { running, scheduled, paused, ended }

enum AdManagementSort { status, endingSoon, placement, title }

String adStatusLabel(AdDeliveryStatus status) => switch (status) {
  AdDeliveryStatus.running => '掲載中',
  AdDeliveryStatus.scheduled => '予約中',
  AdDeliveryStatus.paused => '停止中',
  AdDeliveryStatus.ended => '終了',
};

AdDeliveryStatus adDeliveryStatus(InAppAd ad, DateTime now) {
  if (!ad.isActive) return AdDeliveryStatus.paused;
  if (ad.endAt != null && now.isAfter(ad.endAt!)) return AdDeliveryStatus.ended;
  if (ad.startAt != null && now.isBefore(ad.startAt!)) {
    return AdDeliveryStatus.scheduled;
  }
  return AdDeliveryStatus.running;
}

List<InAppAd> queryManagedAds(
  List<InAppAd> ads, {
  required DateTime now,
  String search = '',
  AdDeliveryStatus? status,
  AdPlacement? placement,
  bool sponsoredOnly = false,
  AdManagementSort sort = AdManagementSort.status,
}) {
  final terms = search
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty);
  final result =
      ads.where((ad) {
        final text =
            '${ad.title} ${ad.body} ${ad.sponsorName} ${ad.actionPayload}'
                .toLowerCase();
        return (status == null || adDeliveryStatus(ad, now) == status) &&
            (placement == null || ad.placement == placement) &&
            (!sponsoredOnly || ad.isSponsored) &&
            terms.every(text.contains);
      }).toList();
  result.sort((a, b) {
    final order = switch (sort) {
      AdManagementSort.status => adDeliveryStatus(
        a,
        now,
      ).index.compareTo(adDeliveryStatus(b, now).index),
      AdManagementSort.endingSoon =>
        a.endAt == null
            ? (b.endAt == null ? 0 : 1)
            : b.endAt == null
            ? -1
            : a.endAt!.compareTo(b.endAt!),
      AdManagementSort.placement => a.placement.index.compareTo(
        b.placement.index,
      ),
      AdManagementSort.title => a.title.compareTo(b.title),
    };
    if (order != 0) return order;
    final byTitle = a.title.compareTo(b.title);
    return byTitle == 0 ? a.id.compareTo(b.id) : byTitle;
  });
  return result;
}

String adDateLabel(DateTime value) =>
    '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')} '
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
