'use strict';

/** No message content goes into lock-screen notifications. */
function replyNotification(uid, messageId, message, createdAt) {
  if (message.userId !== uid || message.senderRole !== 'admin' ||
      typeof message.senderId !== 'string' || typeof message.text !== 'string' ||
      !Number.isInteger(message.senderSequence) || message.senderSequence < 1) return null;
  return {userId: uid, type: 'general', title: 'CIT App 運営から返信が届きました',
    message: 'お問い合わせを開いて確認してください', isRead: false,
    fromUserId: message.senderId, fromUserName: 'CIT App 運営', createdAt,
    data: {type: 'contact_response', source: 'contact_chat', contactId: uid, messageId}};
}

function createChatReplyHandler({db, serverTimestamp}) {
  return async (uid, messageId, message) => {
    const notification = replyNotification(uid, messageId, message, serverTimestamp());
    if (!notification) return;
    const target = db.collection('notifications').doc('contact_chat_' + uid + '_' + messageId);
    await db.runTransaction(async tx => {
      const [existing, room, deletion] = await Promise.all([
        tx.get(target), tx.get(db.collection('contact_chats').doc(uid)),
        tx.get(db.collection('account_deletion_jobs').doc(uid)),
      ]);
      if (existing.exists || !room.exists || deletion.exists ||
          room.data().userReadCount >= message.senderSequence) return;
      tx.set(target, notification);
    });
  };
}
module.exports = {replyNotification, createChatReplyHandler};