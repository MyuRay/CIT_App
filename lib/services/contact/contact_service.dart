import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/admin/admin_model.dart';
import '../../models/notification/notification_model.dart';
import '../../core/providers/notification_provider.dart';

class ContactService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collectionName = 'contact_forms';

  // お問い合わせを作成
  static Future<String> createContact({
    String? name,
    String? email,
    required String category,
    required String categoryName,
    required String subject,
    required String message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ログインが必要です');
      }

      final contact = ContactForm(
        id: '', // 後でdoc.idを設定
        name: name?.trim(),
        email: email?.trim(),
        category: category,
        categoryName: categoryName,
        subject: subject.trim(),
        message: message.trim(),
        createdAt: DateTime.now(),
        status: 'pending',
        userId: user.uid,
      );

      // ルール互換のためdoc().setで作成時にidを含める
      final docRef = _firestore.collection(_collectionName).doc();
      final data = contact.toJson();
      data['id'] = docRef.id; // 作成時にidを含める

      // 環境によっては追加で必須とされるフィールドに対応（存在しても無害）
      data['userEmail'] = user.email ?? (email ?? ''); // string必須想定
      data['title'] = contact.subject; // subjectの別名
      data['deviceInfo'] = <String, dynamic>{}; // map型で最低限充足
      data['appInfo'] = <String, dynamic>{}; // map型で最低限充足

      await docRef.set(data);

      print('✅ お問い合わせを作成しました: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ お問い合わせ作成エラー: $e');
      rethrow;
    }
  }

  // 全てのお問い合わせを取得（管理者用）
  static Stream<List<ContactForm>> getAllContacts({
    String? statusFilter,
    String? categoryFilter,
  }) {
    Query query = _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true);

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      query = query.where('category', isEqualTo: categoryFilter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        // ドキュメントIDを確実に設定
        data['id'] = doc.id;
        return ContactForm.fromJson(data);
      }).toList();
    });
  }

  // 特定のお問い合わせを取得
  static Future<ContactForm?> getContactById(String contactId) async {
    try {
      if (contactId.isEmpty) {
        print('❌ お問い合わせID取得エラー: IDが空文字列です');
        throw ArgumentError('お問い合わせIDが空文字列です');
      }
      
      final doc = await _firestore
          .collection(_collectionName)
          .doc(contactId)
          .get();
      
      if (doc.exists) {
        final data = Map<String, dynamic>.from(doc.data()! as Map<String, dynamic>);
        // ドキュメントIDを確実に設定
        data['id'] = doc.id;
        return ContactForm.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ お問い合わせ取得エラー: $e');
      rethrow;
    }
  }

  // ユーザー自身のお問い合わせを取得
  static Stream<List<ContactForm>> getUserContacts(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        // ドキュメントIDを確実に設定
        data['id'] = doc.id;
        return ContactForm.fromJson(data);
      }).toList();
    });
  }

  // お問い合わせのステータスを更新
  static Future<void> updateContactStatus(String contactId, String newStatus) async {
    try {
      if (contactId.isEmpty) {
        print('❌ ステータス更新エラー: IDが空文字列です');
        throw ArgumentError('お問い合わせIDが空文字列です');
      }
      
      await _firestore
          .collection(_collectionName)
          .doc(contactId)
          .update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });
      
      print('✅ ステータスを更新しました: $contactId -> $newStatus');
    } catch (e) {
      print('❌ ステータス更新エラー: $e');
      rethrow;
    }
  }

  // お問い合わせに返信
  static Future<void> respondToContact({
    required String contactId,
    required String response,
  }) async {
    try {
      if (contactId.isEmpty) {
        print('❌ 返信送信エラー: IDが空文字列です');
        throw ArgumentError('お問い合わせIDが空文字列です');
      }
      
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ログインが必要です');
      }

      // お問い合わせ情報を取得（通知送信用）
      final contactDoc = await _firestore
          .collection(_collectionName)
          .doc(contactId)
          .get();
      
      if (!contactDoc.exists) {
        throw Exception('お問い合わせが見つかりません');
      }

      final contactData = contactDoc.data()!;
      final contactUserId = contactData['userId'] as String? ?? '';
      final contactSubject = contactData['subject'] as String? ?? 'お問い合わせ';

      // 返信を更新
      await _firestore
          .collection(_collectionName)
          .doc(contactId)
          .update({
        'response': response.trim(),
        'respondedAt': Timestamp.now(),
        'respondedBy': user.uid,
        'status': 'resolved',
        'updatedAt': Timestamp.now(),
      });
      
      print('✅ 返信を送信しました: $contactId');

      // お問い合わせしたユーザーに通知を送信
      if (contactUserId.isNotEmpty) {
        try {
          // 管理者の名前を取得（ユーザー情報から）
          String? responderName;
          try {
            final responderDoc = await _firestore
                .collection('users')
                .doc(user.uid)
                .get();
            if (responderDoc.exists) {
              final responderData = responderDoc.data();
              responderName = responderData?['displayName'] as String? ?? 
                             responderData?['name'] as String? ?? 
                             user.displayName ?? 
                             '管理者';
            }
          } catch (e) {
            print('⚠️ 管理者名取得エラー（通知は送信します）: $e');
            responderName = user.displayName ?? '管理者';
          }

          final notification = NotificationFactory.createContactResponseNotification(
            contactUserId: contactUserId,
            contactSubject: contactSubject,
            contactId: contactId,
            response: response.trim(),
            responderName: responderName,
          );

          await NotificationService.sendNotification(notification);
          print('✅ お問い合わせ返信通知を送信しました: $contactUserId');
        } catch (notificationError) {
          // 通知送信エラーは返信処理を阻害しない
          print('⚠️ 通知送信エラー（返信は完了しています）: $notificationError');
        }
      } else {
        print('⚠️ お問い合わせユーザーIDが空のため、通知を送信しませんでした');
      }
    } catch (e) {
      print('❌ 返信送信エラー: $e');
      rethrow;
    }
  }

  // お問い合わせを削除（管理者のみ）
  static Future<void> deleteContact(String contactId) async {
    try {
      if (contactId.isEmpty) {
        print('❌ お問い合わせ削除エラー: IDが空文字列です');
        throw ArgumentError('お問い合わせIDが空文字列です');
      }
      
      await _firestore
          .collection(_collectionName)
          .doc(contactId)
          .delete();
      
      print('✅ お問い合わせを削除しました: $contactId');
    } catch (e) {
      print('❌ お問い合わせ削除エラー: $e');
      rethrow;
    }
  }

  // お問い合わせ統計を取得
  static Future<ContactStats> getContactStats() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // 全件数
      final allSnapshot = await _firestore.collection(_collectionName).get();
      final totalCount = allSnapshot.size;

      // 未対応件数
      final pendingSnapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: 'pending')
          .get();
      final pendingCount = pendingSnapshot.size;

      // 対応中件数
      final inProgressSnapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: 'in_progress')
          .get();
      final inProgressCount = inProgressSnapshot.size;

      // 解決済み件数
      final resolvedSnapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: 'resolved')
          .get();
      final resolvedCount = resolvedSnapshot.size;

      // 今日の新規件数
      final todaySnapshot = await _firestore
          .collection(_collectionName)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .get();
      final todayCount = todaySnapshot.size;

      // 今週の新規件数
      final weekSnapshot = await _firestore
          .collection(_collectionName)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .get();
      final weekCount = weekSnapshot.size;

      // 今月の新規件数
      final monthSnapshot = await _firestore
          .collection(_collectionName)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .get();
      final monthCount = monthSnapshot.size;

      return ContactStats(
        totalCount: totalCount,
        pendingCount: pendingCount,
        inProgressCount: inProgressCount,
        resolvedCount: resolvedCount,
        todayCount: todayCount,
        weekCount: weekCount,
        monthCount: monthCount,
      );
    } catch (e) {
      print('❌ 統計取得エラー: $e');
      rethrow;
    }
  }

  // カテゴリ別統計を取得
  static Future<Map<String, int>> getCategoryStats() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      final Map<String, int> categoryStats = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String;
        categoryStats[category] = (categoryStats[category] ?? 0) + 1;
      }

      return categoryStats;
    } catch (e) {
      print('❌ カテゴリ別統計取得エラー: $e');
      rethrow;
    }
  }
}

// お問い合わせ統計モデル
class ContactStats {
  final int totalCount;
  final int pendingCount;
  final int inProgressCount;
  final int resolvedCount;
  final int todayCount;
  final int weekCount;
  final int monthCount;

  const ContactStats({
    required this.totalCount,
    required this.pendingCount,
    required this.inProgressCount,
    required this.resolvedCount,
    required this.todayCount,
    required this.weekCount,
    required this.monthCount,
  });

  double get responseRate {
    if (totalCount == 0) return 0.0;
    return (resolvedCount / totalCount) * 100;
  }

  int get activeCount => pendingCount + inProgressCount;
}
