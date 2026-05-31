import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/community/cwitter_activity_counts.dart';
import '../../models/community/cwitter_follow_counts.dart';
import '../../models/community/cwitter_follow_user.dart';
import '../../models/community/cwitter_hashtag_summary.dart';
import '../../models/community/cwitter_post.dart';
import '../../models/community/cwitter_profile_activity.dart';
import '../../models/community/cwitter_ranking_entry.dart';
import '../../models/community/cwitter_recweet.dart';
import '../../models/community/cwitter_reply.dart';
import '../../core/constants/app_constants.dart';
import '../../models/community/cwitter_feed_item.dart';
import '../../models/user/user_model.dart';
import '../../services/community/cwitter_service.dart';
import '../../services/user/user_service.dart';
import '../../services/users/content_filter_service.dart';
import 'schedule_provider.dart';
import 'settings_provider.dart';
import 'user_block_provider.dart';
import 'cwitter_tags_override_provider.dart';

/// SharedPreferences: 既読時点の最新「投稿」作成日時（ミリ秒・返信は含めない）
const String cwitterLastSeenAtKey = 'cwitter_last_seen_at';

class CwitterFeedState {
  const CwitterFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<CwitterPost> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  CwitterFeedState copyWith({
    List<CwitterPost>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return CwitterFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CwitterFeedNotifier extends StateNotifier<CwitterFeedState> {
  CwitterFeedNotifier(this._ref) : super(const CwitterFeedState()) {
    _ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous != next) {
        refresh();
      }
    });
    if (_ref.read(currentUserIdProvider) != null) {
      refresh();
    }
  }

  final Ref _ref;
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDocument;

  Future<void> refresh() async {
    if (_ref.read(currentUserIdProvider) == null) {
      _lastDocument = null;
      state = const CwitterFeedState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    _lastDocument = null;

    try {
      final page = await CwitterService.fetchPostsPage();
      _lastDocument = page.lastDocument;
      state = CwitterFeedState(
        posts: page.posts,
        hasMore: page.hasMore,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> loadMore() async {
    if (_ref.read(currentUserIdProvider) == null) return;
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await CwitterService.fetchPostsPage(startAfter: _lastDocument);
      if (page.lastDocument != null) {
        _lastDocument = page.lastDocument;
      }
      state = state.copyWith(
        posts: _mergePosts(state.posts, page.posts),
        isLoadingMore: false,
        hasMore: page.hasMore,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMore: false, error: error);
    }
  }

  List<CwitterPost> _mergePosts(
    List<CwitterPost> current,
    List<CwitterPost> incoming,
  ) {
    if (incoming.isEmpty) return current;
    final seen = current.map((post) => post.id).toSet();
    final merged = List<CwitterPost>.from(current);
    for (final post in incoming) {
      if (seen.add(post.id)) {
        merged.add(post);
      }
    }
    return merged;
  }

  /// 削除済み Cweet をフィードから即時に除外する
  void removePost(String postId) {
    if (state.posts.every((post) => post.id != postId)) return;
    state = state.copyWith(
      posts: state.posts.where((post) => post.id != postId).toList(),
    );
  }
}

final cwitterFeedProvider =
    StateNotifierProvider<CwitterFeedNotifier, CwitterFeedState>((ref) {
  return CwitterFeedNotifier(ref);
});

/// 現在の AppUser をリアルタイム監視
final currentAppUserStreamProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value(null);
  }
  return UserService.watchUser(uid);
});

/// Cwitter ID 設定済みか
final hasCwitterIdProvider = Provider<bool>((ref) {
  final user = ref.watch(currentAppUserStreamProvider).valueOrNull;
  return user?.hasCwitterId ?? false;
});

/// 指定ユーザーの Cwitter プロフィール bio
final cwitterUserBioProvider = StreamProvider.family<String?, String>((ref, userId) {
  return UserService.watchUser(userId).map((user) => user?.cwitterBio);
});

/// 指定ユーザーの Cwitter プロフィールハッシュタグ（Firestore）
final _cwitterUserTagsStreamProvider =
    StreamProvider.family<List<String>, String>((ref, userId) {
  return UserService.watchUser(userId).map((user) => user?.cwitterTags ?? const []);
});

