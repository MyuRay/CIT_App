import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/schedule/academic_calendar_event_model.dart';

class AcademicCalendarService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'academic_calendar_events';

  static Stream<List<AcademicCalendarEvent>> watchEventsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    return _firestore
        .collection(_collection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(AcademicCalendarEvent.fromDoc)
              .where((e) => e.title.isNotEmpty)
              .toList();
        });
  }

  static Stream<List<AcademicCalendarEvent>> watchAllEvents() {
    return _firestore
        .collection(_collection)
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(AcademicCalendarEvent.fromDoc)
              .where((e) => e.title.isNotEmpty)
              .toList();
        });
  }

  static Future<void> upsertEvent(AcademicCalendarEvent event) async {
    final docId =
        event.id.trim().isEmpty
            ? _firestore.collection(_collection).doc().id
            : event.id;
    await _firestore.collection(_collection).doc(docId).set(event.toMap());
  }

  static Future<void> deleteEvent(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
