'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {requireVerifiedRegistration} = require('../verified_registration');
const cases = require('../../test/fixtures/registration_email_policy.json');

function denied(event) {
  assert.throws(() => requireVerifiedRegistration(event), error =>
    error.code === 'permission-denied');
}

for (const {email, allowed} of cases) {
  test(`server registration policy: ${JSON.stringify(email)}`, () => {
    const event = {data: {email, emailVerified: true}};
    if (allowed) {
      assert.doesNotThrow(() => requireVerifiedRegistration(event));
    } else {
      denied(event);
    }
  });
}

test('an unverified or missing identity cannot register', () => {
  for (const emailVerified of [false, undefined, 'true', 1]) {
    denied({data: {email: 'student@chibatech.ac.jp', emailVerified}});
  }
  denied({});
  denied({data: {emailVerified: true}});
  denied({data: {email: 123, emailVerified: true}});
});

test('raw Auth addresses with whitespace are rejected, not silently changed', () => {
  for (const email of [
    'student@chibatech.ac.jp\n',
    'student@chibatech.ac.jp ',
    ' student@chibatech.ac.jp',
  ]) {
    denied({data: {email, emailVerified: true}});
  }
});

test('requesting a sponsor or admin role cannot bypass student registration', () => {
  for (const customClaims of [{role: 'sponsor'}, {admin: true}]) {
    denied({data: {email: 'sponsor@company.example', emailVerified: true, customClaims}});
  }
});
