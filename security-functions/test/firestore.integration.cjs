'use strict';
const {test, before, after} = require('node:test');
const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertFails} = require('@firebase/rules-unit-testing');
const {doc, getDoc, setDoc, deleteDoc} = require('firebase/firestore');
const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const assert = require('node:assert/strict');
const {createAlertStore, createDelivery} = require('../security_monitor');
let env, server, db;
before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw Error('Requires isolated Firestore emulator');
  env = await initializeTestEnvironment({projectId: 'demo-cit-security-notify',
    firestore: {host: '127.0.0.1', port: 8188, rules: readFileSync('firestore.rules', 'utf8')}});
  server = initializeApp({projectId: 'demo-cit-security-notify'}, 'security-integration');
  db = getFirestore(server);
});
after(async () => {if (env) await env.cleanup(); if (server) await deleteApp(server);});
test('users, including in-app admins, cannot read, forge or erase security records', async () => {
  await db.doc('admin_permissions/admin').set({isAdmin: true});
  for (const collection of ['security_alerts', 'security_monitor_state', 'security_monitor_probes']) {
    await db.doc(collection + '/sample').set({status: 'pending'});
    for (const uid of ['reader', 'admin']) {
      const client = env.authenticatedContext(uid, {email: `${uid}@s.chibakoudai.jp`, email_verified: true}).firestore();
      const ref = doc(client, collection + '/sample');
      await assertFails(getDoc(ref)); await assertFails(setDoc(ref, {status: 'sent'})); await assertFails(deleteDoc(ref));
    }
  }
});
test('concurrent detections produce one queued notification; concurrent deliveries send once', async () => {
  const enqueue = createAlertStore({db, now: () => 1000000});
  const results = await Promise.all(Array.from({length: 6}, (_, i) => enqueue({kind: 'identity_changed', source: 'test', eventId: 'event-' + i})));
  assert.equal(results.filter(r => r.created).length, 1);
  const id = results.find(r => r.created).id;
  let sends = 0;
  const deliver = createDelivery({db, now: () => 1000000, webhook: () => 'https://discord.com/api/webhooks/123/local-mock',
    fetchImpl: async () => {sends++; return {ok: true, json: async () => ({id: 'mock-message'})};}});
  await Promise.allSettled(Array.from({length: 4}, () => deliver(id)));
  assert.equal(sends, 1);
  assert.equal((await db.doc('security_alerts/' + id).get()).data().status, 'sent');
});
