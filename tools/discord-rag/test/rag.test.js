'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {loadSources, chunkSource, buildIndex, checkIndex, retrieve, hasSecret, normalize, DIMENSIONS} = require('../src/knowledge');
const {verifyRequest, validateInteraction, formatAnswer, UNKNOWN, editOriginal} = require('../src/discord');
const {createInteractionHandler, createWorker} = require('../src/service');
const {createGemini} = require('../src/gemini');
const {createJobStore} = require('../src/jobs');
const root = path.resolve(__dirname, '../../..');
const sources = loadSources(root, require('../sources.json'));
const index = buildIndex(sources);
const config = {applicationId: '100000000000000001', guildId: '100000000000000002', channelIds: ['100000000000000003'], roleIds: ['100000000000000004'], enabled: true};
const interaction = () => ({type: 2, id: '100000000000000005', application_id: config.applicationId,
  guild_id: config.guildId, channel_id: config.channelIds[0], token: 'test-interaction-token',
  member: {user: {id: '100000000000000006'}, roles: config.roleIds},
  data: {name: 'ask', options: [{name: 'question', type: 3, value: 'AndroidのAnalyticsに反映されない'}]}});
const job = () => ({id: '100000000000000005', applicationId: config.applicationId, guildId: config.guildId, userId: '100000000000000006', question: 'Android Analytics', token: 'test', createdAt: Date.now()});

test('curated Japanese questions retrieve the corresponding runbook', () => {
  for (const [question, expected] of [
    ['Androidの利用がAnalyticsに反映されない', 'Androidの利用がAnalyticsに出ない'],
    ['新しいメンバーが開発環境を用意するには', '開発環境を用意する'],
    ['学年暦のbottom overflowを直す場所', '学年暦のbottom overflow'],
    ['FirebaseルールとFunctionsとアプリの反映順序', '2026-09-12の認証・通知修正の反映順序'],
    ['OneDrive内でビルドが止まる', 'OneDrive内でビルドが止まる'],
  ]) assert.ok(retrieve(index, question, null, 4).some(chunk => chunk.section === expected), question);
});

test('unrelated questions do not fabricate a match', () => {
  assert.deepEqual(retrieve(index, 'quantum banana submarine xyzzy'), []);
});

test('source changes, removal and missing embeddings block deployment', () => {
  assert.equal(checkIndex(index, sources), true);
  assert.throws(() => checkIndex(index, sources, true), /Embeddings/);
  assert.throws(() => checkIndex(index, sources.slice(1)), /stale/);
  assert.throws(() => checkIndex(index, sources.map((s, i) => i ? s : {...s, text: `${s.text}\n変更`, hash: 'changed'})), /stale/);
});

test('credentials and paths outside the approved documents are rejected', () => {
  assert.throws(() => loadSources(root, {files: ['../private.md']}), /approved/);
  assert.throws(() => loadSources(root, {files: ['functions/.env']}), /approved/);
  for (const secret of ['-----BEGIN PRIVATE KEY-----', `sk-${'a'.repeat(30)}`, `https://discord.com/api/webhooks/123/${'a'.repeat(30)}`]) assert.equal(hasSecret(secret), true);
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'cit-rag-test-'));
  try {
    fs.mkdirSync(path.join(temp, 'docs/handoff'), {recursive: true});
    fs.writeFileSync(path.join(temp, 'docs/handoff/key.md'), `確認日: 2026-09-12\n状態: 試験\n${'sk-'}${'a'.repeat(30)}`);
    assert.throws(() => loadSources(temp, {files: ['docs/handoff/key.md']}), /Secret-like/);
  } finally {
    const resolved = fs.realpathSync(temp);
    assert.equal(path.dirname(resolved), fs.realpathSync(os.tmpdir()));
    assert.ok(path.basename(resolved).startsWith('cit-rag-test-'));
    fs.rmSync(resolved, {recursive: true});
  }
});

test('chunks retain their source and review metadata', () => {
  for (const source of sources) for (const chunk of chunkSource(source)) {
    assert.ok(chunk.startLine >= 1 && chunk.endLine >= chunk.startLine);
    assert.ok(chunk.text.includes(source.reviewedAt));
    assert.ok(chunk.text.includes('状態:'));
    assert.equal(chunk.file, source.file);
  }
});

test('embedding normalization and dimension checks reject corrupt vectors', () => {
  assert.deepEqual(normalize([3, 4]), [0.6, 0.8]);
  assert.throws(() => normalize([0, 0]));
  assert.throws(() => normalize([NaN]));
  assert.throws(() => retrieve(index, 'hello', [1, 0]), /mismatch/);
});

