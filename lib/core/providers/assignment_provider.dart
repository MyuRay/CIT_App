import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/assignments/assignment.dart';
import '../../services/assignments/assignment_repository.dart';
import 'auth_provider.dart';

final assignmentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  return user?.emailVerified == true ? user!.uid : null;
});
final assignmentRepositoryProvider = Provider<AssignmentRepository>(
  (ref) => AssignmentRepository(
    FirebaseFirestore.instance,
    currentUserId: () => ref.read(assignmentUserIdProvider),
  ),
);
final assignmentViewOpenProvider = StateProvider<bool>((ref) {
  ref.watch(assignmentUserIdProvider);
  return false;
});
final userAssignmentsProvider = StreamProvider.autoDispose
    .family<List<Assignment>, String>(
      (ref, uid) => ref.watch(assignmentRepositoryProvider).watch(uid),
    );
// Family isolation prevents a previous user's cached tasks flashing on sign-in.
final assignmentsProvider = Provider<AsyncValue<List<Assignment>>>((ref) {
  final uid = ref.watch(assignmentUserIdProvider);
  return uid == null
      ? const AsyncData([])
      : ref.watch(userAssignmentsProvider(uid));
});
final assignmentClockProvider = StreamProvider.autoDispose<DateTime>((
  ref,
) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});
void retryAssignments(WidgetRef ref) {
  final uid = ref.read(assignmentUserIdProvider);
  if (uid != null) ref.invalidate(userAssignmentsProvider(uid));
}

bool showAssignmentHomeCard(
  AsyncValue<List<Assignment>> tasks, {
  required bool alwaysShow,
}) =>
    alwaysShow ||
    tasks.hasError ||
    tasks.valueOrNull?.any((t) => !t.isCompleted) == true;
