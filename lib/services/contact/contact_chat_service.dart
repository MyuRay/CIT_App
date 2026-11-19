import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/contact/contact_chat.dart';

class ContactChatService {
  ContactChatService({required this.firestore, required this.auth});
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  DocumentReference<Map<String, dynamic>> _room(String uid) =>
      firestore.collection(contactChatCollection).doc(uid);
  Stream<ContactChat?> watchChat(String uid) => _room(
    uid,
  ).snapshots().map((doc) => doc.exists ? ContactChat.fromDoc(doc) : null);
  Stream<List<ContactChat>> watchChats() => firestore
      .collection(contactChatCollection)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(ContactChat.fromDoc).toList());

  /// Newest first. Increasing the limit reveals older messages in the same room.
  Stream<List<ContactChatMessage>> watchMessages(
    String uid, {
    int limit = 50,
  }) => _room(uid)
      .collection('messages')
      .orderBy('sequence', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(ContactChatMessage.fromDoc).toList(),
      );
  String newMessageId(String uid) => _room(uid).collection('messages').doc().id;

  Future<void> sendMessage({
    required String userId,
    required String text,
    required String messageId,
    bool asAdmin = false,
    List<String> imagePaths = const [],
  }) async {
    final user = auth.currentUser;
    if (user == null || !user.emailVerified) throw StateError('ログインが必要です');
    if (!asAdmin && userId != user.uid) throw StateError('このお問い合わせには送信できません');
    final body = text.trim();
    if ((body.isEmpty && imagePaths.isEmpty) ||
        body.length > contactChatMessageLimit) {
      throw ArgumentError('メッセージは1〜$contactChatMessageLimit文字で入力してください');
    }
    if (messageId.isEmpty || messageId.contains('/'))
      throw ArgumentError('Invalid message ID');
    if (imagePaths.length > contactChatMaxImages)
      throw ArgumentError('画像は4枚まで添付できます');
    for (var i = 0; i < imagePaths.length; i++) {
      if (imagePaths[i] !=
          'contact_chat_images/$userId/${user.uid}/$messageId/$i.jpg') {
        throw ArgumentError('添付画像が正しくありません');
      }
    }
    final room = _room(userId);
    final message = room.collection('messages').doc(messageId);
    final role = asAdmin ? 'admin' : 'user';
    await firestore.runTransaction((tx) async {
      final existing = await tx.get(message);
      if (existing.exists) {
        if (existing.data()?['senderId'] != user.uid ||
            existing.data()?['text'] != body ||
            !listEquals(
              List<String>.from(
                existing.data()?['imagePaths'] as List? ?? const [],
              ),
              imagePaths,
            )) {
          throw StateError('送信内容が変わりました。もう一度送信してください');
        }
        return; // A retry after an uncertain network result must not send twice.
      }
      final snapshot = await tx.get(room);
      if (asAdmin && !snapshot.exists) throw StateError('お問い合わせが見つかりません');
      if (auth.currentUser?.uid != user.uid) throw StateError('ログイン状態が変わりました');
      final data = snapshot.data() ?? <String, dynamic>{};
      final sequence = (data['messageCount'] as int? ?? 0) + 1;
      final counter = asAdmin ? 'adminMessageCount' : 'userMessageCount';
      final senderSequence = (data[counter] as int? ?? 0) + 1;
      if (asAdmin) {
        tx.set(
          firestore
              .collection('notifications')
              .doc('contact_chat_${userId}_$messageId'),
          {
            'userId': userId,
            'type': 'general',
            'title': 'CIT App 運営から返信が届きました',
            'message': 'お問い合わせを開いて確認してください',
            'isRead': false,
            'fromUserId': user.uid,
            'fromUserName': 'CIT App 運営',
            'createdAt': FieldValue.serverTimestamp(),
            'data': {
              'type': 'contact_response',
              'source': 'contact_chat',
              'contactId': userId,
              'messageId': messageId,
            },
          },
        );
      }
      tx.set(message, {
        'userId': userId,
        'senderId': user.uid,
        'senderRole': role,
        'text': body,
        if (imagePaths.isNotEmpty) 'imagePaths': imagePaths,
        'sequence': sequence,
        'senderSequence': senderSequence,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(room, {
        ...data,
        if (!snapshot.exists) ...{
          'userId': userId,
          'displayName': (user.displayName ?? '').substring(
            0,
            math.min(100, (user.displayName ?? '').length),
          ),
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'adminMessageCount': 0,
          'userReadCount': 0,
          'adminReadCount': 0,
        },
        counter: senderSequence,
        'messageCount': sequence,
        'lastMessageId': messageId,
        'lastMessage': body.isEmpty ? '📷 画像' : body,
        'lastSenderRole': role,
        'updatedAt': FieldValue.serverTimestamp(),
        'status': asAdmin ? 'in_progress' : 'pending',
      });
    });
  }

  /// Acknowledges only messages already rendered, never a newer arrival.
  Future<void> markRead(
    String uid, {
    required bool asAdmin,
    required int seen,
  }) async {
    final user = auth.currentUser;
    if (user == null || (!asAdmin && user.uid != uid)) return;
    await firestore.runTransaction((tx) async {
      final doc = await tx.get(_room(uid));
      if (!doc.exists || auth.currentUser?.uid != user.uid) return;
      final data = doc.data()!;
      final key = asAdmin ? 'adminReadCount' : 'userReadCount';
      final total =
          data[asAdmin ? 'userMessageCount' : 'adminMessageCount'] as int;
      final next = math.min(seen, total);
      if (next > (data[key] as int)) tx.update(doc.reference, {key: next});
    });
  }

  Future<void> setStatus(String uid, String status) {
    if (!['pending', 'in_progress', 'resolved'].contains(status))
      throw ArgumentError('Invalid status');
    return _room(uid).update({'status': status});
  }
}