function signedRequest(body, age = 0) {
  const {publicKey, privateKey} = crypto.generateKeyPairSync('ed25519');
  const rawBody = Buffer.from(JSON.stringify(body));
  const timestamp = String(Math.floor(Date.now() / 1000) - age);
  const signature = crypto.sign(null, Buffer.concat([Buffer.from(timestamp), rawBody]), privateKey).toString('hex');
  const rawKey = publicKey.export({type: 'spki', format: 'der'}).subarray(-32).toString('hex');
  return {publicKey: rawKey, req: {method: 'POST', rawBody, get: name => name === 'X-Signature-Ed25519' ? signature : timestamp}, signature, timestamp};
}
function response() {
  return {statusCode: 200, payload: null, status(code) {this.statusCode = code; return this;}, send(body) {this.payload = body; return this;}, json(body) {this.payload = body; return this;}};
}

test('signed Discord requests reject tampering, stale timestamps and wrong keys', () => {
  const signed = signedRequest(interaction());
  assert.equal(verifyRequest(signed.req.rawBody, signed.signature, signed.timestamp, signed.publicKey), true);
  assert.equal(verifyRequest(Buffer.from('{}'), signed.signature, signed.timestamp, signed.publicKey), false);
  assert.equal(verifyRequest(signed.req.rawBody, signed.signature, signed.timestamp, 'a'.repeat(64)), false);
  const old = signedRequest(interaction(), 301);
  assert.equal(verifyRequest(old.req.rawBody, old.signature, old.timestamp, old.publicKey), false);
});

test('only the selected guild, channel and team role may ask', () => {
  assert.ok(validateInteraction(interaction(), config).question);
  for (const changed of [{guild_id: 'different'}, {application_id: 'different'}, {channel_id: 'different'}, {member: {roles: []}}]) {
    assert.ok(validateInteraction({...interaction(), ...changed}, config).error);
  }
  assert.ok(validateInteraction(interaction(), {...config, roleIds: []}).error);
  assert.ok(validateInteraction(interaction(), {...config, channelIds: []}).error);
});

test('PING works without an AI call; invalid requests never enqueue', async () => {
  let queued = 0;
  const signed = signedRequest({type: 1});
  const handler = createInteractionHandler({config: {...config, publicKey: signed.publicKey}, enqueue: async () => queued++});
  const res = response();
  await handler(signed.req, res);
  assert.deepEqual(res.payload, {type: 1});
  await handler({...signed.req, rawBody: Buffer.from('{}')}, response());
  assert.equal(queued, 0);
});

test('authorized commands enqueue durably before returning an ephemeral defer', async () => {
  const signed = signedRequest(interaction());
  const res = response();
  let queued;
  await createInteractionHandler({config: {...config, publicKey: signed.publicKey}, enqueue: async value => {queued = value; assert.equal(res.payload, null);}})(signed.req, res);
  assert.equal(queued.question, interaction().data.options[0].value);
  assert.deepEqual(res.payload, {type: 5, data: {flags: 64}});
});

test('a failed queue or disabled bot gives a clear private response', async () => {
  for (const enabled of [true, false]) {
    const signed = signedRequest(interaction());
    const res = response();
    await createInteractionHandler({config: {...config, enabled, publicKey: signed.publicKey}, enqueue: async () => {throw Error('private upstream failure');}})(signed.req, res);
    assert.equal(res.payload.type, 4);
    assert.equal(res.payload.data.flags, 64);
    assert.ok(!JSON.stringify(res.payload).includes('private upstream'));
  }
});

test('unknown or invented citations cause abstention; actual sources are attached', () => {
  const chunks = retrieve(index, 'Android Analytics');
  assert.equal(formatAnswer({status: 'answered', answer: '本番公開済み', citations: ['invented']}, chunks, index), UNKNOWN);
  assert.equal(formatAnswer({status: 'unknown', answer: 'guess', citations: []}, chunks, index), UNKNOWN);
  const answer = formatAnswer({status: 'answered', answer: '@everyone https://untrusted.example/', citations: [chunks[0].id]}, chunks, index);
  assert.ok(answer.includes(chunks[0].file));
  assert.ok(!answer.includes('@everyone'));
  assert.ok(!answer.includes('https://untrusted.example'));
  assert.ok(answer.length <= 2000);
});

test('Gemini uses separate retrieval tasks and does not expose upstream error bodies', async () => {
  const calls = [];
  const ai = createGemini({apiKey: 'fake-key', fetchImpl: async (url, options) => {
    calls.push({url, body: JSON.parse(options.body)});
    return {ok: true, json: async () => ({embedding: {values: Array(DIMENSIONS).fill(1)}})};
  }});
  await ai.embed('document', true);
  await ai.embed('question');
  assert.equal(calls[0].body.taskType, 'RETRIEVAL_DOCUMENT');
  assert.equal(calls[1].body.taskType, 'RETRIEVAL_QUERY');
  const failing = createGemini({apiKey: 'fake-key', fetchImpl: async () => ({ok: false, status: 429, text: async () => 'private-token'})});
  await assert.rejects(() => failing.embed('x'), /^Error: AI request failed \(429\)$/);
});

