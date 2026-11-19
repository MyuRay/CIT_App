'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {webhookAddress, maskNotificationEmail} = require('../discord_notifications');

test('only Discord webhook destinations can be used by the deletion client', () => {
  assert.equal(webhookAddress('https://discord.com/api/webhooks/123/token').id, '123');
  assert.equal(webhookAddress('https://discord.com/api/v10/webhooks/123/token?thread_id=456').threadId, '456');
  for (const value of ['http://discord.com/api/webhooks/123/token',
    'https://evil.example/api/webhooks/123/token', 'https://discord.com/api/users/me',
    'https://user:password@discord.com/api/webhooks/123/token',
    'https://discord.com/api/webhooks/123/token?thread_id=bad']) {
    assert.throws(() => webhookAddress(value));
  }
});

test('email masking never exposes the entire local part, including short addresses', () => {
  assert.equal(maskNotificationEmail('abcdef@example.test'), 'abc***@example.test');
  assert.equal(maskNotificationEmail('abc@example.test'), 'ab*@example.test');
  assert.equal(maskNotificationEmail('a@example.test'), '*@example.test');
  assert.equal(maskNotificationEmail('not-an-email'), '（未設定）');
});
