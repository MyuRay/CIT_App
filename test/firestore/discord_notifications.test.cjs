'use strict';
// Emulator-only tests must never probe cloud instance metadata or use real ADC.
process.env.METADATA_SERVER_DETECTION = 'none';
const {test, before, beforeEach, after} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {createRequire} = require('node:module');
const req = createRequire(require.resolve('../../functions/package.json'));
const {initializeApp, deleteApp} = req('firebase-admin/app');
const {getFirestore} = req('firebase-admin/firestore');
const {OAuth2Client} = req('google-auth-library');
const {initializeTestEnvironment, assertFails} = require('@firebase/rules-unit-testing');
const {doc, getDoc, setDoc, getDocs, collection} = require('firebase/firestore');
const {COLLECTION, LEASE_MS, createDiscordNotifications} = require('../../functions/discord_notifications');
const {GROUPS, createDeletionWorker} = require('../../functions/account_deletion');
let app, db, env;
const webhook = 'https://discord.com/api/webhooks/123456/fake-test-token';
const payload = {embeds: [{description: 'PRIVATE CONTENT', fields: [{name: 'UID', value: 'alice'}]}]};

before(async () => {
  assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8089');
  app = initializeApp({projectId: 'demo-cit-discord'}, 'discord-tests');
  db = getFirestore(app);
  const emulatorAuth = new OAuth2Client();
  emulatorAuth.setCredentials({access_token: 'owner', expiry_date: Date.now() + 3600000});
  db.settings({authClient: emulatorAuth, universeDomain: 'googleapis.com'});
  env = await initializeTestEnvironment({projectId: 'demo-cit-discord', firestore: {
    host: '127.0.0.1', port: 8089, rules: fs.readFileSync('firestore.rules', 'utf8'),
  }});
});
beforeEach(async () => env.clearFirestore());
after(async () => {await env?.cleanup(); await db?.terminate(); if (app) await deleteApp(app);});

function fixture(options = {}) {
  const messages = new Map();
  const calls = [];
  let id = 1000;
  const auth = {async getUser(uid) {return {uid, disabled: false};}, ...options.auth};
  const http = {
    async post(url, body) {
      calls.push('post');
      assert.equal(new URL(url).searchParams.get('wait'), 'true');
      assert.equal(JSON.stringify(body).includes('PRIVATE'), false);
      assert.equal(JSON.stringify(body).includes('alice'), false);
      const messageId = String(++id);
      messages.set(messageId, body);
      await options.afterPost?.(messageId);
      return {data: {id: messageId}};
    },
    async patch(url, body) {
      calls.push('patch');
      await options.beforePatch?.(url);
      const messageId = new URL(url).pathname.split('/').at(-1);
      const receipts = await db.collection(COLLECTION).where('messageId', '==', messageId).get();
      assert.equal(receipts.size, 1, 'receipt is durable before publishing personal content');
      assert.equal(JSON.stringify(receipts.docs[0].data()).includes('fake-test-token'), false);
      assert.equal(JSON.stringify(receipts.docs[0].data()).includes('PRIVATE CONTENT'), false);
      assert.deepEqual(body.allowed_mentions, {parse: []});
      if (!messages.has(messageId)) throw {response: {status: 404, data: {code: 10008}}};
      messages.set(messageId, body);
      await options.afterPatch?.();
    },
    async delete(url) {
      calls.push('delete');
      await options.beforeDelete?.(url);
      messages.delete(new URL(url).pathname.split('/').at(-1));
    },
  };
  const service = createDiscordNotifications({db: options.db || db, auth, http,
    getWebhook: options.getWebhook || (() => webhook),
    getHistoricalWebhooks: options.getHistoricalWebhooks,
    now: options.now});
  return {...service, messages, calls, sendEvent: (eventId = 'event-1', userIds = ['alice']) =>
    service.send('cwitter', payload, {eventId, userIds})};
}

