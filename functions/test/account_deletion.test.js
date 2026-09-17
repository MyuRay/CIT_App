const {test} = require('node:test');
const assert = require('node:assert/strict');
const {createDeletionApi, belongsTo, storagePaths} = require('../account_deletion');
function fixture({token = {uid: 'owner', auth_time: 1000}, method = 'POST', body = {confirm: true}, bearer = true} = {}) {
  const jobs = new Map();
  const db = {collection: () => ({doc: id => ({id})}), async runTransaction(fn) {
    await fn({get: async r => ({exists: jobs.has(r.id)}), create: (r, d) => jobs.set(r.id, d)});
  }};
  const auth = {async verifyIdToken(_, checkRevoked) {assert.equal(checkRevoked, true); if (!token) throw Error(); return token;}};
  const req = {method, body, get: () => bearer ? 'Bearer test' : ''};
  const res = {set() {}, status(n) {this.code = n; return this;}, json(d) {this.data = d; return this;}};
  return {jobs, req, res, run: () => createDeletionApi({auth, db, now: () => 1100000})(req, res)};
}
for (const [name, input, code] of [
  ['anonymous', {bearer: false}, 401], ['invalid token', {token: null}, 401],
  ['stale login', {token: {uid: 'owner', auth_time: 1}}, 401],
  ['missing consent', {body: {}}, 400], ['other UID', {body: {confirm: true, uid: 'victim'}}, 400],
  ['GET', {method: 'GET'}, 405],
]) test('rejects ' + name, async () => {const f = fixture(input); await f.run(); assert.equal(f.res.code, code); assert.equal(f.jobs.size, 0);});
test('recently authenticated owner queues exactly one durable job', async () => {
  const f = fixture(); await f.run(); await f.run();
  assert.equal(f.res.code, 202); assert.deepEqual([...f.jobs.keys()], ['owner']);
});
test('ownership matching never uses a partial UID', () => {
  assert.equal(belongsTo('users/owner/assignments/a', {}, 'owner'), true);
  assert.equal(belongsTo('users/owner2/assignments/a', {}, 'owner'), false);
  assert.equal(belongsTo('users/other/cwitter_followers/owner', {}, 'owner'), true);
  assert.equal(belongsTo('cwitter_posts/a', {authorId: 'owner2'}, 'owner'), false);
});
test('only this bucket and user-upload paths can enter file cleanup', () => {
  const prefix = 'https://firebasestorage.googleapis.com/v0/b/test-bucket/o/';
  assert.deepEqual(storagePaths({urls: [prefix + 'bulletin_images%2Fa.jpg?token=x',
    prefix + 'menu_images%2Fshared.png', 'https://evil.example/a.jpg',
    'https://storage.googleapis.com/test-bucket/profile_images/u/a.jpg']}, 'test-bucket'),
  ['bulletin_images/a.jpg', 'profile_images/u/a.jpg']);
});
