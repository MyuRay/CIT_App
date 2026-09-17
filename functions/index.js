const functions = require('firebase-functions');
const {setGlobalOptions} = require('firebase-functions/v2');
const {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentWritten,
} = require('firebase-functions/v2/firestore');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {onRequest} = require('firebase-functions/v2/https');
const {createTrainInfoHandler} = require('./train_info');
const admin = require('firebase-admin');
const axios = require('axios');
const cheerio = require('cheerio');

admin.initializeApp();
const {createAdminAuthorizer, retiredBulkVerification} = require('./admin_http');
const {getUserTokenEntries, removeInvalidToken} = require('./device_tokens');
const authorizeAdmin = createAdminAuthorizer({auth: admin.auth(), firestore: admin.firestore()});

// 優先順位: env(FUNCTIONS_REGION / FUNCTION_REGION) → us-central1
const REGION = (
  process.env.FUNCTIONS_REGION ||
  process.env.FUNCTION_REGION ||
  'us-central1'
);

setGlobalOptions({region: REGION});

const {beforeUserCreated} = require('firebase-functions/v2/identity');
const {requireVerifiedRegistration} = require('./verified_registration');
exports.requireVerifiedEmailBeforeCreate = beforeUserCreated(requireVerifiedRegistration);

const {JOBS: DELETION_JOBS, createDeletionApi, createDeletionWorker} = require('./account_deletion');
const deletionWorker = createDeletionWorker({auth: admin.auth(), db: admin.firestore(), bucket: admin.storage().bucket()});
exports.deleteMyAccount = onRequest({timeoutSeconds: 60, cors: true},
    createDeletionApi({auth: admin.auth(), db: admin.firestore()}));
exports.processAccountDeletion = onDocumentCreated({document: `${DELETION_JOBS}/{uid}`, retry: true, timeoutSeconds: 540, memory: '512MiB'},
    event => deletionWorker(event.params.uid));
exports.retryAccountDeletions = onSchedule({schedule: 'every 15 minutes', timeoutSeconds: 540, memory: '512MiB'}, async () => {
  const jobs = await admin.firestore().collection(DELETION_JOBS).where('status', 'in', ['queued', 'retry', 'running']).limit(10).get();
  for (const job of jobs.docs) {
    try { await deletionWorker(job.id); } catch (_) { console.error('Account deletion will retry'); }
  }
  // Keep the write-denial tombstone beyond the lifetime of any old ID token.
  const expired = await admin.firestore().collection(DELETION_JOBS)
      .where('completedAt', '<', admin.firestore.Timestamp.fromMillis(Date.now() - 7 * 86400000)).limit(100).get();
  for (const job of expired.docs) await admin.firestore().recursiveDelete(job.ref);
});

const {syncFavoriteCounts} = require('./cafeteria_favorites');
exports.syncCafeteriaFavoriteCounts = onDocumentWritten({
  document: 'users/{userId}/cafeteria_favorites/{favoriteId}',
  retry: true,
}, event => syncFavoriteCounts(admin.firestore(), event.data?.before.data(), event.data?.after.data()));

exports.syncCafeteriaMenuFavoriteCounts = onDocumentWritten({
  document: 'cafeteria_menu_items/{menuItemId}',
  retry: true,
}, event => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (before && after && before.menuName === after.menuName && before.cafeteriaId === after.cafeteriaId) return;
  const target = data => data ? {...data, type: 'menu', menuItemId: event.params.menuItemId} : undefined;
  return syncFavoriteCounts(admin.firestore(), target(before), target(after));
});

function pickWebhookUrl(...candidates) {
  for (const candidate of candidates) {
    const value = String(candidate || '').trim();
    if (value.startsWith('https://')) return value;
  }
  return null;
}

function getWebhook(kind) {
  // 優先順位: 種類別 env → 共通 env
  const envKey = {
    users: process.env.DISCORD_WEBHOOK_URL_USERS,
    contacts: process.env.DISCORD_WEBHOOK_URL_CONTACTS,
    bulletin: process.env.DISCORD_WEBHOOK_URL_BULLETIN,
    menu: process.env.DISCORD_WEBHOOK_URL_MENU,
    menu_image: process.env.DISCORD_WEBHOOK_URL_MENU_IMAGE,
    review: process.env.DISCORD_WEBHOOK_URL_REVIEW,
    report: process.env.DISCORD_WEBHOOK_URL_REPORT,
    coupon: process.env.DISCORD_WEBHOOK_URL_COUPON,
    comment: process.env.DISCORD_WEBHOOK_URL_COMMENT,
    cwitter: process.env.DISCORD_WEBHOOK_URL_CWITTER,
    chiba_channel_thread: process.env.DISCORD_WEBHOOK_URL_CHIBA_CHANNEL_THREAD,
    chiba_channel_reply: process.env.DISCORD_WEBHOOK_URL_CHIBA_CHANNEL_REPLY,
  };
  const generic = process.env.DISCORD_WEBHOOK_URL;

  const url = pickWebhookUrl(envKey[kind], generic);
  if (!url) {
    console.warn(`No Discord webhook URL configured for kind="${kind}".`);
  }
  return url;
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

// メールアドレスをマスクする関数（@前の最初の3文字だけ表示、残りは*で表示）
function maskEmail(email) {
  if (!email || email === '（未設定）' || !email.includes('@')) {
    return email;
  }
  const [localPart, domain] = email.split('@');
  if (localPart.length <= 3) {
    return email; // 3文字以下の場合はそのまま
  }
  const visiblePart = localPart.substring(0, 3);
  const maskedPart = '*'.repeat(localPart.length - 3);
  return `${visiblePart}${maskedPart}@${domain}`;
}

function clampDiscordText(text, maxLen = 1024) {
  const value = String(text ?? '').trim() || '（なし）';
  if (value.length <= maxLen) return value;
  return `${value.substring(0, maxLen - 3)}...`;
}

function truncatePreview(text, maxLen = 40) {
  const value = String(text ?? '').trim();
  if (!value) return '';
  if (value.length <= maxLen) return value;
  return `${value.substring(0, maxLen)}…`;
}

function normalizeCwitterId(raw) {
  return String(raw ?? '').trim().toLowerCase();
}

async function createInAppNotification(notification) {
  try {
    await admin.firestore().collection('notifications').add({
      ...notification,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
    });
    console.log(`アプリ内通知を作成: ${notification.type} -> ${notification.userId}`);
  } catch (error) {
    console.error('アプリ内通知の作成に失敗:', error);
  }
}

async function fetchCwitterUserProfile(userId) {
  if (!userId) return null;
  try {
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) return null;
    const data = userDoc.data() || {};
    const displayName = String(data.displayName || '').trim();
    const cwitterId = normalizeCwitterId(data.cwitterId);
    if (!displayName || !cwitterId) return null;
    return {displayName, cwitterId};
  } catch (error) {
    console.error(`Cwitterユーザープロフィール取得に失敗 (${userId}):`, error);
    return null;
  }
}

function parseCwitterImageUrls(raw) {
  if (!Array.isArray(raw)) return [];
  return raw
      .map((item) => String(item || '').trim())
      .filter((url) => url.startsWith('http'))
      .slice(0, 4);
}

function buildCwitterPollField(post) {
  const poll = post.poll;
  if (!poll || !Array.isArray(poll.options) || poll.options.length < 2) {
    return null;
  }
  const pollLines = poll.options
      .map((option, index) => `${index + 1}. ${option.text || '（未設定）'}`)
      .join('\n');
  return {
    name: '投票',
    value: clampDiscordText(pollLines, 1024),
    inline: false,
  };
}

