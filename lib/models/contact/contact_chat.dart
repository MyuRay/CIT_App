import 'package:cloud_firestore/cloud_firestore.dart';

const contactChatCollection = 'contact_chats';
const contactChatMessageLimit = 2000;
const contactChatMaxImages = 4;
const contactChatMaxImageBytes = 5 * 1024 * 1024;
const contactChatWelcomeMessage =
    'こちらの画面ではCIT Appに関するお問い合わせや不具合報告、新機能提案などをすることができます。お気軽にメッセージをお送りください。';

class ContactChat {
  const ContactChat({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.lastMessage,
    required this.status,
    required this.userMessageCount,
    required this.adminMessageCount,
    required this.userReadCount,
    required this.adminReadCount,
    this.updatedAt,
  });

  factory ContactChat.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ContactChat(
      userId: doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      lastMessage: data['lastMessage'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      userMessageCount: data['userMessageCount'] as int? ?? 0,
      adminMessageCount: data['adminMessageCount'] as int? ?? 0,
      userReadCount: data['userReadCount'] as int? ?? 0,
      adminReadCount: data['adminReadCount'] as int? ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
  final String userId, displayName, email, lastMessage, status;
  final int userMessageCount, adminMessageCount, userReadCount, adminReadCount;
  final DateTime? updatedAt;
  int get userUnreadCount =>
      (adminMessageCount - userReadCount).clamp(0, 1 << 30);
  int get adminUnreadCount =>
      (userMessageCount - adminReadCount).clamp(0, 1 << 30);
  String get userLabel => displayName.isNotEmpty ? displayName : email;
}

class ContactChatMessage {
  const ContactChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderRole,
    required this.sequence,
    required this.senderSequence,
    this.createdAt,
    this.imagePaths = const [],
  });
  factory ContactChatMessage.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ContactChatMessage(
      id: doc.id,
      text: data['text'] as String,
      imagePaths: List<String>.from(data['imagePaths'] as List? ?? const []),
      senderId: data['senderId'] as String,
      senderRole: data['senderRole'] as String,
      sequence: data['sequence'] as int,
      senderSequence: data['senderSequence'] as int,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
  final String id, text, senderId, senderRole;
  final List<String> imagePaths;
  final int sequence, senderSequence;
  final DateTime? createdAt;
}
