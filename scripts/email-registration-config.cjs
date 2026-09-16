'use strict';
// Uses the Firebase CLI's existing login in memory. Never prints or writes tokens.
const auth = require('../node_modules/firebase-tools/lib/auth');
const args = process.argv.slice(2);
const project = args[args.indexOf('--project') + 1];
if (!args.includes('--project') || project !== 'cit-app-2de1c') throw new Error('Pass --project cit-app-2de1c explicitly. Default is read-only.');
const apply = args.includes('--apply');
const requested = ['--upgrade-identity-platform', '--enable-email-links', '--register-debug-certificate'].filter(flag => args.includes(flag));
if (requested.length && !apply) throw new Error('Mutations require --apply after approval of the production configuration change.');
const configUrl = 'https://identitytoolkit.googleapis.com/admin/v2/projects/' + project + '/config';

(async () => {
  const account = auth.getGlobalDefaultAccount();
  if (!account?.tokens?.refresh_token) throw new Error('Use an existing Firebase CLI login for the project owner.');
  const token = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  async function request(url, {method = 'GET', body} = {}) {
    const response = await fetch(url, {method, headers:{Authorization:'Bearer ' + token.access_token, 'Content-Type':'application/json'},
      body: body === undefined ? undefined : JSON.stringify(body)});
    const responseText = await response.text();
    const data = responseText.trim() ? JSON.parse(responseText) : {};
    if (!response.ok) throw new Error('Configuration request failed: HTTP ' + response.status + ' ' + (data.error?.status || ''));
    return data;
  }
  let config = await request(configUrl);
  if (apply && args.includes('--upgrade-identity-platform') && config.subtype !== 'IDENTITY_PLATFORM') {
    await request('https://identitytoolkit.googleapis.com/v2/projects/' + project + '/identityPlatform:initializeAuth', {method:'POST',body:{}});
    config = await request(configUrl);
  }
  if (apply && args.includes('--enable-email-links')) {
    if (config.subtype !== 'IDENTITY_PLATFORM') throw new Error('Upgrade to Identity Platform before enabling the verified-only registration rollout.');
    await request(configUrl + '?updateMask=signIn.email', {method:'PATCH',body:{signIn:{email:{...config.signIn?.email, enabled:true, passwordRequired:false}}}});
  }
  if (apply && args.includes('--register-debug-certificate')) {
    const apps = await request('https://firebase.googleapis.com/v1beta1/projects/' + project + '/androidApps');
    const app = apps.apps?.find(value => value.packageName === 'jp.ac.chibakoudai.citapp');
    if (!app) throw new Error('CIT Android app is not registered in this project.');
    const url = 'https://firebase.googleapis.com/v1beta1/' + app.name + '/sha';
    const registered = await request(url);
    // Public fingerprints verified from this workstation's debug.keystore.
    // A replacement keystore requires refreshing these values and assetlinks.
    for (const certificate of [
      {certType:'SHA_1',shaHash:'16f848d10467f6646be9f9a6e3ae3424da40090d'},
      {certType:'SHA_256',shaHash:'9fb80ab1b5e00a68a0381604115c72fd4f754a8a36f75c23ee169e6481a711ea'},
    ]) {
      if (!registered.certificates?.some(value => value.certType === certificate.certType && value.shaHash.toLowerCase() === certificate.shaHash)) {
        await request(url, {method:'POST',body:certificate});
      }
    }
  }
  config = await request(configUrl);
  console.log(JSON.stringify({project,subtype:config.subtype,
    passwordSignInEnabled:config.signIn?.email?.enabled === true,
    emailLinkEnabled:config.signIn?.email?.enabled === true && config.signIn?.email?.passwordRequired === false,
    beforeCreateConfigured:!!config.blockingFunctions?.triggers?.beforeCreate,
    applied:apply ? requested : []},null,2));
})().catch(error => { console.error(error.message); process.exitCode = 1; });