function buildCwitterEntityEmbed({title, color, entity, entityId}) {
  const displayName = entity.displayName || '匿名';
  const cwitterId = entity.cwitterId || 'unknown';
  const authorId = entity.authorId || 'unknown';
  const email = maskEmail(entity.authorEmail || '（未設定）');
  const body = (entity.body || '').trim();
  const profileImageUrl = (entity.profileImageUrl || '').trim();
  const imageUrls = parseCwitterImageUrls(entity.imageUrls);

  const description = body ||
    (imageUrls.length > 0 ? '（テキストなし・画像のみ）' : '（内容なし）');

  const itemEmbed = {
    title,
    description: clampDiscordText(description, 4096),
    color,
    fields: [
      {name: '投稿者', value: clampDiscordText(displayName, 256), inline: true},
      {name: 'Cwitter ID', value: clampDiscordText(`@${cwitterId}`, 256), inline: true},
      {name: 'メール', value: clampDiscordText(email, 256), inline: true},
      {name: 'UID', value: clampDiscordText(authorId, 1024), inline: false},
      {name: '投稿ID', value: clampDiscordText(entityId, 1024), inline: false},
    ],
    timestamp: new Date().toISOString(),
  };

  if (profileImageUrl.startsWith('http')) {
    itemEmbed.thumbnail = {url: profileImageUrl};
  }

  if (imageUrls.length > 0) {
    itemEmbed.fields.push({
      name: '添付画像',
      value: clampDiscordText(`${imageUrls.length}枚`, 1024),
      inline: true,
    });
  }

  const pollField = buildCwitterPollField(entity);
  if (pollField) {
    itemEmbed.fields.push(pollField);
  }

  return {embed: itemEmbed, imageUrls};
}

function appendCwitterImageEmbeds(embeds, imageUrls, color, labelPrefix) {
  for (let i = 0; i < imageUrls.length; i++) {
    embeds.push({
      title: `📷 ${labelPrefix} ${i + 1}/${imageUrls.length}`,
      color,
      image: {url: imageUrls[i]},
      timestamp: new Date().toISOString(),
    });
  }
}

function buildCwitterPostDiscordPayload(post, postId) {
  const {embed, imageUrls} = buildCwitterEntityEmbed({
    title: '🐦 新規Cweet',
    color: 0x4caf50,
    entity: post,
    entityId: postId,
  });

  const embeds = [embed];
  appendCwitterImageEmbeds(embeds, imageUrls, 0x4caf50, '添付画像');
  return {embeds: embeds.slice(0, 10)};
}

function buildCwitterReplyDiscordPayload({
  originalPost,
  originalPostId,
  targetPost,
  targetPostId,
  reply,
  replyId,
}) {
  const embeds = [];

  const original = buildCwitterEntityEmbed({
    title: '📌 元Cweet',
    color: 0x4caf50,
    entity: originalPost,
    entityId: originalPostId,
  });
  embeds.push(original.embed);

  const target = buildCwitterEntityEmbed({
    title: '↩️ 返信先Cweet',
    color: 0xff9800,
    entity: targetPost,
    entityId: targetPostId,
  });
  embeds.push(target.embed);

  const replyEmbed = buildCwitterEntityEmbed({
    title: '💬 返信Cweet',
    color: 0x2196f3,
    entity: reply,
    entityId: replyId,
  });
  embeds.push(replyEmbed.embed);

  appendCwitterImageEmbeds(
      embeds,
      original.imageUrls,
      0x4caf50,
      '元Cweetの画像',
  );

  if (targetPostId !== originalPostId) {
    appendCwitterImageEmbeds(
        embeds,
        target.imageUrls,
        0xff9800,
        '返信先Cweetの画像',
    );
  }

  return {embeds: embeds.slice(0, 10)};
}

