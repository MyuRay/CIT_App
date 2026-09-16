import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads shared aggregate counts only, never another user's favorites.
class CafeteriaPopularityService {
  CafeteriaPopularityService(this.firestore);
  final FirebaseFirestore firestore;
  static const batchSize = 30;

  Stream<Map<String, int>> watchCounts(Iterable<String> targetKeys) {
    final keys = targetKeys.toSet().toList()..sort();
    if (keys.isEmpty) return Stream.value(const {});
    final chunks = <List<String>>[
      for (var i = 0; i < keys.length; i += batchSize)
        keys.skip(i).take(batchSize).toList(),
    ];
    return Stream.multi((controller) {
      final values = <int, Map<String, int>>{};
      final subscriptions =
          <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
      for (var i = 0; i < chunks.length; i++) {
        final index = i;
        subscriptions.add(
          firestore
              .collection('cafeteria_favorite_stats')
              .where(FieldPath.documentId, whereIn: chunks[index])
              .snapshots()
              .listen(
                (snapshot) {
                  final counts = <String, int>{};
                  for (final doc in snapshot.docs) {
                    final count = doc.data()['count'];
                    if (count is int && count >= 0) counts[doc.id] = count;
                  }
                  values[index] = counts;
                  if (values.length == chunks.length) {
                    controller.add({
                      for (final batch in values.values) ...batch,
                    });
                  }
                },
                onError: (Object error, StackTrace stack) {
                  values.remove(index);
                  controller.addError(error, stack);
                },
              ),
        );
      }
      controller.onCancel = () async {
        await Future.wait(
          subscriptions.map((subscription) => subscription.cancel()),
        );
      };
    });
  }
}