test('records message ID before content, suppresses duplicate and concurrent events', async () => {
  const f = fixture();
  await Promise.all([f.sendEvent(), f.sendEvent()]);
  await f.sendEvent();
  assert.deepEqual(f.calls, ['post', 'patch']);
  assert.equal((await db.collection(COLLECTION).get()).size, 1);
});

test('deleting or nonexistent accounts cannot send, including delayed event delivery', async () => {
  const f = fixture();
  await db.doc('account_deletion_jobs/alice').set({status: 'complete'});
  assert.equal(await f.sendEvent(), false);
  const missing = fixture({auth: {async getUser() {throw {code: 'auth/user-not-found'};}}});
  await db.doc('account_deletion_jobs/alice').delete();
  assert.equal(await missing.sendEvent(), false);
  assert.deepEqual(f.calls, []);
  assert.deepEqual(missing.calls, []);
});

test('retirement during placeholder creation never publishes personal content', async () => {
  const f = fixture({afterPost: () => db.doc('account_deletion_jobs/alice').set({status: 'queued'})});
  assert.equal(await f.sendEvent(), false);
  assert.equal(f.calls.includes('patch'), false);
  assert.equal(await f.purgeUser('alice'), true);
  assert.equal(f.messages.size, 0);
  assert.equal((await db.collection(COLLECTION).get()).size, 0);
});

test('cleanup waits for in-flight send and then clears all copies', async () => {
  let release, entered;
  const hold = new Promise(resolve => {release = resolve;});
  const posted = new Promise(resolve => {entered = resolve;});
  const f = fixture({afterPost: async () => {entered(); await hold;}});
  const sending = f.sendEvent();
  await posted;
  await db.doc('account_deletion_jobs/alice').set({status: 'queued'});
  assert.equal(await f.purgeUser('alice'), false);
  release();
  await sending;
  assert.equal(await f.purgeUser('alice'), true);
  assert.equal(f.messages.size, 0);
});

test('lost PATCH response still leaves a receipt that can delete the published content', async () => {
  const f = fixture({afterPatch: async () => {throw Error('simulated timeout');}});
  await assert.rejects(f.sendEvent(), /requires retry/);
  assert.equal(JSON.stringify([...f.messages.values()]).includes('PRIVATE CONTENT'), true);
  assert.equal(await f.purgeUser('alice'), true);
  assert.equal(f.messages.size, 0);
});

test('receipt write failure cannot orphan personal content', async () => {
  let transactions = 0;
  const wrapped = {collection: name => db.collection(name), runTransaction: fn => {
    if (++transactions === 2) throw Error('simulated Firestore outage after POST');
    return db.runTransaction(fn);
  }};
  const f = fixture({db: wrapped});
  await assert.rejects(f.sendEvent(), /requires retry/);
  assert.equal(f.calls.includes('patch'), false);
  assert.equal(JSON.stringify([...f.messages.values()]).includes('PRIVATE CONTENT'), false);
  assert.equal(await f.purgeUser('alice'), true);
});

test('shared context is removed for either author without deleting unrelated notifications', async () => {
  const f = fixture();
  await f.sendEvent('reply', ['alice', 'bob']);
  await f.sendEvent('other', ['carol']);
  assert.equal(await f.purgeUser('bob'), true);
  assert.equal(f.messages.size, 1);
  const left = (await db.collection(COLLECTION).get()).docs[0].data();
  assert.deepEqual(left.ownerIds, ['carol']);
});

test('429 and 403 keep receipts; retry removes them, explicit missing message is success', async () => {
  let failure = {response: {status: 429, data: {}}};
  const f = fixture({beforeDelete: async () => {if (failure) throw failure;}});
  await f.sendEvent();
  await assert.rejects(f.purgeUser('alice'), /requires retry/);
  assert.equal((await db.collection(COLLECTION).get()).size, 1);
  failure = {response: {status: 403, data: {code: 50013}}};
  await assert.rejects(f.purgeUser('alice'), /requires retry/);
  failure = {response: {status: 404, data: {code: 10008}}};
  assert.equal(await f.purgeUser('alice'), true);
  assert.equal((await db.collection(COLLECTION).get()).size, 0);
});

