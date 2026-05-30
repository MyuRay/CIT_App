import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/community/chiba_channel_comment.dart';
import '../../models/community/chiba_channel_thread.dart';
import '../../core/providers/notification_provider.dart';
import 'chiba_channel_image_service.dart';

class ChibaChannelService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _threadsCollection = 'chiba_channel_threads';
  static const int _maxTitleLength = 80;
  static const int _maxBodyLength = 1000;
  static const _anonymousIdChars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  static Stream<List<ChibaChannelThread>> watchThreads({int limit = 50}) {
    return _firestore
        .collection(_threadsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ChibaChannelThread.fromFirestore)
              .toList(),
        );
  }

  static Stream<List<ChibaChannelComment>> watchComments(String threadId) {
    return _firestore
        .collection(_threadsCollection)
        .doc(threadId)
        .collection('comments')
        .orderBy('commentNumber', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChibaChannelComment.fromFirestore(threadId, doc))
              .toList(),
        );
  }

  static Future<String> createThread({
    required String authorId,
    required String authorEmail,
    required String title,
    required String category,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('タイトルを入力してください');
    }
    if (trimmedTitle.length > _maxTitleLength) {
      throw ArgumentError('タイトルは$_maxTitleLength文字以内で入力してください');
    }
    if (!ChibaChannelThread.categories.contains(category)) {
      throw ArgumentError('カテゴリが不正です');
    }

    final email = authorEmail.trim().toLowerCase();
    if (email.isEmpty) {
      throw ArgumentError('登録メールアドレスを取得できませんでした');
    }

    final ref = _firestore.collection(_threadsCollection).doc();
    await ref.set({
      'title': trimmedTitle,
      'category': category,
      'authorId': authorId,
      'authorEmail': email,
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivityAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> createComment({
    required String threadId,
    required String authorId,
    required String authorEmail,
    required String body,
    int? inReplyToCommentNumber,
    String? inReplyToCommentId,
    List<XFile>? imageFiles,
  }) async {
    var trimmed = body.trim();
    final files = imageFiles ?? const <XFile>[];

    if (inReplyToCommentNumber != null) {
      final anchor = '>>$inReplyToCommentNumber';
      if (trimmed.isEmpty) {
        trimmed = anchor;
      } else if (!trimmed.startsWith(anchor)) {
        trimmed = '$anchor\n$trimmed';
      }
    }

    if (trimmed.isEmpty && files.isEmpty) {
      throw ArgumentError('レス内容または画像を入力してください');
    }
    if (trimmed.length > _maxBodyLength) {
      throw ArgumentError('レスは$_maxBodyLength文字以内で入力してください');
    }
    if (files.length > ChibaChannelImageService.maxImagesPerComment) {
      throw ArgumentError(
        '画像は最大${ChibaChannelImageService.maxImagesPerComment}枚までです',
      );
    }

    final email = authorEmail.trim().toLowerCase();
    if (email.isEmpty) {
      throw ArgumentError('登録メールアドレスを取得できませんでした');
    }

    final threadRef = _firestore.collection(_threadsCollection).doc(threadId);
    final commentRef = threadRef.collection('comments').doc();

    List<String> imageUrls = const [];
    if (files.isNotEmpty) {
      imageUrls = await ChibaChannelImageService.uploadCommentImages(
        userId: authorId,
        threadId: threadId,
        commentId: commentRef.id,
        files: files,
      );
    }

    await _firestore.runTransaction((transaction) async {
      final threadSnap = await transaction.get(threadRef);
      if (!threadSnap.exists) {
        throw StateError('スレッドが見つかりません');
      }

      final currentCount =
          (threadSnap.data()?['commentCount'] as num?)?.toInt() ?? 0;
      final nextNumber = currentCount + 1;

      final anonymousId = await _resolveAnonymousId(
        transaction: transaction,
        threadRef: threadRef,
        authorId: authorId,
      );

      final commentData = <String, dynamic>{
        'authorId': authorId,
        'authorEmail': email,
        'body': trimmed,
        'commentNumber': nextNumber,
        'anonymousId': anonymousId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (inReplyToCommentNumber != null && inReplyToCommentNumber > 0) {
        commentData['inReplyToCommentNumber'] = inReplyToCommentNumber;
      }
      if (inReplyToCommentId != null && inReplyToCommentId.trim().isNotEmpty) {
        commentData['inReplyToCommentId'] = inReplyToCommentId.trim();
      }
      if (imageUrls.isNotEmpty) {
        commentData['imageUrls'] = imageUrls;
      }

      transaction.set(commentRef, commentData);
      transaction.update(threadRef, {
        'commentCount': nextNumber,
        'lastActivityAt': FieldValue.serverTimestamp(),
      });
    });

    try {
      await _notifyOnNewComment(
        threadId: threadId,
        commentId: commentRef.id,
        commentAuthorId: authorId,
        bodyPreview: trimmed,
        inReplyToCommentNumber: inReplyToCommentNumber,
        inReplyToCommentId: inReplyToCommentId,
      );
    } catch (_) {
      // レス投稿自体は成功しているため通知失敗は握りつぶす
    }
  }

  static Future<void> _notifyOnNewComment({
    required String threadId,
    required String commentId,
    required String commentAuthorId,
    required String bodyPreview,
    int? inReplyToCommentNumber,
    String? inReplyToCommentId,
  }) async {
    final threadRef = _firestore.collection(_threadsCollection).doc(threadId);
    final threadSnap = await threadRef.get();
    if (!threadSnap.exists) return;

    final threadData = threadSnap.data()!;
    final threadTitle = threadData['title'] as String? ?? '';
    final threadAuthorId = threadData['authorId'] as String? ?? '';

    String? repliedToAuthorId;
    int? repliedToCommentNumber = inReplyToCommentNumber;
    if (inReplyToCommentId != null && inReplyToCommentId.trim().isNotEmpty) {
      final parentSnap =
          await threadRef.collection('comments').doc(inReplyToCommentId.trim()).get();
      if (parentSnap.exists) {
        final parentData = parentSnap.data()!;
        repliedToAuthorId = parentData['authorId'] as String? ?? '';
        repliedToCommentNumber ??=
            (parentData['commentNumber'] as num?)?.toInt();
      }
    } else if (inReplyToCommentNumber != null) {
      final parentSnap = await threadRef
          .collection('comments')
          .where('commentNumber', isEqualTo: inReplyToCommentNumber)
          .limit(1)
          .get();
      if (parentSnap.docs.isNotEmpty) {
        repliedToAuthorId =
            parentSnap.docs.first.data()['authorId'] as String? ?? '';
      }
    }

    final notifiedUserIds = <String>{};

    if (repliedToAuthorId != null &&
        repliedToAuthorId.isNotEmpty &&
        repliedToAuthorId != commentAuthorId &&
        repliedToCommentNumber != null &&
        repliedToCommentNumber > 0) {
      await NotificationService.sendChibaChannelCommentReplyNotification(
        commentAuthorId: repliedToAuthorId,
        threadId: threadId,
        threadTitle: threadTitle,
        commentId: commentId,
        replyToCommentNumber: repliedToCommentNumber,
        fromUserId: commentAuthorId,
        bodyPreview: bodyPreview,
      );
      notifiedUserIds.add(repliedToAuthorId);
    }

    if (threadAuthorId.isNotEmpty &&
        threadAuthorId != commentAuthorId &&
        !notifiedUserIds.contains(threadAuthorId)) {
      await NotificationService.sendChibaChannelThreadReplyNotification(
        threadAuthorId: threadAuthorId,
        threadId: threadId,
        threadTitle: threadTitle,
        commentId: commentId,
        fromUserId: commentAuthorId,
        bodyPreview: bodyPreview,
      );
    }
  }

  static Future<String> _resolveAnonymousId({
    required Transaction transaction,
    required DocumentReference<Map<String, dynamic>> threadRef,
    required String authorId,
  }) async {
    final anonRef = threadRef.collection('anonymous_ids').doc(authorId);
    final anonSnap = await transaction.get(anonRef);
    if (anonSnap.exists) {
      final existing = anonSnap.data()?['anonymousId'] as String? ?? '';
      if (existing.isNotEmpty) return existing;
    }

    final anonymousId = _generateAnonymousId();
    transaction.set(anonRef, {
      'anonymousId': anonymousId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return anonymousId;
  }

  static String _generateAnonymousId() {
    final random = Random.secure();
    return List.generate(
      8,
      (_) => _anonymousIdChars[random.nextInt(_anonymousIdChars.length)],
    ).join();
  }

  static Future<void> deleteThread({
    required String threadId,
    required String authorId,
  }) async {
    final threadRef = _firestore.collection(_threadsCollection).doc(threadId);
    final threadSnap = await threadRef.get();
    if (!threadSnap.exists) return;

    final threadAuthorId = threadSnap.data()?['authorId'] as String? ?? '';
    if (threadAuthorId != authorId) {
      throw StateError('このスレッドを削除する権限がありません');
    }

    final commentsSnap = await threadRef.collection('comments').get();
    for (final doc in commentsSnap.docs) {
      await _deleteCommentImagesFromDoc(doc);
    }

    final anonSnap = await threadRef.collection('anonymous_ids').get();
    final batch = _firestore.batch();
    for (final doc in commentsSnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in anonSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(threadRef);
    await batch.commit();
  }

  static Future<void> deleteComment({
    required String threadId,
    required String commentId,
    required String authorId,
  }) async {
    final threadRef = _firestore.collection(_threadsCollection).doc(threadId);
    final commentRef = threadRef.collection('comments').doc(commentId);
    final commentSnap = await commentRef.get();
    if (!commentSnap.exists) return;

    final data = commentSnap.data()!;
    final commentAuthorId = data['authorId'] as String? ?? '';
    if (commentAuthorId != authorId) {
      throw StateError('このレスを削除する権限がありません');
    }
    if (data['isDeleted'] as bool? ?? false) return;

    await commentRef.update({
      'isDeleted': true,
      'body': '',
      'imageUrls': <String>[],
    });

    await _deleteCommentImagesFromDoc(commentSnap);
  }

  static Future<void> _deleteCommentImagesFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    if (data == null) return;

    final authorId = data['authorId'] as String? ?? '';
    final threadId = doc.reference.parent.parent?.id;
    if (authorId.isEmpty || threadId == null) return;

    await ChibaChannelImageService.deleteCommentImages(
      userId: authorId,
      threadId: threadId,
      commentId: doc.id,
    );
  }
}
