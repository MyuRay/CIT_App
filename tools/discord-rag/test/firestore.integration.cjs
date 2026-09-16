'use strict';
const {test, before, after, beforeEach} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertFails} = require('@firebase/rules-unit-testing');
const {doc, getDoc, setDoc} = require('firebase/firestore');
const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {createJobStore} = require('../src/jobs');
assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8091', 'Only the dedicated local emulator is allowed');
const projectId = 'demo-cit-rag';
let env, app, db;
before(async () => {
  env = await initializeTestEnvironment({projectId, firestore: {host: '127.0.0.1', port: 8091,
    rules: fs.readFileSync(path.resolve(__dirname, '../../../firestore.rules'), 'utf8')}});
  app = initializeApp({projectId}, 'rag-integration');
  db = getFirestore(app);
});
beforeEach(async () => env.clearFirestore());
after(async () => {await env?.cleanup(); if (app) await deleteApp(app);});
const job = (id = '1', userId = 'user') => ({id, userId, guildId: 'guild', question: 'private-question', token: 'private-token'});

test('concurrent transactions reserve one job and enforce shared user and guild limits', async () => {
  const store = createJobStore(db, {userDailyLimit: 2, guildDailyLimit: 3});
  const statuses = await Promise.all(Array.from({length: 6}, () => store.claim(job())));
  assert.equal(statuses.filter(result => result.status === 'claimed').length, 1);
  assert.equal(statuses.filter(result => result.status === 'busy').length, 5);
  assert.equal((await store.claim(job('2'))).status, 'claimed');
  assert.equal((await store.claim(job('3'))).status, 'limited');
  assert.equal((await store.claim(job('4', 'other'))).status, 'claimed');
  assert.equal((await store.claim(job('5', 'another'))).status, 'limited');
});

test('answer cache survives retries; questions and tokens are not persisted', async () => {
  const store = createJobStore(db);
  await store.claim(job());
  await store.complete(job(), '回答');
  await store.release(job());
  assert.deepEqual(await store.claim(job()), {status: 'cached', content: '回答'});
  const records = await db.collection('handoff_rag_jobs').get();
  const serialized = JSON.stringify(records.docs.map(record => record.data()));
  assert.ok(!serialized.includes('private-question'));
  assert.ok(!serialized.includes('private-token'));
  assert.ok(records.docs[0].data().expiresAt.toMillis() > Date.now());
});

test('anonymous, signed-in and app administrators cannot access RAG internal records', async () => {
  await db.doc('admin_permissions/admin').set({isAdmin: true});
  for (const client of [env.unauthenticatedContext().firestore(),
    env.authenticatedContext('member', {email_verified: true, email: 'member@s.chibakoudai.jp'}).firestore(),
    env.authenticatedContext('admin', {email_verified: true, email: 'admin@s.chibakoudai.jp'}).firestore()]) {
    for (const collection of ['handoff_rag_jobs', 'handoff_rag_usage']) {
      await db.doc(`${collection}/test`).set({count: 1});
      await assertFails(getDoc(doc(client, `${collection}/test`)));
      await assertFails(setDoc(doc(client, `${collection}/test`), {count: 0}));
    }
  }
});
