'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {fragment, mergeRules, specs} = require('../../../scripts/deploy_contact_chat.cjs');
for (const spec of specs) {
  const local = fs.readFileSync(path.join(__dirname, '../../..', spec.file), 'utf8');
  test(spec.file + ': adding inquiry rules preserves unrelated deployed bytes', () => {
    const live = 'rules_version = "2";\nfunction isCITUser() {}\n  // existing rule\n  ' + spec.anchor + '{x} {}\n// untouched ending\n';
    const merged = mergeRules(live, local, spec);
    const block = fragment(local, spec) + '\n';
    assert.equal(merged.replace(block, ''), live);
    assert.equal(mergeRules(merged, local, spec), merged);
  });
  test(spec.file + ': mismatched or duplicate destinations are rejected', () => {
    assert.throws(() => mergeRules('function isCITUser() {}', local, spec));
    assert.throws(() => mergeRules('function isCITUser() {}\n' + spec.collection, local, spec));
    assert.throws(() => mergeRules('function isCITUser() {}\n' + spec.begin + '\n' + spec.anchor, local, spec));
  });
  test(spec.file + ': already deployed inquiry blocks can be replaced without changing adjacent rules', () => {
    const live = 'PREFIX\n' + fragment(local, spec) + 'SUFFIX';
    const replacement = local.replace('allow delete: if false;', 'allow delete: if false; // revision');
    const merged = mergeRules(live, replacement, spec);
    assert.equal(merged, 'PREFIX\n' + fragment(replacement, spec) + 'SUFFIX');
  });
}