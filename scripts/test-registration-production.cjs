'use strict';
// Explicit, isolated production smoke test. Sends NO emails and creates no
// profiles. Admin generates proof for a unique temporary test address; the
// public client API still has to pass the deployed beforeCreate function.
// Tokens, passwords and action links are kept in memory and never printed.
const assert = require('node:assert/strict');
const {randomUUID, randomBytes} = require('node:crypto');
const cliAuth = require('../node_modules/firebase-tools/lib/auth');
const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const projectId = 'cit-app-2de1c';
if (process.argv.slice(2).join(' ') !== '--project cit-app-2de1c --run') {
  throw new Error('Requires --project cit-app-2de1c --run. Creates and removes temporary Auth test accounts.');
}
const config = require('../android/app/google-services.json');
assert.equal(config.project_info.project_id, projectId);
const key = config.client.find(c => c.client_info.android_client_info.package_name === 'jp.ac.chibakoudai.citapp').api_key[0].current_key;
const suffix = randomUUID();
const addresses = [`citapp-test-${suffix}@chibatech.ac.jp`, `citapp-test-${suffix}@example.invalid`];
let app;
async function api(operation, data) {
  const response = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:${operation}?key=${key}`, {
    method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(data),
  });
  const body = await response.json();
  if (!response.ok) {
    // Only expose the API error message, never the response credentials.
    const error = new Error(`${operation}: ${body.error?.message || 'UNKNOWN'}`);
    error.status = response.status;
    throw error;
  }
  return body;
}
async function main() {
  const account = cliAuth.getGlobalDefaultAccount();
  if (!account?.tokens?.refresh_token) throw new Error('Firebase CLI login required.');
  const token = await cliAuth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  app = initializeApp({projectId, credential: {getAccessToken: async () => ({access_token: token.access_token, expires_in: 3600})}});
  const auth = getAuth(app);
  async function absent(email) {
    try { await auth.getUserByEmail(email); return false; }
    catch (e) { if (e.code === 'auth/user-not-found') return true; throw e; }
  }
  async function proof(email) {
    const link = await auth.generateSignInWithEmailLink(email, {
      url: `https://${projectId}.firebaseapp.com/signup/complete`, handleCodeInApp: true,
      android: {packageName: 'jp.ac.chibakoudai.citapp', installApp: false},
      iOS: {bundleId: 'com.masatomurai.citapp'},
    });
    let url = new URL(link);
    for (let i = 0; i < 5 && url.searchParams.has('link'); i++) url = new URL(url.searchParams.get('link'));
    const code = url.searchParams.get('oobCode');
    assert.ok(code, 'Expected email proof code');
    return code;
  }
  // Do not enter cleanup if either address unexpectedly existed beforehand.
  for (const email of addresses) assert.ok(await absent(email));
  try {
    const password = randomBytes(24).toString('hex');
    await assert.rejects(api('signUp', {email: addresses[0], password, returnSecureToken: true}), /BLOCKING_FUNCTION_ERROR/);
    assert.ok(await absent(addresses[0]));
    console.log('PASS: unverified password signup rejected before account creation');
    const oobCode = await proof(addresses[0]);
    assert.ok(await absent(addresses[0]));
    console.log('PASS: generating email proof does not create an account');
    const signed = await api('signInWithEmailLink', {email: addresses[0], oobCode});
    const user = await auth.getUser(signed.localId);
    assert.equal(user.emailVerified, true);
    assert.equal(user.email, addresses[0]);
    console.log('PASS: verified email-link signup creates a verified account');
    await api('update', {idToken: signed.idToken, password, returnSecureToken: true});
    const login = await api('signInWithPassword', {email: addresses[0], password, returnSecureToken: true});
    assert.equal(login.localId, signed.localId);
    console.log('PASS: password setup and subsequent password login');
    await assert.rejects(api('signInWithEmailLink', {email: addresses[0], oobCode}), /INVALID_OOB_CODE|EXPIRED_OOB_CODE/);
    console.log('PASS: consumed email proof cannot be reused');
    const externalCode = await proof(addresses[1]);
    await assert.rejects(api('signInWithEmailLink', {email: addresses[1], oobCode: externalCode}), /BLOCKING_FUNCTION_ERROR/);
    assert.ok(await absent(addresses[1]));
    console.log('PASS: verified external-domain signup rejected');
  } finally {
    // Only look up the exact random addresses owned by this test invocation.
    for (const email of addresses) {
      try { const user = await auth.getUserByEmail(email); await auth.deleteUser(user.uid); }
      catch (e) { if (e.code !== 'auth/user-not-found') throw e; }
      assert.ok(await absent(email));
    }
    console.log('PASS: temporary Auth accounts removed');
  }
}
main().catch(e => {console.error(e.message); process.exitCode = 1;})
  .finally(async () => {if (app) await deleteApp(app);});
