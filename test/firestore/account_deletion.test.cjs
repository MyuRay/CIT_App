const {test, before, after} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {createRequire} = require('node:module');
const functionsRequire = createRequire(require.resolve('../../functions/package.json'));
const {initializeApp, deleteApp} = functionsRequire('firebase-admin/app');
const {getFirestore} = functionsRequire('firebase-admin/firestore');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc} = require('firebase/firestore');
const {createDeletionWorker} = require('../../functions/account_deletion');
let app, db, env;
before(async () => {
  assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8089');
  app = initializeApp({projectId: 'demo-cit-deletion'}, 'deletion-tests');
  db = getFirestore(app);
  env = await initializeTestEnvironment({projectId: 'demo-cit-deletion', firestore: {
    host: '127.0.0.1', port: 8089, rules: fs.readFileSync('firestore.rules', 'utf8')}});
});
after(async () => {await env?.cleanup(); await db?.terminate(); if (app) await deleteApp(app);});
test('deletion guard denies even still-valid owner tokens and cannot be forged', async () => {
  const user = env.authenticatedContext('guard-owner', {email: 'user@chibatech.ac.jp', email_verified: true}).firestore();
  await assertSucceeds(setDoc(doc(user, 'users/guard-owner'), {uid: 'guard-owner'}));
  await assertFails(setDoc(doc(user, 'account_deletion_jobs/guard-owner'), {status: 'queued'}));
  await db.doc('account_deletion_jobs/guard-owner').set({status: 'queued'});
  await assertFails(setDoc(doc(user, 'users/guard-owner'), {uid: 'guard-owner'}));
  await assertFails(getDoc(doc(user, 'users/guard-owner')));
  const other = env.authenticatedContext('other', {email: 'other@chibatech.ac.jp', email_verified: true}).firestore();
  await assertSucceeds(setDoc(doc(other, 'users/other'), {uid: 'other'}));
});
test('worker resumes storage failure, deletes private descendants, preserves others and finishes Auth last', async () => {
  const uid = 'delete-owner';
  const image = 'https://firebasestorage.googleapis.com/v0/b/test-bucket/o/bulletin_images%2Flegacy.jpg?token=test';
  const fixtures = {
    [`account_deletion_jobs/${uid}`]: {status: 'queued'},
    [`users/${uid}`]: {displayName: 'Private'},
    [`users/${uid}/assignments/a`]: {title: 'Private'},
    [`users/${uid}/cafeteria_favorites/a`]: {userId: uid},
    [`user_tokens/${uid}/devices/a`]: {token: 'private'},
    'bulletin_posts/owned': {authorId: uid, imageUrl: image},
    'bulletin_posts/other': {authorId: 'other', couponUsedBy: {[uid]: 2, other: 3}, couponUsedCount: 5},
    'cwitter_posts/other': {authorId: 'other', replyCount: 1, poll: {votedBy: {[uid]: 'a', other: 'a'}, options: [{id: 'a', voteCount: 2}]}},
    'cwitter_posts/other/replies/mine': {authorId: uid},
    'chiba_channel_threads/other/comments/mine': {authorId: uid},
    'chiba_channel_threads/other/anonymous_ids/delete-owner': {anonymousId: 'private'},
    'users/other/cwitter_followers/delete-owner': {authorId: uid},
    'cafeteria_reviews/other': {userId: 'other', likedBy: {[uid]: true, other: true}, likeCount: 2},
    'notifications/incoming': {userId: uid},
    'notifications/outgoing': {userId: 'other', fromUserId: uid},
  };
  for (const [p, d] of Object.entries(fixtures)) await db.doc(p).set(d);
  const files = new Set(['profile_images/delete-owner/a', 'bulletin_images/legacy.jpg', 'profile_images/other/a']);
  const calls = []; let fail = true;
  const worker = createDeletionWorker({db,
    auth: {updateUser: async () => calls.push('disable'), revokeRefreshTokens: async () => calls.push('revoke'), deleteUser: async () => calls.push('deleteAuth')},
    bucket: {name: 'test-bucket', async deleteFiles({prefix}) {for (const f of files) if (f.startsWith(prefix)) files.delete(f);},
      file: path => ({async delete() {if (fail) {fail = false; throw Error('temporary storage outage');} files.delete(path);}})},
  });
  await assert.rejects(worker(uid), /temporary storage outage/);
  assert.equal(calls.includes('deleteAuth'), false);
  assert.equal((await db.doc(`account_deletion_jobs/${uid}`).get()).data().status, 'retry');
  await worker(uid);
  assert.equal((await db.doc(`account_deletion_jobs/${uid}`).get()).data().status, 'complete');
  assert.equal(calls.at(-1), 'deleteAuth');
  for (const p of Object.keys(fixtures)) {
    if (p.startsWith('account_deletion_jobs/') || ['bulletin_posts/other', 'cafeteria_reviews/other', 'cwitter_posts/other'].includes(p)) continue;
    assert.equal((await db.doc(p).get()).exists, false, p);
  }
  assert.equal((await db.doc('bulletin_posts/other').get()).exists, true);
  assert.equal((await db.doc('bulletin_posts/other').get()).data().couponUsedCount, 3);
  const post = (await db.doc('cwitter_posts/other').get()).data();
  assert.equal(post.replyCount, 0);
  assert.deepEqual(post.poll.votedBy, {other: 'a'});
  assert.equal(post.poll.options[0].voteCount, 1);
  assert.deepEqual((await db.doc('cafeteria_reviews/other').get()).data().likedBy, {other: true});
  assert.equal((await db.doc('cafeteria_reviews/other').get()).data().likeCount, 1);
  assert.deepEqual([...files], ['profile_images/other/a']);
  const count = calls.length; await worker(uid); assert.equal(calls.length, count);
});
