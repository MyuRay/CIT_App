const functions = require('firebase-functions');
const {setGlobalOptions} = require('firebase-functions/v2');
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require('firebase-functions/v2/firestore');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');
const axios = require('axios');
const cheerio = require('cheerio');

admin.initializeApp();

// 優先順位: env(FUNCTIONS_REGION / FUNCTION_REGION) → us-central1
const REGION = (
  process.env.FUNCTIONS_REGION ||
  process.env.FUNCTION_REGION ||
  'us-central1'
);

setGlobalOptions({region: REGION});

function getWebhook(kind) {
  // 優先順位: 種類別 env → 共通 env
  const envKey = {
    users: process.env.DISCORD_WEBHOOK_URL_USERS,
    contacts: process.env.DISCORD_WEBHOOK_URL_CONTACTS,
    bulletin: process.env.DISCORD_WEBHOOK_URL_BULLETIN,
    menu: process.env.DISCORD_WEBHOOK_URL_MENU,
    review: process.env.DISCORD_WEBHOOK_URL_REVIEW,
    report: process.env.DISCORD_WEBHOOK_URL_REPORT,
  };
  const generic = process.env.DISCORD_WEBHOOK_URL;

  return (
    envKey[kind] ||
    generic ||
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
  const becameApproved = prevStatus !== 'approved' && currStatus === 'approved';

  if (!becamePending && !becamePinRequested && !becameApproved) return;

  const title = after.title || '（無題）';
  const author = after.authorName || after.authorId || '匿名';
  const categoryName = after.category?.name || after.categoryName || after.category?.id || '未分類';

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
        type: 'bulletin_approved',
        title: '掲示板投稿が承認されました',
        body: `「${title}」が承認されました`,
        postId: event.params.id,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      });
      console.log(`承認通知を送信: ユーザー ${after.authorId}, 投稿 ${event.params.id}`);
    } catch (error) {
      console.error('承認通知の送信に失敗:', error);
    }
  }
});

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

// 学食レビュー: 追加時に通知
exports.notifyReviewCreated = onDocumentCreated('cafeteria_reviews/{id}', async (event) => {
  const snap = event.data;
  if (!snap) return;

  const review = snap.data() || {};
  const menuName = review.menuItemName || review.menuName || '（メニュー不明）';
  const rating = review.rating != null ? `${review.rating}` : '評価なし';
  const reviewerName = review.userName || review.reviewerName || '匿名';
  const comment = review.comment || review.text || '（コメントなし）';

  // コメントが長すぎる場合は切り詰める
  const truncatedComment = comment.length > 100
    ? comment.substring(0, 100) + '...'
    : comment;

  const payload = embed({
    title: '⭐ 新しい学食レビューが投稿されました',
    description: '学食メニューに新しいレビューが追加されました。',
    color: 0xfee75c,
    fields: [
      {name: 'メニュー名', value: String(menuName), inline: true},
      {name: '評価', value: `${rating} / 5`, inline: true},
      {name: '投稿者', value: String(reviewerName), inline: true},
      {name: 'コメント', value: String(truncatedComment), inline: false},
      {name: 'ドキュメントID', value: event.params.id, inline: false},
    ],
  });

  await postToDiscord(getWebhook('review'), payload);
});

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

// 学食メニュー画像の自動更新（月曜日 1am JST）
exports.updateMenuImagesAt1AM = onSchedule({
  schedule: '0 1 * * 1',
  timeZone: 'Asia/Tokyo',
}, async (event) => {
  console.log('🍽️ 学食メニュー画像更新開始 (1:00 AM JST)');
  await updateMenuImages();
});

// 学食メニュー画像の自動更新（月曜日 8am JST）
exports.updateMenuImagesAt8AM = onSchedule({
  schedule: '0 8 * * 1',
  timeZone: 'Asia/Tokyo',
}, async (event) => {
  console.log('🍽️ 学食メニュー画像更新開始 (8:00 AM JST)');
  await updateMenuImages();
});

