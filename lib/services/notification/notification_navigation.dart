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
import '../users/user_block_service.dart';
import 'notification_target.dart';

class NotificationNavigation {
  static Future<void> open(
    BuildContext context,
    NotificationTarget target,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified || !target.belongsTo(user.uid)) {
      return;
    }
    bool stillCurrent() =>
        context.mounted && FirebaseAuth.instance.currentUser?.uid == user.uid;
    try {
      Widget? destination;
      if (target.source == 'cwitter' &&
          target.data['type'] == 'follow' &&
          target.fromUserId != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(target.fromUserId)
                .get();
        final hiddenUsers = await UserBlockService.getHiddenUserIds();
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
            await FirebaseFirestore.instance
                .collection('cwitter_posts')
                .doc(target.postId)
                .get();
        if (!doc.exists) throw StateError('missing');
        final post = CwitterPost.fromFirestore(doc);
        final hiddenUsers = await UserBlockService.getHiddenUserIds();
        if (hiddenUsers.contains(post.authorId)) {
          throw StateError('unavailable');
        }
        if (!context.mounted || !stillCurrent()) return;
        CwitterReplySheet.show(context, post);
        await _markRead(target);
        return;
      } else if (target.source == 'chiba_channel' && target.postId != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('chiba_channel_threads')
                .doc(target.postId)
                .get();
        if (!doc.exists) throw StateError('missing');
        destination = ChibaChannelThreadScreen(
          thread: ChibaChannelThread.fromFirestore(doc),
        );
      } else if (target.postId != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('bulletin_posts')
                .doc(target.postId)
                .get();
        if (!doc.exists) throw StateError('missing');
        final post = BulletinPost.fromJson({...doc.data()!, 'id': doc.id});
        final hiddenUsers = await UserBlockService.getHiddenUserIds();
        if (!post.isActive ||
            hiddenUsers.contains(post.authorId) ||
            (post.approvalStatus != 'approved' && post.authorId != user.uid)) {
          throw StateError('unavailable');
        }
        destination = BulletinPostDetailScreen(
          post: post,
          initialCommentId: target.commentId,
        );
      }
      if (!context.mounted || !stillCurrent()) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => destination ?? const UnifiedNotificationScreen(),
        ),
      );
      await _markRead(target);
    } catch (_) {
      if (!context.mounted || !stillCurrent()) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const UnifiedNotificationScreen(),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('通知の内容を開けませんでした。削除・公開範囲・通信状態をご確認ください。')),
      );
    }
  }

  static Future<void> _markRead(NotificationTarget target) async {
    if (target.notificationId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(target.notificationId)
          .update({'isRead': true});
    } catch (_) {}
  }
}
