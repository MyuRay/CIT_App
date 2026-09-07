/**
 * 全 Discord Webhook に役割ごとのテスト通知を送信する。
 * 使い方: node scripts/test-discord-webhooks.js
 */
const fs = require('fs');
const path = require('path');
const axios = require('axios');

const envPath = path.join(__dirname, '..', '.env');
const envText = fs.readFileSync(envPath, 'utf8');

function readEnv(key) {
  const m = envText.match(new RegExp(`^${key}=(.+)$`, 'm'));
  return m ? m[1].trim() : '';
}

const tests = [
  {
    key: 'DISCORD_WEBHOOK_URL_USERS',
    kind: 'users',
    title: '🆕 [テスト] 新規ユーザー登録',
    description: 'notifyUserCreated 用 Webhook の接続確認です。',
    color: 0x57f287,
  },
  {
    key: 'DISCORD_WEBHOOK_URL_CONTACTS',
    kind: 'contacts',
    title: '📮 [テスト] お問い合わせ',
    description: 'notifyContactCreated 用 Webhook の接続確認です。',
    color: 0x5865f2,
  },
  {
    key: 'DISCORD_WEBHOOK_URL_BULLETIN',
    kind: 'bulletin',
    title: '📰 [テスト] 掲示板申請・承認待ち',
    description: 'notifyBulletinSubmitted / notifyBulletinPendingOnUpdate 用です。',
    color: 0xfee75c,
  },
  {
    key: 'DISCORD_WEBHOOK_URL_COUPON',
    kind: 'coupon',
    title: '🎫 [テスト] クーポン利用',
    description: '掲示板クーポン利用通知用 Webhook の接続確認です。',
    color: 0x57f287,
  },
  {
    key: 'DISCORD_WEBHOOK_URL_COMMENT',
    kind: 'comment',
    title: '💬 [テスト] 掲示板コメント',
    description: 'notifyBulletinCommentCreated 用 Webhook の接続確認です。',
    color: 0x5865f2,
  },
  {
    key: 'DISCORD_WEBHOOK_URL_CWITTER',
    kind: 'cwitter',
    title: '🐦 [テスト] 新規 Cweet',
    description: 'notifyCwitterPostCreated / notifyCwitterReplyCreated 用です。',
    color: 0x4caf50,
  },
  {
    key: 'DISCORD_WEBHOOK_URL_CHIBA_CHANNEL_THREAD',
    kind: 'chiba_channel_thread',
    title: '🧵 [テスト] ちばちゃんねる新規スレ',
    description: 'notifyChibaChannelThreadCreated 用 Webhook の接続確認です。',
    color: 0x9c27b0,
  },
  {
    key: 'DISCORD_WEBHOOK_URL_CHIBA_CHANNEL_REPLY',
    kind: 'chiba_channel_reply',
    title: '💬 [テスト] ちばちゃんねる新規レス',
    description: 'notifyChibaChannelCommentCreated 用 Webhook の接続確認です。',
    color: 0x7b1fa2,
  },
  {
    key: 'DISCORD_WEBHOOK_URL_MENU',
    kind: 'menu',
    title: '🍽️ [テスト] 学食メニュー追加',
    description: 'notifyMenuItemCreated 用 Webhook の接続確認です。',
    color: 0xf26522,
  },
  {
    key: 'DISCORD_WEBHOOK_URL_MENU_IMAGE',
    kind: 'menu_image',
    title: '🖼️ [テスト] 学食メニュー画像更新',
    description: 'updateMenuImagesDailyAt8AM / updateMenuImagesNow 用です。',
    color: 0xf26522,
  },
  {
    key: 'DISCORD_WEBHOOK_URL_REVIEW',
    kind: 'review',
    title: '⭐ [テスト] 学食レビュー追加',
    description: '学食レビュー通知用（現在 Functions では未使用）の接続確認です。',
    color: 0xfaa81a,
  },
  {
    key: 'DISCORD_WEBHOOK_URL_REPORT',
    kind: 'report',
    title: '🚨 [テスト] 通報',
    description: 'notifyReportCreated 用 Webhook の接続確認です。',
    color: 0xed4245,
  },
  {
    key: 'DISCORD_WEBHOOK_URL',
    kind: 'generic',
    title: '🔔 [テスト] 共通フォールバック',
    description: '種類別 URL 未設定時の DISCORD_WEBHOOK_URL 用です。',
    color: 0x2f3136,
  },
];

async function main() {
  const results = [];
  const seenUrls = new Map();

  for (const test of tests) {
    const url = readEnv(test.key);
    if (!url) {
      results.push({...test, status: 'SKIP', detail: 'URL未設定'});
      continue;
    }

    const duplicateOf = seenUrls.get(url);
    if (duplicateOf) {
      results.push({
        ...test,
        status: 'SKIP_DUP',
        detail: `${duplicateOf} と同一URL`,
      });
      continue;
    }
    seenUrls.set(url, test.key);

    const payload = {
      embeds: [
        {
          title: test.title,
          description: test.description,
          color: test.color,
          fields: [
            {name: 'env', value: test.key, inline: false},
            {name: 'kind', value: test.kind, inline: true},
          ],
          timestamp: new Date().toISOString(),
        },
      ],
    };

    try {
      const res = await axios.post(url, payload, {
        timeout: 8000,
        validateStatus: () => true,
      });
      const ok = res.status === 204 || res.status === 200;
      results.push({
        ...test,
        status: ok ? 'OK' : 'NG',
        detail: `HTTP ${res.status}${res.data?.code ? ` (${res.data.code})` : ''}`,
      });
    } catch (err) {
      results.push({
        ...test,
        status: 'NG',
        detail: err.message,
      });
    }

    // Discord レート制限回避
    await new Promise((r) => setTimeout(r, 500));
  }

  console.log('\n=== Discord Webhook テスト結果 ===\n');
  for (const r of results) {
    const mark = r.status === 'OK' ? '✅' : r.status.startsWith('SKIP') ? '⏭️' : '❌';
    console.log(`${mark} ${r.kind.padEnd(22)} ${r.status.padEnd(8)} ${r.key}`);
    if (r.detail) console.log(`   ${r.detail}`);
  }

  const failed = results.filter((r) => r.status === 'NG');
  process.exit(failed.length > 0 ? 1 : 0);
}

main();