/// 指定ユーザーの Cwitter プロフィールハッシュタグ（楽観的更新込み）
final cwitterUserTagsProvider =
    Provider.family<AsyncValue<List<String>>, String>((ref, userId) {
  final override = ref.watch(cwitterTagsOverrideProvider)[userId];
  if (override != null) {
    return AsyncValue.data(override);
  }
  return ref.watch(_cwitterUserTagsStreamProvider(userId));
});

/// 自分のハッシュタグ変更を Firestore 反映後にオーバーライド解除
final cwitterTagsOverrideSyncProvider = Provider<void>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return;

  ref.listen(_cwitterUserTagsStreamProvider(uid), (_, next) {
    next.whenData((tags) {
      ref.read(cwitterTagsOverrideProvider.notifier).syncWithTags(uid, tags);
    });
  });
});

/// 登録済みハッシュタグ一覧
final cwitterRegisteredHashtagsProvider =
    FutureProvider<List<CwitterHashtagSummary>>((ref) {
  return CwitterService.fetchRegisteredHashtags();
});

/// ハッシュタグを保存し、UI に即時反映する
Future<void> saveCwitterTags(WidgetRef ref, {
  required String uid,
  required List<String> tags,
}) async {
  final normalized = CwitterService.normalizeCwitterTags(tags);
  ref.read(cwitterTagsOverrideProvider.notifier).apply(
        userId: uid,
        tags: normalized,
      );
  ref.invalidate(cwitterRegisteredHashtagsProvider);

  try {
    await CwitterService.updateCwitterTags(uid: uid, tags: tags);
  } catch (e) {
    ref.read(cwitterTagsOverrideProvider.notifier).revert(uid);
    rethrow;
  }
}

/// 指定ユーザーの Cwitter プロフィール SNS リンク
final cwitterUserSocialLinksProvider =
    StreamProvider.family<Map<String, String>, String>((ref, userId) {
  return UserService.watchUser(userId).map(
    (user) => user?.cwitterSocialLinks ?? const {},
  );
});

/// 読み込み済み Cweet 一覧（ページネーション対応）
final cwitterPostsProvider = Provider<AsyncValue<List<CwitterPost>>>((ref) {
  final feed = ref.watch(cwitterFeedProvider);
  if (feed.isLoading && feed.posts.isEmpty) {
    return const AsyncValue.loading();
  }
  if (feed.error != null && feed.posts.isEmpty) {
    return AsyncValue.error(feed.error!, StackTrace.current);
  }
  return AsyncValue.data(feed.posts);
});

/// 最新 Cweet の作成日時（NEW バッジ用）
final cwitterLatestPostCreatedAtProvider = StreamProvider<DateTime?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value(null);
  }
  return CwitterService.watchLatestPostCreatedAt();
});

/// 最終既読時刻（ミリ秒）。更新で NEW バッジの再計算を促す
final cwitterLastSeenMsProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getInt(cwitterLastSeenAtKey) ?? 0;
});

/// 最終既読より新しい「投稿」があるか（返信の増加では NEW にしない）
final hasNewCwitterPostsProvider = Provider<bool>((ref) {
  final lastSeenMs = ref.watch(cwitterLastSeenMsProvider);
  final latestCreatedAt =
      ref.watch(cwitterLatestPostCreatedAtProvider).valueOrNull;
  if (latestCreatedAt == null) return false;
  return latestCreatedAt.millisecondsSinceEpoch > lastSeenMs;
});

int? _latestCwitterPostCreatedAtMs(List<CwitterPost>? posts) {
  if (posts == null || posts.isEmpty) return null;
  return posts
      .map((p) => p.createdAt.millisecondsSinceEpoch)
      .reduce((a, b) => a > b ? a : b);
}

/// Cwitter フィードを既読にする（表示中の最新投稿の createdAt を基準）
void markCwitterFeedSeen(WidgetRef ref) {
  final latestPostMs = ref.read(cwitterLatestPostCreatedAtProvider).valueOrNull
          ?.millisecondsSinceEpoch ??
      _latestCwitterPostCreatedAtMs(
        ref.read(cwitterPostsProvider).valueOrNull,
      ) ??
      DateTime.now().millisecondsSinceEpoch;

  ref.read(sharedPreferencesProvider).setInt(cwitterLastSeenAtKey, latestPostMs);
  ref.read(cwitterLastSeenMsProvider.notifier).state = latestPostMs;
}

