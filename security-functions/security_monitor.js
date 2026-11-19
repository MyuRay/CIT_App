'use strict';

const {createHash} = require('node:crypto');
const {isDeepStrictEqual} = require('node:util');

const PROJECT = 'cit-app-2de1c';
const ALERTS = 'security_alerts';
const STATE = 'security_monitor_state';
const COOLDOWN_MS = 10 * 60 * 1000;
const RETENTION_MS = 30 * 24 * 60 * 60 * 1000;
const DEFINITIONS = Object.freeze({
  identity_changed: ['投稿者情報の変更', '作成後の投稿者ID・メール・Cwitter IDの変更を検知しました。'],
  required_field_removed: ['投稿の必須情報に異常', '必須項目の削除・型異常、または作成日時の変更を検知しました。'],
  admin_permission_changed: ['管理者権限の変更', '管理者権限の追加・変更・削除を検知しました。正規の管理操作か確認してください。'],
  firestore_denied: ['Firestoreへのアクセス拒否が増加', '10分間に50件以上の拒否を検知しました。アプリの不具合の可能性もあります。'],
  storage_denied: ['Storageへのアクセス拒否が増加', '10分間に50件以上の拒否を検知しました。アプリの不具合の可能性もあります。'],
  auth_failures: ['ログイン失敗が増加', '10分間に20件以上のログイン失敗を検知しました。'],
  admin_denied: ['管理APIへのアクセス拒否が増加', '10分間に10件以上の認証・権限エラーを検知しました。'],
  bulk_deletes: ['データの大量削除', '10分間に100件以上の削除を検知しました。退会処理などの正規操作も確認してください。'],
  read_spike: ['データの大量読み取り', '10分間に50,000件以上の読み取りを検知しました。'],
  write_spike: ['データの大量書き込み', '10分間に5,000件以上の書き込みを検知しました。'],
  security_config_changed: ['セキュリティ設定の変更', 'アクセス権限またはFirebaseルールの変更を検知しました。正規の管理操作か確認してください。'],
  monitor_error: ['監視の一部で取得エラー', '監視データを取得できませんでした。監視状況を確認してください。'],
  delivery_test: ['セキュリティ通知の動作確認', 'これは通知経路のテストです。不正アクセスの発生を示すものではありません。'],
});

function hash(value) { return createHash('sha256').update(String(value)).digest('hex'); }
function reference(value) { return value ? hash(value).slice(0, 16) : 'unknown'; }

function detectDocumentChange({collection, before, after}) {
  if (collection === 'admin_permissions') {
    return isDeepStrictEqual(before, after) ? [] : ['admin_permission_changed'];
  }
  if (!before || !after) return []; // Whole-document deletes are monitored in aggregate.
  const findings = [];
  if (['authorId', 'authorEmail', 'cwitterId'].some(key =>
    (Object.hasOwn(before, key) || Object.hasOwn(after, key)) && !isDeepStrictEqual(before[key], after[key]))) {
    findings.push('identity_changed');
  }
  const contentFields = collection === 'chiba_channel_threads' ? ['title'] :
    collection === 'bulletin_posts' ? ['title', 'description'] : ['body'];
  if (contentFields.some(key => Object.hasOwn(before, key) && typeof after[key] !== 'string') ||
      Object.hasOwn(before, 'createdAt') && !isDeepStrictEqual(before.createdAt, after.createdAt)) {
    findings.push('required_field_removed');
  }
  return findings;
}

function discordPayload(alert, id) {
  const [title, description] = DEFINITIONS[alert.kind] || ['監視イベント', '監視内容を確認してください。'];
  const fields = [
    {name: '検知時刻（日本時間）', value: new Date(alert.detectedAtMs).toLocaleString('ja-JP', {timeZone: 'Asia/Tokyo'}), inline: false},
    {name: '対象', value: String(alert.source || 'project').slice(0, 100), inline: true},
    {name: '確認番号', value: id, inline: false},
  ];
  if (Number.isFinite(alert.count)) fields.push({name: '検知件数', value: String(alert.count), inline: true});
  if (alert.documentRef) fields.push({name: '対象文書の照合番号', value: alert.documentRef, inline: true});
  return {
    username: 'CIT App セキュリティ監視', allowed_mentions: {parse: []},
    embeds: [{title: (alert.kind === 'delivery_test' ? '【テスト】' : '【要確認】') + title,
      description, color: alert.kind === 'delivery_test' ? 0x3498db : 0xe67e22,
      fields, footer: {text: '不正アクセスの断定ではありません。同種の通知は10分間隔で抑制します。'},
      url: `https://console.cloud.google.com/firestore/databases/-default-/data/panel/${ALERTS}/${id}?project=${PROJECT}`,
    }],
  };
}

