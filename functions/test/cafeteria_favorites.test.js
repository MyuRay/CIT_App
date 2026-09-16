'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {targetKey, countUniqueUsers} = require('../cafeteria_favorites');
const cases = require('../../test/fixtures/cafeteria_favorite_keys.json');

test('favorite keys match the shared Flutter contract', () => {
  for (const {target, key} of cases) assert.equal(targetKey(target), key);
});

test('counts include each owner once and ignore mismatched owners and unrelated paths', () => {
  const target = cases[0].target;
  const doc = (path, uid) => ({ref: {path}, data: () => ({...target, userId: uid})});
  const docs = [
    doc('users/u1/cafeteria_favorites/old', 'u1'),
    doc('users/u1/cafeteria_favorites/new', 'u1'),
    doc('users/u2/cafeteria_favorites/a', 'u2'),
    doc('users/u3/cafeteria_favorites/a', 'u1'),
    doc('archive/u4/cafeteria_favorites/a', 'u4'),
    doc('users/u5/other/b/cafeteria_favorites/a', 'u5'),
  ];
  assert.equal(countUniqueUsers(docs, target), 2);
});
