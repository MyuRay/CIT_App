const {test} = require('node:test');
const assert = require('node:assert/strict');
const {getUserTokenEntries, removeInvalidToken} = require('../device_tokens');

function fixture(initial) {
  const records = new Map(Object.entries(initial));
  function reference(path) {
    return {path, get: async () => ({exists: records.has(path), data: () => records.get(path)}),
      collection: name => collection(`${path}/${name}`)};
  }
  function collection(path) {
    return {doc: id => reference(`${path}/${id}`), get: async () => ({docs: [...records]
      .filter(([key]) => key.startsWith(`${path}/`) && !key.slice(path.length + 1).includes('/'))
      .map(([key, value]) => ({ref: reference(key), data: () => value}))})};
  }
  const db = {collection, async runTransaction(fn) {
    await fn({get: ref => ref.get(), delete: ref => records.delete(ref.path),
      update(ref, fields) {const value = {...records.get(ref.path), ...fields};
        for (const [key, field] of Object.entries(value)) if (field === 'DELETE') delete value[key];
        records.set(ref.path, value);
      }});
  }};
  return {db, records};
}
test('all devices and legacy tokens are included without duplicate sends', async () => {
  const {db} = fixture({'user_tokens/A': {fcmToken: 'one'},
    'user_tokens/A/devices/phone': {fcmToken: 'one'}, 'user_tokens/A/devices/tablet': {fcmToken: 'two'}});
  const entries = await getUserTokenEntries(db, 'A');
  assert.deepEqual(entries.map(x => x.token).sort(), ['one', 'two']);
});
test('invalid device cleanup preserves sibling devices', async () => {
  const {db, records} = fixture({'user_tokens/A': {},
    'user_tokens/A/devices/phone': {fcmToken: 'one'}, 'user_tokens/A/devices/tablet': {fcmToken: 'two'}});
  const entries = await getUserTokenEntries(db, 'A');
  await removeInvalidToken(db, entries[0], () => 'DELETE');
  assert.equal(records.has('user_tokens/A/devices/phone'), false);
  assert.equal(records.get('user_tokens/A/devices/tablet').fcmToken, 'two');
});
test('late failed delivery cannot delete a refreshed token', async () => {
  const {db, records} = fixture({'user_tokens/A': {}, 'user_tokens/A/devices/phone': {fcmToken: 'old'}});
  const [entry] = await getUserTokenEntries(db, 'A');
  records.set('user_tokens/A/devices/phone', {fcmToken: 'fresh'});
  await removeInvalidToken(db, entry, () => 'DELETE');
  assert.equal(records.get('user_tokens/A/devices/phone').fcmToken, 'fresh');
});
test('legacy cleanup removes only the expired field, retaining device ownership', async () => {
  const {db, records} = fixture({'user_tokens/A': {fcmToken: 'old', updatedAt: 1}});
  const [entry] = await getUserTokenEntries(db, 'A');
  await removeInvalidToken(db, entry, () => 'DELETE');
  assert.deepEqual(records.get('user_tokens/A'), {updatedAt: 1});
});