function createAlertStore({db, now = Date.now}) {
  return async function enqueue(input) {
    if (!Object.hasOwn(DEFINITIONS, input.kind)) throw Error('Unknown security alert kind');
    const time = now();
    const eventId = hash(input.eventId || `${input.kind}:${time}`);
    const throttle = db.collection(STATE).doc('throttle_' + input.kind);
    const id = hash(`${input.kind}:${eventId}`).slice(0, 32);
    const ref = db.collection(ALERTS).doc(id);
    return db.runTransaction(async tx => {
      const [existing, last] = await Promise.all([tx.get(ref), tx.get(throttle)]);
      if (existing.exists) return {id, created: false};
      if (last.exists && time - last.data().lastAlertAtMs < COOLDOWN_MS && input.kind !== 'delivery_test') {
        tx.update(throttle, {suppressed: (last.data().suppressed || 0) + 1});
        return {id: last.data().alertId, created: false};
      }
      // Explicit allowlist: never persist raw log payloads, credentials, email or post text.
      const data = {kind: input.kind, source: input.source, detectedAtMs: time,
        eventId, status: 'pending', attempts: 0, expiresAtMs: time + RETENTION_MS};
      if (input.count !== undefined) data.count = input.count;
      if (input.path) data.documentRef = reference(input.path);
      if (input.actor) data.actorRef = reference(input.actor);
      tx.create(ref, data);
      tx.set(throttle, {lastAlertAtMs: time, alertId: id, suppressed: 0});
      return {id, created: true};
    });
  };
}

function createDelivery({db, webhook, fetchImpl = fetch, now = Date.now}) {
  return async function deliver(id) {
    const ref = db.collection(ALERTS).doc(id);
    const alert = await db.runTransaction(async tx => {
      const snap = await tx.get(ref);
      if (!snap.exists || snap.data().status === 'sent') return null;
      const data = snap.data();
      if ((data.leaseUntilMs || 0) > now()) throw Error('Security delivery lease is busy');
      tx.update(ref, {status: 'sending', leaseUntilMs: now() + 90000, attempts: (data.attempts || 0) + 1});
      return data;
    });
    if (!alert) return {sent: false};
    try {
      const url = new URL(webhook());
      if (url.protocol !== 'https:' || !['discord.com', 'discordapp.com'].includes(url.hostname) ||
          !/^\/api\/webhooks\/\d+\/[A-Za-z0-9_-]+$/.test(url.pathname)) throw Error('Invalid security notification destination');
      url.searchParams.set('wait', 'true');
      const response = await fetchImpl(url, {method: 'POST', headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(discordPayload(alert, id)), signal: AbortSignal.timeout(15000)});
      if (!response.ok) throw Error(`Discord HTTP ${response.status}`);
      const message = await response.json();
      if (typeof message.id !== 'string') throw Error('Discord did not confirm a message');
      await ref.update({status: 'sent', sentAtMs: now(), discordMessageId: message.id, leaseUntilMs: 0});
      return {sent: true, messageId: message.id};
    } catch (_) {
      await ref.update({status: 'pending', leaseUntilMs: 0, lastFailureAtMs: now()});
      // Do not rethrow HTTP library errors: they may contain the secret webhook URL.
      throw Error('Security notification delivery failed; retry required');
    }
  };
}

const METRIC_CHECKS = [
  ['firestore_denied', 'firestore.googleapis.com/rules/evaluation_count', 50, ' AND metric.labels.result != "ALLOW"'],
  ['storage_denied', 'firebasestorage.googleapis.com/rules/evaluation_count', 50, ' AND metric.labels.result != "ALLOW"'],
  ['bulk_deletes', 'firestore.googleapis.com/document/delete_count', 100, ''],
  ['read_spike', 'firestore.googleapis.com/document/read_count', 50000, ''],
  ['write_spike', 'firestore.googleapis.com/document/write_count', 5000, ''],
];
const ADMIN_SERVICES = ['updatemenuimagesnow', 'synccluborganizationsnow', 'getusergrowthstats'];
const LOG_CHECKS = [
  ['auth_failures', 20, 'log_id("identitytoolkit.googleapis.com/requests") AND (protoPayload.methodName =~ "SignIn" OR jsonPayload.methodName =~ "SignIn") AND (severity>=ERROR OR protoPayload.status.code>0 OR jsonPayload.status.code>0)'],
  ['admin_denied', 10, 'resource.type="cloud_run_revision" AND resource.labels.service_name=(' + ADMIN_SERVICES.map(x => '"' + x + '"').join(' OR ') + ') AND (httpRequest.status=401 OR httpRequest.status=403)'],
  ['security_config_changed', 1, 'log_id("cloudaudit.googleapis.com/activity") AND (protoPayload.serviceName="firebaserules.googleapis.com" OR protoPayload.methodName =~ "[Ss]etIamPolicy") AND NOT protoPayload.status.code>0'],
];

