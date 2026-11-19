import 'package:cloud_firestore/cloud_firestore.dart';
import 'ad_audience.dart';
import 'in_app_ad_model.dart';

class AdEvent {
  const AdEvent({
    required this.adId,
    required this.placement,
    required this.grade,
    required this.slotIndex,
    required this.kind,
  });
  final String adId, grade, kind;
  final AdPlacement placement;
  final int slotIndex;

  static AdEvent? fromMap(Map<String, dynamic> data) {
    final placement = adPlacementFromString(
      data['placement'] is String ? data['placement'] as String : null,
    );
    if (placement == null ||
        data['adId'] is! String ||
        !adGrades.contains(data['grade']) ||
        !const ['impression', 'click'].contains(data['kind']) ||
        data['slotIndex'] is! int ||
        (data['slotIndex'] as int) < 0 ||
        (data['slotIndex'] as int) > 99999) {
      return null;
    }
    return AdEvent(
      adId: data['adId'],
      placement: placement,
      grade: data['grade'],
      slotIndex: data['slotIndex'],
      kind: data['kind'],
    );
  }
}

class AdAnalyticsCount {
  const AdAnalyticsCount({
    required this.adId,
    required this.placement,
    required this.grade,
    required this.slotIndex,
    required this.impressions,
    required this.clicks,
  });
  final String adId, grade;
  final AdPlacement placement;
  final int slotIndex, impressions, clicks;
  double? get ctr => impressions == 0 ? null : clicks * 100 / impressions;
}

List<AdAnalyticsCount> summarizeAdEvents(
  Iterable<AdEvent> events, {
  String? adId,
  AdPlacement? placement,
  String? grade,
}) {
  final groups = <(String, AdPlacement, String, int), List<int>>{};
  for (final event in events) {
    if ((adId != null && adId != event.adId) ||
        (placement != null && placement != event.placement) ||
        (grade != null && grade != event.grade)) {
      continue;
    }
    final count = groups.putIfAbsent((
      event.adId,
      event.placement,
      event.grade,
      event.slotIndex,
    ), () => [0, 0]);
    count[event.kind == 'impression' ? 0 : 1]++;
  }
  final rows =
      groups.entries
          .map(
            (entry) => AdAnalyticsCount(
              adId: entry.key.$1,
              placement: entry.key.$2,
              grade: entry.key.$3,
              slotIndex: entry.key.$4,
              impressions: entry.value[0],
              clicks: entry.value[1],
            ),
          )
          .toList();
  rows.sort((a, b) {
    final byClicks = b.clicks.compareTo(a.clicks);
    if (byClicks != 0) return byClicks;
    final byPlacement = a.placement.index.compareTo(b.placement.index);
    if (byPlacement != 0) return byPlacement;
    final bySlot = a.slotIndex.compareTo(b.slotIndex);
    if (bySlot != 0) return bySlot;
    final byGrade = adGrades
        .indexOf(a.grade)
        .compareTo(adGrades.indexOf(b.grade));
    return byGrade != 0 ? byGrade : a.adId.compareTo(b.adId);
  });
  return rows;
}

class AdAnalyticsReport {
  const AdAnalyticsReport({
    required this.events,
    required this.from,
    required this.to,
    this.truncated = false,
  });
  final List<AdEvent> events;
  final DateTime from, to;
  final bool truncated;
}

DateTime adAnalyticsPeriodStart(DateTime now, int days) {
  final japan = now.toUtc().add(const Duration(hours: 9));
  return DateTime.utc(
    japan.year,
    japan.month,
    japan.day,
  ).subtract(Duration(days: days - 1, hours: 9));
}

AdAnalyticsReport adAnalyticsReportFromSnapshot(
  QuerySnapshot<Map<String, dynamic>> snapshot,
  DateTime from,
  DateTime to,
) => AdAnalyticsReport(
  events:
      snapshot.docs
          .take(5000)
          .map((doc) => AdEvent.fromMap(doc.data()))
          .whereType<AdEvent>()
          .toList(),
  from: from,
  to: to,
  truncated: snapshot.docs.length > 5000,
);
