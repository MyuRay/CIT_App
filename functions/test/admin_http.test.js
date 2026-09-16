const {test} = require('node:test');
const assert = require('node:assert/strict');
const {createAdminAuthorizer, retiredBulkVerification} = require('../admin_http');

function setup({method = 'POST', header = 'Bearer token', verified = true, isAdmin = true, email = 'admin@s.chibakoudai.jp', invalid = false, lookupError = false} = {}) {
  const calls = [];
  const auth = {async verifyIdToken(token, revoked) {
    calls.push([token, revoked]);
    if (invalid) throw Error('secret invalid token');
    return {uid: 'admin', email_verified: verified, email};
  }};
  const firestore = {collection(name) {
    calls.push(name);
    return {doc: () => ({get: async () => {
      if (lookupError) throw Error('secret database error');
      return {exists: true, data: () => ({isAdmin})};
    }})};
  }};
  const req = {method, get: () => header};
  const res = {code: null, body: null, set() {return this;}, status(code) {this.code = code; return this;}, json(body) {this.body = body;}, send(body) {this.body = body;}};
  return {req, res, calls, authorize: createAdminAuthorizer({auth, firestore})};
}
for (const [name, options, code] of [
  ['missing bearer', {header: ''}, 401], ['invalid token', {invalid: true}, 401],
  ['unverified email', {verified: false}, 403], ['non-admin', {isAdmin: false}, 403],
  ['wrong domain', {email: 'admin@example.org'}, 403], ['suffix attack', {email: 'admin@s.chibakoudai.jp.attacker.org'}, 403],
  ['GET mutation', {method: 'GET'}, 405], ['database failure', {lookupError: true}, 503],
]) {
  test(`admin endpoint denies ${name}`, async () => {
    const t = setup(options);
    assert.equal(await t.authorize(t.req, t.res), false);
    assert.equal(t.res.code, code);
    assert.equal(JSON.stringify(t.res.body).includes('secret'), false);
  });
}
test('preflight performs no authentication or database reads', async () => {
  const t = setup({method: 'OPTIONS'});
  assert.equal(await t.authorize(t.req, t.res), false);
  assert.equal(t.res.code, 204);
  assert.deepEqual(t.calls, []);
});
test('verified admin is accepted with revocation checking', async () => {
  const t = setup();
  assert.equal(await t.authorize(t.req, t.res), true);
  assert.deepEqual(t.calls, [['token', true], 'admin_permissions']);
});
test('statistics can explicitly allow authenticated GET', async () => {
  const t = setup({method: 'GET'});
  assert.equal(await t.authorize(t.req, t.res, 'GET'), true);
});
test('retired verification URL cannot perform writes for any method', () => {
  for (const method of ['GET', 'POST', 'PUT', 'OPTIONS']) {
    const t = setup({method});
    retiredBulkVerification(t.req, t.res);
    assert.equal(t.res.code, 410);
    assert.deepEqual(t.calls, []);
  }
});
