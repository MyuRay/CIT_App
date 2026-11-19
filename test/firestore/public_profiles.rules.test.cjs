'use strict';
process.env.METADATA_SERVER_DETECTION = 'none';
const {test, before, beforeEach, after} = require('node:test');
const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, collection, getDoc, getDocs, setDoc} = require('firebase/firestore');
let env;
function client(uid, verified = true) {
  return env.authenticatedContext(uid, {email: `${uid}@chibatech.ac.jp`, email_verified: verified}).firestore();
}
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-cit-profiles', firestore: {
    host: '127.0.0.1', port: 8089, rules: readFileSync(process.env.PROFILE_RULES_FILE || 'firestore.rules', 'utf8'),
  }});
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/alice'), {uid: 'alice', email: 'alice@chibatech.ac.jp', studentId: 'private'});
    await setDoc(doc(db, 'public_profiles/alice'), {uid: 'alice', displayName: 'Alice'});
    await setDoc(doc(db, 'admin_permissions/admin'), {isAdmin: true});
  });
});
after(async () => env?.cleanup());
test('account email and student ID are unavailable to another university user', async () => {
  await assertFails(getDoc(doc(client('bob'), 'users/alice')));
  await assertFails(getDocs(collection(client('bob'), 'users')));
  await assertSucceeds(getDoc(doc(client('alice'), 'users/alice')));
  await assertSucceeds(getDoc(doc(client('admin'), 'users/alice')));
});
test('readable profiles cannot be created or poisoned by clients', async () => {
  await assertSucceeds(getDoc(doc(client('bob'), 'public_profiles/alice')));
  for (const uid of ['alice', 'bob', 'admin']) {
    await assertFails(setDoc(doc(client(uid), 'public_profiles/alice'), {email: 'leak@example.com'}));
  }
  await assertFails(getDoc(doc(client('bob', false), 'public_profiles/alice')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'public_profiles/alice')));
});
test('retirement immediately prevents reads and account writes', async () => {
  await env.withSecurityRulesDisabled(ctx => setDoc(doc(ctx.firestore(), 'account_deletion_jobs/alice'), {status: 'queued'}));
  await assertFails(getDoc(doc(client('alice'), 'users/alice')));
  await assertFails(getDoc(doc(client('alice'), 'public_profiles/alice')));
});
