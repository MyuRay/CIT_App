import 'app_store_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../models/community/chiba_channel_thread.dart';
import '../../models/community/cwitter_post.dart';
import '../../models/community/cwitter_profile_user.dart';
import '../../screens/bulletin/bulletin_post_detail_screen.dart';
import '../../screens/community/widgets/chiba_channel_thread_screen.dart';
import '../../screens/community/widgets/cwitter_profile_screen.dart';
import '../../screens/community/widgets/cwitter_reply_sheet.dart';
import '../../screens/notification/unified_notification_screen.dart';
import '../../screens/contact/user_contact_list_screen.dart';
import '../../screens/contact/contact_chat_screen.dart';
import '../users/user_block_service.dart';
import 'notification_target.dart';

class NotificationNavigation {
  static Future<void> open(
    BuildContext context,
    NotificationTarget target, {
    bool fromNotificationList = false,
    bool markRead = true,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    Future<Set<String>> Function()? hiddenUserIds,
    Future<bool> Function()? launchStore,
  }) async {
    final session = auth ?? FirebaseAuth.instance;
    final db = firestore ?? FirebaseFirestore.instance;
    final getHiddenUsers = hiddenUserIds ?? UserBlockService.getHiddenUserIds;
    final user = session.currentUser;
    if (user == null || !user.emailVerified || !target.belongsTo(user.uid)) {
      return;
    }
    bool stillCurrent() =>
        context.mounted && session.currentUser?.uid == user.uid;
    if (markRead) await _markRead(target, db);
    if (!stillCurrent()) return;
    try {
      if (target.data['type'] == 'app_update') {
        if (!await (launchStore ?? openAppStore)()) {
          throw StateError('store unavailable');
        }
        return;
      }
      Widget? destination;
      if (target.source == 'contact_chat') {
        destination = const ContactChatScreen();
      } else if (target.data['type'] == 'contact_response') {
        destination = const UserContactListScreen();
      } else if (target.source == 'cwitter' &&
          target.data['type'] == 'follow') {
        if (target.fromUserId == null) throw StateError('missing');
        final doc =
            await db.collection('public_profiles').doc(target.fromUserId).get();
        final hiddenUsers = await getHiddenUsers();
        if (!doc.exists || hiddenUsers.contains(target.fromUserId)) {
          throw StateError('unavailable');
        }
        final data = doc.data()!;
        final handle = (data['cwitterId'] as String?) ?? '';
        if (handle.isEmpty) throw StateError('unavailable');
        destination = CwitterProfileScreen(
          user: CwitterProfileUser(
            authorId: doc.id,
            displayName: (data['displayName'] as String?) ?? handle,
            cwitterId: handle,
            profileImageUrl: data['profileImageUrl'] as String?,
          ),
        );
      } else if (target.source == 'cwitter' && target.postId != null) {
        final doc =
            await db.collection('cwitter_posts').doc(target.postId).get();
        if (!doc.exists) throw StateError('missing');
        final post = CwitterPost.fromFirestore(doc);
        final hiddenUsers = await getHiddenUsers();
        if (hiddenUsers.contains(post.authorId)) {
          throw StateError('unavailable');
        }
        if (!context.mounted || !stillCurrent()) return;
        CwitterReplySheet.show(context, post);
        return;
      } else if (target.source == 'chiba_channel' && target.postId != null) {
        final doc =
            await db
                .collection('chiba_channel_threads')
                .doc(target.postId)
                .get();
        if (!doc.exists) throw StateError('missing');
        destination = ChibaChannelThreadScreen(
          thread: ChibaChannelThread.fromFirestore(doc),
        );
      } else if (target.postId != null &&
          (target.source.isEmpty || target.source == 'bulletin')) {
        final doc =
            await db.collection('bulletin_posts').doc(target.postId).get();
        if (!doc.exists) throw StateError('missing');
        final post = BulletinPost.fromJson({...doc.data()!, 'id': doc.id});
        final hiddenUsers = await getHiddenUsers();
        if (hiddenUsers.contains(post.authorId) ||
            ((!post.isActive || post.approvalStatus != 'approved') &&
                post.authorId != user.uid)) {
          throw StateError('unavailable');
        }
        destination = BulletinPostDetailScreen(
          post: post,
          initialCommentId: target.commentId,
        );
      } else if (target.source == 'cwitter' ||
          target.source == 'chiba_channel') {
        throw StateError('missing');
      }
      if (!context.mounted || !stillCurrent()) return;
      if (destination == null && fromNotificationList) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => destination ?? const UnifiedNotificationScreen(),
        ),
      );
    } catch (_) {
      if (!context.mounted || !stillCurrent()) return;
      if (!fromNotificationList) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const UnifiedNotificationScreen(),
          ),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('通知の内容を開けませんでした。削除・公開範囲・通信状態をご確認ください。')),
      );
    }
  }

  static Future<void> _markRead(
    NotificationTarget target,
    FirebaseFirestore db,
  ) async {
    if (target.notificationId == null) return;
    try {
      await db.collection('notifications').doc(target.notificationId).update({
        'isRead': true,
      });
    } catch (_) {}
  }
}
