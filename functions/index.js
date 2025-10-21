const functions = require('firebase-functions');
const {setGlobalOptions} = require('firebase-functions/v2');
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

// 優先順位: functions:config().app.region → env(FUNCTIONS_REGION / FUNCTION_REGION) → us-central1
const REGION = (
  (functions.config && functions.config().app && functions.config().app.region) ||
  process.env.FUNCTIONS_REGION ||
  process.env.FUNCTION_REGION ||
  'us-central1'
);

setGlobalOptions({region: REGION});

function getWebhook(kind) {
  // 優先順位: 種類別 env → 共通 env → functions.config()
  const envKey = {
    users: process.env.DISCORD_WEBHOOK_URL_USERS,
    contacts: process.env.DISCORD_WEBHOOK_URL_CONTACTS,
    bulletin: process.env.DISCORD_WEBHOOK_URL_BULLETIN,
  };
  const generic = process.env.DISCORD_WEBHOOK_URL;
  const config = (functions.config && functions.config().discord) || {};

  return (
    envKey[kind] ||
    generic ||
    config[`${kind}_webhook_url`] ||
    config.webhook_url ||
    null
  );
}

async function postToDiscord(webhookUrl, payload) {
  if (!webhookUrl) {
    console.warn('No Discord webhook URL configured. Skipping message.');
    return;
  }
  try {
    await axios.post(webhookUrl, payload, {timeout: 8000});
  } catch (err) {
    console.error('Failed to post to Discord:', err?.response?.status || err?.message);
  }
}

function embed({
  title,
  description,
  color = 0x2f3136,
  fields = [],
  url,
  timestamp = new Date().toISOString(),
}) {
  return {
    embeds: [
      {
        title,
        description,
        color,
        url,
        fields,
        timestamp,
      },
    ],
  };
}

exports.notifyUserCreated = onDocumentCreated('users/{uid}', async (event) => {
  const snap = event.data;
  if (!snap) return;

  const data = snap.data() || {};
  const name = data.displayName || '（未設定）';
  const email = data.email || '（未設定）';
  const uid = event.params.uid;

  const payload = embed({
    title: '🆕 新規ユーザー登録',
    description: '新しいユーザーが登録されました。',
    color: 0x57f287,
    fields: [
      {name: '名前', value: String(name), inline: true},
      {name: 'メール', value: String(email), inline: true},
      {name: 'UID', value: String(uid), inline: false},
    ],
  });

  await postToDiscord(getWebhook('users'), payload);
});

exports.notifyContactCreated = onDocumentCreated('contact_forms/{id}', async (event) => {
  const snap = event.data;
  if (!snap) return;

  const c = snap.data() || {};
  const subject = c.title || c.subject || '（未設定）';
  const category = c.categoryName || c.category || '未分類';
  const userId = c.userId || 'unknown';
  const email = c.userEmail || c.email || '（未設定）';

  const payload = embed({
    title: '📮 新しいお問い合わせ',
    description: 'お問い合わせフォームへの投稿がありました。',
    color: 0x5865f2,
    fields: [
      {name: 'カテゴリー', value: String(category), inline: true},
      {name: '件名', value: String(subject), inline: true},
      {name: 'ユーザーID', value: String(userId), inline: true},
      {name: 'メール', value: String(email), inline: true},
      {name: 'ドキュメントID', value: event.params.id, inline: false},
    ],
  });

  await postToDiscord(getWebhook('contacts'), payload);
});

// 掲示板: 提出時（承認待ち）に通知
exports.notifyBulletinSubmitted = onDocumentCreated('bulletin_posts/{id}', async (event) => {
  const snap = event.data;
  if (!snap) return;

  const p = snap.data() || {};
  const status = (p.approvalStatus || 'pending').toString();
  if (status !== 'pending') return;

  const title = p.title || '（無題）';
  const author = p.authorName || p.authorId || '匿名';
  const categoryName = p.category?.name || p.categoryName || p.category?.id || '未分類';

  const payload = embed({
    title: '📰 掲示板投稿が承認待ち',
    description: '新しい掲示板投稿が承認待ちとして提出されました。',
    color: 0xfee75c,
    fields: [
      {name: 'タイトル', value: String(title), inline: true},
      {name: 'カテゴリー', value: String(categoryName), inline: true},
      {name: '投稿者', value: String(author), inline: true},
      {name: 'ドキュメントID', value: event.params.id, inline: false},
    ],
  });

  await postToDiscord(getWebhook('bulletin'), payload);
});

// 掲示板: 承認ステータスが pending になった／ピン留め依頼が入ったら通知
exports.notifyBulletinPendingOnUpdate = onDocumentUpdated('bulletin_posts/{id}', async (event) => {
  const before = event.data?.before?.data() || {};
  const after = event.data?.after?.data() || {};

  const prevStatus = (before.approvalStatus || '').toString();
  const currStatus = (after.approvalStatus || '').toString();

  const prevPin = !!before.pinRequested;
  const currPin = !!after.pinRequested;

  const becamePending = prevStatus !== 'pending' && currStatus === 'pending';
  const becamePinRequested = !prevPin && currPin;

  if (!becamePending && !becamePinRequested) return;

  const title = after.title || '（無題）';
  const author = after.authorName || after.authorId || '匿名';
  const categoryName = after.category?.name || after.categoryName || after.category?.id || '未分類';

  const payload = embed({
    title: becamePinRequested
      ? '📌 掲示板のピン留め申請'
      : '📰 掲示板投稿が承認待ちに変更',
    description: becamePinRequested
      ? '掲示板投稿にピン留めのリクエストが入りました。'
      : '掲示板投稿の承認ステータスが pending になりました。',
    color: 0xfaa81a,
    fields: [
      {name: 'タイトル', value: String(title), inline: true},
      {name: 'カテゴリー', value: String(categoryName), inline: true},
      {name: '投稿者', value: String(author), inline: true},
      {name: 'ドキュメントID', value: event.params.id, inline: false},
    ],
  });

  await postToDiscord(getWebhook('bulletin'), payload);
});
