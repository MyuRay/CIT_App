'use strict';
const admin = require('firebase-admin');
const {rebuildFavoriteCounts} = require('../cafeteria_favorites');
const args = process.argv.slice(2);
const projectIndex = args.indexOf('--project');
const projectId = projectIndex < 0 ? null : args[projectIndex + 1];
if (!projectId || projectId.startsWith('--')) throw new Error('Pass --project <Firebase project ID>. Defaults to dry run; add --write to update count-only documents.');
admin.initializeApp({projectId});
rebuildFavoriteCounts(admin.firestore(), {write: args.includes('--write')})
  .then(result => { console.log(JSON.stringify(result, null, 2)); return admin.app().delete(); })
  .catch(error => { console.error(error.message); process.exitCode = 1; });
