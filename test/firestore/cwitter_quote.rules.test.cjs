const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const {test, before, after, beforeEach} = require('node:test');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, deleteDoc, runTransaction, serverTimestamp, collection, query, where, getDocs} = require('firebase/firestore');

let env;
const client = (uid = 'writer', verified = true) => env.authenticatedContext(uid, {
  email: `${uid}@chibatech.ac.jp`, email_verified: verified,
}).firestore();
const post = (authorId, extra = {}) => ({authorId, authorEmail: `${authorId}@chibatech.ac.jp`,
  cwitterId: authorId, displayName: '学生', body: '引用コメント', createdAt: serverTimestamp(),
  replyCount: 0, likeCount: 0, recweetCount: 0, likedBy: {}, ...extra});

before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-cit-review', firestore: {
    host: '127.0.0.1', port: 8089,
    rules: readFileSync(process.env.CIT_QUOTE_RULES_PATH || 'firestore.rules', 'utf8'),
  }});
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/writer'), {cwitterId: 'writer'});
    await setDoc(doc(db, 'users/source'), {cwitterId: 'source'});
    await setDoc(doc(db, 'cwitter_posts/original'), post('source'));
  });
});

test('existing rules accept a quote and rate limit atomically without modifying the original', async () => {
  const db = client();
  const original = doc(db, 'cwitter_posts/original');
  const rate = doc(db, 'users/writer/rate_limits/cwitter_post');
  await assertSucceeds(runTransaction(db, async transaction => {
    assert.equal((await transaction.get(original)).exists(), true);
    await transaction.get(rate);
    transaction.set(rate, {windowStart: serverTimestamp(), count: 1, updatedAt: serverTimestamp()});
    transaction.set(doc(db, 'cwitter_posts/quote'), post('writer', {quotedPostId: 'original'}));
  }));
  const quote = (await getDoc(doc(db, 'cwitter_posts/quote'))).data();
  assert.equal(quote.quotedPostId, 'original');
  assert.equal(quote.authorId, 'writer');
  assert.equal((await getDoc(original)).data().recweetCount, 0);
});

test('quote author and verification requirements remain enforced', async () => {
  await assertFails(setDoc(doc(client('source'), 'cwitter_posts/forged'), post('writer', {quotedPostId: 'original'})));
  await assertFails(setDoc(doc(client('writer', false), 'cwitter_posts/unverified'), post('writer', {quotedPostId: 'original'})));
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), 'cwitter_posts/anonymous'), post('writer', {quotedPostId: 'original'})));
});

test('deleting a quote preserves its source and deleted sources are observable', async () => {
  const db = client();
  const quote = doc(db, 'cwitter_posts/quote');
  await assertSucceeds(setDoc(quote, post('writer', {quotedPostId: 'original'})));
  await assertFails(deleteDoc(doc(client('source'), 'cwitter_posts/quote')));
  await assertSucceeds(deleteDoc(quote));
  assert.equal((await getDoc(doc(db, 'cwitter_posts/original'))).exists(), true);
  await assertSucceeds(deleteDoc(doc(client('source'), 'cwitter_posts/original')));
  assert.equal((await getDoc(doc(db, 'cwitter_posts/original'))).exists(), false);
});

test('quote visibility checks can read both block directions and the moderation index', async () => {
  const db = client();
  for (const [owner, blocked] of [['writer', 'source'], ['source', 'writer']]) {
    await assertSucceeds(getDocs(query(collection(db, 'blocked_users'), where('userId', '==', owner), where('blockedUserId', '==', blocked))));
  }
  await assertSucceeds(getDoc(doc(db, 'moderation/banned_index')));
});
