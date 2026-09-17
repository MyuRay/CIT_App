'use strict';
// Opt-in smoke test: creates only a unique test identity and private fixtures.
// No profile/post/contact docs are created, so this sends no external messages.
const assert = require('node:assert/strict');
const {randomUUID, randomBytes} = require('node:crypto');
const cli = require('../node_modules/firebase-tools/lib/auth');
const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
if (process.argv.slice(2).join(' ') !== '--project cit-app-2de1c --run') throw Error('Requires --project cit-app-2de1c --run');
const project = 'cit-app-2de1c';
const uid = 'deletion-test-' + randomUUID();
const endpoint = 'https://us-central1-' + project + '.cloudfunctions.net/deleteMyAccount';
let app, accepted = false;
(async () => {
  const account = cli.getGlobalDefaultAccount();
  const token = await cli.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  app = initializeApp({projectId: project, credential: {getAccessToken: async () => ({access_token: token.access_token, expires_in: 3600})}});
  const auth = getAuth(app);
  const adminHeaders = {Authorization: 'Bearer ' + token.access_token, 'Content-Type': 'application/json'};
  const base = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/`;
  const file = `profile_images/${uid}/smoke.txt`;
  const bucket = project + '.firebasestorage.app';
  const paths = [`users/${uid}/assignments/smoke`, `user_tokens/${uid}/devices/smoke`];
  async function adminRequest(url, method = 'GET', body) {
    const r = await fetch(url, {method, headers: adminHeaders, body: body && JSON.stringify(body)});
    if (!r.ok && r.status !== 404) throw Error(`Admin ${method} failed: ${r.status}`);
    return r;
  }
  try {
    const noAuth = await fetch(endpoint, {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({confirm: true})});
    assert.equal(noAuth.status, 401);
    const password = randomBytes(24).toString('hex');
    const email = `${uid}@chibatech.ac.jp`;
    await auth.createUser({uid, email, emailVerified: true, password});
    for (const p of paths) await adminRequest(base + p, 'PATCH', {fields: {smoke: {booleanValue: true}}});
    const uploaded = await fetch(`https://storage.googleapis.com/upload/storage/v1/b/${bucket}/o?uploadType=media&name=${encodeURIComponent(file)}`, {
      method: 'POST', headers: {Authorization: adminHeaders.Authorization, 'Content-Type': 'text/plain'}, body: 'temporary deletion test',
    });
    assert.equal(uploaded.ok, true);
    const config = require('../android/app/google-services.json');
    const key = config.client.find(c => c.client_info.android_client_info.package_name === 'jp.ac.chibakoudai.citapp').api_key[0].current_key;
    const signed = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${key}`, {
      method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({email, password, returnSecureToken: true}),
    });
    assert.equal(signed.ok, true); const credentials = await signed.json();
    const headers = {'Content-Type': 'application/json', Authorization: 'Bearer ' + credentials.idToken};
    const forged = await fetch(endpoint, {method: 'POST', headers, body: JSON.stringify({confirm: true, uid: 'another-user'})});
    assert.equal(forged.status, 400);
    const result = await fetch(endpoint, {method: 'POST', headers, body: JSON.stringify({confirm: true})});
    assert.equal(result.status, 202); accepted = true;
    console.log('PASS: authenticated deletion accepted; unauthenticated/other-UID requests rejected');
    const staleWrite = await fetch(base + paths[0], {method: 'PATCH', headers, body: JSON.stringify({fields: {smoke: {booleanValue: true}}})});
    assert.equal(staleWrite.status, 403);
    console.log('PASS: still-valid old token cannot recreate private data');
    for (let i = 0; i < 90; i++) {
      const r = await adminRequest(base + `account_deletion_jobs/${uid}`);
      const job = await r.json();
      if (job.fields?.status?.stringValue === 'complete') {
        for (const p of paths) assert.equal((await adminRequest(base + p)).status, 404);
        await assert.rejects(auth.getUser(uid), e => e.code === 'auth/user-not-found');
        assert.equal((await adminRequest(`https://storage.googleapis.com/storage/v1/b/${bucket}/o/${encodeURIComponent(file)}`)).status, 404);
        console.log('PASS: automatic worker removed Auth, nested Firestore data, and Storage object');
        return;
      }
      if (i % 6 === 0) console.log('Deletion job: ' + (job.fields?.status?.stringValue || 'unknown') + ', stage ' + (job.fields?.stage?.integerValue || '0'));
      await new Promise(r => setTimeout(r, 5000));
    }
    throw Error('Test job not completed within 450 seconds; server retries remain active');
  } finally {
    if (!accepted) {
      for (const p of paths) await adminRequest(base + p, 'DELETE');
      await adminRequest(`https://storage.googleapis.com/storage/v1/b/${bucket}/o/${encodeURIComponent(file)}`, 'DELETE');
      try {await auth.deleteUser(uid);} catch (e) {if (e.code !== 'auth/user-not-found') throw e;}
    }
  }
})().catch(e => {console.error(e.message); process.exitCode = 1;}).finally(async () => {if (app) await deleteApp(app);});
