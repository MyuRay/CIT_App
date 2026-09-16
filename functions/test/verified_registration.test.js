const {test} = require('node:test');
const assert = require('node:assert/strict');
const {requireVerifiedRegistration} = require('../verified_registration');
test('new accounts require Firebase ownership proof and exact CIT signup domain', () => {
  for (const data of [undefined, {}, {email:'student@chibatech.ac.jp',emailVerified:false},
    {email:'student@chibatech.ac.jp',emailVerified:'true'},
    {email:'student@gmail.com',emailVerified:true},
    {email:'student@chibatech.ac.jp.evil.example',emailVerified:true},
    {email:'student@@chibatech.ac.jp',emailVerified:true},
    {email:'student@s.chibakoudai.jp',emailVerified:true}]) {
    assert.throws(() => requireVerifiedRegistration({data}), {code:'permission-denied'});
  }
});
test('verified CIT users pass without modifying their verification flag', () => {
  for (const email of ['student@chibatech.ac.jp', 'STUDENT+tag@CHIBATECH.AC.JP']) {
    const data = Object.freeze({email, emailVerified:true});
    assert.equal(requireVerifiedRegistration({data}), undefined);
  }
});
