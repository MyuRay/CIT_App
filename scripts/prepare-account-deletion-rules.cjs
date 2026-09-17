'use strict';
// Prepare only the deletion guard on top of each LIVE ruleset; do not deploy
// unrelated, uncommitted local rules. Keeps originals for review/rollback.
const fs = require('node:fs');
const path = require('node:path');
const auth = require('../node_modules/firebase-tools/lib/auth');
function guard(source, storage) {
  if (source.includes('function isActiveAccount()')) return source;
  const guarded = source.replaceAll('request.auth != null', 'isActiveAccount()');
  const marker = storage ? 'match /b/{bucket}/o {' : 'match /databases/{database}/documents {';
  if (!guarded.includes(marker)) throw Error('Unknown rules structure');
  const lookup = storage ? 'firestore.exists(/databases/(default)/documents/account_deletion_jobs/$(request.auth.uid))'
    : 'exists(/databases/$(database)/documents/account_deletion_jobs/$(request.auth.uid))';
  return guarded.replace(marker, marker + '\n    function isActiveAccount() {\n      return request.auth != null && !' + lookup + ';\n    }\n');
}
(async () => {
  const a = auth.getGlobalDefaultAccount();
  const t = await auth.getAccessToken(a.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  async function get(url) {
    const r = await fetch('https://firebaserules.googleapis.com/v1/' + url, {headers: {Authorization: 'Bearer ' + t.access_token}});
    if (!r.ok) throw Error('Rules read failed: ' + r.status);
    return r.json();
  }
  const dir = '.firebase/deletion-deploy';
  fs.mkdirSync(dir, {recursive: true});
  for (const [filename, release, storage] of [
    ['firestore.rules', 'cloud.firestore', false],
    ['storage.rules', 'firebase.storage/cit-app-2de1c.firebasestorage.app', true],
  ]) {
    const current = await get('projects/cit-app-2de1c/releases/' + release);
    const rules = await get(current.rulesetName);
    if (rules.source.files.length !== 1) throw Error('Unexpected multi-file ruleset');
    const content = rules.source.files[0].content;
    fs.writeFileSync(path.join(dir, filename + '.before'), content);
    fs.writeFileSync(path.join(dir, filename), guard(content, storage));
    fs.writeFileSync(filename, guard(fs.readFileSync(filename, 'utf8'), storage));
    console.log('Prepared guard for ' + filename + ' from ' + current.rulesetName);
  }
  fs.writeFileSync(path.join(dir, 'firebase.json'), JSON.stringify({firestore: {rules: 'firestore.rules'}, storage: {rules: 'storage.rules'}}, null, 2));
})().catch(e => {console.error(e.message); process.exitCode = 1;});