/// 投稿への返信一覧
final cwitterRepliesProvider =
    StreamProvider.family<List<CwitterReply>, String>((ref, postId) {
  return CwitterService.watchReplies(postId);
});

/// 指定ユーザーの投稿一覧
final cwitterUserPostsProvider =
    StreamProvider.family<List<CwitterPost>, String>((ref, authorId) {
  return CwitterService.watchMyPosts(authorId);
});

/// 指定ユーザーの投稿 + 返信（時系列）
final cwitterUserActivityProvider =
    StreamProvider.family<List<CwitterProfileActivity>, String>((ref, authorId) {
  return CwitterService.watchUserActivity(authorId);
});

/// 自分の投稿一覧
final myCwitterPostsProvider = StreamProvider<List<CwitterPost>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value(const []);
  }
  return CwitterService.watchMyPosts(uid);
});

/// いいねした投稿一覧
final likedCwitterPostsProvider = StreamProvider<List<CwitterPost>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value(const []);
  }
  return CwitterService.watchLikedPosts(uid);
});

/// フォロワー数・フォロー中数
final cwitterFollowCountsProvider =
    StreamProvider.family<CwitterFollowCounts, String>((ref, userId) {
  return CwitterService.watchFollowCounts(userId);
});

/// Cweet 数（投稿 + 返信 + recweet）
final cwitterUserCweetCountsProvider =
    StreamProvider.family<CwitterActivityCounts, String>((ref, userId) {
  return CwitterService.watchUserCweetCounts(userId);
});

/// 指定ユーザーをフォロー中か（followerId → followeeId）
final cwitterIsFollowingProvider =
    StreamProvider.family<bool, ({String followerId, String followeeId})>(
  (ref, target) {
    return CwitterService.watchIsFollowing(
      followerId: target.followerId,
      followeeId: target.followeeId,
    );
  },
);

AsyncValue<List<T>> _filterListAsync<T>(
  AsyncValue<List<T>> source,
  AsyncValue<Set<String>> hiddenAsync,
  List<T> Function(List<T>, Set<String>) filter,
) {
  return hiddenAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (hiddenUserIds) => source.when(
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
      data: (items) => AsyncValue.data(filter(items, hiddenUserIds)),
    ),
  );
}

/// ブロック対象を除外した Cwitter フィード
final filteredCwitterPostsProvider =
    Provider<AsyncValue<List<CwitterPost>>>((ref) {
  return _filterListAsync(
    ref.watch(cwitterPostsProvider),
    ref.watch(hiddenUserIdsProvider),
    ContentFilterService.filterCwitterPosts,
  );
});

/// ブロック対象を除外したユーザー活動
final filteredCwitterUserActivityProvider =
    Provider.family<AsyncValue<List<CwitterProfileActivity>>, String>(
  (ref, authorId) {
    return _filterListAsync(
      ref.watch(cwitterUserActivityProvider(authorId)),
      ref.watch(hiddenUserIdsProvider),
      ContentFilterService.filterCwitterActivities,
    );
  },
);

/// ブロック対象を除外したいいね一覧
final filteredLikedCwitterPostsProvider =
    Provider<AsyncValue<List<CwitterPost>>>((ref) {
  return _filterListAsync(
    ref.watch(likedCwitterPostsProvider),
    ref.watch(hiddenUserIdsProvider),
    ContentFilterService.filterCwitterPosts,
  );
});

/// ブロック対象を除外した返信一覧
final filteredCwitterRepliesProvider =
    Provider.family<AsyncValue<List<CwitterReply>>, String>((ref, postId) {
  return _filterListAsync(
    ref.watch(cwitterRepliesProvider(postId)),
    ref.watch(hiddenUserIdsProvider),
    ContentFilterService.filterCwitterReplies,
  );
});

/// フォロー中ユーザー ID
final cwitterFollowingUserIdsProvider =
    StreamProvider.family<Set<String>, String>((ref, userId) {
  return CwitterService.watchFollowingUserIds(userId);
});

/// フォロー中ユーザー一覧
final cwitterFollowingUsersProvider =
    StreamProvider.family<List<CwitterFollowUser>, String>((ref, userId) {
  return CwitterService.watchFollowingUsers(userId);
});

