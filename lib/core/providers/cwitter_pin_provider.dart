import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/community/cwitter_post.dart';
import '../../services/community/cwitter_pin_service.dart';
import 'schedule_provider.dart';
import 'user_block_provider.dart';

final cwitterPinServiceProvider = Provider<CwitterPinService>((ref) {
  return CwitterPinService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final cwitterPinnedPostIdProvider = StreamProvider.autoDispose
    .family<String?, String>((ref, userId) {
      if (ref.watch(currentUserIdProvider) == null) return Stream.value(null);
      return ref.watch(cwitterPinServiceProvider).watchPinnedPostId(userId);
    });

final cwitterPinPostProvider = StreamProvider.autoDispose
    .family<CwitterPost?, String>((ref, postId) {
      if (ref.watch(currentUserIdProvider) == null ||
          CwitterPinService.parsePostId(postId) == null) {
        return Stream.value(null);
      }
      return ref.watch(cwitterPinServiceProvider).watchPost(postId);
    });

/// Resolve old pins even outside the activity query's limit. Fail closed while
/// visibility is loading, and never show a reference to someone else's post.
final visibleCwitterPinnedPostProvider = Provider.autoDispose
    .family<AsyncValue<CwitterPost?>, String>((ref, userId) {
      if (ref.watch(currentUserIdProvider) == null) {
        return const AsyncData(null);
      }
      final hidden = ref.watch(hiddenUserIdsProvider);
      if (hidden.hasError) return AsyncError(hidden.error!, hidden.stackTrace!);
      if (hidden.isLoading) return const AsyncLoading();
      if (hidden.requireValue.contains(userId)) return const AsyncData(null);
      final pin = ref.watch(cwitterPinnedPostIdProvider(userId));
      if (pin.hasError) return AsyncError(pin.error!, pin.stackTrace!);
      if (pin.isLoading) return const AsyncLoading();
      final postId = pin.requireValue;
      if (postId == null) return const AsyncData(null);
      return ref
          .watch(cwitterPinPostProvider(postId))
          .whenData((post) => post?.authorId == userId ? post : null);
    });

final cwitterPinSavingProvider = StateProvider.autoDispose.family<bool, String>(
  (ref, userId) => false,
);
