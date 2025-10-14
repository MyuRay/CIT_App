const functions = require("firebase-functions");
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

function getWebhook(kind) {
  // Priority: specific env -> generic env -> functions.config()
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
    config[kind + "_webhook_url"] ||
    config.webhook_url ||
    null
  );
}

async function postToDiscord(webhookUrl, payload) {
  if (!webhookUrl) {
    console.warn("No Discord webhook URL configured. Skipping message.");
    return;
  }
  try {
    await axios.post(webhookUrl, payload, { timeout: 8000 });
  } catch (err) {
    console.error("Failed to post to Discord:", err?.response?.status || err?.message);
  }
}

function embed({ title, description, color = 0x2f3136, fields = [], url, timestamp = new Date().toISOString() }) {
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

exports.notifyUserCreated = onDocumentCreated("users/{uid}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const data = snap.data() || {};
  const name = data.displayName || "（不明）";
  const email = data.email || "（未設定）";
  const uid = event.params.uid;

  const payload = embed({
    title: "🆕 新規ユーザー登録",
    description: `ユーザーが新規登録しました。`,
    color: 0x57f287,
    fields: [
      { name: "名前", value: name, inline: true },
      { name: "メール", value: email, inline: true },
      { name: "UID", value: uid, inline: false },
    ],
  });
  await postToDiscord(getWebhook("users"), payload);
});

exports.notifyContactCreated = onDocumentCreated("contact_forms/{id}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const c = snap.data() || {};
  const subject = c.subject || "件名なし";
  const category = c.categoryName || c.category || "未分類";
  const userId = c.userId || "unknown";
  const email = c.email || "（未設定）";

  const payload = embed({
    title: "📩 新しいお問い合わせ",
    description: "新しいお問い合わせが届きました。",
    color: 0x5865f2,
    fields: [
      { name: "カテゴリ", value: String(category), inline: true },
      { name: "件名", value: String(subject), inline: true },
      { name: "ユーザーID", value: String(userId), inline: true },
      { name: "メール", value: String(email), inline: true },
      { name: "ドキュメントID", value: event.params.id, inline: false },
    ],
  });
  await postToDiscord(getWebhook("contacts"), payload);
});

// 掲示板: 申請（承認待ち）で通知
exports.notifyBulletinSubmitted = onDocumentCreated("bulletin_posts/{id}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const p = snap.data() || {};
  const status = (p.approvalStatus || "pending").toString();
  if (status !== "pending") return;

  const title = p.title || "無題";
  const author = p.authorName || p.authorId || "不明";
  const categoryName = p.category?.name || p.categoryName || p.category?.id || "未分類";

  const payload = embed({
    title: "📝 掲示板 申請が届きました（承認待ち）",
    description: "新しい掲示板投稿の申請があります。",
    color: 0xfee75c,
    fields: [
      { name: "タイトル", value: String(title), inline: true },
      { name: "カテゴリ", value: String(categoryName), inline: true },
      { name: "申請者", value: String(author), inline: true },
      { name: "ドキュメントID", value: event.params.id, inline: false },
    ],
  });
  await postToDiscord(getWebhook("bulletin"), payload);
});

// 既存投稿で承認状態が pending に変わったら通知
exports.notifyBulletinPendingOnUpdate = onDocumentUpdated("bulletin_posts/{id}", async (event) => {
  const before = event.data?.before?.data() || {};
  const after = event.data?.after?.data() || {};

  const prev = (before.approvalStatus || "").toString();
  const curr = (after.approvalStatus || "").toString();

  // または pinRequested が false -> true も通知
  const prevPin = !!before.pinRequested;
  const currPin = !!after.pinRequested;

  const becamePending = prev !== "pending" && curr === "pending";
  const becamePinRequested = !prevPin && currPin;

  if (!becamePending && !becamePinRequested) return;

  const title = after.title || "無題";
  const author = after.authorName || after.authorId || "不明";
  const categoryName = after.category?.name || after.categoryName || after.category?.id || "未分類";

  const payload = embed({
    title: becamePinRequested
      ? "📌 掲示板 ピン留め申請"
      : "📝 掲示板 申請が届きました（承認待ち）",
    description: becamePinRequested
      ? "掲示板投稿でピン留め申請が行われました。"
      : "掲示板投稿の承認待ちが設定されました。",
    color: 0xfaa81a,
    fields: [
      { name: "タイトル", value: String(title), inline: true },
      { name: "カテゴリ", value: String(categoryName), inline: true },
      { name: "申請者", value: String(author), inline: true },
      { name: "ドキュメントID", value: event.params.id, inline: false },
    ],
  });

  await postToDiscord(getWebhook("bulletin"), payload);
});
