import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/users/blocked_user_model.dart';

class UserBlockService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ユーザーをブロック
  static Future<void> blockUser({
    required String blockedUserId,
    required String blockedUserName,
    required BlockReason reason,
    String? notes,
  }) async {
    try {
      // 認証チェック
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('ユーザーが認証されていません。ログインしてください。');
      }

      // 自分自身をブロックしようとしていないかチェック
      if (currentUser.uid == blockedUserId) {
        throw Exception('自分自身をブロックすることはできません。');
      }

      // 既にブロック済みかチェック
      final bool alreadyBlocked = await isBlocked(
        userId: currentUser.uid,
        blockedUserId: blockedUserId,
      );
      if (alreadyBlocked) {
        throw Exception('このユーザーは既にブロックされています。');
      }

      // メモが500文字以内かチェック
      if (notes != null && notes.length > 500) {
        throw Exception('メモは500文字以内で入力してください。');
      }

      // ブロックデータを作成
      final BlockedUser blockedUser = BlockedUser(
        id: '', // Firestoreで自動生成
        blockedUserId: blockedUserId,
        blockedUserName: blockedUserName,
        userId: currentUser.uid,
        reason: reason,
        notes: notes,
        blockedAt: DateTime.now(),
      );

      // Firestoreに保存
      await _firestore.collection('blocked_users').add(blockedUser.toJson());
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ユーザーのブロックに失敗しました: $e');
    }
  }

  /// ユーザーのブロックを解除
  static Future<void> unblockUser({
    required String blockedUserId,
  }) async {
    try {
      // 認証チェック
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('ユーザーが認証されていません。');
      }

      // ブロックレコードを取得
      final QuerySnapshot snapshot = await _firestore
          .collection('blocked_users')
          .where('userId', isEqualTo: currentUser.uid)
          .where('blockedUserId', isEqualTo: blockedUserId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('ブロック情報が見つかりません。');
      }

      // ブロックレコードを削除
      await _firestore
          .collection('blocked_users')
          .doc(snapshot.docs.first.id)
          .delete();
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ブロック解除に失敗しました: $e');
    }
  }

  /// ブロックしたユーザー一覧を取得（Stream）
  static Stream<List<BlockedUser>> watchBlockedUsers() {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return Stream.value([]);
      }

      return _firestore
          .collection('blocked_users')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('blockedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return BlockedUser.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      });
    } catch (e) {
      print('ブロックユーザー取得時のエラー: $e');
      return Stream.value([]);
    }
  }

  /// ブロックしたユーザー一覧を取得（Future）
  static Future<List<BlockedUser>> getBlockedUsers() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      final QuerySnapshot snapshot = await _firestore
          .collection('blocked_users')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('blockedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return BlockedUser.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      print('ブロックユーザー取得時のエラー: $e');
      return [];
    }
  }

  /// ブロックしたユーザーIDのセットを取得
  static Future<Set<String>> getBlockedUserIds() async {
    try {
      final List<BlockedUser> blockedUsers = await getBlockedUsers();
      return blockedUsers.map((user) => user.blockedUserId).toSet();
    } catch (e) {
      print('ブロックユーザーID取得時のエラー: $e');
      return {};
    }
  }

  /// 特定のユーザーがブロック済みかチェック
  static Future<bool> isBlocked({
    String? userId,
    required String blockedUserId,
  }) async {
    try {
      final String checkUserId = userId ?? _auth.currentUser?.uid ?? '';
      if (checkUserId.isEmpty) {
        return false;
      }

      final QuerySnapshot snapshot = await _firestore
          .collection('blocked_users')
          .where('userId', isEqualTo: checkUserId)
          .where('blockedUserId', isEqualTo: blockedUserId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('ブロック状態チェック時のエラー: $e');
      return false;
    }
  }

  /// ブロック数を取得
  static Future<int> getBlockedUserCount() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return 0;
      }

      final QuerySnapshot snapshot = await _firestore
          .collection('blocked_users')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('ブロック数取得時のエラー: $e');
      return 0;
    }
  }
}
