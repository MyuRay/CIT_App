'use strict';
// Administrative setup/verification. Never accepts or prints a webhook URL.
const fs = require('node:fs');
const path = require('node:path');
const auth = require('firebase-tools/lib/auth');
const {PROJECT, ALERTS, STATE} = require('../security-functions/security_monitor');
const SA = `cit-security-monitor@${PROJECT}.iam.gserviceaccount.com`;
const output = path.resolve('.firebase/security-deploy');
let accessToken;
async function api(url, method = 'GET', body, allow404 = false) {
  const r = await fetch(url, {method, headers: {Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json'},
    ...(body ? {body: JSON.stringify(body)} : {})});
  if (allow404 && r.status === 404) return null;
  if (!r.ok) throw Error(`${method} ${new URL(url).hostname} HTTP ${r.status}`);
  return r.status === 204 ? {} : r.json();
}
const firestoreBase = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/`;
const toFields = data => Object.fromEntries(Object.entries(data).map(([k, v]) => [k,
  typeof v === 'number' ? {integerValue: String(v)} : typeof v === 'boolean' ? {booleanValue: v} : {stringValue: v}]));
function fromValue(value) {
  if (value.stringValue !== undefined) return value.stringValue;
  if (value.integerValue !== undefined) return Number(value.integerValue);
  if (value.doubleValue !== undefined) return value.doubleValue;
  if (value.booleanValue !== undefined) return value.booleanValue;
  if (value.arrayValue) return (value.arrayValue.values || []).map(fromValue);
  if (value.mapValue) return fromFields(value.mapValue);
  return null;
}
const fromFields = data => Object.fromEntries(Object.entries(data.fields || {}).map(([k, v]) => [k, fromValue(v)]));
async function configure() {
  const identity = `https://iam.googleapis.com/v1/projects/${PROJECT}/serviceAccounts/${SA}`;
  if (!await api(identity, 'GET', null, true)) {
    await api(`https://iam.googleapis.com/v1/projects/${PROJECT}/serviceAccounts`, 'POST', {
      accountId: 'cit-security-monitor', serviceAccount: {displayName: 'CIT security monitoring'},
    });
  }
  const base = `https://cloudresourcemanager.googleapis.com/v1/projects/${PROJECT}`;
  const policy = await api(base + ':getIamPolicy', 'POST', {options: {requestedPolicyVersion: 3}});
  const backup = path.join(output, 'iam-before.json');
  if (!fs.existsSync(backup)) fs.writeFileSync(backup, JSON.stringify(policy, null, 2));
  policy.bindings ||= [];
  for (const role of ['roles/datastore.user', 'roles/monitoring.viewer', 'roles/logging.privateLogViewer', 'roles/eventarc.eventReceiver']) {
    let binding = policy.bindings.find(b => b.role === role && !b.condition);
    if (!binding) {binding = {role, members: []}; policy.bindings.push(binding);}
    if (!binding.members.includes(`serviceAccount:${SA}`)) binding.members.push(`serviceAccount:${SA}`);
  }
  policy.auditConfigs ||= [];
  for (const service of ['datastore.googleapis.com', 'storage.googleapis.com']) {
    let config = policy.auditConfigs.find(c => c.service === service);
    if (!config) {config = {service, auditLogConfigs: []}; policy.auditConfigs.push(config);}
    if (!config.auditLogConfigs.some(c => c.logType === 'DATA_WRITE')) config.auditLogConfigs.push({logType: 'DATA_WRITE'});
  }
  await api(base + ':setIamPolicy', 'POST', {policy});
  const authUrl = `https://identitytoolkit.googleapis.com/admin/v2/projects/${PROJECT}/config`;
  const config = await api(authUrl);
  const monitoringBackup = path.join(output, 'authentication-monitoring-before.json');
  if (!fs.existsSync(monitoringBackup)) fs.writeFileSync(monitoringBackup, JSON.stringify(config.monitoring || {}, null, 2));
  await api(authUrl + '?updateMask=monitoring.requestLogging.enabled', 'PATCH', {monitoring: {requestLogging: {enabled: true}}});
  console.log(JSON.stringify({serviceAccount: SA, dataWriteAudit: ['datastore', 'storage'], authenticationActivityLogging: true}));
}
async function grantSecret() {
  const base = `https://secretmanager.googleapis.com/v1/projects/${PROJECT}/secrets/DISCORD_SECURITY_WEBHOOK`;
  const policy = await api(base + ':getIamPolicy');
  policy.bindings ||= [];
  let b = policy.bindings.find(x => x.role === 'roles/secretmanager.secretAccessor' && !x.condition);
  if (!b) {b = {role: 'roles/secretmanager.secretAccessor', members: []}; policy.bindings.push(b);}
  if (!b.members.includes(`serviceAccount:${SA}`)) b.members.push(`serviceAccount:${SA}`);
  await api(base + ':setIamPolicy', 'POST', {policy});
  console.log('Security runtime can access only the named notification secret through this grant.');
}
async function probe() {
  const id = 'delivery-check-' + Date.now();
  const url = firestoreBase + 'security_monitor_probes/' + id;
  await api(url, 'PATCH', {fields: toFields({authorId: 'synthetic-owner', body: 'Synthetic security probe', createdAt: 1})});
  await api(url + '?updateMask.fieldPaths=authorId', 'PATCH', {fields: toFields({authorId: 'synthetic-replacement'})});
  fs.writeFileSync(path.join(output, 'probe.json'), JSON.stringify({id, createdAtMs: Date.now()}, null, 2));
  console.log(JSON.stringify({probeId: id, changedOnlyPrivateSyntheticDocument: true}));
}
async function status() {
  const health = await api(firestoreBase + STATE + '/health', 'GET', null, true);
  const functions = await api(`https://cloudfunctions.googleapis.com/v2/projects/${PROJECT}/locations/us-central1/functions`);
  const jobs = await api(`https://cloudscheduler.googleapis.com/v1/projects/${PROJECT}/locations/us-central1/jobs`);
  const report = {health: health ? fromFields(health) : null,
    functions: (functions.functions || []).filter(f => f.name.split('/').pop().startsWith('security')).map(f => ({name: f.name.split('/').pop(), state: f.state, serviceAccount: f.serviceConfig?.serviceAccountEmail, eventType: f.eventTrigger?.eventType, filters: f.eventTrigger?.eventFilters})),
    jobs: (jobs.jobs || []).filter(j => j.name.includes('security')).map(j => ({name: j.name, schedule: j.schedule, state: j.state, status: j.status})),
  };
  fs.writeFileSync(path.join(output, 'status.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report));
}
async function verifyDelivery() {
  const probeState = JSON.parse(fs.readFileSync(path.join(output, 'probe.json'), 'utf8'));
  const result = await api(firestoreBase.slice(0, -1) + ':runQuery', 'POST', {structuredQuery: {
    from: [{collectionId: ALERTS}], where: {fieldFilter: {field: {fieldPath: 'kind'}, op: 'EQUAL', value: {stringValue: 'delivery_test'}}},
  }});
  const matches = result.filter(x => x.document).map(x => ({id: x.document.name.split('/').pop(), ...fromFields(x.document)}))
    .filter(x => x.detectedAtMs >= probeState.createdAtMs - 10000).sort((a, b) => b.detectedAtMs - a.detectedAtMs);
  if (!matches.length) {console.log(JSON.stringify({state: 'waiting_for_trigger'})); return;}
  const alert = matches[0];
  if (alert.status !== 'sent') {console.log(JSON.stringify({state: alert.status, attempts: alert.attempts, alertId: alert.id})); return;}
  const secret = await api(`https://secretmanager.googleapis.com/v1/projects/${PROJECT}/secrets/DISCORD_SECURITY_WEBHOOK/versions/latest:access`);
  const webhook = Buffer.from(secret.payload.data, 'base64').toString('utf8').trim();
  const r = await fetch(webhook + '/messages/' + alert.discordMessageId);
  if (!r.ok) throw Error('Discord confirmation HTTP ' + r.status);
  const message = await r.json();
  const confirmation = {state: 'confirmed', alertId: alert.id, messageId: message.id,
    title: message.embeds?.[0]?.title, timestamp: message.timestamp, viaDeployedDetector: alert.source};
  fs.writeFileSync(path.join(output, 'delivery-confirmation.json'), JSON.stringify(confirmation, null, 2));
  await api(firestoreBase + 'security_monitor_probes/' + probeState.id, 'DELETE');
  console.log(JSON.stringify(confirmation));
}
async function runPoll() {
  const jobs = await api(`https://cloudscheduler.googleapis.com/v1/projects/${PROJECT}/locations/us-central1/jobs`);
  const job = (jobs.jobs || []).find(j => j.name.includes('securityPollSignals'));
  if (!job) throw Error('Security scheduler job not found');
  await api('https://cloudscheduler.googleapis.com/v1/' + job.name + ':run', 'POST', {});
  console.log('Scheduled security monitor invoked.');
}
async function grantInvocation() {
  const result = await api(`https://cloudfunctions.googleapis.com/v2/projects/${PROJECT}/locations/us-central1/functions`);
  const names = [];
  for (const f of result.functions || []) {
    if (f.labels?.['firebase-functions-codebase'] !== 'security') continue;
    const url = 'https://run.googleapis.com/v2/' + f.serviceConfig.service;
    const policy = await api(url + ':getIamPolicy');
    policy.bindings ||= [];
    let binding = policy.bindings.find(b => b.role === 'roles/run.invoker' && !b.condition);
    if (!binding) {binding = {role: 'roles/run.invoker', members: []}; policy.bindings.push(binding);}
    if (!binding.members.includes(`serviceAccount:${SA}`)) binding.members.push(`serviceAccount:${SA}`);
    await api(url + ':setIamPolicy', 'POST', {policy});
    names.push(f.name.split('/').pop());
  }
  if (!names.length) throw Error('No security codebase services found');
  console.log(JSON.stringify({privateInvokerGrantedTo: SA, functions: names}));
}
(async () => {
  fs.mkdirSync(output, {recursive: true});
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw Error('No existing Firebase login');
  const token = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  accessToken = token.access_token;
  const commands = {configure, 'grant-secret': grantSecret, 'grant-invocation': grantInvocation,
    probe, status, 'verify-delivery': verifyDelivery, 'run-poll': runPoll};
  const action = commands[process.argv[2]];
  if (!action) throw Error('Choose configure, grant-secret, grant-invocation, probe, status, verify-delivery or run-poll');
  await action();
})().catch(e => {console.error(e.message); process.exitCode = 1;});
