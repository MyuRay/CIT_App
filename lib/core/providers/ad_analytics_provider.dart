import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/ads/ad_analytics.dart';
import '../../services/ads/ad_event_service.dart';
import 'admin_provider.dart';

final adAnalyticsProvider = FutureProvider.autoDispose
    .family<AdAnalyticsReport, int>((ref, days) async {
      final admin = await ref.watch(currentUserAdminProvider.future);
      if (admin?.isAdmin != true) throw StateError('管理者権限が必要です');
      final now = DateTime.now().toUtc();
      final from = adAnalyticsPeriodStart(now, days);
      final snapshot =
          await ref
              .watch(adFirestoreProvider)
              .collection('ad_events')
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(from),
              )
              .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
              .orderBy('createdAt', descending: true)
              .limit(5001)
              .get();
      return adAnalyticsReportFromSnapshot(snapshot, from, now);
    });
