import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/assignments/assignment.dart';

class AssignmentRepository {
  AssignmentRepository(this.firestore, {required this.currentUserId});
  final FirebaseFirestore firestore;
  final String? Function() currentUserId;
  CollectionReference<Map<String, dynamic>> _tasks(String uid) =>
      firestore.collection('users').doc(uid).collection('assignments');
  void _checkUser(String uid) {
    if (uid.isEmpty || currentUserId() != uid) {
      throw StateError('ログイン状態が変わりました。開き直してください。');
    }
  }

  String newId(String uid) {
    _checkUser(uid);
    return _tasks(uid).doc().id;
  }

  Stream<List<Assignment>> watch(String uid) {
    _checkUser(uid);
    return _tasks(uid).snapshots().map(
      (snapshot) => [
        for (final doc in snapshot.docs)
          Assignment.fromJson(doc.id, doc.data()),
      ]..sort(Assignment.compare),
    );
  }

  // A stable ID and transaction make a retry safe after an uncertain response.
  // Editing content never overwrites a completion change from another device.
  Future<void> save(
    String uid,
    String id,
    AssignmentDraft draft, {
    required bool creating,
  }) async {
    _checkUser(uid);
    draft.validate();
    final doc = _tasks(uid).doc(id);
    await firestore.runTransaction((transaction) async {
      final existing = await transaction.get(doc);
      _checkUser(uid);
      if (!creating && !existing.exists) throw StateError('この課題は削除されています。');
      final fields = {
        ...draft.toJson(),
        if (!existing.exists) 'isCompleted': false,
        if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (existing.exists) {
        transaction.update(doc, fields);
      } else {
        transaction.set(doc, fields);
      }
    });
  }

  Future<void> setCompleted(String uid, String id, bool completed) async {
    _checkUser(uid);
    await _tasks(uid).doc(id).update({
      'isCompleted': completed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String uid, String id) async {
    _checkUser(uid);
    await _tasks(uid).doc(id).delete();
  }
}
