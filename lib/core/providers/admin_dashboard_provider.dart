import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/admin/admin_destination.dart';
import 'admin_provider.dart';
import 'settings_provider.dart';

enum AdminQueue {
  approvals(
    '投稿申請',
    'bulletin_posts',
    'approvalStatus',
    'pending',
    AdminDestination.approvals,
  ),
  contacts(
    '問い合わせ',
    'contact_forms',
    'status',
    'pending',
    AdminDestination.contacts,
  ),
  reports('通報', 'reports', 'status', 'pending', AdminDestination.reports);

  const AdminQueue(
    this.label,
    this.collection,
    this.field,
    this.value,
    this.destination,
  );
  final String label, collection, field, value;
  final AdminDestination destination;
}

final adminDashboardFirestoreProvider = Provider(
  (ref) => FirebaseFirestore.instance,
);
final adminUserIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  if (ref.watch(currentUserAdminProvider).asData?.value?.isAdmin != true)
    return Stream.value(<String>{});
  return ref
      .watch(adminDashboardFirestoreProvider)
      .collection('admin_permissions')
      .where('isAdmin', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
});
final adminQueueCountProvider = FutureProvider.autoDispose
    .family<int, AdminQueue>((ref, queue) async {
      final permissions = ref.watch(currentUserAdminProvider).asData?.value;
      if (permissions?.isAdmin != true) throw StateError('管理者権限が必要です');
      final result =
          await ref
              .watch(adminDashboardFirestoreProvider)
              .collection(queue.collection)
              .where(queue.field, isEqualTo: queue.value)
              .count()
              .get();
      return result.count ?? 0;
    });

final adminFavoriteToolsProvider = StateNotifierProvider.autoDispose
    .family<AdminFavoriteTools, Set<String>, String>((ref, uid) {
      return AdminFavoriteTools(ref.watch(sharedPreferencesProvider), uid);
    });

class AdminFavoriteTools extends StateNotifier<Set<String>> {
  AdminFavoriteTools(this.preferences, String uid)
    : key = 'admin_favorite_tools_v1_$uid',
      super(
        (preferences.getStringList('admin_favorite_tools_v1_$uid') ??
                ['bulletin', 'ads', 'notifications'])
            .where(
              (id) => AdminDestination.values.any((tool) => tool.name == id),
            )
            .toSet(),
      );
  final SharedPreferences preferences;
  final String key;
  Future<void> _pending = Future.value();

  Future<void> toggle(AdminDestination tool) {
    final operation = _pending.then((_) async {
      if (!mounted) return;
      final next = {...state};
      if (!next.add(tool.name)) next.remove(tool.name);
      if (!await preferences.setStringList(key, next.toList())) {
        throw StateError('保存できませんでした');
      }
      if (mounted) state = next;
    });
    _pending = operation.catchError((Object _) {});
    return operation;
  }
}
