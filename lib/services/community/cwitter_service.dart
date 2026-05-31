import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/notification_provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/community/cwitter_activity_counts.dart';
import '../../models/community/cwitter_follow_counts.dart';
import '../../models/community/cwitter_follow_user.dart';
import '../../models/community/cwitter_hashtag_summary.dart';
import '../../models/community/cwitter_poll.dart';
import '../../models/community/cwitter_post.dart';
import '../../models/community/cwitter_profile_activity.dart';
import '../../models/community/cwitter_ranking_entry.dart';
import '../../models/community/cwitter_recweet.dart';
import '../../models/community/cwitter_reply.dart';
import '../../models/community/cwitter_social_platform.dart';
import 'cwitter_post_image_service.dart';
import '../common/user_post_rate_limit.dart';
import '../users/user_block_service.dart';

class CwitterPostsPageResult {
  const CwitterPostsPageResult({
    required this.posts,
    required this.hasMore,
    this.lastDocument,
  });

  final List<CwitterPost> posts;
  final bool hasMore;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
}

class CwitterIdAlreadyTakenException implements Exception {
  const CwitterIdAlreadyTakenException();

  @override
  String toString() => AppConstants.errorCwitterIdTaken;
}

class CwitterIdAlreadySetException implements Exception {
  const CwitterIdAlreadySetException();

  @override
  String toString() => 'Cwitter IDは既に設定済みです';
}

class CwitterPostRateLimitException implements Exception {
  const CwitterPostRateLimitException();

  @override
  String toString() => 'Cweetは1分間に2件までです。少し待ってからもう一度Cweetしてください';
}

class CwitterReplyRateLimitException implements Exception {
  const CwitterReplyRateLimitException();

  @override
  String toString() => '返信は1分間に2件までです。少し待ってからもう一度返信してください';
}

