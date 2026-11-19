'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {createChibaPrivateCleanup} = require('../chiba_private_cleanup');

function fixture(count, {parentExists = false, failAt = 0, recreateAt = 0} = {}) {
  const remaining = new Set(Array.from({length: count}, (_, i) => i));
  let transactions = 0;
  const parent = {collection: name => {
    assert.equal(name, 'anonymous_ids');
    return {limit: size => ({size})};
  }};
  const db = {collection: name => {
    assert.equal(name, 'chiba_channel_threads');
    return {doc: () => parent};
  }, runTransaction: async fn => {
    transactions++;
    if (transactions === failAt) throw Error('temporary failure');
    const deleted = [];
    const value = await fn({get: async ref => ref === parent
      ? {exists: parentExists || transactions === recreateAt}
      : {docs: [...remaining].slice(0, ref.size).map(id => ({ref: id})), size: Math.min(remaining.size, ref.size)},
    delete: ref => deleted.push(ref)});
    for (const ref of deleted) remaining.delete(ref);
    return value;
  }};
  return {remaining, cleanup: createChibaPrivateCleanup({db})};
}
test('private mappings are paged beyond the client batch limit and repeat safely', async () => {
  const f = fixture(607);
  await f.cleanup('thread');
  assert.equal(f.remaining.size, 0);
  await f.cleanup('thread');
});
test('delayed deletion does not remove mappings of an existing thread', async () => {
  const f = fixture(5, {parentExists: true});
  await f.cleanup('thread');
  assert.equal(f.remaining.size, 5);
});
test('cleanup rechecks the parent between pages', async () => {
  const f = fixture(250, {recreateAt: 2});
  await f.cleanup('thread');
  assert.equal(f.remaining.size, 150);
});
test('partial failure surfaces for retry without losing remaining work', async () => {
  const f = fixture(250, {failAt: 2});
  await assert.rejects(f.cleanup('thread'), /temporary failure/);
  assert.equal(f.remaining.size, 150);
  await f.cleanup('thread');
  assert.equal(f.remaining.size, 0);
});
test('malformed thread paths are rejected', async () => {
  await assert.rejects(fixture(0).cleanup('thread/other'), /Invalid thread ID/);
});
