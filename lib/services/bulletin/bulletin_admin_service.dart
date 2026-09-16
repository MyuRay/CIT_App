import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/bulletin/bulletin_model.dart';

final bulletinAdminServiceProvider = Provider(
  (ref) => BulletinAdminService(FirebaseFirestore.instance),
);
final adminBulletinPostsProvider = StreamProvider<List<BulletinPost>>(
  (ref) => ref.watch(bulletinAdminServiceProvider).watchPosts(),
);

class BulletinAdminService {
  BulletinAdminService(this.firestore);
  final FirebaseFirestore firestore;
  static const selectionLimit = 400;

  Stream<List<BulletinPost>> watchPosts() => firestore
      .collection('bulletin_posts')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map(
                  (doc) => BulletinPost.fromJson({...doc.data(), 'id': doc.id}),
                )
                .toList(),
      );

  Future<void> update(String id, Map<String, dynamic> patch) =>
      firestore.collection('bulletin_posts').doc(id).update(patch);

  Future<void> saveSettings(
    String id, {
    required bool isSponsored,
    required String sponsorName,
    required bool isActive,
    required bool isPinned,
    required bool allowComments,
    required DateTime? expiresAt,
  }) {
    final name = sponsorName.trim();
    if (isSponsored && (name.isEmpty || name.length > 80)) {
      throw ArgumentError('スポンサー名は1〜80文字で入力してください');
    }
    return update(id, {
      'isSponsored': isSponsored,
      'sponsorName': isSponsored ? name : '',
      'isActive': isActive,
      'isPinned': isPinned,
      'allowComments': allowComments,
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt),
    });
  }

  Future<void> bulkUpdate(List<String> ids, Map<String, dynamic> patch) async {
    _validateSelection(ids);
    final batch = firestore.batch();
    for (final id in ids.toSet()) {
      batch.update(firestore.collection('bulletin_posts').doc(id), patch);
    }
    await batch.commit();
  }

  Future<void> deletePosts(List<String> ids) async {
    _validateSelection(ids);
    final batch = firestore.batch();
    for (final id in ids.toSet()) {
      batch.delete(firestore.collection('bulletin_posts').doc(id));
    }
    await batch.commit();
  }

  Future<void> extendExpiry(List<String> ids, DateTime now) async {
    _validateSelection(ids);
    // Read every current expiry before writing, including concurrent admin edits.
    await firestore.runTransaction((transaction) async {
      final documents = [
        for (final id in ids.toSet())
          await transaction.get(firestore.collection('bulletin_posts').doc(id)),
      ];
      for (final doc in documents) {
        if (!doc.exists) throw StateError('投稿が削除されています。再読み込みしてください');
        final expiry = doc.data()?['expiresAt'];
        final previous = expiry is Timestamp ? expiry.toDate() : now;
        final base = previous.isAfter(now) ? previous : now;
        transaction.update(doc.reference, {
          'expiresAt': Timestamp.fromDate(base.add(const Duration(days: 7))),
        });
      }
    });
  }

  void _validateSelection(List<String> ids) {
    if (ids.isEmpty || ids.length > selectionLimit) {
      throw ArgumentError('一度に操作できるのは1〜400件です');
    }
  }
}
