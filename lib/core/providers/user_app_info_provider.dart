import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../services/user/user_app_info_service.dart';
import 'auth_provider.dart';
import 'admin_provider.dart';

final userAppInfoFirestoreProvider = Provider(
  (ref) => FirebaseFirestore.instance,
);
final userAppInfoServiceProvider = Provider(
  (ref) => UserAppInfoService(
    firestore: ref.watch(userAppInfoFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  ),
);
final userAppInfoSyncProvider = Provider<void>((ref) {
  final account = ref.watch(
    authStateProvider.select(
      (state) => (
        uid: state.valueOrNull?.uid,
        verified: state.valueOrNull?.emailVerified == true,
      ),
    ),
  );
  var disposed = false;
  Timer? retry;
  ref.onDispose(() {
    disposed = true;
    retry?.cancel();
  });
  Future<void> sync() async {
    if (disposed || account.uid == null || !account.verified) return;
    try {
      await ref
          .read(userAppInfoServiceProvider)
          .sync(account.uid!)
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      if (!disposed)
        retry = Timer(const Duration(seconds: 30), () => unawaited(sync()));
    }
  }

  unawaited(sync());
});
final userAppInfoProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, uid) {
      final user = ref.watch(authStateProvider).valueOrNull;
      final permissions = ref.watch(currentUserAdminProvider).valueOrNull;
      if (user?.emailVerified != true ||
          (user?.uid != uid &&
              permissions?.isAdmin != true &&
              permissions?.canViewContacts != true &&
              permissions?.canManageUsers != true)) {
        return Stream.value(null);
      }
      return ref
          .watch(userAppInfoFirestoreProvider)
          .collection('users')
          .doc(uid)
          .collection('support_info')
          .doc('client')
          .snapshots()
          .map((doc) => doc.data());
    });
