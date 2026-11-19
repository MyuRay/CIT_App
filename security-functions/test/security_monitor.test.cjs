'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {detectDocumentChange, discordPayload, createAlertStore, createDelivery, createGoogleReader,
  metricCount, logCount, pollSignals, COOLDOWN_MS} = require('../security_monitor');

const post = () => ({authorId: 'owner', authorEmail: 'owner@example.invalid', cwitterId: 'owner',
  body: 'private post text', createdAt: 123, likedBy: [], likeCount: 0, replyCount: 0});
function findings(after, before = post(), collection = 'cwitter_posts') {
  return detectDocumentChange({collection, before, after});
}
test('legitimate edits, likes, reply counters and empty image-post text are quiet', () => {
  for (const patch of [{body: 'edited'}, {likeCount: 1, likedBy: ['reader']}, {replyCount: 1}, {body: '', imageUrls: ['url']}]) {
    assert.deepEqual(findings({...post(), ...patch}), []);
  }
});
test('counter plus deletion bypass is detected', () => {
  const after = {...post(), replyCount: 1}; delete after.body;
  assert.deepEqual(findings(after), ['required_field_removed']);
});
test('identity replacement, removal and introduction are detected', () => {
  for (const field of ['authorId', 'authorEmail', 'cwitterId']) {
    assert.deepEqual(findings({...post(), [field]: 'forged'}), ['identity_changed']);
    const after = {...post()}; delete after[field];
    assert.deepEqual(findings(after), ['identity_changed']);
    assert.deepEqual(findings(post(), after), ['identity_changed']);
  }
});
test('malformed text and rewritten creation time are detected', () => {
  for (const patch of [{body: null}, {body: {}}, {createdAt: 456}]) {
    assert.deepEqual(findings({...post(), ...patch}), ['required_field_removed']);
  }
});
test('thread title removal is detected while normal comment soft delete is quiet', () => {
  assert.deepEqual(findings({createdAt: 123}, {title: 'title', createdAt: 123}, 'chiba_channel_threads'), ['required_field_removed']);
  assert.deepEqual(findings({...post(), body: '', isDeleted: true}, post(), 'comments'), []);
});
test('whole-document deletion and creation do not masquerade as tampering', () => {
  assert.deepEqual(findings(undefined), []);
  assert.deepEqual(detectDocumentChange({collection: 'cwitter_posts', before: undefined, after: post()}), []);
});
test('admin permission creation, update, deletion are all audited', () => {
  for (const [before, after] of [[undefined, {isAdmin: true}], [{isAdmin: false}, {isAdmin: true}], [{isAdmin: true}, undefined]]) {
    assert.deepEqual(detectDocumentChange({collection: 'admin_permissions', before, after}), ['admin_permission_changed']);
  }
  assert.deepEqual(detectDocumentChange({collection: 'admin_permissions', before: {isAdmin: true}, after: {isAdmin: true}}), []);
});

