const {test, before, after, beforeEach} = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');

// Only the local Auth emulator uses unsigned test tokens. These flags must
// never be used in a deployed function or against a real Firebase project.
assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST, '127.0.0.1:9098');
process.env.GCLOUD_PROJECT = 'demo-cit-registration';
process.env.FIREBASE_DEBUG_MODE = 'true';
process.env.FIREBASE_DEBUG_FEATURES = JSON.stringify({skipTokenVerification:true});
const {createRequire} = require('node:module');
const functionsRequire = createRequire(require.resolve('../../functions/package.json'));
const admin = functionsRequire('firebase-admin');
const {beforeUserCreated} = functionsRequire('firebase-functions/v2/identity');
const {requireVerifiedRegistration} = require('../../functions/verified_registration');
const express = require('express');
const project = 'demo-cit-registration';
const base = 'http://127.0.0.1:9098';
let server, app, auth;
const email = 'student@chibatech.ac.jp';

async function request(path, data, method = 'POST') {
  const response = await fetch(base + path, {method,
    headers:{'Content-Type':'application/json',
      ...(path.includes('/v1/accounts:') ? {} : {Authorization:'Bearer owner'})},
    body: data === undefined ? undefined : JSON.stringify(data)});
  const body = await response.json();
  if (!response.ok) throw Object.assign(new Error(body.error?.message || 'Emulator request failed'), {status:response.status});
  return body;
}
const api = (operation, data) => request('/identitytoolkit.googleapis.com/v1/accounts:' + operation + '?key=test-key', data);
async function send(address = email) {
  await api('sendOobCode', {requestType:'EMAIL_SIGNIN',email:address,
    continueUrl:'https://cit-app-2de1c.firebaseapp.com/signup/complete',canHandleCodeInApp:true});
  const result = await request('/emulator/v1/projects/' + project + '/oobCodes', undefined, 'GET');
  return result.oobCodes.filter(item => item.email === address).at(-1).oobCode;
}
before(async () => {
  app = admin.initializeApp({projectId:project});
  auth = app.auth();
  const endpoint = express();
  endpoint.use(express.json());
  endpoint.post('/before-create', beforeUserCreated(requireVerifiedRegistration));
  server = http.createServer(endpoint);
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const functionUri = 'http://127.0.0.1:' + server.address().port + '/before-create';
  await request('/identitytoolkit.googleapis.com/v2/projects/' + project + '/config', {
    signIn:{email:{enabled:true,passwordRequired:false}},
    blockingFunctions:{triggers:{beforeCreate:{functionUri}}},
  }, 'PATCH');
});
beforeEach(async () => {
  await request('/emulator/v1/projects/' + project + '/accounts', undefined, 'DELETE');
});
after(async () => {
  await app?.delete();
  if (server) await new Promise(resolve => server.close(resolve));
});

test('sending an email leaves Auth empty; only valid link proof creates a verified account', async () => {
  const oobCode = await send();
  assert.equal((await auth.listUsers()).users.length, 0);
  await assert.rejects(api('signInWithEmailLink', {email:'wrong@chibatech.ac.jp',oobCode}));
  assert.equal((await auth.listUsers()).users.length, 0);
  const result = await api('signInWithEmailLink', {email,oobCode});
  assert.equal((await auth.getUser(result.localId)).emailVerified, true);
  assert.equal((await auth.listUsers()).users.length, 1);
  await assert.rejects(api('signInWithEmailLink', {email,oobCode}));
  assert.equal((await auth.listUsers()).users.length, 1);
});
test('old client password signup is blocked before any Auth account is stored', async () => {
  await assert.rejects(api('signUp', {email,password:'Password123',returnSecureToken:true}));
  assert.equal((await auth.listUsers()).users.length, 0);
});
test('verified external email links cannot create a new non-CIT account', async () => {
  const other = 'someone@example.com';
  const oobCode = await send(other);
  await assert.rejects(api('signInWithEmailLink', {email:other,oobCode}));
  assert.equal((await auth.listUsers()).users.length, 0);
});
test('after proof a password can be set and ordinary password login remains verified', async () => {
  const oobCode = await send();
  const result = await api('signInWithEmailLink', {email,oobCode});
  await api('update', {idToken:result.idToken,password:'Password123',returnSecureToken:true});
  const login = await api('signInWithPassword', {email,password:'Password123',returnSecureToken:true});
  assert.equal(login.localId, result.localId);
  assert.equal((await auth.getUser(login.localId)).emailVerified, true);
});
test('an existing unverified account is recovered without changing its UID', async () => {
  const old = await auth.createUser({email,password:'OldPass123',emailVerified:false,displayName:'既存名'});
  const oobCode = await send();
  const result = await api('signInWithEmailLink', {email,oobCode});
  await api('update', {idToken:result.idToken,password:'NewPass123',returnSecureToken:true});
  const login = await api('signInWithPassword', {email,password:'NewPass123',returnSecureToken:true});
  assert.equal(login.localId, old.uid);
  const recovered = await auth.getUser(old.uid);
  assert.equal(recovered.emailVerified, true);
  assert.equal(recovered.displayName, '既存名');
  assert.equal((await auth.listUsers()).users.length, 1);
});