// 学食メニュー画像更新の実装
// 更新: 新習志野食堂のパターンをsd1, sd2に変更 (2025-11-07)
async function updateMenuImages() {
  try {
    const bucket = admin.storage().bucket();

    // 1. menu_images フォルダ内の全ファイルを削除
    console.log('📁 menu_images フォルダをクリア中...');
    const [files] = await bucket.getFiles({prefix: 'menu_images/'});

    if (files.length > 0) {
      await Promise.all(files.map((file) => file.delete()));
      console.log(`✅ ${files.length} 個のファイルを削除しました`);
    } else {
      console.log('📁 menu_images フォルダは空です');
    }

    // 2. https://www.cit-s.com/dining/ からメニュー画像URLをスクレイピング
    console.log('🔍 学食ページからメニュー画像URLを取得中...');
    const diningPageUrl = 'https://www.cit-s.com/dining/';
    const response = await axios.get(diningPageUrl, {timeout: 15000});
    const $ = cheerio.load(response.data);

    // 画像URLを抽出（td_YYYYMM_W.png, sd1_YYYYMM_W.png, sd2_YYYYMM_W.png パターン）
    const imageUrls = [];
    $('img').each((i, elem) => {
      const src = $(elem).attr('src');
      if (src && src.includes('/menu/') && (
        src.includes('td_') ||
        src.includes('sd1_') ||
        src.includes('sd2_')
      )) {
        // 相対URLを絶対URLに変換
        const fullUrl = src.startsWith('http') ? src : `https://www.cit-s.com${src}`;
        imageUrls.push(fullUrl);
      }
    });

    console.log(`📷 ${imageUrls.length} 個のメニュー画像URLを発見:`, imageUrls);

    if (imageUrls.length === 0) {
      console.warn('⚠️ メニュー画像URLが見つかりませんでした');
      return;
    }

    // 3. 画像をダウンロードしてリネーム・アップロード
    for (const imageUrl of imageUrls) {
      try {
        // URLからファイル名を判定
        let newFileName = '';
        if (imageUrl.includes('td_')) {
          newFileName = 'td.png';
        } else if (imageUrl.includes('sd1_')) {
          newFileName = 'sd1.png';
        } else if (imageUrl.includes('sd2_')) {
          newFileName = 'sd2.png';
        } else {
          console.warn(`⚠️ 不明な画像形式: ${imageUrl}`);
          continue;
        }

        console.log(`📥 ダウンロード中: ${imageUrl} -> ${newFileName}`);

        // 画像をダウンロード
        const imageResponse = await axios.get(imageUrl, {
          responseType: 'arraybuffer',
          timeout: 30000,
        });

        // Firebase Storageにアップロード
        const file = bucket.file(`menu_images/${newFileName}`);
        await file.save(Buffer.from(imageResponse.data), {
          metadata: {
            contentType: 'image/png',
            metadata: {
              originalUrl: imageUrl,
              uploadedAt: new Date().toISOString(),
            },
          },
        });

        // 公開URLを設定
        await file.makePublic();

        console.log(`✅ アップロード完了: ${newFileName}`);
      } catch (imageError) {
        console.error(`❌ 画像処理エラー (${imageUrl}):`, imageError.message);
      }
    }

    console.log('🎉 学食メニュー画像の更新が完了しました');
  } catch (error) {
    console.error('❌ 学食メニュー画像更新エラー:', error);
    throw error;
  }
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

    const tokenEntries = tokensSnapshot.docs
      .map((doc) => {
        const data = doc.data();
        if (!data) return null;
        const token = data.fcmToken;
        if (!token) return null;
        return {token, userId: doc.id};
      })
      .filter(Boolean);

    if (tokenEntries.length === 0) {
      console.log('有効なFCMトークンが存在しません');
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
            await admin.firestore().collection('user_tokens').doc(userId).delete();
          } else {
            console.error(`グローバル通知プッシュ送信エラー (${userId}):`, res.error?.message || errorCode);
          }
        }
      });

      await Promise.all(cleanupPromises);
    }

    console.log(`🌐 全体通知プッシュ送信完了: success=${successCount}, failure=${failureCount}`);
  } catch (error) {
    console.error('全体通知プッシュ送信処理でエラーが発生:', error);
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

  try {
    // ユーザーのFCMトークンを取得
    const tokenDoc = await admin.firestore()
      .collection('user_tokens')
      .doc(userId)
      .get();

    if (!tokenDoc.exists) {
      console.log(`ユーザーのFCMトークンが見つかりません: ${userId}`);
      return;
    }

    const tokenData = tokenDoc.data();
    const fcmToken = tokenData && tokenData.fcmToken;
    if (!fcmToken) {
      console.log('FCMトークンが空です');
      return;
    }

    // FCMメッセージを構築
    const message = {
      token: fcmToken,
      notification: {
        title: notification.title || 'CIT App',
        body: notification.body || '',
      },
      data: {
        notificationId: event.params.notificationId,
        type: notification.type || 'general',
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
    await admin.messaging().send(message);
    console.log(`プッシュ通知を送信しました: ${notification.title} -> ${userId}`);
  } catch (error) {
    console.error('プッシュ通知送信エラー:', error);

    // 無効なトークンの場合は削除
    if (error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered') {
      console.log(`無効なトークンを削除します: ${userId}`);
      await admin.firestore()
        .collection('user_tokens')
        .doc(userId)
        .delete();
    }
  }
});