/// フォロワー一覧
final cwitterFollowerUsersProvider =
    StreamProvider.family<List<CwitterFollowUser>, String>((ref, userId) {
  return CwitterService.watchFollowerUsers(userId);
});

List<CwitterFollowUser> _filterFollowUsers(
  List<CwitterFollowUser> users,
  Set<String> hiddenUserIds,
) {
  if (hiddenUserIds.isEmpty) return users;
  return users.where((user) => !hiddenUserIds.contains(user.authorId)).toList();
}

/// ブロック対象を除外したフォロー中一覧
final filteredCwitterFollowingUsersProvider =
    Provider.family<AsyncValue<List<CwitterFollowUser>>, String>((ref, userId) {
  return _filterListAsync(
    ref.watch(cwitterFollowingUsersProvider(userId)),
    ref.watch(hiddenUserIdsProvider),
    _filterFollowUsers,
  );
});

/// ブロック対象を除外したフォロワー一覧
final filteredCwitterFollowerUsersProvider =
    Provider.family<AsyncValue<List<CwitterFollowUser>>, String>((ref, userId) {
  return _filterListAsync(
    ref.watch(cwitterFollowerUsersProvider(userId)),
    ref.watch(hiddenUserIdsProvider),
    _filterFollowUsers,
  );
});

/// フォロー中ユーザーの recweet 一覧
final cwitterRecweetsProvider = StreamProvider<List<CwitterRecweet>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value(const []);
  }

  final followingIdsAsync = ref.watch(cwitterFollowingUserIdsProvider(uid));
  if (followingIdsAsync.hasError) {
    return Stream.error(
      followingIdsAsync.error!,
      followingIdsAsync.stackTrace ?? StackTrace.empty,
    );
  }

  final followingIds = followingIdsAsync.valueOrNull ?? const {};
  return CwitterService.watchRecweetsFromUserIds(followingIds);
});

/// ブロック対象を除外した recweet 一覧
final filteredCwitterRecweetsProvider =
    Provider<AsyncValue<List<CwitterRecweet>>>((ref) {
  return _filterListAsync(
    ref.watch(cwitterRecweetsProvider),
    ref.watch(hiddenUserIdsProvider),
    ContentFilterService.filterCwitterRecweets,
  );
});

/// recweet 済みか
final cwitterIsRecweetedProvider =
    StreamProvider.family<bool, ({String userId, String postId})>((ref, target) {
  return CwitterService.watchIsRecweeted(
    userId: target.userId,
    postId: target.postId,
  );
});

/// 指定 Cweet にいいねしたユーザー一覧
final cwitterPostLikersProvider =
    StreamProvider.family<List<CwitterFollowUser>, String>((ref, postId) {
  return CwitterService.watchPostLikers(postId);
});

/// 指定 Cweet の返信数
final cwitterPostReplyCountProvider =
    StreamProvider.family<int, String>((ref, postId) {
  return CwitterService.watchPostReplyCount(postId);
});

/// 指定 Cweet を recweet したユーザー一覧
final cwitterPostRecweetersProvider =
    StreamProvider.family<List<CwitterFollowUser>, String>((ref, postId) {
  return CwitterService.watchPostRecweeters(postId);
});

/// ブロック対象を除外したいいねユーザー一覧
final filteredCwitterPostLikersProvider =
    Provider.family<AsyncValue<List<CwitterFollowUser>>, String>((ref, postId) {
  return _filterListAsync(
    ref.watch(cwitterPostLikersProvider(postId)),
    ref.watch(hiddenUserIdsProvider),
    _filterFollowUsers,
  );
});

/// ブロック対象を除外した recweet ユーザー一覧
final filteredCwitterPostRecweetersProvider =
    Provider.family<AsyncValue<List<CwitterFollowUser>>, String>((ref, postId) {
  return _filterListAsync(
    ref.watch(cwitterPostRecweetersProvider(postId)),
    ref.watch(hiddenUserIdsProvider),
    _filterFollowUsers,
  );
});

