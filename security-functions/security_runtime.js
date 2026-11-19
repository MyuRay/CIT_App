'use strict';

const {onDocumentUpdatedWithAuthContext, onDocumentWrittenWithAuthContext, onDocumentCreated} = require('firebase-functions/v2/firestore');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {defineSecret} = require('firebase-functions/params');
const admin = require('firebase-admin');
const {PROJECT, ALERTS, STATE, detectDocumentChange, createAlertStore, createDelivery,
  createGoogleReader, pollSignals} = require('./security_monitor');

const webhook = defineSecret('DISCORD_SECURITY_WEBHOOK');
const SERVICE_ACCOUNT = `cit-security-monitor@${PROJECT}.iam.gserviceaccount.com`;
const common = {region: 'us-central1', serviceAccount: SERVICE_ACCOUNT, memory: '256MiB',
  timeoutSeconds: 60, maxInstances: 3, retry: true};
const db = () => admin.firestore();

function watch(document, collection, allWrites = false, probe = false) {
  const trigger = allWrites ? onDocumentWrittenWithAuthContext : onDocumentUpdatedWithAuthContext;
  return trigger({...common, document}, async event => {
    if (!event.data) return;
    const kinds = detectDocumentChange({collection,
      before: event.data.before.exists ? event.data.before.data() : undefined,
      after: event.data.after.exists ? event.data.after.data() : undefined});
    const enqueue = createAlertStore({db: db()});
    for (const kind of kinds) await enqueue({kind: probe ? 'delivery_test' : kind,
      source: probe ? `監視経路テスト (${kind})` : collection, eventId: event.id,
      path: event.document, actor: event.authId});
  });
}

exports.securityWatchCwitter = watch('cwitter_posts/{postId}', 'cwitter_posts');
exports.securityWatchCwitterReplies = watch('cwitter_posts/{postId}/replies/{replyId}', 'replies');
exports.securityWatchChibaThreads = watch('chiba_channel_threads/{threadId}', 'chiba_channel_threads');
exports.securityWatchChibaComments = watch('chiba_channel_threads/{threadId}/comments/{commentId}', 'comments');
exports.securityWatchBulletin = watch('bulletin_posts/{postId}', 'bulletin_posts');
exports.securityWatchAdmins = watch('admin_permissions/{userId}', 'admin_permissions', true);
// This private collection has no client rules. It exercises the real detector and
// delivery pipeline without creating visible posts or touching any user's data.
exports.securityWatchProbe = watch('security_monitor_probes/{probeId}', 'cwitter_posts', false, true);

exports.securityDeliverAlert = onDocumentCreated({...common,
  document: `${ALERTS}/{alertId}`, secrets: [webhook]}, async event => {
  const result = await createDelivery({db: db(), webhook: () => webhook.value()})(event.params.alertId);
  console.info('Security notification delivery', {alertId: event.params.alertId, sent: result.sent});
});

exports.securityPollSignals = onSchedule({schedule: 'every 5 minutes', timeZone: 'Asia/Tokyo',
  region: 'us-central1', serviceAccount: SERVICE_ACCOUNT, memory: '256MiB', timeoutSeconds: 240,
  maxInstances: 1, retryCount: 2, minBackoffSeconds: 30}, async () => {
  const read = createGoogleReader({credential: admin.app().options.credential});
  const result = await pollSignals({read, enqueue: createAlertStore({db: db()})});
  await db().collection(STATE).doc('health').set(result);
  const expired = await db().collection(ALERTS).where('expiresAtMs', '<', Date.now()).limit(100).get();
  const batch = db().batch();
  for (const doc of expired.docs) if (doc.data().status === 'sent') batch.delete(doc.ref);
  if (!expired.empty) await batch.commit();
  console.info('Security monitoring completed', {checks: result.checks.length, failures: result.failures});
  if (result.failures) throw Error('Some security checks could not complete');
});
