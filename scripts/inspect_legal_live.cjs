'use strict';
// Read-only cloud inspection: configuration and rules, never user documents.
const fs = require('node:fs');
const path = require('node:path');
process.env.METADATA_SERVER_DETECTION = 'none';
let stage = 'authentication';
async function main() {
  const project = 'cit-app-2de1c';
  const root = path.resolve(__dirname, '..');
  if (JSON.parse(fs.readFileSync(path.join(root, '.firebaserc'))).projects.default !== project) {
    throw Error('Unexpected project');
  }
  const auth = require('firebase-tools/lib/auth');
  const account = auth.selectAccount(undefined, root);
  if (!account) throw Error('Firebase CLI login required');
  await require('firebase-tools/lib/requireAuth').requireAuth({project,
    nonInteractive: true, user: account.user, tokens: account.tokens});
  stage = 'list-releases';
  const rules = require('firebase-tools/lib/gcp/rules');
  let releases;
  if (process.argv.includes('--direct')) {
    stage = 'get-active-release';
    const {Client} = require('firebase-tools/lib/apiv2');
    const client = new Client({urlPrefix: 'https://firebaserules.googleapis.com', apiVersion: 'v1'});
    const response = await client.get(`/projects/${project}/releases/cloud.firestore`);
    releases = [response.body];
  } else {
    releases = await rules.listAllReleases(project);
  }
  const release = releases.find(r => r.name === `projects/${project}/releases/cloud.firestore` ||
    r.name === `projects/${project}/releases/cloud.firestore/(default)`);
  if (!release) throw Error('No active Firestore rules');
  stage = 'fetch-rules';
  const files = await rules.getRulesetContent(release.rulesetName);
  if (files.length !== 1) throw Error('Multi-file rules require inspection');
  const directory = path.join(root, 'build', 'legal-release');
  stage = 'save-local-copy';
  fs.mkdirSync(directory, {recursive: true});
  fs.writeFileSync(path.join(directory, 'firestore.live.rules'), files[0].content);
  fs.writeFileSync(path.join(directory, 'live-rules-metadata.json'), JSON.stringify({
    checkedAt: new Date().toISOString(), project, release: release.name, ruleset: release.rulesetName,
  }, null, 2));
  console.log('Saved active Firestore rules and release metadata. No cloud writes or user reads.');
}
main().catch(error => {console.error('Live legal inspection did not complete. No deployment performed.',
  {stage, code: error.code || error.status || error.context?.response?.statusCode || 'unavailable'}); process.exitCode = 1;});
