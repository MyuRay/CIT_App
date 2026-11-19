'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {publicProfile, createPublicProfileSync} = require('../public_profiles');
test('public profile copies only explicitly public account fields', () => {
  assert.deepEqual(publicProfile('alice', {uid: 'forged', email: 'private@example.com',
    studentId: 'private', legalConsentVersion: 'private', displayName: 'Alice',
    privateFutureField: 'secret', cwitterTags: ['campus']}),
  {uid: 'alice', displayName: 'Alice', cwitterTags: ['campus']});
});
for (const state of ['active', 'missing', 'deleting']) {
  test(`sync handles ${state} current account without reviving deleted users`, async () => {
    const writes = [];
    const db = {collection: c => ({doc: id => `${c}/${id}`}), runTransaction: fn => fn({
      get: async ref => ({exists: ref.startsWith('users/') ? state !== 'missing' : state === 'deleting',
        data: () => ({displayName: 'Current', email: 'secret@example.com'})}),
      set: (ref, data) => writes.push({ref, data}), delete: ref => writes.push({ref}),
    })};
    await createPublicProfileSync({db})('alice');
    assert.deepEqual(writes, state === 'active'
      ? [{ref: 'public_profiles/alice', data: {uid: 'alice', displayName: 'Current'}}]
      : [{ref: 'public_profiles/alice'}]);
  });
}