List<CwitterFeedItem> _buildFollowingFeedItems({
  required List<CwitterPost> posts,
  required List<CwitterRecweet> recweets,
  required Set<String> followingIds,
}) {
  if (followingIds.isEmpty) return const [];

  final postById = {for (final post in posts) post.id: post};
  final items = <CwitterFeedItem>[];

  for (final post in posts) {
    if (followingIds.contains(post.authorId)) {
      items.add(CwitterFeedItem(post: post, sortAt: post.createdAt));
    }
  }

  for (final recweet in recweets) {
    if (!followingIds.contains(recweet.userId)) continue;
    final original = postById[recweet.postId];
    if (original == null) continue;
    items.add(
      CwitterFeedItem(
        post: original,
        recweet: recweet,
        sortAt: recweet.recweetedAt,
      ),
    );
  }

  items.sort((a, b) => b.sortAt.compareTo(a.sortAt));
  return items;
}

/// フォロー中ユーザーの Cweet + recweet（ブロック除外済み）
final filteredFollowingFeedCwitterItemsProvider =
    Provider<AsyncValue<List<CwitterFeedItem>>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return const AsyncValue.data([]);
  }

  final allPosts = ref.watch(filteredCwitterPostsProvider);
  final recweets = ref.watch(filteredCwitterRecweetsProvider);
  final followingIdsAsync = ref.watch(cwitterFollowingUserIdsProvider(uid));

  return followingIdsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (followingIds) {
      if (followingIds.isEmpty) {
        return const AsyncValue.data([]);
      }

      return recweets.when(
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
        data: (recweetList) => allPosts.when(
          loading: () => const AsyncValue.loading(),
          error: (error, stack) => AsyncValue.error(error, stack),
          data: (posts) => AsyncValue.data(
            _buildFollowingFeedItems(
              posts: posts,
              recweets: recweetList,
              followingIds: followingIds,
            ),
          ),
        ),
      );
    },
  );
});

/// フォロー中ユーザーの Cweet のみ（ブロック除外済み）
final filteredFollowingFeedCwitterPostsProvider =
    Provider<AsyncValue<List<CwitterPost>>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return const AsyncValue.data([]);
  }

  final allPosts = ref.watch(filteredCwitterPostsProvider);
  final followingIdsAsync = ref.watch(cwitterFollowingUserIdsProvider(uid));

  return followingIdsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (followingIds) {
      if (followingIds.isEmpty) {
        return const AsyncValue.data([]);
      }
      return allPosts.when(
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
        data: (posts) => AsyncValue.data(
          posts.where((post) => followingIds.contains(post.authorId)).toList(),
        ),
      );
    },
  );
});

List<CwitterRankingEntry> _filterRankingEntries(
  List<CwitterRankingEntry> entries,
  Set<String> hiddenUserIds,
) {
  final filtered = entries
      .where(
        (entry) =>
            !hiddenUserIds.contains(entry.user.authorId) &&
            !AppConstants.isOfficialCwitterAccount(entry.user.cwitterId),
      )
      .toList();
  if (filtered.length == entries.length) return entries;

  return [
    for (var i = 0; i < filtered.length; i++)
      CwitterRankingEntry(
        rank: i + 1,
        user: filtered[i].user,
        value: filtered[i].value,
      ),
  ];
}

/// Cwitter ランキング（累計・月間 × Cweet数・フォロワー数・いいね数）
final cwitterRankingsProvider = FutureProvider<CwitterRankingBoard>((ref) async {
  final hiddenUserIds =
      ref.watch(hiddenUserIdsProvider).valueOrNull ?? const {};
  final board = await CwitterService.fetchRankings();
  return CwitterRankingBoard(
    allTime: CwitterRankings(
      cweetCount:
          _filterRankingEntries(board.allTime.cweetCount, hiddenUserIds),
      followerCount:
          _filterRankingEntries(board.allTime.followerCount, hiddenUserIds),
      likeCount: _filterRankingEntries(board.allTime.likeCount, hiddenUserIds),
    ),
    monthly: CwitterRankings(
      cweetCount:
          _filterRankingEntries(board.monthly.cweetCount, hiddenUserIds),
      followerCount:
          _filterRankingEntries(board.monthly.followerCount, hiddenUserIds),
      likeCount: _filterRankingEntries(board.monthly.likeCount, hiddenUserIds),
    ),
    monthLabel: board.monthLabel,
  );
});
