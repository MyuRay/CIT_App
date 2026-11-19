'use strict';
const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const project = 'cit-app-2de1c';
const bucket = 'cit-app-2de1c.firebasestorage.app';
const specs = [
  {file: 'firestore.rules', begin: '// BEGIN CONTACT CHAT RULES', end: '// END CONTACT CHAT RULES',
    anchor: 'match /contact_forms/', collection: 'match /contact_chats/',
    releases: ['cloud.firestore', 'cloud.firestore/(default)']},
  {file: 'storage.rules', begin: '// BEGIN CONTACT CHAT IMAGE RULES', end: '// END CONTACT CHAT IMAGE RULES',
    anchor: 'match /profile_images/', collection: 'match /contact_chat_images/',
    releases: ['firebase.storage/' + bucket]},
];
function count(text, value) { return text.split(value).length - 1; }
function fragment(source, spec) {
  const s = source.replace(/\r\n/g, '\n');
  if (count(s, spec.begin) !== 1 || count(s, spec.end) !== 1) throw Error('Expected one marked inquiry block');
  const start = s.lastIndexOf('\n', s.indexOf(spec.begin)) + 1;
  const end = s.indexOf(spec.end) + spec.end.length;
  if (end <= start) throw Error('Invalid inquiry block');
  return s.slice(start, end) + '\n';
}
function mergeRules(live, local, spec) {
  const code = fragment(local, spec);
  if (count(live, spec.begin) === 1 && count(live, spec.end) === 1) {
    const start = live.lastIndexOf('\n', live.indexOf(spec.begin)) + 1;
    const end = live.indexOf(spec.end) + spec.end.length;
    if (end <= start) throw Error('Invalid deployed inquiry markers');
    return live.slice(0, start) + code.trimEnd() + live.slice(end);
  }
  if (live.includes(spec.begin) || live.includes(spec.end) || live.includes(spec.collection)) {
    throw Error('Existing inquiry rules need review; deployment stopped');
  }
  if (count(live, spec.anchor) !== 1 || !live.includes('function isCITUser()')) {
    throw Error('Unexpected deployed rules; deployment stopped');
  }
  const start = live.lastIndexOf('\n', live.indexOf(spec.anchor)) + 1;
  return live.slice(0, start) + code + '\n' + live.slice(start);
}
function cli(args) {
  const result = spawnSync(process.execPath,
    [require.resolve('firebase-tools/lib/bin/firebase'), ...args,
      '--project', project, '--config', 'firebase.contact-chat-deploy.json', '--non-interactive'],
    {cwd: root, stdio: 'inherit', env: {...process.env, CI: 'true'}});
  if (result.error) throw result.error;
  if (result.status !== 0) throw Error('Firebase CLI did not complete; inspect its output before retrying');
}
function verifyRules(stage) {
  const result = spawnSync(process.execPath, [
    require.resolve('firebase-tools/lib/bin/firebase'), 'emulators:exec',
    '--project', 'demo-cit-contact-chat', '--only', 'firestore,storage',
    '--config', 'firebase.contact-chat-test.json',
    'node --test --test-concurrency=1 test/firestore/contact_chat.rules.test.cjs test/storage/contact_chat.rules.test.cjs',
  ], {cwd: root, stdio: 'inherit', env: {...process.env, CI: 'true', CONTACT_CHAT_RULES_DIR: stage}});
  if (result.error) throw result.error;
  if (result.status !== 0) throw Error('Inquiry authorization tests did not pass; rule release stopped');
}
async function main() {
  const deploy = process.argv.includes('--deploy');
  if (!deploy && !process.argv.includes('--prepare-only')) {
    console.log('Usage: node scripts/deploy_contact_chat.cjs --prepare-only | --deploy');
    return;
  }
  const settings = JSON.parse(fs.readFileSync(path.join(root, '.firebaserc'), 'utf8'));
  if (settings.projects?.default !== project) throw Error('Unexpected Firebase project');
  process.chdir(root);
  const auth = require('firebase-tools/lib/auth');
  const account = auth.selectAccount(undefined, root);
  if (!account) throw Error('Sign in using the Firebase CLI before deploying');
  await require('firebase-tools/lib/requireAuth').requireAuth({
    project, nonInteractive: true, user: account.user, tokens: account.tokens});
  const rules = require('firebase-tools/lib/gcp/rules');
  const stage = path.join(root, 'build', 'contact-chat-deploy');
  const stamp = new Date().toISOString().replace(/[^0-9TZ]/g, '');
  const backup = path.join(stage, stamp);
  fs.mkdirSync(backup, {recursive: true});
  async function prepare(label) {
    const releases = await rules.listAllReleases(project);
    const prepared = [];
    for (const spec of specs) {
      const matches = releases.filter(r =>
        spec.releases.some(name => r.name === 'projects/' + project + '/releases/' + name));
      if (matches.length !== 1) throw Error('Could not uniquely identify deployed ' + spec.file);
      const release = matches[0];
      const files = await rules.getRulesetContent(release.rulesetName);
      if (files.length !== 1) throw Error('Multi-file deployed rules require review');
      const live = files[0].content;
      const next = mergeRules(live, fs.readFileSync(path.join(root, spec.file), 'utf8'), spec);
      const check = await rules.testRuleset(project, [{name: files[0].name, content: next}]);
      const errors = (check.body?.issues || []).filter(i => i.severity === 'ERROR');
      if (errors.length) throw Error('Rules validation failed: ' + errors.map(i => i.description).join('; '));
      fs.writeFileSync(path.join(backup, label + '-' + spec.file), live);
      fs.writeFileSync(path.join(stage, spec.file), next);
      prepared.push({file: spec.file, release: release.name, before: release.rulesetName, content: next});
    }
    fs.writeFileSync(path.join(backup, label + '-releases.json'),
      JSON.stringify(prepared.map(({content, ...metadata}) => metadata), null, 2));
    return prepared;
  }
  const firstPrepared = await prepare('before');
  console.log('Prepared inquiry-only Firestore and Storage rule changes for ' + project);
  if (!deploy) return;
  verifyRules(stage);
  cli(['deploy', '--only', [
    'notifyContactChatMessage', 'sendPushNotification', 'processAccountDeletion', 'retryAccountDeletions',
  ].map(id => 'functions:default:' + id).join(',')]);
  // Fetch again after Functions finish so concurrent unrelated rule edits survive.
  const prepared = await prepare('before-rules-release');
  if (prepared.some((item, i) => item.content !== firstPrepared[i].content)) verifyRules(stage);
  cli(['deploy', '--only', 'firestore:rules,storage']);
  const releases = await rules.listAllReleases(project);
  for (const expected of prepared) {
    const release = releases.find(r => r.name === expected.release);
    if (!release) throw Error('Deployed release was not found');
    const files = await rules.getRulesetContent(release.rulesetName);
    if (files.length !== 1 ||
        files[0].content.replace(/\r\n/g, '\n').trimEnd() !== expected.content.replace(/\r\n/g, '\n').trimEnd()) {
      throw Error('Deployed rules differ from the prepared inquiry-only change');
    }
  }
  console.log('Verified inquiry backend deployment. Mobile app distribution is a separate release.');
}
module.exports = {fragment, mergeRules, specs};
if (require.main === module) main().catch(error => {
  console.error('Inquiry deployment stopped: ' + error.message);
  process.exitCode = 1;
});