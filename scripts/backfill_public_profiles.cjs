'use strict';
// Defaults to counting profiles without writing. Never print account contents.
process.env.METADATA_SERVER_DETECTION = 'none';
const {createRequire} = require('node:module');
const req = createRequire(require.resolve('../functions/package.json'));
const {initializeApp, deleteApp} = req('firebase-admin/app');
const {getFirestore, FieldPath} = req('firebase-admin/firestore');
const {createPublicProfileSync, PUBLIC_FIELDS} = require('../functions/public_profiles');
async function main() {
  if (process.env.FIRESTORE_EMULATOR_HOST) throw Error('Production migration cannot target an emulator');
  const apply = process.argv.includes('--apply');
  const expected = 'cit-app-2de1c';
  if (!process.argv.includes('--project=' + expected)) throw Error('Explicit CIT App project is required');
  const cliAuth = require('firebase-tools/lib/auth');
  const account = cliAuth.selectAccount(undefined, process.cwd());
  if (!account) throw Error('Firebase CLI login required');
  const app = initializeApp({projectId: expected, credential: {getAccessToken: async () => {
    const tokens = await cliAuth.getAccessToken(account.tokens.refresh_token,
      ['https://www.googleapis.com/auth/cloud-platform']);
    return {access_token: tokens.access_token, expires_in: 3000};
  }}});
  const db = getFirestore(app);
  try {
    const sync = createPublicProfileSync({db});
    let cursor, count = 0;
    while (true) {
      let query = db.collection('users').select(...PUBLIC_FIELDS).orderBy(FieldPath.documentId()).limit(100);
      if (cursor) query = query.startAfter(cursor);
      const page = await query.get();
      for (const profile of page.docs) {
        if (apply) await sync(profile.id);
        count++;
      }
      if (page.size < 100) break;
      cursor = page.docs.at(-1).id;
    }
    console.log(JSON.stringify({project: expected, mode: apply ? 'apply' : 'dry-run', profiles: count}));
  } finally {await db.terminate(); await deleteApp(app);}
}
main().catch(() => {console.error('Profile backfill did not finish; no account contents are logged.'); process.exitCode = 1;});
