'use strict';
process.env.METADATA_SERVER_DETECTION = 'none';
const {test, before, beforeEach, after} = require('node:test');
const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, collection, getDoc, getDocs, setDoc, deleteDoc, updateDoc, Timestamp} = require('firebase/firestore');
let env;
const mapping = () => ({anonymousId: 'AbCd1234', createdAt: Timestamp.now()});
const path = 'chiba_channel_threads/thread/anonymous_ids/author';
function client(uid) {
  return env.authenticatedContext(uid, {email: `${uid}@chibatech.ac.jp`, email_verified: true}).firestore();
}
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-cit-chiba-private', firestore: {
    host: '127.0.0.1', port: 8089,
    rules: readFileSync(process.env.CHIBA_RULES_FILE || 'firestore.rules', 'utf8'),
  }});
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'admin_permissions/admin'), {isAdmin: true});
    await setDoc(doc(db, 'chiba_channel_threads/thread'), {authorId: 'owner'});
    await setDoc(doc(db, path), mapping());
  });
});
after(async () => env?.cleanup());
test('only the mapping subject and admin can get an identity, including when its UID is known', async () => {
  await assertSucceeds(getDoc(doc(client('author'), path)));
  await assertSucceeds(getDoc(doc(client('admin'), path)));
  for (const uid of ['reader', 'owner']) await assertFails(getDoc(doc(client(uid), path)));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), path)));
});
test('thread owner and ordinary users cannot enumerate identities', async () => {
  for (const uid of ['author', 'reader', 'owner']) {
    await assertFails(getDocs(collection(client(uid), 'chiba_channel_threads/thread/anonymous_ids')));
  }
  await assertSucceeds(getDocs(collection(client('admin'), 'chiba_channel_threads/thread/anonymous_ids')));
});
test('own missing identity can be checked and created, but never forged or replaced', async () => {
  const db = client('new-user');
  const own = doc(db, 'chiba_channel_threads/thread/anonymous_ids/new-user');
  await assertSucceeds(getDoc(own));
  await assertSucceeds(setDoc(own, mapping()));
  await assertFails(updateDoc(own, {anonymousId: 'Changed1'}));
  await assertFails(setDoc(doc(db, path), mapping()));
  await assertFails(setDoc(doc(db, 'chiba_channel_threads/missing/anonymous_ids/new-user'), mapping()));
});
test('only admins may directly delete mappings; retired accounts lose access', async () => {
  for (const uid of ['author', 'owner']) await assertFails(deleteDoc(doc(client(uid), path)));
  await env.withSecurityRulesDisabled(ctx => setDoc(doc(ctx.firestore(), 'account_deletion_jobs/author'), {status: 'queued'}));
  await assertFails(getDoc(doc(client('author'), path)));
  await assertSucceeds(deleteDoc(doc(client('admin'), path)));
});
