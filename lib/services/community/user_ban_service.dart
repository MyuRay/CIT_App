import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/community/user_ban.dart';

/// 垢BAN中のユーザーが投稿系の操作を行ったときに投げる例外。
class UserBannedException implements Exception {
  const UserBannedException(this.ban);

  final UserBan ban;

  /// ユーザーに表示するメッセージ（理由・期間を含む）
  String get message {
    final buffer = StringBuffer('お使いのアカウントはBANされているため投稿ができません');
    buffer.write('\n\n理由: ${ban.reason.label}');
    if (ban.isPermanent) {
      buffer.write('\n処分: 永久BAN');
    } else {
      final expires = ban.expiresAt;
      if (expires != null) {
        buffer.write('\n解除予定: ${_formatDate(expires)}');
      } else {
        buffer.write('\n処分: ${ban.duration.label}');
      }
    }
    return buffer.toString();
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}/${two(local.month)}/${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  String toString() => message;
}

/// Cwitter・ちばちゃんねるの垢BANを管理するサービス。
class UserBanService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'banned_users';

  // BAN中ユーザーの投稿を全員から非表示にするための公開索引。
  // 理由などの機微情報は含めず、UID と期限のみを持つ（全認証ユーザーが読み取り可）。
  static const String _indexCollection = 'moderation';
  static const String _indexDocId = 'banned_index';

  static DocumentReference<Map<String, dynamic>> _ref(String userId) =>
      _firestore.collection(_collection).doc(userId);

  static DocumentReference<Map<String, dynamic>> _indexRef() =>
      _firestore.collection(_indexCollection).doc(_indexDocId);

  /// 指定ユーザーの有効なBANを取得（期限切れ・未BANなら null）
  static Future<UserBan?> getActiveBan(String userId) async {
    if (userId.isEmpty) return null;
    final snap = await _ref(userId).get();
    if (!snap.exists) return null;

    final ban = UserBan.fromJson(userId, snap.data() ?? <String, dynamic>{});
    return ban.isActiveAt(DateTime.now()) ? ban : null;
  }

  /// 指定ユーザーのBANをリアルタイム監視（期限切れ・未BANなら null）
  static Stream<UserBan?> watchActiveBan(String userId) {
    if (userId.isEmpty) return Stream.value(null);
    return _ref(userId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final ban = UserBan.fromJson(userId, snap.data() ?? <String, dynamic>{});
      return ban.isActiveAt(DateTime.now()) ? ban : null;
    });
  }

  /// BAN中なら [UserBannedException] を投げる（投稿系操作の前段チェック）
  static Future<void> requireNotBanned(String userId) async {
    final ban = await getActiveBan(userId);
    if (ban != null) {
      throw UserBannedException(ban);
    }
  }

  /// ユーザーをBANする（運営・管理者のみ）
  static Future<UserBan> banUser({
    required String targetUserId,
    required BanReason reason,
    required BanDuration duration,
    required String adminId,
  }) async {
    if (targetUserId.isEmpty) {
      throw ArgumentError('対象ユーザーが不正です');
    }

    final now = DateTime.now();
    final expiresAt =
        duration.duration == null ? null : now.add(duration.duration!);

    final ban = UserBan(
      userId: targetUserId,
      reason: reason,
      duration: duration,
      bannedAt: now,
      expiresAt: expiresAt,
      bannedBy: adminId,
    );

    await _ref(targetUserId).set(ban.toJson());

    // 全員向けの非表示用索引にも反映（理由は含めない）
    await _indexRef().set({
      'users': {
        targetUserId: {
          'permanent': ban.isPermanent,
          'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt),
        },
      },
    }, SetOptions(merge: true));

    return ban;
  }

  /// BANを解除する（運営・管理者のみ）
  static Future<void> unbanUser(String targetUserId) async {
    if (targetUserId.isEmpty) return;
    await _ref(targetUserId).delete();
    await _indexRef().set({
      'users': {targetUserId: FieldValue.delete()},
    }, SetOptions(merge: true));
  }

  /// 現在BAN中（期限内）のユーザーIDをリアルタイム監視する。
  /// 投稿一覧から該当ユーザーの投稿を非表示にするために利用する。
  static Stream<Set<String>> watchActiveBannedUserIds() {
    return _indexRef().snapshots().map((snap) {
      if (!snap.exists) return <String>{};
      final data = snap.data();
      final users = data?['users'];
      if (users is! Map) return <String>{};

      final now = DateTime.now();
      final ids = <String>{};
      users.forEach((key, value) {
        if (key is! String || value is! Map) return;
        final permanent = value['permanent'] == true;
        final expiresRaw = value['expiresAt'];
        final expiresAt =
            expiresRaw is Timestamp ? expiresRaw.toDate() : null;
        final isActive =
            permanent || (expiresAt != null && now.isBefore(expiresAt));
        if (isActive) {
          ids.add(key);
        }
      });
      return ids;
    }).handleError(
      // 索引の読み取りに失敗（ルール未デプロイ等）してもフィードを壊さない
      (_) {},
      test: (_) => true,
    );
  }
}