function createGoogleReader({credential, project = PROJECT, fetchImpl = fetch}) {
  return async function read(url, body) {
    const {access_token: token} = await credential.getAccessToken();
    const response = await fetchImpl(url, {method: body ? 'POST' : 'GET',
      headers: {Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', 'x-goog-user-project': project},
      ...(body ? {body: JSON.stringify(body)} : {}), signal: AbortSignal.timeout(20000)});
    if (!response.ok) throw Error(`Security monitor API HTTP ${response.status}`);
    return response.json();
  };
}

async function metricCount(read, type, extra, end, start, project = PROJECT) {
  let pageToken;
  let total = 0;
  do {
    const params = new URLSearchParams({filter: `metric.type="${type}"${extra}`,
      'interval.startTime': new Date(start).toISOString(), 'interval.endTime': new Date(end).toISOString(),
      pageSize: '1000'});
    if (pageToken) params.set('pageToken', pageToken);
    const result = await read(`https://monitoring.googleapis.com/v3/projects/${project}/timeSeries?${params}`);
    for (const series of result.timeSeries || []) for (const point of series.points || []) {
      total += Number(point.value?.int64Value ?? point.value?.doubleValue ?? 0);
    }
    pageToken = result.nextPageToken;
  } while (pageToken);
  return total;
}

async function logCount(read, filter, start, end, limit, project = PROJECT) {
  let pageToken;
  let count = 0;
  do {
    const result = await read('https://logging.googleapis.com/v2/entries:list', {
      resourceNames: [`projects/${project}`], filter: `${filter} AND timestamp>="${new Date(start).toISOString()}" AND timestamp<"${new Date(end).toISOString()}"`,
      orderBy: 'timestamp desc', pageSize: Math.min(100, limit - count), ...(pageToken ? {pageToken} : {}),
    });
    count += (result.entries || []).length;
    pageToken = result.nextPageToken;
  } while (pageToken && count < limit);
  return count; // Stop at the threshold: avoid downloading unnecessary personal logs.
}

async function pollSignals({read, enqueue, now = Date.now, project = PROJECT}) {
  const time = now();
  // Cloud Monitoring can take 240 seconds to ingest a one-minute sample.
  const metricEnd = Math.floor((time - 5 * 60000) / 60000) * 60000;
  const results = await Promise.allSettled([
    ...METRIC_CHECKS.map(async ([kind, type, threshold, extra]) => {
      const count = await metricCount(read, type, extra, metricEnd, metricEnd - 10 * 60000, project);
      if (count >= threshold) await enqueue({kind, source: 'Cloud Monitoring', count, eventId: `${kind}:${metricEnd}`});
      return {kind, count, threshold};
    }),
    ...LOG_CHECKS.map(async ([kind, threshold, filter]) => {
      const count = await logCount(read, filter, time - 10 * 60000, time, threshold, project);
      if (count >= threshold) await enqueue({kind, source: 'Cloud Logging', count, eventId: `${kind}:${Math.floor(time / 300000)}`});
      return {kind, count, threshold, countIsLowerBound: count >= threshold};
    }),
  ]);
  const failures = results.filter(r => r.status === 'rejected').length;
  if (failures) await enqueue({kind: 'monitor_error', source: 'securityPollSignals', count: failures,
    eventId: `monitor-error:${Math.floor(time / 600000)}`});
  return {checkedAtMs: time, failures, checks: results.map((r, i) => r.status === 'fulfilled' ? r.value :
    {kind: [...METRIC_CHECKS, ...LOG_CHECKS][i][0], error: 'data_unavailable'})};
}

module.exports = {PROJECT, ALERTS, STATE, COOLDOWN_MS, DEFINITIONS, detectDocumentChange, discordPayload,
  createAlertStore, createDelivery, createGoogleReader, metricCount, logCount, pollSignals, reference};