test('Discord replies cannot trigger mentions or leak upstream response bodies', async () => {
  await editOriginal({applicationId: config.applicationId, token: 'fake-token', content: 'hello', fetchImpl: async (url, options) => {
    assert.ok(url.endsWith('/messages/@original'));
    assert.deepEqual(JSON.parse(options.body).allowed_mentions, {parse: []});
    return {ok: true};
  }});
});

function memoryDb() {
  const data = new Map();
  let serial = Promise.resolve();
  const ref = key => ({key, set: async (values, options) => data.set(key, options?.merge ? {...data.get(key), ...values} : values)});
  return {data, collection: name => ({doc: id => ref(`${name}/${id}`)}),
    runTransaction: fn => {
      const result = serial.then(() => fn({get: async reference => ({data: () => data.get(reference.key)}), set: (reference, values, options) => reference.set(values, options)}));
      serial = result.catch(() => {});
      return result;
    }};
}

test('job reservations prevent duplicate AI work and enforce daily quotas', async () => {
  const db = memoryDb();
  const jobs = createJobStore(db, {userDailyLimit: 1, guildDailyLimit: 2});
  const current = job();
  const results = await Promise.all([jobs.claim(current), jobs.claim(current)]);
  assert.deepEqual(results.map(result => result.status), ['claimed', 'busy']);
  await jobs.complete(current, 'cached answer');
  assert.deepEqual(await jobs.claim(current), {status: 'cached', content: 'cached answer'});
  assert.equal((await jobs.claim({...current, id: '100000000000000007'})).status, 'limited');
});

test('expired or unauthorized queued jobs never call AI or Discord', async () => {
  const worker = createWorker({config, index, ai: {embed: () => assert.fail('AI called')}, jobs: {claim: () => assert.fail('claim called')}, reply: () => assert.fail('reply called')});
  await worker({...job(), createdAt: Date.now() - 11 * 60000});
  await worker({...job(), guildId: 'other'});
});

test('cached responses retry delivery without regenerating', async () => {
  let answer;
  const worker = createWorker({config, index, ai: {embed: () => assert.fail('AI called')},
    jobs: {claim: async () => ({status: 'cached', content: 'previous answer'})}, reply: async (_, value) => {answer = value;}});
  await worker(job());
  assert.equal(answer, 'previous answer');
});

test('generation follows retrieved evidence and caches before sending', async () => {
  const vector = normalize(Array(DIMENSIONS).fill(1));
  const embedded = {...index, chunks: index.chunks.map(chunk => ({...chunk, vector}))};
  const order = [];
  const worker = createWorker({config, index: embedded, ai: {
    embed: async () => vector,
    generate: async (_, chunks) => ({status: 'answered', answer: '現行Androidの登録を確認してください。', citations: [chunks[0].id]}),
  }, jobs: {claim: async () => ({status: 'claimed'}), complete: async () => order.push('cached'), release: async () => {}},
  reply: async (_, content) => {order.push('sent'); assert.ok(content.includes('出典'));}});
  await worker(job());
  assert.deepEqual(order, ['cached', 'sent']);
});

test('AI failures release reservations and return a non-sensitive failure message', async () => {
  let released = false;
  let content;
  const worker = createWorker({config, index, ai: {embed: async () => {throw Error('private-upstream-token');}},
    jobs: {claim: async () => ({status: 'claimed'}), release: async () => {released = true;}},
    reply: async (_, value) => {content = value;}});
  await assert.rejects(() => worker(job()), /RAG job failed/);
  assert.equal(released, true);
  assert.ok(content.includes('失敗'));
  assert.ok(!content.includes('private-upstream-token'));
});

test('a delivery failure reuses the persisted answer on the next queue attempt', async () => {
  const vector = normalize(Array(DIMENSIONS).fill(1));
  const embedded = {...index, chunks: index.chunks.map(chunk => ({...chunk, vector}))};
  let generations = 0;
  let firstReply = true;
  const worker = createWorker({config, index: embedded,
    ai: {embed: async () => vector, generate: async (_, chunks) => {
      generations++;
      return {status: 'answered', answer: '確認してください。', citations: [chunks[0].id]};
    }}, jobs: createJobStore(memoryDb()), reply: async () => {
      if (firstReply) {firstReply = false; throw Error('Temporary Discord failure');}
    }});
  const current = job();
  await assert.rejects(() => worker(current), /RAG job failed/);
  await worker(current);
  assert.equal(generations, 1);
});
