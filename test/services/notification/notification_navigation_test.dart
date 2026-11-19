import 'package:cit_app/models/notification/notification_model.dart';
import 'package:cit_app/screens/bulletin/bulletin_post_detail_screen.dart';
import 'package:cit_app/screens/community/widgets/chiba_channel_thread_screen.dart';
import 'package:cit_app/screens/community/widgets/cwitter_profile_screen.dart';
import 'package:cit_app/screens/community/widgets/cwitter_reply_sheet.dart';
import 'package:cit_app/screens/contact/user_contact_list_screen.dart';
import 'package:cit_app/screens/contact/contact_chat_screen.dart';
import 'package:cit_app/services/notification/notification_navigation.dart';
import 'package:cit_app/services/notification/notification_target.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class PushObserver extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      pushed.add(route);
}

void main() {
  for (final type in [
    NotificationType.like,
    NotificationType.reply,
    NotificationType.follow,
    NotificationType.comment,
    NotificationType.postApproved,
    NotificationType.postRejected,
    NotificationType.pinApproved,
    NotificationType.pinRejected,
  ]) {
    testWidgets('${type.id} opens the correct content from the personal list', (
      tester,
    ) async {
      final db = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'self', isEmailVerified: true),
        signedIn: true,
      );
      final cwitter = [
        NotificationType.like,
        NotificationType.reply,
        NotificationType.follow,
      ].contains(type);
      await db.doc('cwitter_posts/post').set({
        'authorId': 'self',
        'body': 'target post',
      });
      await db.doc('bulletin_posts/post').set({
        'authorId': 'self',
        'approvalStatus':
            type == NotificationType.postRejected ? 'rejected' : 'approved',
        'isActive': type != NotificationType.postRejected,
      });
      await db.doc('public_profiles/actor').set({
        'cwitterId': 'latest_handle',
        'displayName': '最新名',
      });
      await db.doc('notifications/notice').set({
        'userId': 'self',
        'isRead': false,
      });
      final observer = PushObserver();
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(navigatorObservers: [observer], home: Scaffold(key: key)),
      );
      final notification = AppNotification(
        id: 'notice',
        userId: 'self',
        type: type,
        title: 'title',
        message: 'message',
        postId: type == NotificationType.follow ? null : 'post',
        commentId: 'reply',
        fromUserId: 'actor',
        createdAt: DateTime.now(),
        data: cwitter ? {'source': 'cwitter'} : {'parentCommentId': 'parent'},
      );
      await NotificationNavigation.open(
        key.currentContext!,
        NotificationTarget.fromNotification(notification),
        fromNotificationList: true,
        auth: auth,
        firestore: db,
        hiddenUserIds: () async => {},
      );
      expect(observer.pushed.length, 2);
      final route = observer.pushed.last;
      if (type == NotificationType.follow) {
        final profile =
            (route as MaterialPageRoute).builder(key.currentContext!)
                as CwitterProfileScreen;
        expect(profile.user!.cwitterId, 'latest_handle');
      } else if (cwitter) {
        final body =
            (route as ModalBottomSheetRoute).builder(key.currentContext!)
                as Padding;
        expect((body.child as CwitterReplySheet).post.id, 'post');
      } else {
        final post =
            (route as MaterialPageRoute).builder(key.currentContext!)
                as BulletinPostDetailScreen;
        expect(post.post.id, 'post');
        expect(post.initialCommentId, 'parent');
      }
      expect(
        (await db.doc('notifications/notice').get()).data()!['isRead'],
        isTrue,
      );
      // Verify the route before rendering its independent data subscriptions.
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'contact responses open contact history instead of doing nothing',
    (tester) async {
      final observer = PushObserver();
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(navigatorObservers: [observer], home: Scaffold(key: key)),
      );
      final notification =
          NotificationFactory.createContactResponseNotification(
            contactUserId: 'self',
            contactSubject: 'subject',
            contactId: 'contact',
            response: 'answer',
          );
      await NotificationNavigation.open(
        key.currentContext!,
        NotificationTarget.fromNotification(notification),
        fromNotificationList: true,
        markRead: false,
        firestore: FakeFirebaseFirestore(),
        auth: MockFirebaseAuth(
          mockUser: MockUser(uid: 'self', isEmailVerified: true),
          signedIn: true,
        ),
      );
      final screen = (observer.pushed.last as MaterialPageRoute).builder(
        key.currentContext!,
      );
      expect(screen, isA<UserContactListScreen>());
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('both Chiba notification kinds open their thread', (
    tester,
  ) async {
    for (final kind in ['thread_reply', 'comment_reply']) {
      final db = FakeFirebaseFirestore();
      await db.doc('chiba_channel_threads/thread').set({
        'title': 'target thread',
      });
      final observer = PushObserver();
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(navigatorObservers: [observer], home: Scaffold(key: key)),
      );
      await NotificationNavigation.open(
        key.currentContext!,
        NotificationTarget.fromData({
          'source': 'chiba_channel',
          'postId': 'thread',
          'type': kind,
        }),
        fromNotificationList: true,
        firestore: db,
        auth: MockFirebaseAuth(
          mockUser: MockUser(uid: 'self', isEmailVerified: true),
          signedIn: true,
        ),
      );
      final screen =
          (observer.pushed.last as MaterialPageRoute).builder(
                key.currentContext!,
              )
              as ChibaChannelThreadScreen;
      expect(screen.thread.id, 'thread');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('deleted/blocked content stays in the list with feedback', (
    tester,
  ) async {
    for (final blocked in [false, true]) {
      final db = FakeFirebaseFirestore();
      if (blocked) {
        await db.doc('cwitter_posts/post').set({'authorId': 'hidden'});
      }
      final observer = PushObserver();
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(navigatorObservers: [observer], home: Scaffold(key: key)),
      );
      await NotificationNavigation.open(
        key.currentContext!,
        NotificationTarget.fromData({'source': 'cwitter', 'postId': 'post'}),
        fromNotificationList: true,
        firestore: db,
        auth: MockFirebaseAuth(
          mockUser: MockUser(uid: 'self', isEmailVerified: true),
          signedIn: true,
        ),
        hiddenUserIds: () async => {'hidden'},
      );
      await tester.pump();
      expect(observer.pushed.length, 1);
      expect(find.textContaining('通知の内容を開けませんでした'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('support chat notifications open only the signed-in users chat', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final observer = PushObserver();
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(navigatorObservers: [observer], home: Scaffold(key: key)),
    );
    await NotificationNavigation.open(
      key.currentContext!,
      NotificationTarget.fromData({
        'source': 'contact_chat',
        'type': 'contact_response',
        'userId': 'self',
        'contactId': 'other',
      }),
      fromNotificationList: true,
      firestore: db,
      auth: MockFirebaseAuth(
        mockUser: MockUser(uid: 'self', isEmailVerified: true),
        signedIn: true,
      ),
    );
    final screen =
        (observer.pushed.last as MaterialPageRoute).builder(key.currentContext!)
            as ContactChatScreen;
    expect(
      screen.userId,
      isNull,
    ); // The route derives the owner from the live session.
    expect(screen.asAdmin, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