function memoryDb() {
  const docs = new Map();
  const ref = path => ({path, async update(patch) {if (!docs.has(path)) throw Error('not found'); docs.set(path, {...docs.get(path), ...patch});}});
  return {docs, collection: name => ({doc: id => ref(`${name}/${id}`)}),
    async runTransaction(fn) {
      const writes = [];
      const result = await fn({get: async r => ({exists: docs.has(r.path), data: () => structuredClone(docs.get(r.path))}),
        create: (r, data) => writes.push(() => {if (docs.has(r.path)) throw Error('exists'); docs.set(r.path, structuredClone(data));}),
        set: (r, data) => writes.push(() => docs.set(r.path, structuredClone(data))),
        update: (r, data) => writes.push(() => docs.set(r.path, {...docs.get(r.path), ...structuredClone(data)})),
      });
      writes.forEach(w => w()); return result;
    }};
}
test('event redelivery is idempotent and same-kind notifications are throttled', async () => {
  const db = memoryDb(); let time = 1000000;
  const enqueue = createAlertStore({db, now: () => time});
  const input = {kind: 'identity_changed', source: 'cwitter_posts', eventId: 'event1'};
  const first = await enqueue(input);
  assert.equal(first.created, true);
  assert.equal((await enqueue(input)).created, false);
  assert.equal((await enqueue({...input, eventId: 'event2'})).created, false);
  time += COOLDOWN_MS;
  assert.equal((await enqueue({...input, eventId: 'event3'})).created, true);
});
test('alert storage and Discord payload exclude user text, raw identity and webhook', async () => {
  const db = memoryDb();
  const {id} = await createAlertStore({db, now: () => 1000})({kind: 'identity_changed', source: 'cwitter_posts',
    eventId: 'event', path: 'users/private-uid', actor: 'private-uid', email: 'sensitive@example.invalid',
    body: 'private post text', webhook: 'secret-webhook-token'});
  const alert = db.docs.get('security_alerts/' + id);
  const payload = discordPayload(alert, id);
  const serialized = JSON.stringify([alert, payload]);
  for (const secret of ['private-uid', 'sensitive@example.invalid', 'private post text', 'secret-webhook-token']) {
    assert.equal(serialized.includes(secret), false);
  }
  assert.deepEqual(payload.allowed_mentions, {parse: []});
});
test('successful Discord delivery requires confirmed message and is not resent', async () => {
  const db = memoryDb(); let sends = 0;
  const {id} = await createAlertStore({db, now: () => 1000})({kind: 'delivery_test', source: 'test', eventId: 'test'});
  const deliver = createDelivery({db, now: () => 1000, webhook: () => 'https://discordapp.com/api/webhooks/123/test-token',
    fetchImpl: async (url, options) => {sends++; assert.equal(url.searchParams.get('wait'), 'true');
      assert.equal(options.method, 'POST'); return {ok: true, json: async () => ({id: 'message1'})};}});
  assert.deepEqual(await deliver(id), {sent: true, messageId: 'message1'});
  assert.deepEqual(await deliver(id), {sent: false}); assert.equal(sends, 1);
});
test('failed delivery is retryable and secret-containing exceptions are sanitized', async () => {
  const db = memoryDb();
  const {id} = await createAlertStore({db, now: () => 1000})({kind: 'delivery_test', source: 'test', eventId: 'test'});
  const deliver = createDelivery({db, now: () => 1000, webhook: () => 'https://discord.com/api/webhooks/123/test-token',
    fetchImpl: async () => {throw Error('leaked-webhook-and-token');}});
  await assert.rejects(deliver(id), e => !e.message.includes('leaked') && e.message.includes('retry'));
  assert.equal(db.docs.get('security_alerts/' + id).status, 'pending');
  assert.equal(db.docs.get('security_alerts/' + id).leaseUntilMs, 0);
});
test('Discord rate limits or missing response confirmation never mark delivery sent', async () => {
  for (const response of [{ok: false, status: 429}, {ok: true, json: async () => ({})}]) {
    const db = memoryDb();
    const {id} = await createAlertStore({db, now: () => 1000})({kind: 'delivery_test', source: 'test', eventId: 'test'});
    const deliver = createDelivery({db, now: () => 1000, webhook: () => 'https://discord.com/api/webhooks/123/test-token', fetchImpl: async () => response});
    await assert.rejects(deliver(id)); assert.equal(db.docs.get('security_alerts/' + id).status, 'pending');
  }
});
test('delivery lease prevents concurrent sends and expired lease can recover', async () => {
  const db = memoryDb(); let time = 1000;
  db.docs.set('security_alerts/test', {kind: 'delivery_test', detectedAtMs: time, status: 'sending', leaseUntilMs: 2000});
  let sends = 0;
  const deliver = createDelivery({db, now: () => time, webhook: () => 'https://discord.com/api/webhooks/123/test-token',
    fetchImpl: async () => {sends++; return {ok: true, json: async () => ({id: 'recovered'})};}});
  await assert.rejects(deliver('test'), /busy/); assert.equal(sends, 0);
  time = 2001; assert.equal((await deliver('test')).sent, true);
});
test('Google reader sanitizes failures instead of exposing tokens or response payload', async () => {
  const read = createGoogleReader({credential: {getAccessToken: async () => ({access_token: 'private-token'})},
    fetchImpl: async () => ({ok: false, status: 403, text: async () => 'private user data'})});
  await assert.rejects(read('https://example.invalid'), /^Error: Security monitor API HTTP 403$/);
});
test('metric totals include every page and use an exact raw-sample interval', async () => {
  let calls = 0;
  const count = await metricCount(async url => {
    const u = new URL(url); assert.equal(u.searchParams.has('aggregation.alignmentPeriod'), false);
    calls++; return calls === 1 ? {timeSeries: [{points: [{value: {int64Value: '31'}}]}], nextPageToken: 'page2'} :
      {timeSeries: [{points: [{value: {int64Value: '20'}}]}]};
  }, 'firestore.googleapis.com/rules/evaluation_count', '', 1000000, 400000);
  assert.equal(count, 51); assert.equal(calls, 2);
});
test('log pagination stops once threshold is established', async () => {
  let calls = 0;
  const count = await logCount(async (_url, body) => {calls++; assert.ok(body.pageSize <= 20);
    return {entries: Array(calls === 1 ? 12 : 8).fill({}), nextPageToken: 'another'};
  }, 'filter', 0, 1000, 20);
  assert.equal(count, 20); assert.equal(calls, 2);
});
test('signal thresholds generate alerts while low-volume traffic stays quiet', async () => {
  const alerts = [];
  const result = await pollSignals({now: () => 2000000, enqueue: async a => alerts.push(a), read: async (url, body) => {
    if (body) return {entries: []};
    const filter = new URL(url).searchParams.get('filter');
    return {timeSeries: [{points: [{value: {int64Value: filter.includes('firestore.googleapis.com/rules') ? '50' : '0'}}]}]};
  }});
  assert.equal(result.failures, 0); assert.equal(result.checks.length, 8);
  assert.deepEqual(alerts.map(a => a.kind), ['firestore_denied']);
});
test('one unavailable signal alerts about monitoring failure without cancelling other checks', async () => {
  const alerts = [];
  const result = await pollSignals({now: () => 2000000, enqueue: async a => alerts.push(a), read: async (url, body) => {
    if (url.includes('monitoring') && decodeURIComponent(url).includes('firebasestorage')) throw Error('private-token');
    return body ? {entries: []} : {timeSeries: []};
  }});
  assert.equal(result.failures, 1);
  assert.deepEqual(alerts.map(a => a.kind), ['monitor_error']);
  assert.equal(JSON.stringify(result).includes('private-token'), false);
});
