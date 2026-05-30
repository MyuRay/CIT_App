import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/community/chiba_channel_comment.dart';
import '../../models/community/chiba_channel_thread.dart';
import '../../services/community/chiba_channel_service.dart';
import 'schedule_provider.dart';

class ChibaChannelFeed {
  const ChibaChannelFeed({
    required this.hotThreads,
    required this.activeThreads,
    required this.archivedThreads,
  });

  final List<ChibaChannelThread> hotThreads;
  final List<ChibaChannelThread> activeThreads;
  final List<ChibaChannelThread> archivedThreads;
}

final chibaChannelThreadsProvider =
    StreamProvider<List<ChibaChannelThread>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(const []);
  return ChibaChannelService.watchThreads();
});

final chibaChannelThreadSortKeyProvider =
    StateProvider<ChibaChannelThreadSortKey>(
  (ref) => ChibaChannelThreadSortKey.lastActivity,
);

final chibaChannelThreadSortAscendingProvider = StateProvider<bool>(
  (ref) => false,
);

final chibaChannelFeedProvider = Provider<AsyncValue<ChibaChannelFeed>>((ref) {
  final sortKey = ref.watch(chibaChannelThreadSortKeyProvider);
  final ascending = ref.watch(chibaChannelThreadSortAscendingProvider);
  return ref.watch(chibaChannelThreadsProvider).whenData(
        (threads) => _splitThreads(
          threads,
          sortKey: sortKey,
          ascending: ascending,
        ),
      );
});

int _compareThreads(
  ChibaChannelThread a,
  ChibaChannelThread b,
  ChibaChannelThreadSortKey sortKey,
) {
  final result = switch (sortKey) {
    ChibaChannelThreadSortKey.lastActivity =>
      a.lastActivityAt.compareTo(b.lastActivityAt),
    ChibaChannelThreadSortKey.createdAt =>
      a.createdAt.compareTo(b.createdAt),
    ChibaChannelThreadSortKey.commentCount =>
      a.commentCount.compareTo(b.commentCount),
  };
  if (result != 0) return result;
  return a.createdAt.compareTo(b.createdAt);
}

void _sortThreads(
  List<ChibaChannelThread> threads, {
  required ChibaChannelThreadSortKey sortKey,
  required bool ascending,
}) {
  threads.sort((a, b) {
    final cmp = _compareThreads(a, b, sortKey);
    return ascending ? cmp : -cmp;
  });
}

ChibaChannelFeed _splitThreads(
  List<ChibaChannelThread> threads, {
  required ChibaChannelThreadSortKey sortKey,
  required bool ascending,
}) {
  final archived = threads.where((t) => t.isArchived).toList()
    ..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));

  final active = threads.where((t) => !t.isArchived).toList();

  final hot = active.where((t) => t.isHot).toList()
    ..sort((a, b) {
      final byActivity = b.lastActivityAt.compareTo(a.lastActivityAt);
      if (byActivity != 0) return byActivity;
      return b.commentCount.compareTo(a.commentCount);
    });

  final regular = active.where((t) => !t.isHot).toList();
  _sortThreads(regular, sortKey: sortKey, ascending: ascending);

  return ChibaChannelFeed(
    hotThreads: hot,
    activeThreads: regular,
    archivedThreads: archived,
  );
}

final chibaChannelCommentsProvider =
    StreamProvider.family<List<ChibaChannelComment>, String>((ref, threadId) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(const []);
  return ChibaChannelService.watchComments(threadId);
});