class CwitterService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _postsCollection = 'cwitter_posts';
  static const String _repliesIndexCollection = 'cwitter_replies';
  static const String _idsCollection = 'cwitter_ids';
  static const String _usersCollection = 'users';
  static const String _followingCollection = 'cwitter_following';
  static const String _followersCollection = 'cwitter_followers';
  static const String _recweetsCollection = 'cwitter_recweets';
  static const String _socialCollection = 'cwitter_social';
  static const String _socialStatsDocId = 'stats';
  static const int _maxPostLength = 280;

  static String normalizeCwitterId(String raw) => raw.trim().toLowerCase();

  static bool isValidCwitterIdFormat(String id) {
    return AppConstants.cwitterIdPattern.hasMatch(id.trim());
  }

  /// 利用可能か（大文字小文字を区別しない）
  static Future<bool> isCwitterIdAvailable(String rawId) async {
    final normalized = normalizeCwitterId(rawId);
    if (!isValidCwitterIdFormat(normalized)) return false;

    final doc =
        await _firestore.collection(_idsCollection).doc(normalized).get();
    return !doc.exists;
  }

  /// Cwitter ID を初回設定（トランザクションで重複・二重設定を防止）
  static Future<String> claimCwitterId({
    required String uid,
    required String rawId,
  }) async {
    final normalized = normalizeCwitterId(rawId);
    if (!isValidCwitterIdFormat(normalized)) {
      throw ArgumentError(AppConstants.errorCwitterIdFormat);
    }

    final idRef = _firestore.collection(_idsCollection).doc(normalized);
    final userRef = _firestore.collection(_usersCollection).doc(uid);

    await _firestore.runTransaction<String>((transaction) async {
      final idSnap = await transaction.get(idRef);
      if (idSnap.exists) {
        throw const CwitterIdAlreadyTakenException();
      }

      final userSnap = await transaction.get(userRef);
      final existingId = userSnap.data()?['cwitterId']?.toString().trim();
      if (existingId != null && existingId.isNotEmpty) {
        throw const CwitterIdAlreadySetException();
      }

      transaction.set(idRef, {
        'uid': uid,
        'cwitterId': normalized,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(
        userRef,
        {
          'cwitterId': normalized,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return normalized;
    });

    await _autoFollowOfficialAccount(
      followerId: uid,
      claimedCwitterId: normalized,
    );

    return normalized;
  }

  /// Cwitter ID から Firebase UID を解決（cwitter_ids コレクション）
  static Future<String?> resolveUserIdByCwitterId(String rawId) async {
    final normalized = normalizeCwitterId(rawId);
    final idSnap =
        await _firestore.collection(_idsCollection).doc(normalized).get();
    if (!idSnap.exists) return null;

    final uid = idSnap.data()?['uid']?.toString();
    return (uid != null && uid.isNotEmpty) ? uid : null;
  }

  /// 初回 Cwitter ID 設定時に公式 @citapp をフォロー
  static Future<void> _autoFollowOfficialAccount({
    required String followerId,
    required String claimedCwitterId,
  }) async {
    if (normalizeCwitterId(claimedCwitterId) ==
        AppConstants.cwitterOfficialCwitterId) {
      return;
    }

    final officialUid = await resolveUserIdByCwitterId(
      AppConstants.cwitterOfficialCwitterId,
    );
    if (officialUid == null || officialUid == followerId) return;

    try {
      await followUser(
        followerId: followerId,
        followeeId: officialUid,
        sendNotification: false,
      );
    } catch (_) {
      // ID 設定自体は成功扱い
    }
  }

  static Stream<List<CwitterPost>> watchPosts({
    int limit = AppConstants.postPageSize,
  }) {
    return _firestore
        .collection(_postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(CwitterPost.fromFirestore)
              .toList(),
        );
  }

  /// ページ単位で Cweet を取得（追加読み込み用）
  static Future<CwitterPostsPageResult> fetchPostsPage({
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = AppConstants.postPageSize,
  }) async {
    var query = _firestore
        .collection(_postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit + 1);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;
    final hasMore = docs.length > limit;
    final pageDocs = hasMore ? docs.sublist(0, limit) : docs;
    final posts = pageDocs.map(CwitterPost.fromFirestore).toList();

    return CwitterPostsPageResult(
      posts: posts,
      hasMore: hasMore,
      lastDocument: pageDocs.isEmpty ? null : pageDocs.last,
    );
  }

  static const int _rankingResultLimit = 30;
  static const int _rankingPostMaxScanAllTime = 20000;
  static const int _rankingPostPageSize = 200;
  static const int _rankingMaxUsers = 2000;
  static const int _rankingStatsBatchSize = 30;
  static const int _rankingFollowerGainMaxScan = 10000;
  static const int _rankingFollowerGainPageSize = 500;

  static DateTime _currentMonthStartLocal() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static String _currentMonthLabel() {
    final now = DateTime.now();
    return '${now.year}年${now.month}月';
  }

  static DateTime? _parseCreatedAt(Map<String, dynamic> data) {
    final value = data['createdAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static Future<
      ({
        Map<String, ({int postCount, int likeCount})> allTime,
        Map<String, ({int postCount, int likeCount})> monthly,
      })> _aggregateAuthorPostStats(DateTime monthStart) async {
    final allTime = <String, ({int postCount, int likeCount})>{};
    final monthly = <String, ({int postCount, int likeCount})>{};
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    var scanned = 0;

    while (scanned < _rankingPostMaxScanAllTime) {
      var query = _firestore
          .collection(_postsCollection)
          .orderBy('createdAt', descending: true)
          .limit(_rankingPostPageSize);
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snap = await query.get();
      if (snap.docs.isEmpty) break;

      for (final doc in snap.docs) {
        final data = doc.data();
        final authorId = data['authorId']?.toString() ?? '';
        if (authorId.isEmpty) continue;

        final likes = (data['likeCount'] as num?)?.toInt() ?? 0;
        final createdAt = _parseCreatedAt(data);
        final isMonthly = createdAt != null && !createdAt.isBefore(monthStart);

        final allCurrent = allTime[authorId];
        allTime[authorId] = (
          postCount: (allCurrent?.postCount ?? 0) + 1,
          likeCount: (allCurrent?.likeCount ?? 0) + likes,
        );

        if (isMonthly) {
          final monthCurrent = monthly[authorId];
          monthly[authorId] = (
            postCount: (monthCurrent?.postCount ?? 0) + 1,
            likeCount: (monthCurrent?.likeCount ?? 0) + likes,
          );
        }
      }

      scanned += snap.docs.length;
      cursor = snap.docs.last;
      if (snap.docs.length < _rankingPostPageSize) break;
    }

    return (allTime: allTime, monthly: monthly);
  }

  static Future<Map<String, int>> _aggregateMonthlyFollowerGains(
    DateTime monthStart,
  ) async {
    final counts = <String, int>{};
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    var scanned = 0;

    while (scanned < _rankingFollowerGainMaxScan) {
      var query = _firestore
          .collectionGroup(_followersCollection)
          .where(
            'followedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
          )
          .orderBy('followedAt')
          .limit(_rankingFollowerGainPageSize);
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snap = await query.get();
      if (snap.docs.isEmpty) break;

      for (final doc in snap.docs) {
        final userId = doc.reference.parent.parent?.id;
        if (userId == null || userId.isEmpty) continue;
        counts[userId] = (counts[userId] ?? 0) + 1;
      }

      scanned += snap.docs.length;
      cursor = snap.docs.last;
      if (snap.docs.length < _rankingFollowerGainPageSize) break;
    }

    return counts;
  }

  static Future<List<String>> _collectCwitterUserIds() async {
    final uids = <String>[];

    await _forEachCwitterUserBatch((docs) async {
      for (final doc in docs) {
        final uid = doc.data()['uid']?.toString();
        if (uid == null || uid.isEmpty) continue;
        uids.add(uid);
      }
    }, maxIds: _rankingMaxUsers);

    return uids;
  }

  static Future<Map<String, int>> _fetchFollowerCounts(
    List<String> userIds,
  ) async {
    final counts = <String, int>{};
    if (userIds.isEmpty) return counts;

    for (var i = 0; i < userIds.length; i += _rankingStatsBatchSize) {
      final end = math.min(i + _rankingStatsBatchSize, userIds.length);
      final batch = userIds.sublist(i, end);
      final snaps = await Future.wait(
        batch.map((uid) => _followStatsRef(uid).get()),
      );

      for (var j = 0; j < batch.length; j++) {
        final data = snaps[j].data();
        counts[batch[j]] = (data?['followerCount'] as num?)?.toInt() ?? 0;
      }
    }

    return counts;
  }

  static Future<List<CwitterRankingEntry>> _buildRankingEntries(
    List<MapEntry<String, int>> rankedUsers,
  ) async {
    final results = <CwitterRankingEntry>[];
    for (final entry in rankedUsers) {
      if (results.length >= _rankingResultLimit) break;

      final user = await _fetchFollowUser(entry.key);
      if (user == null) continue;
      if (AppConstants.isOfficialCwitterAccount(user.cwitterId)) continue;

      results.add(
        CwitterRankingEntry(
          rank: results.length + 1,
          user: user,
          value: entry.value,
        ),
      );
    }
    return results;
  }

  static Future<String?> fetchOfficialAccountUserId() async {
    final snap = await _firestore
        .collection(_idsCollection)
        .doc(AppConstants.cwitterOfficialCwitterId)
        .get();
    if (!snap.exists) return null;
    return snap.data()?['uid']?.toString();
  }

  static void _removeOfficialFromCountMap(
    Map<String, int> counts,
    String? officialUid,
  ) {
    if (officialUid == null || officialUid.isEmpty) return;
    counts.remove(officialUid);
  }

  static void _removeOfficialFromPostStats(
    Map<String, ({int postCount, int likeCount})> stats,
    String? officialUid,
  ) {
    if (officialUid == null || officialUid.isEmpty) return;
    stats.remove(officialUid);
  }

  static List<MapEntry<String, int>> _sortByValueDesc(
    Map<String, int> counts,
  ) {
    return counts.entries.where((entry) => entry.value > 0).toList()
      ..sort((a, b) {
        final valueCompare = b.value.compareTo(a.value);
        if (valueCompare != 0) return valueCompare;
        return a.key.compareTo(b.key);
      });
  }

  static Future<CwitterRankings> _buildRankingsForPeriod({
    required Map<String, ({int postCount, int likeCount})> postStats,
    required Map<String, int> followerCounts,
  }) async {
    final cweetCounts = <String, int>{
      for (final entry in postStats.entries) entry.key: entry.value.postCount,
    };
    final likeCounts = <String, int>{
      for (final entry in postStats.entries) entry.key: entry.value.likeCount,
    };

    final cweetRanking = await _buildRankingEntries(
      _sortByValueDesc(cweetCounts).take(_rankingResultLimit * 2).toList(),
    );
    final followerRanking = await _buildRankingEntries(
      _sortByValueDesc(followerCounts).take(_rankingResultLimit * 2).toList(),
    );
    final likeRanking = await _buildRankingEntries(
      _sortByValueDesc(likeCounts).take(_rankingResultLimit * 2).toList(),
    );

    return CwitterRankings(
      cweetCount: cweetRanking,
      followerCount: followerRanking,
      likeCount: likeRanking,
    );
  }

  /// Cweet数・フォロワー数・いいね数のランキング（累計・月間）
  static Future<CwitterRankingBoard> fetchRankings() async {
    final monthStart = _currentMonthStartLocal();
    final officialUidFuture = fetchOfficialAccountUserId();
    final postStatsFuture = _aggregateAuthorPostStats(monthStart);
    final userIdsFuture = _collectCwitterUserIds();
    final monthlyFollowersFuture = _aggregateMonthlyFollowerGains(monthStart);

    final officialUid = await officialUidFuture;
    final postStats = await postStatsFuture;
    final userIds = await userIdsFuture;
    final allTimeFollowers = await _fetchFollowerCounts(userIds);
    final monthlyFollowers = await monthlyFollowersFuture;

    _removeOfficialFromPostStats(postStats.allTime, officialUid);
    _removeOfficialFromPostStats(postStats.monthly, officialUid);
    _removeOfficialFromCountMap(allTimeFollowers, officialUid);
    _removeOfficialFromCountMap(monthlyFollowers, officialUid);

    final allTimeRankings = await _buildRankingsForPeriod(
      postStats: postStats.allTime,
      followerCounts: allTimeFollowers,
    );
    final monthlyRankings = await _buildRankingsForPeriod(
      postStats: postStats.monthly,
      followerCounts: monthlyFollowers,
    );

    return CwitterRankingBoard(
      allTime: allTimeRankings,
      monthly: monthlyRankings,
      monthLabel: _currentMonthLabel(),
    );
  }

  static const int _searchPostResultLimit = 30;
  static const int _searchPostMaxScan = 300;
  static const int _searchUserResultLimit = 20;
  static const int _searchUserMaxScan = 500;
  static const int _searchUserPageSize = 100;
  static const int _hashtagScanMaxIds = 2000;
  static const int _hashtagUserFetchBatchSize = 30;
  static const int _hashtagSearchResultLimit = 30;

  static String _normalizeSearchNeedle(String raw) {
    var needle = raw.trim().toLowerCase();
    if (needle.startsWith('@')) {
      needle = needle.substring(1).trim();
    }
    if (needle.startsWith('#')) {
      needle = needle.substring(1).trim();
    }
    return needle;
  }

  static String _normalizeHashtagNeedle(String raw) => _normalizeSearchNeedle(raw);

  static List<String> _parseCwitterTagsFromData(Map<String, dynamic> data) {
    final value = data['cwitterTags'];
    if (value is! List) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((tag) => tag.isNotEmpty)
        .take(AppConstants.cwitterTagsMaxCount)
        .toList();
  }

  static bool _tagsMatchSearch(List<String> tags, String needle) {
    if (needle.isEmpty) return false;
    return tags.any((tag) => tag.toLowerCase().contains(needle));
  }

  static bool _tagsContainExact(List<String> tags, String needle) {
    if (needle.isEmpty) return false;
    return tags.any((tag) => tag.toLowerCase() == needle);
  }

  static CwitterFollowUser? _followUserFromData(
    String userId,
    Map<String, dynamic> data,
  ) {
    final cwitterId = data['cwitterId']?.toString().trim();
    if (cwitterId == null || cwitterId.isEmpty) return null;

    return CwitterFollowUser(
      authorId: userId,
      displayName: data['displayName']?.toString() ?? 'Unknown',
      cwitterId: cwitterId,
      profileImageUrl: data['profileImageUrl']?.toString(),
      bio: _parseCwitterBio(data['cwitterBio']),
      tags: _parseCwitterTagsFromData(data),
    );
  }

  static Future<void> _forEachCwitterUserBatch(
    Future<void> Function(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    ) onBatch, {
    required int maxIds,
  }) async {
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    var scanned = 0;

    while (scanned < maxIds) {
      var idQuery = _firestore
          .collection(_idsCollection)
          .orderBy(FieldPath.documentId)
          .limit(_searchUserPageSize);
      if (cursor != null) {
        idQuery = idQuery.startAfterDocument(cursor);
      }

      final snap = await idQuery.get();
      if (snap.docs.isEmpty) break;

      await onBatch(snap.docs);

      scanned += snap.docs.length;
      cursor = snap.docs.last;
      if (snap.docs.length < _searchUserPageSize) break;
    }
  }

  static Future<List<Map<String, dynamic>?>> _fetchUserDataBatch(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return const [];

    final results = <Map<String, dynamic>?>[];
    for (var i = 0; i < userIds.length; i += _hashtagUserFetchBatchSize) {
      final end = math.min(i + _hashtagUserFetchBatchSize, userIds.length);
      final batch = userIds.sublist(i, end);
      final snaps = await Future.wait(
        batch.map((uid) => _firestore.collection(_usersCollection).doc(uid).get()),
      );
      for (final snap in snaps) {
        results.add(snap.exists ? snap.data() : null);
      }
    }
    return results;
  }

  /// 登録済みハッシュタグ一覧（使用ユーザー数付き）
  static Future<List<CwitterHashtagSummary>> fetchRegisteredHashtags() async {
    final counts = <String, int>{};
    final pendingUids = <String>[];

    Future<void> flushPending() async {
      if (pendingUids.isEmpty) return;

      final uids = List<String>.from(pendingUids);
      pendingUids.clear();
      final dataList = await _fetchUserDataBatch(uids);

      for (final data in dataList) {
        if (data == null) continue;
        for (final tag in _parseCwitterTagsFromData(data)) {
          counts[tag] = (counts[tag] ?? 0) + 1;
        }
      }
    }

    await _forEachCwitterUserBatch((docs) async {
      for (final doc in docs) {
        final uid = doc.data()['uid']?.toString();
        if (uid == null || uid.isEmpty) continue;
        pendingUids.add(uid);
        if (pendingUids.length >= _hashtagUserFetchBatchSize) {
          await flushPending();
        }
      }
    }, maxIds: _hashtagScanMaxIds);

    await flushPending();

    final summaries = counts.entries
        .map(
          (entry) => CwitterHashtagSummary(
            tag: entry.key,
            userCount: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) {
        final countCompare = b.userCount.compareTo(a.userCount);
        if (countCompare != 0) return countCompare;
        return a.tag.compareTo(b.tag);
      });

    return summaries;
  }

  /// 指定ハッシュタグを設定しているユーザー一覧（完全一致）
  static Future<List<CwitterFollowUser>> fetchUsersWithHashtag(String tag) async {
    final needle = _normalizeHashtagNeedle(tag);
    if (needle.isEmpty) return const [];

    final results = <CwitterFollowUser>[];
    final seenUserIds = <String>{};
    final pendingUids = <String>[];

    Future<void> flushPending() async {
      if (pendingUids.isEmpty) return;

      final uids = List<String>.from(pendingUids);
      pendingUids.clear();
      final dataList = await _fetchUserDataBatch(uids);

      for (var i = 0; i < uids.length; i++) {
        final uid = uids[i];
        final data = dataList[i];
        if (data == null || seenUserIds.contains(uid)) continue;

        final tags = _parseCwitterTagsFromData(data);
        if (!_tagsContainExact(tags, needle)) continue;

        final user = _followUserFromData(uid, data);
        if (user == null) continue;

        seenUserIds.add(uid);
        results.add(user);
      }
    }

    await _forEachCwitterUserBatch((docs) async {
      for (final doc in docs) {
        final uid = doc.data()['uid']?.toString();
        if (uid == null || uid.isEmpty) continue;
        pendingUids.add(uid);
        if (pendingUids.length >= _hashtagUserFetchBatchSize) {
          await flushPending();
        }
      }
    }, maxIds: _hashtagScanMaxIds);

    await flushPending();

    results.sort(
      (a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    return results;
  }

  /// ハッシュタグでユーザーを検索（部分一致・大文字小文字無視）
  static Future<List<CwitterFollowUser>> searchUsersByHashtag(
    String rawQuery,
  ) async {
    final needle = _normalizeHashtagNeedle(rawQuery);
    if (needle.isEmpty) return const [];

    final results = <CwitterFollowUser>[];
    final seenUserIds = <String>{};
    var scanned = 0;
    var shouldStop = false;

    await _forEachCwitterUserBatch((docs) async {
      if (shouldStop) return;

      final batchUids = <String>[];
      for (final doc in docs) {
        scanned++;
        if (scanned > _searchUserMaxScan) {
          shouldStop = true;
          break;
        }

        final uid = doc.data()['uid']?.toString();
        if (uid == null || uid.isEmpty || seenUserIds.contains(uid)) continue;
        batchUids.add(uid);
      }

      final dataList = await _fetchUserDataBatch(batchUids);
      for (var i = 0; i < batchUids.length; i++) {
        if (results.length >= _hashtagSearchResultLimit) {
          shouldStop = true;
          break;
        }

        final uid = batchUids[i];
        final data = dataList[i];
        if (data == null) continue;

        final tags = _parseCwitterTagsFromData(data);
        if (!_tagsMatchSearch(tags, needle)) continue;

        final user = _followUserFromData(uid, data);
        if (user == null || seenUserIds.contains(uid)) continue;

        seenUserIds.add(uid);
        results.add(user);
      }

      if (results.length >= _hashtagSearchResultLimit) {
        shouldStop = true;
      }
    }, maxIds: _searchUserMaxScan);

    return results;
  }

  static bool _postMatchesSearch(CwitterPost post, String needle) {
    if (needle.isEmpty) return false;
    return post.body.toLowerCase().contains(needle) ||
        post.displayName.toLowerCase().contains(needle) ||
        post.cwitterId.toLowerCase().contains(needle);
  }

  static bool _userMatchesSearch(CwitterFollowUser user, String needle) {
    if (needle.isEmpty) return false;
    return user.cwitterId.toLowerCase().contains(needle) ||
        user.displayName.toLowerCase().contains(needle);
  }

  /// キーワードを含む Cweet を検索（直近の投稿から走査・部分一致・大文字小文字無視）
  static Future<List<CwitterPost>> searchPosts(String query) async {
    final needle = _normalizeSearchNeedle(query);
    if (needle.isEmpty) return const [];

    final results = <CwitterPost>[];
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    var scanned = 0;

    while (results.length < _searchPostResultLimit &&
        scanned < _searchPostMaxScan) {
      final batchSize = math.min(
        AppConstants.postPageSize,
        _searchPostMaxScan - scanned,
      );
      final page = await fetchPostsPage(
        startAfter: cursor,
        limit: batchSize,
      );
      if (page.posts.isEmpty) break;

      scanned += page.posts.length;
      for (final post in page.posts) {
        if (_postMatchesSearch(post, needle)) {
          results.add(post);
          if (results.length >= _searchPostResultLimit) break;
        }
      }

      if (!page.hasMore || page.lastDocument == null) break;
      cursor = page.lastDocument;
    }

    return results;
  }

  /// Cwitter ID・表示名でユーザーを検索（部分一致・大文字小文字無視）
  static Future<List<CwitterFollowUser>> searchUsersByCwitterId(
    String rawQuery,
  ) async {
    final needle = _normalizeSearchNeedle(rawQuery);
    if (needle.isEmpty) return const [];

    final results = <CwitterFollowUser>[];
    final seenUserIds = <String>{};
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    var scanned = 0;

    while (results.length < _searchUserResultLimit &&
        scanned < _searchUserMaxScan) {
      var idQuery = _firestore
          .collection(_idsCollection)
          .orderBy(FieldPath.documentId)
          .limit(_searchUserPageSize);
      if (cursor != null) {
        idQuery = idQuery.startAfterDocument(cursor);
      }

      final snap = await idQuery.get();
      if (snap.docs.isEmpty) break;

      for (final doc in snap.docs) {
        scanned++;
        if (scanned > _searchUserMaxScan) break;

        final uid = doc.data()['uid']?.toString();
        if (uid == null || uid.isEmpty || seenUserIds.contains(uid)) {
          continue;
        }

        // ID の部分一致を先に判定（大文字小文字は doc.id が小文字のため needle も小文字）
        if (!doc.id.contains(needle)) continue;

        final user = await _fetchFollowUser(uid);
        if (user == null || !_userMatchesSearch(user, needle)) continue;

        seenUserIds.add(uid);
        results.add(user);
        if (results.length >= _searchUserResultLimit) break;
      }

      if (results.length >= _searchUserResultLimit) break;
      cursor = snap.docs.last;
      if (snap.docs.length < _searchUserPageSize) break;
    }

    return results;
  }

  /// NEW バッジ判定用（最新1件の作成日時）
  static Stream<DateTime?> watchLatestPostCreatedAt() {
    return _firestore
        .collection(_postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final createdAt = snapshot.docs.first.data()['createdAt'];
      if (createdAt is Timestamp) return createdAt.toDate();
      return null;
    });
  }

  /// 自分の投稿一覧
  static Stream<List<CwitterPost>> watchMyPosts(
    String authorId, {
    int limit = 50,
  }) {
    return _firestore
        .collection(_postsCollection)
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(CwitterPost.fromFirestore)
              .toList(),
        );
  }

  /// ユーザーが書いた返信（全投稿の replies サブコレクション横断）
  static Stream<List<CwitterProfileActivity>> watchUserReplies(
    String authorId, {
    int limit = 50,
  }) {
    return _firestore
        .collection(_repliesIndexCollection)
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      final activities = <CwitterProfileActivity>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final postId = data['postId'] as String?;
        if (postId == null) continue;

        final createdAt = data['createdAt'];
        final reply = CwitterReply(
          id: data['replyId'] as String? ?? doc.id,
          postId: postId,
          authorId: data['authorId'] as String? ?? '',
          authorEmail: data['authorEmail'] as String?,
          cwitterId: data['cwitterId'] as String? ?? '',
          displayName: data['displayName'] as String? ?? '匿名',
          body: data['body'] as String? ?? '',
          createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
          profileImageUrl: data['profileImageUrl'] as String?,
          inReplyToReplyId: data['inReplyToReplyId'] as String?,
          imageUrls: CwitterReply.parseImageUrls(data['imageUrls']),
        );
        final postSnap =
            await _firestore.collection(_postsCollection).doc(postId).get();
        final parentPost =
            postSnap.exists ? CwitterPost.fromFirestore(postSnap) : null;

        activities.add(
          CwitterProfileActivity.reply(
            reply: reply,
            parentPost: parentPost,
          ),
        );
      }
      return activities;
    });
  }

  /// ユーザーが recweet した Cweet
  static Stream<List<CwitterProfileActivity>> watchUserRecweets(
    String userId, {
    int limit = 50,
  }) {
    return _userRecweetsRef(userId)
        .orderBy('recweetedAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      final activities = <CwitterProfileActivity>[];
      for (final doc in snapshot.docs) {
        final recweet = CwitterRecweet.fromFirestore(doc);
        final postSnap =
            await _firestore.collection(_postsCollection).doc(recweet.postId).get();
        if (!postSnap.exists) continue;

        activities.add(
          CwitterProfileActivity.recweet(
            recweet: recweet,
            post: CwitterPost.fromFirestore(postSnap),
          ),
        );
      }
      return activities;
    });
  }

  /// 投稿・返信・recweet を時系列でマージ
  static Stream<List<CwitterProfileActivity>> watchUserActivity(
    String authorId, {
    int limit = 50,
  }) {
    return Stream.multi((controller) {
      var posts = <CwitterPost>[];
      var replyActivities = <CwitterProfileActivity>[];
      var recweetActivities = <CwitterProfileActivity>[];
      var postsReady = false;
      var repliesReady = false;
      var recweetsReady = false;

      void emitMerged() {
        if (!postsReady || !repliesReady || !recweetsReady) return;
        final merged = <CwitterProfileActivity>[
          ...posts.map(CwitterProfileActivity.post),
          ...replyActivities,
          ...recweetActivities,
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        controller.add(
          merged.length > limit ? merged.sublist(0, limit) : merged,
        );
      }

      final postsSub = watchMyPosts(authorId, limit: limit).listen(
        (value) {
          posts = value;
          postsReady = true;
          emitMerged();
        },
        onError: controller.addError,
      );
      final repliesSub = watchUserReplies(authorId, limit: limit).listen(
        (value) {
          replyActivities = value;
          repliesReady = true;
          emitMerged();
        },
        onError: controller.addError,
      );
      final recweetsSub = watchUserRecweets(authorId, limit: limit).listen(
        (value) {
          recweetActivities = value;
          recweetsReady = true;
          emitMerged();
        },
        onError: controller.addError,
      );

      controller.onCancel = () {
        postsSub.cancel();
        repliesSub.cancel();
        recweetsSub.cancel();
      };
    });
  }

  static CollectionReference<Map<String, dynamic>> _userLikesRef(String userId) =>
      _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('cwitter_likes');

  static CollectionReference<Map<String, dynamic>> _userRecweetsRef(
    String userId,
  ) =>
      _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_recweetsCollection);

  /// 指定ユーザーたちの recweet 一覧（フォロー中フィード用）
  static Stream<List<CwitterRecweet>> watchRecweetsFromUserIds(
    Set<String> userIds, {
    int limitPerUser = 50,
  }) {
    if (userIds.isEmpty) return Stream.value(const []);

    late StreamController<List<CwitterRecweet>> controller;
    final latest = <String, List<CwitterRecweet>>{};
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emitMerged() {
      if (controller.isClosed) return;
      final merged = latest.values.expand((list) => list).toList()
        ..sort((a, b) => b.recweetedAt.compareTo(a.recweetedAt));
      controller.add(merged);
    }

    controller = StreamController<List<CwitterRecweet>>.broadcast(
      onListen: () {
        for (final userId in userIds) {
          final sub = _userRecweetsRef(userId)
              .orderBy('recweetedAt', descending: true)
              .limit(limitPerUser)
              .snapshots()
              .listen(
            (snapshot) {
              latest[userId] =
                  snapshot.docs.map(CwitterRecweet.fromFirestore).toList();
              emitMerged();
            },
            onError: controller.addError,
          );
          subscriptions.add(sub);
        }
      },
      onCancel: () async {
        for (final sub in subscriptions) {
          await sub.cancel();
        }
        subscriptions.clear();
      },
    );

    return controller.stream;
  }

  /// recweet 済みか
  static Stream<bool> watchIsRecweeted({
    required String userId,
    required String postId,
  }) {
    return _userRecweetsRef(userId)
        .doc(postId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  /// recweet / 取り消し
  static Future<void> toggleRecweet({
    required String postId,
    required String userId,
    required String displayName,
    required String cwitterId,
    required String originalAuthorId,
    String? profileImageUrl,
  }) async {
    if (userId != originalAuthorId &&
        await UserBlockService.isBlocked(
          userId: userId,
          blockedUserId: originalAuthorId,
        )) {
      throw StateError('ブロック中のユーザーのCweetはrecweetできません');
    }
    if (userId != originalAuthorId &&
        await UserBlockService.isBlocked(
          userId: originalAuthorId,
          blockedUserId: userId,
        )) {
      throw StateError('このCweetはrecweetできません');
    }

    final ref = _userRecweetsRef(userId).doc(postId);
    final postRef = _firestore.collection(_postsCollection).doc(postId);

    await _firestore.runTransaction((transaction) async {
      final recweetSnap = await transaction.get(ref);
      final postSnap = await transaction.get(postRef);
      if (!postSnap.exists) return;

      final currentCount =
          (postSnap.data()?['recweetCount'] as num?)?.toInt() ?? 0;

      if (recweetSnap.exists) {
        transaction.delete(ref);
        transaction.update(postRef, {
          'recweetCount': currentCount > 0 ? currentCount - 1 : 0,
        });
        return;
      }

      transaction.set(ref, {
        'postId': postId,
        'originalAuthorId': originalAuthorId,
        'displayName': displayName,
        'cwitterId': normalizeCwitterId(cwitterId),
        if (profileImageUrl != null && profileImageUrl.trim().isNotEmpty)
          'profileImageUrl': profileImageUrl.trim(),
        'recweetedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {
        'recweetCount': currentCount + 1,
      });
    });
  }

  static CollectionReference<Map<String, dynamic>> _followingRef(String userId) =>
      _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_followingCollection);

  static CollectionReference<Map<String, dynamic>> _followersRef(String userId) =>
      _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_followersCollection);

  static DocumentReference<Map<String, dynamic>> _followStatsRef(String userId) =>
      _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_socialCollection)
          .doc(_socialStatsDocId);

  /// フォロワー数・フォロー中数（サブコレクションの実件数を正とする）
  static Stream<CwitterFollowCounts> watchFollowCounts(String userId) {
    late StreamController<CwitterFollowCounts> controller;
    var followingCount = 0;
    var followerCount = 0;
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emit() {
      if (controller.isClosed) return;
      controller.add(
        CwitterFollowCounts(
          followerCount: followerCount,
          followingCount: followingCount,
        ),
      );
    }

    controller = StreamController<CwitterFollowCounts>.broadcast(
      onListen: () {
        subscriptions.add(
          _followingRef(userId).snapshots().listen(
            (snapshot) {
              followingCount = snapshot.docs.length;
              emit();
            },
            onError: controller.addError,
          ),
        );
        subscriptions.add(
          _followersRef(userId).snapshots().listen(
            (snapshot) {
              followerCount = snapshot.docs.length;
              emit();
            },
            onError: controller.addError,
          ),
        );
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
        subscriptions.clear();
      },
    );

    return controller.stream;
  }

  /// ユーザーの Cweet 数（投稿 + 返信 + recweet）
  static Stream<CwitterActivityCounts> watchUserCweetCounts(String userId) {
    late StreamController<CwitterActivityCounts> controller;
    var postCount = 0;
    var replyCount = 0;
    var recweetCount = 0;
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emit() {
      if (controller.isClosed) return;
      controller.add(
        CwitterActivityCounts(
          postCount: postCount,
          replyCount: replyCount,
          recweetCount: recweetCount,
        ),
      );
    }

    controller = StreamController<CwitterActivityCounts>.broadcast(
      onListen: () {
        subscriptions.add(
          _firestore
              .collection(_postsCollection)
              .where('authorId', isEqualTo: userId)
              .snapshots()
              .listen(
            (snapshot) {
              postCount = snapshot.docs.length;
              emit();
            },
            onError: controller.addError,
          ),
        );
        subscriptions.add(
          _firestore
              .collection(_repliesIndexCollection)
              .where('authorId', isEqualTo: userId)
              .snapshots()
              .listen(
            (snapshot) {
              replyCount = snapshot.docs.length;
              emit();
            },
            onError: controller.addError,
          ),
        );
        subscriptions.add(
          _userRecweetsRef(userId).snapshots().listen(
            (snapshot) {
              recweetCount = snapshot.docs.length;
              emit();
            },
            onError: controller.addError,
          ),
        );
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
        subscriptions.clear();
      },
    );

    return controller.stream;
  }

  /// フォロー中か
  static Stream<bool> watchIsFollowing({
    required String followerId,
    required String followeeId,
  }) {
    if (followerId == followeeId) {
      return Stream.value(false);
    }
    return _followingRef(followerId)
        .doc(followeeId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  /// フォロー中ユーザー ID 一覧
  static Stream<Set<String>> watchFollowingUserIds(String userId) {
    return _followingRef(userId).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.id).toSet(),
        );
  }

  /// フォロー中ユーザー一覧
  static Stream<List<CwitterFollowUser>> watchFollowingUsers(String userId) {
    return _followingRef(userId)
        .orderBy('followedAt', descending: true)
        .snapshots()
        .asyncMap(_mapFollowDocumentsToUsers);
  }

  /// フォロワー一覧
  static Stream<List<CwitterFollowUser>> watchFollowerUsers(String userId) {
    return _followersRef(userId)
        .orderBy('followedAt', descending: true)
        .snapshots()
        .asyncMap(_mapFollowDocumentsToUsers);
  }

  static Future<List<CwitterFollowUser>> _mapFollowDocumentsToUsers(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (snapshot.docs.isEmpty) return const [];

    final users = await Future.wait(
      snapshot.docs.map((doc) async {
        final followedAtRaw = doc.data()['followedAt'];
        DateTime? followedAt;
        if (followedAtRaw is Timestamp) {
          followedAt = followedAtRaw.toDate();
        }

        final user = await _fetchFollowUser(doc.id);
        if (user == null) return null;

        return CwitterFollowUser(
          authorId: user.authorId,
          displayName: user.displayName,
          cwitterId: user.cwitterId,
          profileImageUrl: user.profileImageUrl,
          bio: user.bio,
          followedAt: followedAt,
        );
      }),
    );

    return users.whereType<CwitterFollowUser>().toList();
  }

  static Future<CwitterFollowUser?> _fetchFollowUser(String userId) async {
    final userSnap =
        await _firestore.collection(_usersCollection).doc(userId).get();
    if (!userSnap.exists) return null;

    return _followUserFromData(userId, userSnap.data()!);
  }

  /// 指定 Cweet にいいねしたユーザー一覧
  static Stream<List<CwitterFollowUser>> watchPostLikers(String postId) {
    return _firestore
        .collection(_postsCollection)
        .doc(postId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (!snapshot.exists) return const <CwitterFollowUser>[];

      final likedBy = snapshot.data()?['likedBy'];
      if (likedBy is! Map) return const <CwitterFollowUser>[];

      final userIds = likedBy.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key.toString())
          .toList();
      if (userIds.isEmpty) return const <CwitterFollowUser>[];

      final users = await Future.wait(
        userIds.map((userId) => _fetchFollowUser(userId)),
      );
      return users.whereType<CwitterFollowUser>().toList();
    });
  }

  /// 指定 Cweet の返信数
  static Stream<int> watchPostReplyCount(String postId) {
    return _firestore.collection(_postsCollection).doc(postId).snapshots().map(
          (snapshot) {
        if (!snapshot.exists) return 0;
        return (snapshot.data()?['replyCount'] as num?)?.toInt() ?? 0;
      },
    );
  }

  /// 指定 Cweet を recweet したユーザー一覧
  static Stream<List<CwitterFollowUser>> watchPostRecweeters(String postId) {
    return _firestore
        .collectionGroup(_recweetsCollection)
        .where('postId', isEqualTo: postId)
        .orderBy('recweetedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final recweet = CwitterRecweet.fromFirestore(doc);
        return CwitterFollowUser(
          authorId: recweet.userId,
          displayName: recweet.displayName,
          cwitterId: recweet.cwitterId,
          profileImageUrl: recweet.profileImageUrl,
          followedAt: recweet.recweetedAt,
        );
      }).toList();
    });
  }

  static String? _parseCwitterBio(dynamic value) {
    if (value == null) return null;
    final bio = value.toString().trim();
    return bio.isEmpty ? null : bio;
  }

  static String _normalizeCwitterTag(String raw) {
    var tag = raw.trim();
    if (tag.startsWith('#')) {
      tag = tag.substring(1).trim();
    }
    return tag;
  }

  static List<String> normalizeCwitterTags(List<String> tags) {
    final normalized = <String>[];
    for (final raw in tags) {
      final tag = _normalizeCwitterTag(raw);
      if (tag.isEmpty) continue;
      if (!AppConstants.isValidCwitterTag(tag)) {
        throw ArgumentError(AppConstants.errorCwitterTagFormat);
      }
      if (normalized.contains(tag)) continue;
      normalized.add(tag);
      if (normalized.length >= AppConstants.cwitterTagsMaxCount) break;
    }
    return normalized;
  }

  /// Cwitter プロフィールのハッシュタグを更新
  static Future<void> updateCwitterTags({
    required String uid,
    required List<String> tags,
  }) async {
    final normalized = normalizeCwitterTags(tags);

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (normalized.isEmpty) {
      updates['cwitterTags'] = FieldValue.delete();
    } else {
      updates['cwitterTags'] = normalized;
    }

    await _firestore.collection(_usersCollection).doc(uid).set(
          updates,
          SetOptions(merge: true),
        );
  }

  /// Cwitter プロフィールの自己紹介を更新
  static Future<void> updateCwitterBio({
    required String uid,
    required String bio,
  }) async {
    final trimmed = bio.trim();
    if (trimmed.length > AppConstants.cwitterBioMaxLength) {
      throw ArgumentError(
        '自己紹介は${AppConstants.cwitterBioMaxLength}文字以内で入力してください',
      );
    }

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (trimmed.isEmpty) {
      updates['cwitterBio'] = FieldValue.delete();
    } else {
      updates['cwitterBio'] = trimmed;
    }

    await _firestore.collection(_usersCollection).doc(uid).set(
          updates,
          SetOptions(merge: true),
        );
  }

  /// Cwitter プロフィールの SNS リンクを更新
  static Future<void> updateCwitterSocialLinks({
    required String uid,
    required Map<String, String> links,
  }) async {
    final sanitized = CwitterSocialPlatform.sanitizeLinks(links);

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (sanitized.isEmpty) {
      updates['cwitterSocialLinks'] = FieldValue.delete();
    } else {
      updates['cwitterSocialLinks'] = sanitized;
    }

    await _firestore.collection(_usersCollection).doc(uid).set(
          updates,
          SetOptions(merge: true),
        );
  }

  static Future<void> followUser({
    required String followerId,
    required String followeeId,
    bool sendNotification = true,
  }) async {
    if (followerId == followeeId) {
      throw ArgumentError('自分自身をフォローすることはできません');
    }
    if (await UserBlockService.isBlocked(
      userId: followerId,
      blockedUserId: followeeId,
    )) {
      throw StateError('ブロック中のユーザーはフォローできません');
    }
    if (await UserBlockService.isBlocked(
      userId: followeeId,
      blockedUserId: followerId,
    )) {
      throw StateError('このユーザーはフォローできません');
    }

    final followingRef = _followingRef(followerId).doc(followeeId);
    final followerRef = _followersRef(followeeId).doc(followerId);
    final followerStatsRef = _followStatsRef(followerId);
    final followeeStatsRef = _followStatsRef(followeeId);

    final didFollow = await _firestore.runTransaction<bool>((transaction) async {
      final followingSnap = await transaction.get(followingRef);
      if (followingSnap.exists) return false;

      final followerSnap = await transaction.get(followerRef);
      final followerStatsSnap = await transaction.get(followerStatsRef);
      final followeeStatsSnap = await transaction.get(followeeStatsRef);

      transaction.set(followingRef, {
        'followedAt': FieldValue.serverTimestamp(),
      });
      if (followerSnap.exists) {
        // 不整合データ（followers のみ残存）を修復してから再作成
        transaction.delete(followerRef);
      }
      transaction.set(followerRef, {
        'followedAt': FieldValue.serverTimestamp(),
      });

      if (followerStatsSnap.exists) {
        transaction.update(followerStatsRef, {
          'followingCount': FieldValue.increment(1),
        });
      } else {
        transaction.set(followerStatsRef, {
          'followingCount': 1,
          'followerCount': 0,
        });
      }

      if (followeeStatsSnap.exists) {
        transaction.update(followeeStatsRef, {
          'followerCount': FieldValue.increment(1),
        });
      } else {
        transaction.set(followeeStatsRef, {
          'followerCount': 1,
          'followingCount': 0,
        });
      }

      return true;
    });

    if (!didFollow || !sendNotification) return;

    try {
      final followerSnap =
          await _firestore.collection(_usersCollection).doc(followerId).get();
      if (!followerSnap.exists) return;

      final followerData = followerSnap.data()!;
      final displayName = followerData['displayName']?.toString().trim();
      final cwitterId = followerData['cwitterId']?.toString().trim();
      if (displayName == null ||
          displayName.isEmpty ||
          cwitterId == null ||
          cwitterId.isEmpty) {
        return;
      }

      await NotificationService.sendCwitterFollowNotification(
        followeeId: followeeId,
        fromUserName: displayName,
        fromCwitterId: normalizeCwitterId(cwitterId),
        fromUserId: followerId,
      );
    } catch (_) {
      // フォロー自体は成功しているため通知失敗は握りつぶす
    }
  }

  static Future<void> unfollowUser({
    required String followerId,
    required String followeeId,
  }) async {
    if (followerId == followeeId) return;

    final followingRef = _followingRef(followerId).doc(followeeId);
    final followerRef = _followersRef(followeeId).doc(followerId);
    final followerStatsRef = _followStatsRef(followerId);
    final followeeStatsRef = _followStatsRef(followeeId);

    await _firestore.runTransaction((transaction) async {
      final followingSnap = await transaction.get(followingRef);
      if (!followingSnap.exists) return;

      final followerStatsSnap = await transaction.get(followerStatsRef);
      final followeeStatsSnap = await transaction.get(followeeStatsRef);

      transaction.delete(followingRef);
      transaction.delete(followerRef);

      if (followerStatsSnap.exists) {
        transaction.update(followerStatsRef, {
          'followingCount': FieldValue.increment(-1),
        });
      }
      if (followeeStatsSnap.exists) {
        transaction.update(followeeStatsRef, {
          'followerCount': FieldValue.increment(-1),
        });
      }
    });
  }

  /// 双方向のフォロー関係を解除（ブロック時など）
  static Future<void> removeFollowRelationship({
    required String userIdA,
    required String userIdB,
  }) async {
    if (userIdA == userIdB) return;
    await unfollowUser(followerId: userIdA, followeeId: userIdB);
    await unfollowUser(followerId: userIdB, followeeId: userIdA);
  }

  static DocumentReference<Map<String, dynamic>> _replyIndexRef({
    required String postId,
    required String replyId,
  }) {
    return _firestore
        .collection(_repliesIndexCollection)
        .doc('${postId}_$replyId');
  }

  /// いいねした投稿一覧（users/{uid}/cwitter_likes から参照）
  static Stream<List<CwitterPost>> watchLikedPosts(
    String userId, {
    int limit = 50,
  }) {
    return _userLikesRef(userId)
        .orderBy('likedAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((likesSnap) async {
      if (likesSnap.docs.isEmpty) return <CwitterPost>[];

      final posts = <CwitterPost>[];
      for (final likeDoc in likesSnap.docs) {
        final postSnap = await _firestore
            .collection(_postsCollection)
            .doc(likeDoc.id)
            .get();
        if (postSnap.exists) {
          posts.add(CwitterPost.fromFirestore(postSnap));
        }
      }
      return posts;
    });
  }

  static Future<void> createPost({
    required String authorId,
    required String authorEmail,
    required String cwitterId,
    required String displayName,
    required String body,
    String? profileImageUrl,
    List<XFile>? imageFiles,
    List<String>? pollOptions,
  }) async {
    final trimmed = body.trim();
    final files = imageFiles ?? const <XFile>[];
    final pollTexts = _normalizePollOptions(pollOptions);
    final hasPoll = pollTexts != null;

    if (trimmed.isEmpty && files.isEmpty && !hasPoll) {
      throw ArgumentError('Cweetする内容、画像、または投票を入力してください');
    }
    if (hasPoll && files.isNotEmpty) {
      throw ArgumentError('投票と画像は同時に投稿できません');
    }
    if (trimmed.length > _maxPostLength) {
      throw ArgumentError('Cweetは$_maxPostLength文字以内で入力してください');
    }
    if (files.length > CwitterPostImageService.maxImagesPerPost) {
      throw ArgumentError(
        '画像は最大${CwitterPostImageService.maxImagesPerPost}枚までです',
      );
    }

    final email = authorEmail.trim().toLowerCase();
    if (email.isEmpty) {
      throw ArgumentError('登録メールアドレスを取得できませんでした');
    }

    final postRef = _firestore.collection(_postsCollection).doc();
    final rateLimitRef = UserPostRateLimit.ref(
      _firestore,
      userId: authorId,
      limitKey: UserPostRateLimit.cwitterPostKey,
    );
    final now = DateTime.now();

    final data = <String, dynamic>{
      'authorId': authorId,
      'authorEmail': email,
      'cwitterId': normalizeCwitterId(cwitterId),
      'displayName': displayName,
      'body': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
      'replyCount': 0,
      'likeCount': 0,
      'recweetCount': 0,
      'likedBy': <String, dynamic>{},
    };
    if (profileImageUrl != null && profileImageUrl.trim().isNotEmpty) {
      data['profileImageUrl'] = profileImageUrl.trim();
    }

    if (files.isNotEmpty) {
      final imageUrls = await CwitterPostImageService.uploadPostImages(
        userId: authorId,
        postId: postRef.id,
        files: files,
      );
      data['imageUrls'] = imageUrls;
    }

    if (pollTexts != null) {
      data['poll'] = CwitterPoll(
        options: [
          for (var i = 0; i < pollTexts.length; i++)
            CwitterPollOption(id: '$i', text: pollTexts[i]),
        ],
      ).toMap();
    }

    await _firestore.runTransaction((transaction) async {
      await UserPostRateLimit.enforceInTransaction(
        transaction: transaction,
        rateLimitRef: rateLimitRef,
        now: now,
        rateLimitException: const CwitterPostRateLimitException(),
      );

      transaction.set(postRef, data);
    });
  }

  static List<String>? _normalizePollOptions(List<String>? pollOptions) {
    if (pollOptions == null || pollOptions.isEmpty) return null;

    final normalized = pollOptions
        .map((option) => option.trim())
        .where((option) => option.isNotEmpty)
        .take(CwitterPoll.maxOptions)
        .toList();

    if (normalized.length < CwitterPoll.minOptions) {
      throw ArgumentError(
        '投票の選択肢は${CwitterPoll.minOptions}件以上入力してください',
      );
    }

    for (final option in normalized) {
      if (option.length > CwitterPoll.maxOptionTextLength) {
        throw ArgumentError(
          '選択肢は${CwitterPoll.maxOptionTextLength}文字以内で入力してください',
        );
      }
    }

    return normalized;
  }

  static Future<CwitterPoll> castPollVote({
    required String postId,
    required String userId,
    required String optionId,
  }) async {
    final postRef = _firestore.collection(_postsCollection).doc(postId);

    return _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(postRef);
      if (!snap.exists) {
        throw StateError('Cweetが見つかりません');
      }

      final pollRaw = snap.data()?['poll'];
      if (pollRaw is! Map) {
        throw StateError('このCweetに投票はありません');
      }

      final poll = CwitterPoll.fromMap(Map<String, dynamic>.from(pollRaw));
      if (!poll.hasPoll) {
        throw StateError('このCweetに投票はありません');
      }
      if (poll.hasVoted(userId)) {
        throw StateError('すでに投票済みです');
      }

      final hasOption = poll.options.any((option) => option.id == optionId);
      if (!hasOption) {
        throw ArgumentError('無効な選択肢です');
      }

      final updatedOptions = poll.options
          .map(
            (option) => option.id == optionId
                ? option.copyWith(voteCount: option.voteCount + 1)
                : option,
          )
          .toList();
      final updatedVotedBy = Map<String, String>.from(poll.votedBy)
        ..[userId] = optionId;
      final updatedPoll = poll.copyWith(
        options: updatedOptions,
        votedBy: updatedVotedBy,
      );

      transaction.update(postRef, {'poll': updatedPoll.toMap()});
      return updatedPoll;
    });
  }

  static Stream<List<CwitterReply>> watchReplies(String postId) {
    return _firestore
        .collection(_postsCollection)
        .doc(postId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CwitterReply.fromFirestore(postId, doc))
              .toList(),
        );
  }

  static Future<void> createReply({
    required String postId,
    required String authorId,
    required String authorEmail,
    required String cwitterId,
    required String displayName,
    required String body,
    String? profileImageUrl,
    String? inReplyToReplyId,
    List<XFile>? imageFiles,
  }) async {
    final trimmed = body.trim();
    final files = imageFiles ?? const <XFile>[];
    if (trimmed.isEmpty && files.isEmpty) {
      throw ArgumentError('返信内容または画像を入力してください');
    }
    if (trimmed.length > _maxPostLength) {
      throw ArgumentError('返信は$_maxPostLength文字以内で入力してください');
    }
    if (files.length > CwitterPostImageService.maxImagesPerPost) {
      throw ArgumentError(
        '画像は最大${CwitterPostImageService.maxImagesPerPost}枚までです',
      );
    }

    final postRef = _firestore.collection(_postsCollection).doc(postId);
    final postSnap = await postRef.get();
    if (!postSnap.exists) {
      throw StateError('Cweetが見つかりません');
    }
    final postData = postSnap.data()!;
    final postAuthorId = postData['authorId'] as String? ?? '';
    final postBody = postData['body'] as String? ?? '';

    final replyRef = postRef.collection('replies').doc();
    final email = authorEmail.trim().toLowerCase();
    if (email.isEmpty) {
      throw ArgumentError('登録メールアドレスを取得できませんでした');
    }

    final replyData = <String, dynamic>{
      'authorId': authorId,
      'authorEmail': email,
      'cwitterId': normalizeCwitterId(cwitterId),
      'displayName': displayName,
      'body': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (profileImageUrl != null && profileImageUrl.trim().isNotEmpty) {
      replyData['profileImageUrl'] = profileImageUrl.trim();
    }
    if (inReplyToReplyId != null && inReplyToReplyId.trim().isNotEmpty) {
      replyData['inReplyToReplyId'] = inReplyToReplyId.trim();
    }
    if (files.isNotEmpty) {
      replyData['imageUrls'] = await CwitterPostImageService.uploadReplyImages(
        userId: authorId,
        postId: postId,
        replyId: replyRef.id,
        files: files,
      );
    }

    final replyIndexData = <String, dynamic>{
      ...replyData,
      'postId': postId,
      'replyId': replyRef.id,
    };

    final rateLimitRef = UserPostRateLimit.ref(
      _firestore,
      userId: authorId,
      limitKey: UserPostRateLimit.cwitterReplyKey,
    );
    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      await UserPostRateLimit.enforceInTransaction(
        transaction: transaction,
        rateLimitRef: rateLimitRef,
        now: now,
        rateLimitException: const CwitterReplyRateLimitException(),
      );

      transaction.set(replyRef, replyData);
      transaction.set(
        _replyIndexRef(postId: postId, replyId: replyRef.id),
        replyIndexData,
      );
      transaction.update(postRef, {'replyCount': FieldValue.increment(1)});
    });

    try {
      await NotificationService.sendCwitterReplyNotification(
        postAuthorId: postAuthorId,
        postId: postId,
        replyId: replyRef.id,
        fromUserName: displayName,
        fromCwitterId: normalizeCwitterId(cwitterId),
        fromUserId: authorId,
        postBodyPreview: postBody,
      );
    } catch (_) {
      // 返信自体は成功しているため通知失敗は握りつぶす
    }
  }

  static Future<void> toggleLike({
    required String postId,
    required String userId,
    required String likerDisplayName,
    required String likerCwitterId,
  }) async {
    final postRef = _firestore.collection(_postsCollection).doc(postId);
    var addedLike = false;
    String postAuthorId = '';
    String postBody = '';

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(postRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      postAuthorId = data['authorId'] as String? ?? '';
      postBody = data['body'] as String? ?? '';
      final likedBy = Map<String, dynamic>.from(
        data['likedBy'] as Map<String, dynamic>? ?? {},
      );
      final currentCount = (data['likeCount'] as num?)?.toInt() ?? 0;
      final alreadyLiked = likedBy[userId] == true;

      final likeRef = _userLikesRef(userId).doc(postId);

      if (alreadyLiked) {
        likedBy.remove(userId);
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likeCount': currentCount > 0 ? currentCount - 1 : 0,
        });
        transaction.delete(likeRef);
      } else {
        likedBy[userId] = true;
        addedLike = true;
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likeCount': currentCount + 1,
        });
        transaction.set(likeRef, {
          'likedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    if (!addedLike) return;

    // UI をブロックしないよう通知は非同期で送る
    unawaited(
      NotificationService.sendCwitterLikeNotification(
        postAuthorId: postAuthorId,
        postId: postId,
        fromUserName: likerDisplayName,
        fromCwitterId: normalizeCwitterId(likerCwitterId),
        fromUserId: userId,
        postBodyPreview: postBody,
      ).catchError((_) {}),
    );
  }

  static Future<void> deletePost({
    required String postId,
    required String userId,
  }) async {
    final postRef = _firestore.collection(_postsCollection).doc(postId);
    final postSnap = await postRef.get();
    if (!postSnap.exists) return;
    if (postSnap.data()?['authorId'] != userId) {
      throw StateError('削除権限がありません');
    }

    final imageUrls = CwitterPost.fromFirestore(postSnap).imageUrls;
    if (imageUrls.isNotEmpty) {
      await CwitterPostImageService.deletePostImages(
        userId: userId,
        postId: postId,
        imageUrls: imageUrls,
      );
    }

    final repliesSnap = await postRef.collection('replies').get();
    final batch = _firestore.batch();
    for (final doc in repliesSnap.docs) {
      batch.delete(doc.reference);
      batch.delete(_replyIndexRef(postId: postId, replyId: doc.id));
    }
    batch.delete(postRef);
    await batch.commit();
  }

  static Future<void> deleteReply({
    required String postId,
    required String replyId,
    required String userId,
  }) async {
    final postRef = _firestore.collection(_postsCollection).doc(postId);
    final replyRef = postRef.collection('replies').doc(replyId);
    final replySnap = await replyRef.get();
    if (!replySnap.exists) return;
    if (replySnap.data()?['authorId'] != userId) {
      throw StateError('削除権限がありません');
    }

    final imageUrls =
        CwitterReply.parseImageUrls(replySnap.data()?['imageUrls']);
    if (imageUrls.isNotEmpty) {
      await CwitterPostImageService.deleteReplyImages(
        userId: userId,
        postId: postId,
        replyId: replyId,
      );
    }

    final batch = _firestore.batch();
    batch.delete(replyRef);
    batch.delete(_replyIndexRef(postId: postId, replyId: replyId));
    batch.update(postRef, {'replyCount': FieldValue.increment(-1)});
    await batch.commit();
  }
}