test('changed webhook requires old credential; no receipt is silently discarded', async () => {
  let current = webhook, historical = [];
  const f = fixture({getWebhook: () => current, getHistoricalWebhooks: () => historical});
  await f.sendEvent();
  current = 'https://discord.com/api/webhooks/789012/new-test-token';
  await assert.rejects(f.purgeUser('alice'), /credential unavailable/);
  assert.equal((await db.collection(COLLECTION).get()).size, 1);
  historical = [webhook];
  assert.equal(await f.purgeUser('alice'), true);
  assert.equal(f.messages.size, 0);
});

test('retry and cleanup retain the original thread, including a non-thread message', async () => {
  for (const originalThread of [null, '112233']) {
    let current = originalThread ? `${webhook}?thread_id=${originalThread}` : webhook;
    let fail = true;
    const checkThread = url => assert.equal(new URL(url).searchParams.get('thread_id'), originalThread);
    const f = fixture({getWebhook: () => current, beforePatch: checkThread, beforeDelete: checkThread,
      afterPatch: () => {if (fail) throw Error('lost response');}});
    await assert.rejects(f.sendEvent(), /requires retry/);
    fail = false;
    current = `${webhook}?thread_id=445566`;
    assert.equal(await f.sendEvent(), true);
    assert.deepEqual(f.calls, ['post', 'patch', 'patch']);
    assert.equal(await f.purgeUser('alice'), true);
    assert.equal(f.messages.size, 0);
  }
});

test('expired preparation with no message ID is safely cancelled', async () => {
  await db.doc(`${COLLECTION}/stale`).set({ownerIds: ['alice'], state: 'preparing',
    leaseUntilMs: Date.now() - LEASE_MS});
  assert.equal(await fixture().purgeUser('alice'), true);
  assert.equal((await db.collection(COLLECTION).get()).empty, true);
});

test('client cannot read, enumerate, create or modify deletion receipts', async () => {
  await db.doc(`${COLLECTION}/private`).set({ownerIds: ['alice'], messageId: '123'});
  for (const uid of ['alice', 'other']) {
    const client = env.authenticatedContext(uid, {email: `${uid}@chibatech.ac.jp`, email_verified: true}).firestore();
    await assertFails(getDoc(doc(client, COLLECTION, 'private')));
    await assertFails(getDocs(collection(client, COLLECTION)));
    await assertFails(setDoc(doc(client, COLLECTION, 'private'), {ownerIds: [uid]}));
    await assertFails(setDoc(doc(client, COLLECTION, 'new'), {ownerIds: [uid]}));
  }
});

test('account deletion stays retryable until Discord cleanup succeeds, then deletes Auth last', async () => {
  let failure = true;
  const f = fixture({beforeDelete: async () => {if (failure) throw {response: {status: 503}};}});
  await f.sendEvent();
  await db.doc('account_deletion_jobs/alice').set({status: 'queued', stage: GROUPS.length});
  await db.doc('users/alice').set({private: 'profile'});
  const calls = [];
  const worker = createDeletionWorker({db, purgeDiscord: f.purgeUser,
    auth: {updateUser: async () => {}, revokeRefreshTokens: async () => {}, deleteUser: async () => calls.push('auth')},
    bucket: {name: 'test', deleteFiles: async () => {}},
  });
  await assert.rejects(worker('alice'), /requires retry/);
  assert.deepEqual(calls, []);
  assert.equal((await db.doc('users/alice').get()).exists, true);
  assert.equal((await db.doc('account_deletion_jobs/alice').get()).data().status, 'retry');
  failure = false;
  await worker('alice');
  assert.equal((await db.doc('account_deletion_jobs/alice').get()).data().status, 'complete');
  assert.equal(f.messages.size, 0);
  assert.equal((await db.doc('users/alice').get()).exists, false);
  assert.deepEqual(calls, ['auth']);
});
