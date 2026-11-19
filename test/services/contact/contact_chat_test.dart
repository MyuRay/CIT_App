import 'dart:typed_data';
import 'package:image/image.dart' as image;
import 'package:cit_app/services/contact/contact_chat_image_service.dart';
import 'package:cit_app/models/contact/contact_chat.dart';
import 'package:cit_app/services/contact/contact_chat_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  late ContactChatService service;
  setUp(() {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'student',
        email: 'student@s.chibakoudai.jp',
        isEmailVerified: true,
        displayName: '学生',
      ),
    );
    service = ContactChatService(firestore: db, auth: auth);
  });
  // The fake transaction invokes writes without awaiting their futures.
  Future<void> send(String id, String text, {bool admin = false}) async {
    await service.sendMessage(
      userId: 'student',
      text: text,
      messageId: id,
      asAdmin: admin,
    );
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> becomeAdmin() async {
    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'operator',
        email: 'operator@s.chibakoudai.jp',
        isEmailVerified: true,
      ),
    );
    service = ContactChatService(firestore: db, auth: auth);
  }

  test(
    'repeated questions and operator replies stay in one room, in order',
    () async {
      await send('one', '  質問です  ');
      await send('two', '追記です');
      await becomeAdmin();
      await send('reply', 'ご連絡ありがとうございます', admin: true);
      final rooms = await db.collection(contactChatCollection).get();
      expect(rooms.docs.length, 1);
      expect(rooms.docs.single.id, 'student');
      final chat = await service.watchChat('student').first;
      expect(chat!.userMessageCount, 2);
      expect(chat.adminMessageCount, 1);
      expect(chat.adminUnreadCount, 2);
      expect(chat.userUnreadCount, 1);
      final messages = await service.watchMessages('student').first;
      expect(messages.map((m) => m.id), ['reply', 'two', 'one']);
      expect(messages.map((m) => m.sequence), [3, 2, 1]);
      expect(messages.last.text, '質問です');
    },
  );

  test(
    'operator replies create one private notification with a chat destination',
    () async {
      await send('question', '質問');
      expect((await db.collection('notifications').get()).docs, isEmpty);
      await becomeAdmin();
      await send('response', '秘密の返信本文', admin: true);
      await send('response', '秘密の返信本文', admin: true);
      final notifications = (await db.collection('notifications').get()).docs;
      expect(notifications, hasLength(1));
      expect(notifications.single.id, 'contact_chat_student_response');
      final data = notifications.single.data();
      expect(data['userId'], 'student');
      expect(data['isRead'], false);
      expect(data['message'], isNot(contains('秘密の返信本文')));
      expect(data['data'], {
        'type': 'contact_response',
        'source': 'contact_chat',
        'contactId': 'student',
        'messageId': 'response',
      });
    },
  );

  test(
    'retrying the same client ID does not append or increment unread twice',
    () async {
      await send('stable', 'こんにちは');
      await send('stable', 'こんにちは');
      expect(
        (await db.collection(contactChatCollection).doc('student').get())
            .data()!['messageCount'],
        1,
      );
      await expectLater(send('stable', '別の本文'), throwsStateError);
    },
  );

  test(
    'mark read acknowledges only rendered messages and never moves backwards',
    () async {
      await send('one', '質問');
      await becomeAdmin();
      await send('reply1', '返信1', admin: true);
      await send('reply2', '返信2', admin: true);
      final student = ContactChatService(
        firestore: db,
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'student', isEmailVerified: true),
        ),
      );
      await student.markRead('student', asAdmin: false, seen: 1);
      await Future<void>.delayed(Duration.zero);
      expect((await student.watchChat('student').first)!.userUnreadCount, 1);
      await student.markRead('student', asAdmin: false, seen: 0);
      await Future<void>.delayed(Duration.zero);
      expect((await student.watchChat('student').first)!.userReadCount, 1);
      await student.markRead('student', asAdmin: false, seen: 999);
      await Future<void>.delayed(Duration.zero);
      expect((await student.watchChat('student').first)!.userReadCount, 2);
      await service.markRead('student', asAdmin: true, seen: 1);
      await Future<void>.delayed(Duration.zero);
      expect((await service.watchChat('student').first)!.adminUnreadCount, 0);
    },
  );

  test('empty and oversized drafts cannot create a conversation', () async {
    for (final text in ['  \n ', 'あ' * 2001]) {
      await expectLater(send('bad', text), throwsArgumentError);
    }
    expect((await db.collection(contactChatCollection).get()).docs, isEmpty);
  });

  test('logout, unverified users and another user ID cannot send', () async {
    await expectLater(
      service.sendMessage(userId: 'other', text: 'x', messageId: 'a'),
      throwsStateError,
    );
    await auth.signOut();
    await expectLater(send('a', 'x'), throwsStateError);
    final unverified = ContactChatService(
      firestore: db,
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'student', isEmailVerified: false),
      ),
    );
    await expectLater(
      unverified.sendMessage(userId: 'student', text: 'x', messageId: 'a'),
      throwsStateError,
    );
  });

  test(
    'resuming a resolved conversation reopens it and paging retains older messages',
    () async {
      for (var i = 0; i < 4; i++) {
        await send('m$i', 'メッセージ$i');
      }
      await service.setStatus('student', 'resolved');
      await send('again', '続きです');
      expect((await service.watchChat('student').first)!.status, 'pending');
      expect(
        (await service.watchMessages('student', limit: 2).first).length,
        2,
      );
      expect(
        (await service.watchMessages('student', limit: 10).first).length,
        5,
      );
    },
  );

  test(
    'admin cannot create an unsolicited room without an initial user message',
    () async {
      await becomeAdmin();
      await expectLater(send('a', '返信', admin: true), throwsStateError);
      expect((await db.collection(contactChatCollection).get()).docs, isEmpty);
    },
  );

  test(
    'images can be sent without a caption and retries preserve one message',
    () async {
      const path = 'contact_chat_images/student/student/photo/0.jpg';
      await service.sendMessage(
        userId: 'student',
        text: '',
        messageId: 'photo',
        imagePaths: [path],
      );
      await Future<void>.delayed(Duration.zero);
      await service.sendMessage(
        userId: 'student',
        text: '',
        messageId: 'photo',
        imagePaths: [path],
      );
      await Future<void>.delayed(Duration.zero);
      final chat = await service.watchChat('student').first;
      expect(chat!.lastMessage, '📷 画像');
      expect(chat.userMessageCount, 1);
      expect((await service.watchMessages('student').first).single.imagePaths, [
        path,
      ]);
    },
  );

  test(
    'attachments cannot reference another room, sender, public URL or more than four images',
    () async {
      for (final paths in [
        ['contact_chat_images/other/student/photo/0.jpg'],
        ['contact_chat_images/student/operator/photo/0.jpg'],
        ['https://example.com/private.jpg'],
        [
          for (var i = 0; i < 5; i++)
            'contact_chat_images/student/student/photo/$i.jpg',
        ],
        ['contact_chat_images/student/student/photo/1.jpg'],
      ]) {
        await expectLater(
          service.sendMessage(
            userId: 'student',
            text: '',
            messageId: 'photo',
            imagePaths: paths,
          ),
          throwsArgumentError,
        );
      }
      expect((await db.collection(contactChatCollection).get()).docs, isEmpty);
    },
  );

  test(
    'image preparation decodes and resizes to JPEG while rejecting invalid input',
    () {
      final source = image.Image(width: 2200, height: 20);
      source.exif.imageIfd[0x010f] = image.IfdValueAscii('private camera');
      final prepared = prepareContactChatImage(
        Uint8List.fromList(image.encodeJpg(source)),
      );
      final decoded = image.decodeJpg(prepared)!;
      expect(decoded.width, 2048);
      expect(decoded.exif.hasTag(0x010f), isFalse);
      expect(
        () => prepareContactChatImage(Uint8List.fromList([1, 2, 3])),
        throwsArgumentError,
      );
    },
  );
}