exports.notifyUserCreated = onDocumentCreated('users/{uid}', async (event) => {
  const snap = event.data;
  if (!snap) return;

  const data = snap.data() || {};
  const name = data.displayName || '（未設定）';
  const email = data.email || '（未設定）';
  const maskedEmail = maskEmail(email);
  const uid = event.params.uid;

  const payload = embed({
    title: '🆕 新規ユーザー登録',
    description: '新しいユーザーが登録されました。',
    color: 0x57f287,
    fields: [
      {name: '名前', value: String(name), inline: true},
      {name: 'メール', value: String(maskedEmail), inline: true},
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

  const prevCouponUsedCount = before.couponUsedCount || 0;
  const currCouponUsedCount = after.couponUsedCount || 0;
  const couponUsed = prevCouponUsedCount < currCouponUsedCount;

  const becamePending = prevStatus !== 'pending' && currStatus === 'pending';
  const becamePinRequested = !prevPin && currPin;
  const becameApproved = prevStatus !== 'approved' && currStatus === 'approved';

  if (!becamePending && !becamePinRequested && !becameApproved && !couponUsed) return;

  const title = after.title || '（無題）';
  const author = after.authorName || after.authorId || '匿名';
  const categoryName = after.category?.name || after.categoryName || after.category?.id || '未分類';

  // クーポン利用の通知
  if (couponUsed && after.isCoupon) {
    // 使用したユーザーIDを取得（couponUsedByから最新の変更を検出）
    const prevUsedBy = before.couponUsedBy || {};
    const currUsedBy = after.couponUsedBy || {};
    
    // 新しく追加されたユーザーまたは使用回数が増えたユーザーを検出
    let usedByUserId = '不明';
    for (const [userId, count] of Object.entries(currUsedBy)) {
      const prevCount = prevUsedBy[userId] || 0;
      if (count > prevCount) {
        usedByUserId = userId;
        break;
      }
    }
    
    // ユーザー名を取得
    let usedByUserName = '不明';
    try {
      if (usedByUserId !== '不明') {
        const userDoc = await admin.firestore().collection('users').doc(usedByUserId).get();
        if (userDoc.exists) {
          usedByUserName = userDoc.data()?.displayName || usedByUserId;
        }
      }
    } catch (error) {
      console.error('ユーザー情報の取得に失敗:', error);
    }

    const payload = embed({
      title: '🎫 クーポンが使用されました',
      description: '掲示板のクーポンが使用されました。',
      color: 0x57f287,
      fields: [
        {name: 'タイトル', value: String(title), inline: true},
        {name: 'カテゴリー', value: String(categoryName), inline: true},
        {name: '投稿者', value: String(author), inline: true},
        {name: '使用したユーザー', value: String(usedByUserName), inline: true},
        {name: '使用回数', value: `${currCouponUsedCount}回`, inline: true},
        {name: 'ドキュメントID', value: event.params.id, inline: false},
      ],
    });

    await postToDiscord(getWebhook('coupon'), payload);
  }

  // Discord通知
  if (becamePending || becamePinRequested) {
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
  }

  // 承認された場合、投稿者に個人通知を送る
  if (becameApproved && after.authorId) {
    try {
      await admin.firestore().collection('notifications').add({
        userId: after.authorId,
        type: 'post_approved',
        title: '掲示板投稿が承認されました',
        message: `「${title}」が承認されました`,
        postId: event.params.id,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
      });
      console.log(`承認通知を送信: ユーザー ${after.authorId}, 投稿 ${event.params.id}`);
    } catch (error) {
      console.error('承認通知の送信に失敗:', error);
    }
  }
});

// 掲示板コメント: 作成時に通知
exports.notifyBulletinCommentCreated = onDocumentCreated('bulletin_comments/{id}', async (event) => {
  const snap = event.data;
  if (!snap) return;

  const comment = snap.data() || {};
  const postId = comment.postId;
  const authorName = comment.authorName || comment.authorId || '匿名';
  const content = comment.content || '（内容なし）';
  const isReply = !!comment.parentCommentId;

  // 投稿情報を取得
  let postTitle = '（タイトル不明）';
  let postAuthor = '（投稿者不明）';
  try {
    if (postId) {
      const postDoc = await admin.firestore().collection('bulletin_posts').doc(postId).get();
      if (postDoc.exists) {
        const postData = postDoc.data();
        postTitle = postData?.title || '（タイトル不明）';
        postAuthor = postData?.authorName || postData?.authorId || '（投稿者不明）';
      }
    }
  } catch (error) {
    console.error('投稿情報の取得に失敗:', error);
  }

  // コメント内容を100文字に制限（長すぎる場合）
  const displayContent = content.length > 100 ? content.substring(0, 100) + '...' : content;

  const payload = embed({
    title: isReply ? '💬 掲示板に返信がつきました' : '💬 掲示板にコメントがつきました',
    description: isReply 
      ? '掲示板の投稿に返信が投稿されました。'
      : '掲示板の投稿にコメントが投稿されました。',
    color: 0x5865f2,
    fields: [
      {name: '投稿タイトル', value: String(postTitle), inline: false},
      {name: '投稿者', value: String(postAuthor), inline: true},
      {name: 'コメント投稿者', value: String(authorName), inline: true},
      {name: 'コメント内容', value: String(displayContent), inline: false},
      {name: '投稿ID', value: String(postId), inline: false},
      {name: 'コメントID', value: event.params.id, inline: false},
    ],
  });

  await postToDiscord(getWebhook('comment'), payload);
});

// Cwitter: 新規Cweet作成時にDiscord通知
exports.notifyCwitterPostCreated = onDocumentCreated('cwitter_posts/{id}', async (event) => {
  const snap = event.data;
  if (!snap) return;

  const post = snap.data() || {};
  const payload = buildCwitterPostDiscordPayload(post, event.params.id);
  await postToDiscord(getWebhook('cwitter'), payload);
});

// Cwitter: 返信作成時にDiscord通知
exports.notifyCwitterReplyCreated = onDocumentCreated(
    'cwitter_posts/{postId}/replies/{replyId}',
    async (event) => {
      const replySnap = event.data;
      if (!replySnap) return;

      const reply = replySnap.data() || {};
      const originalPostId = event.params.postId;
      const replyId = event.params.replyId;

      let originalPost = {};
      try {
        const postDoc = await admin.firestore()
            .collection('cwitter_posts')
            .doc(originalPostId)
            .get();
        if (postDoc.exists) {
          originalPost = postDoc.data() || {};
        }
      } catch (error) {
        console.error('元Cweetの取得に失敗:', error);
      }

      const payload = buildCwitterReplyDiscordPayload({
        originalPost,
        originalPostId,
        targetPost: originalPost,
        targetPostId: originalPostId,
        reply,
        replyId,
      });
      await postToDiscord(getWebhook('cwitter'), payload);

      const replyAuthorId = String(reply.authorId || '').trim();
      const postAuthorId = String(originalPost.authorId || '').trim();
      if (replyAuthorId && postAuthorId && replyAuthorId !== postAuthorId) {
        const fromUserName = String(reply.displayName || '匿名').trim() || '匿名';
        const fromCwitterId = normalizeCwitterId(reply.cwitterId) || 'unknown';
        const preview = truncatePreview(originalPost.body, 40);
        const suffix = preview ? `「${preview}」` : '';
        await createInAppNotification({
          userId: postAuthorId,
          type: 'reply',
          title: 'Cwitterに返信がありました',
          message:
            `${fromUserName} (@${fromCwitterId}) さんがあなたのCweetに返信しました${suffix}`,
          postId: originalPostId,
          commentId: replyId,
          fromUserId: replyAuthorId,
          fromUserName,
          data: {source: 'cwitter'},
        });
      }
    },
);

// Cwitter: いいね時にアプリ内通知
exports.notifyCwitterLikeCreated = onDocumentCreated(
    'users/{userId}/cwitter_likes/{postId}',
    async (event) => {
      const likerId = event.params.userId;
      const postId = event.params.postId;

      let postAuthorId = '';
      let postBody = '';
      try {
        const postDoc = await admin.firestore()
            .collection('cwitter_posts')
            .doc(postId)
            .get();
        if (!postDoc.exists) return;
        const postData = postDoc.data() || {};
        postAuthorId = String(postData.authorId || '').trim();
        postBody = String(postData.body || '');
      } catch (error) {
        console.error('いいね対象Cweetの取得に失敗:', error);
        return;
      }

      if (!postAuthorId || likerId === postAuthorId) return;

      const likerProfile = await fetchCwitterUserProfile(likerId);
      if (!likerProfile) return;

      const preview = truncatePreview(postBody, 40);
      const suffix = preview ? `「${preview}」` : '';
      await createInAppNotification({
        userId: postAuthorId,
        type: 'like',
        title: 'Cwitterにいいねがつきました',
        message:
          `${likerProfile.displayName} (@${likerProfile.cwitterId}) さんがあなたのCweetにいいねしました${suffix}`,
        postId,
        fromUserId: likerId,
        fromUserName: likerProfile.displayName,
        data: {source: 'cwitter'},
      });
    },
);

// Cwitter: フォロー時にアプリ内通知
exports.notifyCwitterFollowCreated = onDocumentCreated(
    'users/{followerId}/cwitter_following/{followeeId}',
    async (event) => {
      const snap = event.data;
      if (!snap) return;
      if (snap.data()?.suppressNotification === true) return;

      const followerId = event.params.followerId;
      const followeeId = event.params.followeeId;
      if (!followerId || !followeeId || followerId === followeeId) return;

      const followerProfile = await fetchCwitterUserProfile(followerId);
      if (!followerProfile) return;

      await createInAppNotification({
        userId: followeeId,
        type: 'follow',
        title: 'Cwitterでフォローされました',
        message:
          `${followerProfile.displayName} (@${followerProfile.cwitterId}) さんがあなたをフォローしました`,
        fromUserId: followerId,
        fromUserName: followerProfile.displayName,
        data: {
          source: 'cwitter',
          type: 'follow',
          fromCwitterId: followerProfile.cwitterId,
        },
      });
    },
);

// ちばちゃんねる: 新規スレッド作成時にDiscord通知
exports.notifyChibaChannelThreadCreated = onDocumentCreated(
    'chiba_channel_threads/{threadId}',
    async (event) => {
      const snap = event.data;
      if (!snap) return;

      const thread = snap.data() || {};
      const threadId = event.params.threadId;
      const title = thread.title || '（無題）';
      const category = thread.category || '未分類';
      const authorId = thread.authorId || 'unknown';
      const email = maskEmail(thread.authorEmail || '（未設定）');

      const payload = embed({
        title: '🧵 新規スレッド（ちばちゃんねる）',
        description: clampDiscordText(title, 4096),
        color: 0x9c27b0,
        fields: [
          {name: 'カテゴリ', value: clampDiscordText(category, 256), inline: true},
          {name: 'メール', value: clampDiscordText(email, 256), inline: true},
          {name: 'UID', value: clampDiscordText(authorId, 1024), inline: false},
          {name: 'スレッドID', value: clampDiscordText(threadId, 1024), inline: false},
        ],
      });

      await postToDiscord(getWebhook('chiba_channel_thread'), payload);
    },
);

// ちばちゃんねる: 新規レス作成時にDiscord通知
exports.notifyChibaChannelCommentCreated = onDocumentCreated(
    'chiba_channel_threads/{threadId}/comments/{commentId}',
    async (event) => {
      const snap = event.data;
      if (!snap) return;

      const comment = snap.data() || {};
      if (comment.isDeleted === true) return;

      const threadId = event.params.threadId;
      const commentId = event.params.commentId;
      const commentNumber = (comment.commentNumber ?? '?').toString();
      const anonymousId = comment.anonymousId || '--------';
      const body = (comment.body || '').trim();
      const imageUrls = parseCwitterImageUrls(comment.imageUrls);
      const email = maskEmail(comment.authorEmail || '（未設定）');
      const replyTo = comment.inReplyToCommentNumber != null
        ? `>>${comment.inReplyToCommentNumber}`
        : 'なし';

      let threadTitle = '（タイトル不明）';
      try {
        const threadDoc = await admin.firestore()
            .collection('chiba_channel_threads')
            .doc(threadId)
            .get();
        if (threadDoc.exists) {
          threadTitle = threadDoc.data()?.title || threadTitle;
        }
      } catch (error) {
        console.error('ちばちゃんねるスレッド取得に失敗:', error);
      }

      const description = body ||
        (imageUrls.length > 0 ? '（テキストなし・画像のみ）' : '（内容なし）');

      const fields = [
        {name: 'スレッド', value: clampDiscordText(threadTitle, 1024), inline: false},
        {name: 'レス番号', value: clampDiscordText(commentNumber, 256), inline: true},
        {name: 'ID', value: clampDiscordText(`ID:${anonymousId}`, 256), inline: true},
        {name: '返信先', value: clampDiscordText(replyTo, 256), inline: true},
        {name: 'メール', value: clampDiscordText(email, 256), inline: true},
        {name: 'スレッドID', value: clampDiscordText(threadId, 1024), inline: false},
        {name: 'レスID', value: clampDiscordText(commentId, 1024), inline: false},
      ];

      if (imageUrls.length > 0) {
        fields.push({
          name: '添付画像',
          value: clampDiscordText(`${imageUrls.length}枚`, 1024),
          inline: true,
        });
      }

      const payload = embed({
        title: `💬 新規レス #${commentNumber}（ちばちゃんねる）`,
        description: clampDiscordText(description, 4096),
        color: 0x7b1fa2,
        fields,
      });

      await postToDiscord(getWebhook('chiba_channel_reply'), payload);
    },
);

// 学食メニュー: 追加時に通知
exports.notifyMenuItemCreated = onDocumentCreated('cafeteria_menu_items/{id}', async (event) => {
  const snap = event.data;
  if (!snap) return;

  const item = snap.data() || {};
  const menuName = item.menuName || '（未設定）';
  const price = item.price != null ? `¥${item.price}` : '（価格未設定）';

  // cafeteriaId を日本語表記に変換
  const cafeteriaId = item.cafeteriaId || 'unknown';
  const cafeteriaMap = {
    'tsudanuma': '津田沼食堂',
    'narashino_1f': '新習志野1階食堂',
    'narashino_2f': '新習志野2階食堂',
  };
  const cafeteria = cafeteriaMap[cafeteriaId] || cafeteriaId;

  const payload = embed({
    title: '🍽️ 新しい学食メニューが追加されました',
    description: '学食に新メニューが追加されました。',
    color: 0xf26522,
    fields: [
      {name: 'メニュー名', value: String(menuName), inline: true},
      {name: '価格', value: String(price), inline: true},
      {name: '食堂', value: String(cafeteria), inline: true},
      {name: 'ドキュメントID', value: event.params.id, inline: false},
    ],
  });

  await postToDiscord(getWebhook('menu'), payload);
});

// 学食レビュー追加時のDiscord通知は廃止しました。
// 再開する場合はGitの履歴から `notifyReviewCreated` を復元し、デプロイしてください。

// 通報: 追加時に通知
exports.notifyReportCreated = onDocumentCreated('reports/{id}', async (event) => {
  const snap = event.data;
  if (!snap) return;

  const report = snap.data() || {};

  // 通報対象の種別を日本語に変換
  const typeMap = {
    'post': '投稿',
    'comment': 'コメント',
    'user': 'ユーザー',
  };
  const reportType = typeMap[report.type] || report.type || '不明';

  // 通報理由を日本語に変換
  const reasonMap = {
    'spam': 'スパム',
    'abuse': '誹謗中傷・嫌がらせ',
    'inappropriate': '不適切なコンテンツ',
    'other': 'その他',
  };
  const reason = reasonMap[report.reason] || report.reason || 'その他';

  const reporterName = report.reporterName || '匿名';
  const targetId = report.targetId || '不明';
  const detail = report.detail || '（詳細なし）';

  // 詳細が長すぎる場合は切り詰める
  const truncatedDetail = detail.length > 150
    ? detail.substring(0, 150) + '...'
    : detail;

  const payload = embed({
    title: '🚨 新しい通報がありました',
    description: 'ユーザーから通報が届きました。対応をお願いします。',
    color: 0xed4245,
    fields: [
      {name: '通報対象', value: String(reportType), inline: true},
      {name: '通報理由', value: String(reason), inline: true},
      {name: '通報者', value: String(reporterName), inline: true},
      {name: '対象ID', value: String(targetId), inline: false},
      {name: '詳細', value: String(truncatedDetail), inline: false},
      {name: 'ドキュメントID', value: event.params.id, inline: false},
    ],
  });

  await postToDiscord(getWebhook('report'), payload);
});

// 学食メニュー画像の自動更新（毎日 8:00 AM JST）
// 公式サイトは PDF (t.pdf / s1.pdf / s2.pdf) を公開 → 1ページ目を PNG 化して Storage へ保存
// 平日のみにしたい場合は schedule を '0 8 * * 1-5' に変更する
exports.updateMenuImagesDailyAt8AM = onSchedule({
  schedule: '0 8 * * *',
  timeZone: 'Asia/Tokyo',
  retryCount: 2,
  memory: '1GiB',
  timeoutSeconds: 300,
}, async (event) => {
  console.log('🍽️ 学食メニュー画像更新開始 (毎日 8:00 AM JST)');
  await updateMenuImages();
});

// 手動実行用（デバッグ/復旧用）
exports.updateMenuImagesNow = onRequest({
  memory: '1GiB',
  timeoutSeconds: 300,
}, async (req, res) => {
  if (!await authorizeAdmin(req, res)) return;

  try {
    const result = await updateMenuImages();
    res.status(200).json({ok: true, ...result});
  } catch (e) {
    console.error('❌ updateMenuImagesNow error:', e);
    res.status(500).json({
      ok: false,
      message: e?.message || String(e),
    });
  }
});

const MENU_PDF_FALLBACKS = {
  'td.png': 'https://www.cit-s.com/wp/wp-content/themes/cit/syokudo/t.pdf',
  'sd1.png': 'https://www.cit-s.com/wp/wp-content/themes/cit/syokudo/s1.pdf',
  'sd2.png': 'https://www.cit-s.com/wp/wp-content/themes/cit/syokudo/s2.pdf',
};

function resolveMenuStorageFileName(url) {
  const lower = String(url || '').toLowerCase();
  // 現行: 固定PDF名
  if (lower.endsWith('/t.pdf') || lower.includes('/syokudo/t.pdf')) return 'td.png';
  if (lower.endsWith('/s1.pdf') || lower.includes('/syokudo/s1.pdf')) return 'sd1.png';
  if (lower.endsWith('/s2.pdf') || lower.includes('/syokudo/s2.pdf')) return 'sd2.png';
  // 旧: 週次PNG名（互換）
  if (lower.includes('td_')) return 'td.png';
  if (lower.includes('sd1_')) return 'sd1.png';
  if (lower.includes('sd2_')) return 'sd2.png';
  return null;
}

function isPdfBuffer(buf) {
  if (!buf || buf.length < 5) return false;
  return buf.slice(0, 5).toString('utf8') === '%PDF-';
}

function isSupportedImageBuffer(buf) {
  if (!buf || buf.length < 12) return false;
  const isPng =
    buf[0] === 0x89 &&
    buf[1] === 0x50 &&
    buf[2] === 0x4e &&
    buf[3] === 0x47 &&
    buf[4] === 0x0d &&
    buf[5] === 0x0a &&
    buf[6] === 0x1a &&
    buf[7] === 0x0a;
  const isJpeg = buf[0] === 0xff && buf[1] === 0xd8;
  const isGif =
    buf[0] === 0x47 &&
    buf[1] === 0x49 &&
    buf[2] === 0x46 &&
    buf[3] === 0x38 &&
    (buf[4] === 0x37 || buf[4] === 0x39) &&
    buf[5] === 0x61;
  const isWebp =
    buf[0] === 0x52 &&
    buf[1] === 0x49 &&
    buf[2] === 0x46 &&
    buf[3] === 0x46 &&
    buf[8] === 0x57 &&
    buf[9] === 0x45 &&
    buf[10] === 0x42 &&
    buf[11] === 0x50;
  return isPng || isJpeg || isGif || isWebp;
}

async function convertPdfFirstPageToPng(pdfBuffer, {scale = 2} = {}) {
  const mupdf = await import('mupdf');
  const doc = mupdf.Document.openDocument(pdfBuffer, 'application/pdf');
  const pageCount = doc.countPages();
  if (pageCount < 1) {
    throw new Error('PDFにページがありません');
  }
  const page = doc.loadPage(0);
  const pixmap = page.toPixmap(
    mupdf.Matrix.scale(scale, scale),
    mupdf.ColorSpace.DeviceRGB,
    false,
    true,
  );
  const png = Buffer.from(pixmap.asPNG());
  if (!isSupportedImageBuffer(png)) {
    throw new Error('PDF→PNG変換結果のシグネチャ検証に失敗');
  }
  return png;
}

// 学食メニュー画像更新の実装
// 更新: 公式が週次PNG→固定PDF公開に変更したため、PDF 1ページ目を PNG 化して保存 (2026-08-03)
async function updateMenuImages() {
  try {
    const bucket = admin.storage().bucket();
    const uploadedImageUrls = {};

    console.log('🔍 学食ページからメニューPDF URLを取得中...');
    const diningPageUrl = 'https://www.cit-s.com/dining/';
    const requestHeaders = {
      'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
      'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'Accept-Language': 'ja,en-US;q=0.9,en;q=0.8',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };
    async function getWithRetry(url, {timeoutMs = 15000, retries = 3} = {}) {
      let lastErr;
      for (let i = 0; i < retries; i++) {
        try {
          return await axios.get(url, {
            timeout: timeoutMs,
            headers: requestHeaders,
            responseType: 'arraybuffer',
            validateStatus: (status) => status >= 200 && status < 400,
          });
        } catch (err) {
          lastErr = err;
          const delayMs = 1000 * Math.pow(2, i); // 1s, 2s, 4s...
          console.warn(
            `⚠️ fetch retry (${i + 1}/${retries}) failed: ${url} - ${err?.response?.status || err?.message || err}`,
          );
          await new Promise((r) => setTimeout(r, delayMs));
        }
      }
      throw lastErr;
    }

    const sourceByFile = {...MENU_PDF_FALLBACKS};
    try {
      const response = await getWithRetry(diningPageUrl, {timeoutMs: 20000, retries: 4});
      const html = Buffer.from(response.data).toString('utf8');
      const $ = cheerio.load(html);

      $('a[href]').each((_, elem) => {
        const href = $(elem).attr('href');
        if (!href) return;
        const fullUrl = href.startsWith('http') ? href : `https://www.cit-s.com${href}`;
        const fileName = resolveMenuStorageFileName(fullUrl);
        if (fileName) {
          sourceByFile[fileName] = fullUrl;
        }
      });

      // 旧PNG形式が残っている場合も拾う
      $('img[src]').each((_, elem) => {
        const src = $(elem).attr('src');
        if (!src) return;
        if (!src.includes('/menu/')) return;
        const fullUrl = src.startsWith('http') ? src : `https://www.cit-s.com${src}`;
        const fileName = resolveMenuStorageFileName(fullUrl);
        if (fileName) {
          sourceByFile[fileName] = fullUrl;
        }
      });
    } catch (scrapeErr) {
      console.warn(
        `⚠️ 学食ページのスクレイピングに失敗したため固定PDF URLを使用: ${scrapeErr?.message || scrapeErr}`,
      );
    }

    const entries = Object.entries(sourceByFile);
    console.log(
      `📷 ${entries.length} 件のメニューソースを使用:`,
      Object.fromEntries(entries),
    );

    if (entries.length === 0) {
      throw new Error('メニューPDF/画像URLが見つかりませんでした');
    }

    // ※既存ファイルは先に削除しない。取得に成功したものだけ上書きする
    for (const [newFileName, sourceUrl] of entries) {
      try {
        console.log(`📥 ダウンロード中: ${sourceUrl} -> ${newFileName}`);

        const sourceResponse = await getWithRetry(sourceUrl, {timeoutMs: 30000, retries: 4});
        const contentTypeHeader = String(
          sourceResponse?.headers?.['content-type'] || '',
        ).toLowerCase();
        const sourceBuffer = Buffer.from(sourceResponse.data);

        let imageBuffer;
        let contentType = 'image/png';

        if (
          contentTypeHeader.includes('application/pdf') ||
          sourceUrl.toLowerCase().endsWith('.pdf') ||
          isPdfBuffer(sourceBuffer)
        ) {
          if (!isPdfBuffer(sourceBuffer)) {
            throw new Error('PDFシグネチャ検証に失敗（壊れたレスポンスの可能性）');
          }
          console.log(`🖨️ PDF→PNG変換中: ${newFileName}`);
          imageBuffer = await convertPdfFirstPageToPng(sourceBuffer, {scale: 2});
        } else if (contentTypeHeader.startsWith('image/') || isSupportedImageBuffer(sourceBuffer)) {
          if (!isSupportedImageBuffer(sourceBuffer)) {
            throw new Error('画像シグネチャ検証に失敗（壊れたレスポンスの可能性）');
          }
          imageBuffer = sourceBuffer;
          contentType = contentTypeHeader.startsWith('image/')
            ? contentTypeHeader.split(';')[0].trim()
            : 'image/png';
        } else {
          throw new Error(
            `未対応のレスポンスを受信: content-type=${contentTypeHeader || 'unknown'}`,
          );
        }

        const file = bucket.file(`menu_images/${newFileName}`);
        await file.save(imageBuffer, {
          metadata: {
            contentType,
            metadata: {
              originalUrl: sourceUrl,
              uploadedAt: new Date().toISOString(),
              sourceType: sourceUrl.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image',
            },
          },
        });

        await file.makePublic();
        uploadedImageUrls[newFileName] = file.publicUrl();

        console.log(`✅ アップロード完了: ${newFileName} (${imageBuffer.length} bytes)`);
      } catch (imageError) {
        console.error(`❌ 画像処理エラー (${sourceUrl}):`, imageError.message);
      }
    }

    // Discordへ更新通知（画像付き）
    try {
      const menuWebhook = getWebhook('menu_image');
      const notifyEntries = [
        {key: 'td.png', label: '津田沼食堂'},
        {key: 'sd1.png', label: '新習志野食堂 1F'},
        {key: 'sd2.png', label: '新習志野食堂 2F'},
      ].filter((e) => !!uploadedImageUrls[e.key]);

      if (notifyEntries.length > 0) {
        const payload = {
          embeds: notifyEntries.map((entry) => ({
            title: `🍽️ 学食メニュー画像を更新しました（${entry.label}）`,
            description: '最新画像を保存しました。',
            color: 0x57f287,
            image: {url: uploadedImageUrls[entry.key]},
            fields: [
              {name: 'ファイル名', value: entry.key, inline: true},
              {name: 'URL', value: uploadedImageUrls[entry.key], inline: false},
            ],
            timestamp: new Date().toISOString(),
          })),
        };
        await postToDiscord(menuWebhook, payload);
      } else {
        console.warn('⚠️ Discord通知対象の画像URLがありませんでした');
      }
    } catch (notifyErr) {
      console.error('❌ 学食更新Discord通知エラー:', notifyErr);
    }

    if (Object.keys(uploadedImageUrls).length === 0) {
      throw new Error('メニュー画像のアップロードに1件も成功しませんでした');
    }

    console.log('🎉 学食メニュー画像の更新が完了しました');
    return {uploaded: uploadedImageUrls};
  } catch (error) {
    console.error('❌ 学食メニュー画像更新エラー:', error);
    throw error;
  }
}

const CLUB_SOURCE_URL = 'https://sites.google.com/view/cittaiiku2021hp/%E5%8A%A0%E7%9B%9F%E5%9B%A3%E4%BD%93%E4%B8%80%E8%A6%A7?authuser=0';
const CLUB_SITE_BASE_URL = 'https://sites.google.com/view/cittaiiku2021hp';

function normalizeText(value) {
  return String(value || '')
    .replace(/\u00a0/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function slugifyClubName(name) {
  return normalizeText(name)
    .toLowerCase()
    .replace(/[^a-z0-9\u3040-\u30ff\u3400-\u9fff]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 120) || `club-${Date.now()}`;
}

function parseClubCategory(rawHeading) {
  const heading = normalizeText(rawHeading);
  if (heading.includes('加盟団体(部)')) return 'club';
  if (heading.includes('加盟団体(同好会)')) return 'circle';
  if (heading.includes('加盟団体(愛好会)')) return 'association';
  return null;
}

function resolveAbsoluteUrl(href) {
  const raw = normalizeText(href);
  if (!raw) return null;
  try {
    return new URL(raw, CLUB_SITE_BASE_URL).toString();
  } catch (_) {
    return null;
  }
}

function extractClubDescriptionFromHtml(html) {
  const $ = cheerio.load(html);
  const candidates = [];
  $('main p, .UtePc, [role="main"] p').each((_, el) => {
    const text = normalizeText($(el).text());
    if (!text) return;
    if (text.length < 8) return;
    if (text.includes('Google Sites') || text.includes('Report abuse')) return;
    candidates.push(text);
  });
  if (candidates.length === 0) return null;
  return candidates[0].slice(0, 220);
}

function getHeadingNodes($) {
  return $('h1, h2, h3, h4, h5, h6, [role="heading"]').toArray();
}

function isKeywordMatch(text, keywords) {
  const lower = normalizeText(text).toLowerCase();
  if (!lower) return false;
  return keywords.some((keyword) => lower.includes(keyword.toLowerCase()));
}

function collectSectionTextFromHeading($, headingEl, maxNodes = 18) {
  const chunks = [];
  let node = $(headingEl).next();
  let guard = 0;
  while (node.length && guard < maxNodes) {
    const tag = (node.prop('tagName') || '').toLowerCase();
    const role = normalizeText(node.attr('role') || '').toLowerCase();
    if (/^h[1-6]$/.test(tag) || role === 'heading') break;
    const text = normalizeText(node.text());
    if (text) chunks.push(text);
    node = node.next();
    guard += 1;
  }
  return normalizeText(chunks.join(' ')).slice(0, 500);
}

function extractSectionText($, sectionKeywords, fallback = '') {
  const headings = getHeadingNodes($);
  for (const heading of headings) {
    const headingText = normalizeText($(heading).text());
    if (!isKeywordMatch(headingText, sectionKeywords)) continue;
    const sectionText = collectSectionTextFromHeading($, heading);
    if (sectionText) return sectionText;
  }
  return fallback;
}

function stripByKeywords(text, keywords) {
  const raw = normalizeText(text);
  if (!raw) return '';
  let cut = raw.length;
  for (const keyword of keywords) {
    const idx = raw.toLowerCase().indexOf(keyword.toLowerCase());
    if (idx > 0 && idx < cut) cut = idx;
  }
  return normalizeText(raw.slice(0, cut));
}

function extractContactInfo($, fromSectionText = '') {
  const contactBits = [];
  const seen = new Set();
  const pushUnique = (value) => {
    const normalized = normalizeText(value);
    if (!normalized) return;
    if (seen.has(normalized)) return;
    seen.add(normalized);
    contactBits.push(normalized);
  };

  if (fromSectionText) pushUnique(fromSectionText);

  $('a').each((_, el) => {
    const href = normalizeText($(el).attr('href'));
    const text = normalizeText($(el).text());
    if (!href && !text) return;
    if (
      href.startsWith('mailto:') ||
      href.startsWith('tel:') ||
      href.includes('instagram.com') ||
      href.includes('x.com') ||
      href.includes('twitter.com') ||
      href.includes('line.me') ||
      href.includes('facebook.com') ||
      href.includes('youtube.com') ||
      href.includes('forms.gle') ||
      href.includes('google.com/forms')
    ) {
      pushUnique(text || href);
      pushUnique(href);
    }
  });

  const bodyText = normalizeText($('main, [role="main"], body').first().text());
  const emails = bodyText.match(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi) || [];
  const phones = bodyText.match(/0\d{1,4}-\d{1,4}-\d{3,4}/g) || [];
  emails.forEach(pushUnique);
  phones.forEach(pushUnique);

  return normalizeText(contactBits.join(' / ')).slice(0, 500);
}

function extractImageUrls($, detailUrl) {
  const urls = [];
  const seen = new Set();
  const pushUrl = (candidate) => {
    const src = resolveAbsoluteUrl(candidate);
    if (!src) return;
    if (!(src.startsWith('https://') || src.startsWith('http://'))) return;
    const lower = src.toLowerCase();
    if (lower.includes('favicon') || lower.includes('logo')) return;
    if (!seen.has(src)) {
      seen.add(src);
      urls.push(src);
    }
  };

  $('img').each((_, el) => {
    pushUrl($(el).attr('src'));
    pushUrl($(el).attr('data-src'));
    pushUrl($(el).attr('data-image-url'));
    const srcset = normalizeText($(el).attr('srcset'));
    if (srcset) {
      srcset.split(',').forEach((entry) => pushUrl(entry.trim().split(' ')[0]));
    }
  });

  $('meta[property="og:image"], meta[name="og:image"], meta[name="twitter:image"]').each((_, el) => {
    pushUrl($(el).attr('content'));
  });

  $('[style*="background-image"]').each((_, el) => {
    const style = normalizeText($(el).attr('style'));
    const match = style.match(/url\((['"]?)(.*?)\1\)/i);
    if (match && match[2]) pushUrl(match[2]);
  });

  // 画像が見つからない場合でも詳細ページ自体は保持
  if (urls.length === 0 && detailUrl) {
    return [];
  }
  return urls.slice(0, 8);
}

async function fetchClubDescription(detailUrl) {
  if (!detailUrl) return null;
  try {
    const res = await axios.get(detailUrl, {timeout: 12000});
    const $ = cheerio.load(res.data);
    const fallback = extractClubDescriptionFromHtml(res.data) || '';
    let introduction = extractSectionText(
      $,
      ['introduction', '紹介', '概要', 'about'],
      fallback,
    );
    const information = extractSectionText(
      $,
      ['information', '活動', '活動内容', 'info', 'schedule'],
      '',
    );
    const contactSection = extractSectionText(
      $,
      ['contact', 'お問い合わせ', '連絡', '連絡先', 'sns'],
      '',
    );
    introduction = stripByKeywords(introduction, [
      'information',
      '活動',
      '活動内容',
      'contact',
      '連絡先',
      'お問い合わせ',
      'sns',
    ]);
    const contact = extractContactInfo($, contactSection);
    const imageUrls = extractImageUrls($, detailUrl);
    return {
      introduction,
      information,
      contact,
      imageUrls,
    };
  } catch (error) {
    console.warn(`Failed to fetch club detail: ${detailUrl} ${error?.message || ''}`);
    return null;
  }
}

function isValidClubLink(url) {
  return !!url && url.startsWith(CLUB_SITE_BASE_URL);
}

async function fetchCitSportsOrganizations() {
  const res = await axios.get(CLUB_SOURCE_URL, {timeout: 20000});
  const $ = cheerio.load(res.data);

  const linkCandidates = [];
  $('a').each((_, el) => {
    const text = normalizeText($(el).text());
    const href = resolveAbsoluteUrl($(el).attr('href'));
    if (!text || !href) return;
    if (!isValidClubLink(href)) return;
    linkCandidates.push({text, href});
  });

  const items = [];
  const seen = new Set();
  let currentCategory = null;

  $('h2, h3').each((_, el) => {
    const text = normalizeText($(el).text());
    const category = parseClubCategory(text);
    if (category) {
      currentCategory = category;
      return;
    }

    if (!currentCategory) return;
    if (!text) return;
    if (text.includes('加盟団体一覧') || text.includes('関連ページ')) return;

    const key = `${currentCategory}::${text}`;
    if (seen.has(key)) return;
    seen.add(key);

    const matchedLink = linkCandidates.find((candidate) => candidate.text === text);
    const detailUrl = matchedLink ? matchedLink.href : null;

    items.push({
      id: slugifyClubName(text),
      name: text,
      category: currentCategory,
      detailUrl,
    });
  });

  const enriched = [];
  for (const item of items) {
    const detailData = await fetchClubDescription(item.detailUrl);
    enriched.push({
      ...item,
      description: detailData?.introduction || '',
      introduction: detailData?.introduction || '',
      information: detailData?.information || '',
      contact: detailData?.contact || '',
      imageUrls: detailData?.imageUrls || [],
    });
  }
  return enriched;
}

async function syncClubOrganizations() {
  const clubs = await fetchCitSportsOrganizations();
  const db = admin.firestore();
  const syncedAt = admin.firestore.FieldValue.serverTimestamp();
  const source = 'cit_sports_hq_google_sites';

  const snapshot = await db.collection('club_organizations').get();
  const existingById = new Map(snapshot.docs.map((d) => [d.id, d]));
  const incomingIds = new Set(clubs.map((c) => c.id));

  const writes = [];
  for (const club of clubs) {
    writes.push(
      db.collection('club_organizations').doc(club.id).set({
        name: club.name,
        category: club.category,
        description: club.description || '',
        introduction: club.introduction || '',
        information: club.information || '',
        contact: club.contact || '',
        imageUrls: Array.isArray(club.imageUrls) ? club.imageUrls : [],
        detailUrl: club.detailUrl || '',
        source,
        sourceUrl: CLUB_SOURCE_URL,
        isActive: true,
        updatedAt: syncedAt,
      }, {merge: true}),
    );
  }

  for (const [docId, doc] of existingById.entries()) {
    if (!incomingIds.has(docId)) {
      writes.push(doc.ref.set({
        isActive: false,
        source,
        sourceUrl: CLUB_SOURCE_URL,
        updatedAt: syncedAt,
      }, {merge: true}));
    }
  }

  writes.push(
    db.collection('app_metadata').doc('club_organizations_sync').set({
      source,
      sourceUrl: CLUB_SOURCE_URL,
      fetchedCount: clubs.length,
      activeCount: clubs.length,
      updatedAt: syncedAt,
    }, {merge: true}),
  );

  await Promise.all(writes);
  return clubs.length;
}

// サークル・部活一覧の定期取得（毎日 4:30 JST）
exports.syncClubOrganizationsDaily = onSchedule({
  schedule: '30 4 * * *',
  timeZone: 'Asia/Tokyo',
}, async () => {
  try {
    const count = await syncClubOrganizations();
    console.log(`✅ club_organizations sync completed: ${count} records`);
  } catch (error) {
    console.error('❌ club_organizations sync error:', error);
    throw error;
  }
});

// 手動同期用HTTPエンドポイント（管理用途）
exports.syncClubOrganizationsNow = onRequest(async (req, res) => {
  if (!await authorizeAdmin(req, res, 'POST')) return;
  try {
    const count = await syncClubOrganizations();
    res.status(200).json({
      ok: true,
      fetchedCount: count,
      sourceUrl: CLUB_SOURCE_URL,
    });
  } catch (error) {
    console.error('❌ manual club sync error:', error);
    res.status(500).json({
      ok: false,
      message: error.message,
    });
  }
});

/** @returns {string|null} notificationPreferences のキー（プッシュ制御用） */
function preferenceKeyFromNotification(notification) {
  const type = String(notification.type || '');
  const data = notification.data && typeof notification.data === 'object'
    ? notification.data
    : {};

  switch (type) {
    case 'comment':
      if (data.source === 'chiba_channel') return 'chiba_channel_thread';
      return 'bulletin_comment';
    case 'reply':
      if (data.source === 'cwitter') return 'cwitter_reply';
      if (data.source === 'chiba_channel') return 'chiba_channel_comment_reply';
      return 'bulletin_reply';
    case 'like':
      return data.source === 'cwitter' ? 'cwitter_like' : null;
    case 'follow':
      return data.source === 'cwitter' ? 'cwitter_follow' : null;
    case 'post_approved':
    case 'post_rejected':
    case 'pin_approved':
    case 'pin_rejected':
      return 'bulletin_moderation';
    case 'general':
      return data.type === 'contact_response' ? 'contact_reply' : null;
    case 'app_update':
    case 'maintenance':
    case 'important':
    case 'feature':
    case 'system':
      return 'global_announcement';
    default:
      return null;
  }
}

/**
 * user_settings.notificationPreferences を参照（未設定はオン扱い）
 * @param {string} userId
 * @param {string} preferenceKey
 * @param {Map<string, object>|null} prefsCache
 */
async function isPushEnabledForUser(userId, preferenceKey, prefsCache = null) {
  if (!preferenceKey) return true;

  let prefs = prefsCache?.get(userId);
  if (prefs === undefined) {
    const settingsDoc = await admin.firestore()
      .collection('user_settings')
      .doc(userId)
      .get();
    prefs = settingsDoc.exists
      ? settingsDoc.data()?.notificationPreferences
      : null;
    if (prefsCache) prefsCache.set(userId, prefs);
  }

  if (!prefs || typeof prefs !== 'object') return true;
  const value = prefs[preferenceKey];
  return typeof value === 'boolean' ? value : true;
}

// 全体通知が作成されたら全ユーザーへプッシュ通知
exports.notifyGlobalNotificationCreated = onDocumentCreated('global_notifications/{id}', async (event) => {
  const snap = event.data;
  if (!snap) return;

  const notification = snap.data() || {};

  if (notification.isActive === false) {
    console.log('全体通知が非アクティブのためプッシュをスキップします');
    return;
  }

  const title = notification.title || 'CIT App';
  const body = notification.message || '新しいお知らせがあります';
  const type = notification.type || 'general';
  const url = notification.url || '';
  const version = notification.version || '';

  try {
    const tokensSnapshot = await admin.firestore()
      .collection('user_tokens')
      .get();

    if (tokensSnapshot.empty) {
      console.log('ユーザートークンが存在しないためプッシュを送信できません');
      return;
    }

    const settingsSnapshot = await admin.firestore()
      .collection('user_settings')
      .get();
    const prefsCache = new Map();
    settingsSnapshot.docs.forEach((doc) => {
      prefsCache.set(doc.id, doc.data()?.notificationPreferences ?? null);
    });

    const globalPrefKey = 'global_announcement';
    const tokenEntries = [];
    for (const doc of tokensSnapshot.docs) {
      const userId = doc.id;
      const pushEnabled = await isPushEnabledForUser(
        userId,
        globalPrefKey,
        prefsCache,
      );
      if (!pushEnabled) continue;
      tokenEntries.push(...await getUserTokenEntries(admin.firestore(), userId));
    }

    if (tokenEntries.length === 0) {
      console.log('プッシュ送信対象のFCMトークンがありません');
      return;
    }

    const chunkSize = 500;
    let successCount = 0;
    let failureCount = 0;

    for (let i = 0; i < tokenEntries.length; i += chunkSize) {
      const chunk = tokenEntries.slice(i, i + chunkSize);
      const message = {
        tokens: chunk.map((entry) => entry.token),
        notification: {
          title: String(title),
          body: String(body),
        },
        data: {
          type: String(type),
          globalNotificationId: event.params.id,
          url: String(url || ''),
          version: String(version || ''),
        },
        android: {
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      successCount += response.successCount;
      failureCount += response.failureCount;

      const cleanupPromises = response.responses.map(async (res, idx) => {
        if (!res.success) {
          const errorCode = res.error?.code;
          const userId = chunk[idx].userId;
          if (errorCode === 'messaging/invalid-registration-token' ||
              errorCode === 'messaging/registration-token-not-registered') {
            console.log(`無効なトークンを削除します: ${userId}`);
            await removeInvalidToken(admin.firestore(), chunk[idx], () => admin.firestore.FieldValue.delete());
          } else {
            console.error('Global push delivery failed', {code: errorCode});
          }
        }
      });

      await Promise.all(cleanupPromises);
    }

    console.log(`🌐 全体通知プッシュ送信完了: success=${successCount}, failure=${failureCount}`);
  } catch (error) {
    console.error('Global push processing failed', {code: error.code});
  }
});

// 個別通知ドキュメント作成時のプッシュ通知
exports.sendPushNotification = onDocumentCreated('notifications/{notificationId}', async (event) => {
  const snap = event.data;
  if (!snap) return;

  const notification = snap.data() || {};
  const userId = notification.userId;

  if (!userId) {
    console.warn('通知にuserIdがありません');
    return;
  }

  const preferenceKey = preferenceKeyFromNotification(notification);
  const pushEnabled = await isPushEnabledForUser(userId, preferenceKey);
  if (!pushEnabled) {
    console.log(
      `プッシュ通知をスキップ（ユーザー設定オフ）: ${preferenceKey} -> ${userId}`,
    );
    return;
  }

  try {
    const tokenEntries = await getUserTokenEntries(admin.firestore(), userId);
    if (tokenEntries.length === 0) return;

    // FCMメッセージを構築
    const message = {
      notification: {
        title: notification.title || 'CIT App',
        body: notification.message || notification.body || '',
      },
      data: {
        notificationId: event.params.notificationId,
        type: notification.type || 'general',
        source: String(notification.data?.source || ''),
        userId: String(userId),
        fromUserId: String(notification.fromUserId || ''),
        fromCwitterId: String(notification.data?.fromCwitterId || ''),
        postId: notification.postId || '',
        commentId: notification.commentId || '',
        replyId: notification.replyId || '',
      },
      android: {
        priority: 'high',
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };

    // プッシュ通知を送信
    for (const entry of tokenEntries) {
      try {
        await admin.messaging().send({...message, token: entry.token});
      } catch (error) {
        if (error.code === 'messaging/invalid-registration-token' ||
            error.code === 'messaging/registration-token-not-registered') {
          await removeInvalidToken(admin.firestore(), entry, () => admin.firestore.FieldValue.delete());
        } else {
          console.error('Push delivery failed', {code: error.code});
        }
      }
    }
  } catch (error) {
    console.error('Push processing failed', {code: error.code});
  }
});

// 最寄駅電車情報プロキシ（mock | static | odpt）
// GET ?campus=tsudanuma|narashino
// env: TRAIN_INFO_MODE=mock|static|odpt, ODPT_ACL_CONSUMER_KEY=...
exports.trainInfo = createTrainInfoHandler();

// ユーザー数推移を取得するCloud Function
exports.getUserGrowthStats = onRequest(async (req, res) => {
  if (!await authorizeAdmin(req, res, 'GET')) return;
  try {
    console.log('📊 ユーザー数推移の取得を開始...');

    // 全ユーザーを取得
    let allUsers = [];
    let nextPageToken;
    
    do {
      const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
      allUsers = allUsers.concat(listUsersResult.users);
      nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);

    console.log(`✅ 合計 ${allUsers.length} 人のユーザーを取得しました`);

    // 日付ごとに集計
    const dailyStats = {};
    const monthlyStats = {};

    allUsers.forEach((user) => {
      const creationTime = user.metadata.creationTime;
      if (!creationTime) return;

      const date = new Date(creationTime);
      
      // 日付ごとの集計（YYYY-MM-DD形式）
      const dateKey = date.toISOString().split('T')[0];
      dailyStats[dateKey] = (dailyStats[dateKey] || 0) + 1;

      // 月ごとの集計（YYYY-MM形式）
      const monthKey = date.toISOString().substring(0, 7);
      monthlyStats[monthKey] = (monthlyStats[monthKey] || 0) + 1;
    });

    // 日付順にソート
    const dailyArray = Object.entries(dailyStats)
      .map(([date, count]) => ({date, count}))
      .sort((a, b) => a.date.localeCompare(b.date));

    const monthlyArray = Object.entries(monthlyStats)
      .map(([month, count]) => ({month, count}))
      .sort((a, b) => a.month.localeCompare(b.month));

    // 累積ユーザー数を計算
    let cumulativeCount = 0;
    const dailyWithCumulative = dailyArray.map((item) => {
      cumulativeCount += item.count;
      return {
        ...item,
        cumulative: cumulativeCount,
      };
    });

    let monthlyCumulativeCount = 0;
    const monthlyWithCumulative = monthlyArray.map((item) => {
      monthlyCumulativeCount += item.count;
      return {
        ...item,
        cumulative: monthlyCumulativeCount,
      };
    });

    const result = {
      totalUsers: allUsers.length,
      daily: dailyWithCumulative,
      monthly: monthlyWithCumulative,
      generatedAt: new Date().toISOString(),
    };

    console.log(`✅ ユーザー数推移の取得が完了しました`);
    res.status(200).json(result);
  } catch (error) {
    console.error('❌ ユーザー数推移の取得エラー:', error);
    res.status(500).json({
      error: 'ユーザー数推移の取得に失敗しました',
      message: error.message,
    });
  }
});

// Retire the old URL without leaving a previously deployed function active.
exports.bulkVerifyExistingUsersNow = onRequest(retiredBulkVerification);
