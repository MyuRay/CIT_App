'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {replyNotification, createChatReplyHandler} = require('../contact_chat');
const message = {userId: 'student', senderId: 'operator', senderRole: 'admin',
  text: 'private support text', senderSequence: 2};

test('only operator replies produce notifications and no private text enters the preview', () => {
  assert.equal(replyNotification('student', 'm', {...message, senderRole: 'user'}, 1), null);
  assert.equal(replyNotification('other', 'm', message, 1), null);
  const notification = replyNotification('student', 'm', message, 1);
  assert.equal(notification.data.source, 'contact_chat');
  assert.equal(notification.data.type, 'contact_response');
  assert.equal(notification.userId, 'student');
  assert.equal(JSON.stringify(notification).includes(message.text), false);
});

function fixture({read = 0, deleted = false, roomExists = true} = {}) {
  const saved = new Map();
  const db = {collection: name => ({doc: id => ({path: name + '/' + id})}),
    async runTransaction(fn) { await fn({
      async get(ref) {
        if (ref.path === 'contact_chats/student') return {exists: roomExists, data: () => ({userReadCount: read})};
        if (ref.path === 'account_deletion_jobs/student') return {exists: deleted};
        return {exists: saved.has(ref.path)};
      },
      set: (ref, data) => saved.set(ref.path, data),
    }); }};
  return {saved, run: () => createChatReplyHandler({db, serverTimestamp: () => 1})('student', 'm', message)};
}
test('duplicate trigger delivery creates exactly one notification', async () => {
  const f = fixture(); await f.run(); await f.run();
  assert.equal(f.saved.size, 1);
});
for (const [name, options] of [
  ['already read', {read: 2}], ['account deletion', {deleted: true}], ['missing room', {roomExists: false}],
]) test('suppresses notification for ' + name, async () => {
  const f = fixture(options); await f.run(); assert.equal(f.saved.size, 0);
});