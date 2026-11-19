const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const {test, before, after, beforeEach} = require('node:test');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, setDoc, updateDoc, getDoc, deleteDoc, deleteField} = require('firebase/firestore');

let env;
const client = (uid = 'owner', verified = true) => env.authenticatedContext(uid, {
  email: `${uid}@chibatech.ac.jp`, email_verified: verified,
}).firestore();
const pin = (db, postId, uid = 'owner') => updateDoc(doc(db, `users/${uid}`), {cwitterPinnedPostId: postId});

before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-cit-pins', firestore: {
    host: '127.0.0.1', port: 8089, rules: readFileSync('firestore.rules', 'utf8'),
  }});
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/owner'), {cwitterId: 'owner', displayName: '学生'});
    await setDoc(doc(db, 'users/other'), {cwitterId: 'other'});
    await setDoc(doc(db, 'cwitter_posts/one'), {authorId: 'owner'});
    await setDoc(doc(db, 'cwitter_posts/two'), {authorId: 'owner'});
    await setDoc(doc(db, 'cwitter_posts/foreign'), {authorId: 'other'});
  });
});

test('the owner can pin, replace, and unpin; another viewer can read the reference', async () => {
  const db = client();
  await assertSucceeds(pin(db, 'one'));
  await assertSucceeds(pin(db, 'two'));
  assert.equal((await getDoc(doc(client('other'), 'users/owner'))).data().cwitterPinnedPostId, 'two');
  await assertSucceeds(pin(db, deleteField()));
  assert.equal((await getDoc(doc(db, 'users/owner'))).data().cwitterPinnedPostId, undefined);
});

test('foreign, missing and malformed pins are rejected when adding or replacing the field', async () => {
  for (const value of ['foreign', 'missing', 'a/b', '', 7, ['one']]) {
    await assertFails(pin(client(), value));
  }
  await assertSucceeds(pin(client(), 'one'));
  await assertFails(pin(client(), 'foreign'));
});

test('another account, an unverified account, and an anonymous caller cannot pin', async () => {
  await assertFails(pin(client('other'), 'one'));
  await assertFails(pin(client('owner', false), 'one'));
  await assertFails(pin(env.unauthenticatedContext().firestore(), 'one'));
});

test('a banned owner cannot set a new pin', async () => {
  await env.withSecurityRulesDisabled(context => setDoc(doc(context.firestore(), 'banned_users/owner'), {permanent: true}));
  await assertFails(pin(client(), 'one'));
});

test('post deletion does not block profile updates or clearing a dangling pin', async () => {
  const db = client();
  await assertSucceeds(pin(db, 'one'));
  await assertSucceeds(deleteDoc(doc(db, 'cwitter_posts/one')));
  await assertSucceeds(updateDoc(doc(db, 'users/owner'), {displayName: '更新した名前'}));
  await assertSucceeds(pin(db, deleteField()));
});

test('profile creation cannot introduce a forged pin', async () => {
  await assertFails(setDoc(doc(client('newuser'), 'users/newuser'), {cwitterPinnedPostId: 'one'}));
  await assertSucceeds(setDoc(doc(client('newuser'), 'users/newuser'), {displayName: '新しい学生'}));
  await assertSucceeds(setDoc(doc(client('unverified', false), 'users/unverified'), {displayName: '登録中の学生'}));
});
