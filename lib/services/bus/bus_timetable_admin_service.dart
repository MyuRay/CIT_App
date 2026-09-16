import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bus/bus_timetable_draft.dart';

class BusTimetableConflict implements Exception {
  const BusTimetableConflict();
  @override
  String toString() => '別の操作でダイヤが更新されました。入力内容を時刻コピーで控え、画面を開き直してください。';
}

class BusTimetableAdminService {
  BusTimetableAdminService(this.firestore);
  final FirebaseFirestore firestore;

  Future<void> save({
    required String routeId,
    required List<BusDepartureData> original,
    required List<BusDepartureData> updated,
    required String updatedBy,
  }) async {
    validateBusDepartures(updated);
    final route = firestore.doc('bus_information/main/bus_routes/$routeId');
    final main = firestore.doc('bus_information/main');
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(route);
      if (!snapshot.exists) throw StateError('路線が削除されています。路線一覧を開き直してください。');
      final current = snapshot.data()?['timeEntries'] ?? [];
      if (!busTimetableDataEquals(current, original)) {
        throw const BusTimetableConflict();
      }
      transaction.update(route, {
        'timeEntries': updated,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy,
      });
      // Public bus data watches the parent document rather than this collection.
      transaction.set(main, {
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy,
      }, SetOptions(merge: true));
    });
  }
}
