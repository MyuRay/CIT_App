const https = require('https');
const http = require('http');
const { URL } = require('url');
const { execSync } = require('child_process');
const fs = require('fs');

const webhookUrl = process.env.DISCORD_WEBHOOK_URL;
const eventName = process.env.GITHUB_EVENT_NAME;
const githubEventPath = process.env.GITHUB_EVENT_PATH;

console.log('=== Discord Notification Script ===');
console.log('Event Name:', eventName);
console.log('Webhook URL configured:', webhookUrl ? 'Yes (hidden)' : 'No');
console.log('Event Path:', githubEventPath);

if (!webhookUrl) {
  console.error('❌ ERROR: Discord webhook URL not configured.');
  console.error('Please set DISCORD_WEBHOOK_URL_GITHUB or DISCORD_WEBHOOK_URL in GitHub Secrets.');
  process.exit(1);
}

// GitHub event dataを読み込む
let githubEvent;
try {
  githubEvent = JSON.parse(fs.readFileSync(githubEventPath, 'utf8'));
} catch (e) {
  console.error('Failed to read GitHub event:', e.message);
  process.exit(1);
}

function createEmbed({ title, description, color, fields = [], url, author }) {
  return {
    embeds: [
      {
        title,
        description,
        color,
        url,
        fields,
        author: author ? {
          name: author.name,
          icon_url: author.icon_url,
        } : undefined,
        timestamp: new Date().toISOString(),
        footer: {
          text: 'GitHub',
          icon_url: 'https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png',
        },
      },
    ],
  };
}

function sendToDiscord(data) {
  return new Promise((resolve, reject) => {
    const url = new URL(webhookUrl);
    const payload = JSON.stringify(data);

    const options = {
      hostname: url.hostname,
      port: url.port || (url.protocol === 'https:' ? 443 : 80),
      path: url.pathname + url.search,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload),
      },
    };

    const client = url.protocol === 'https:' ? https : http;

    const req = client.request(options, (res) => {
      let responseData = '';
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(responseData);
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${responseData}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(payload);
    req.end();
  });
}

function getCommitInfo() {
  try {
    const commitMessage = execSync('git log -1 --pretty=format:"%s"', { encoding: 'utf-8' }).trim();
    const commitAuthor = execSync('git log -1 --pretty=format:"%an"', { encoding: 'utf-8' }).trim();
    const commitHash = execSync('git rev-parse --short HEAD', { encoding: 'utf-8' }).trim();
    const branch = process.env.GITHUB_REF_NAME || githubEvent.ref?.replace('refs/heads/', '') || 'unknown';
    const repository = process.env.GITHUB_REPOSITORY || 'unknown/repo';
    const serverUrl = process.env.GITHUB_SERVER_URL || 'https://github.com';
    const sha = process.env.GITHUB_SHA || githubEvent.after || '';
    
    // 変更されたファイルを取得
    let changedFiles = [];
    try {
      if (githubEvent.commits && githubEvent.commits.length > 0) {
        // 複数のコミットがある場合、最初と最後のコミットを比較
        const before = githubEvent.before;
        const after = githubEvent.after;
        if (before && after && before !== '0000000000000000000000000000000000000000') {
          const files = execSync(`git diff --name-status ${before} ${after}`, { encoding: 'utf-8' }).trim();
          changedFiles = files.split('\n').filter(f => f).slice(0, 15); // 最大15ファイル
        }
      }
    } catch (e) {
      // gitコマンドが失敗する場合は無視
      console.warn('Failed to get changed files:', e.message);
    }

    const commitUrl = `${serverUrl}/${repository}/commit/${sha}`;
    
    return {
      message: commitMessage,
      author: commitAuthor,
      hash: commitHash,
      url: commitUrl,
      branch,
      changedFiles,
      commitCount: githubEvent.commits ? githubEvent.commits.length : 1,
    };
  } catch (e) {
    console.error('Failed to get commit info:', e.message);
    return null;
  }
}

function getPRInfo() {
  const pr = githubEvent.pull_request;
  if (!pr) return null;

  const action = githubEvent.action;
  const isMerged = pr.merged === true;
  const isClosed = action === 'closed';
  
  // 変更されたファイルを取得（GitHub APIから）
  let changedFiles = [];
  if (pr.changed_files && pr.changed_files > 0) {
    // ファイルリストはGitHub APIから取得する必要があるが、
    // ここでは簡易的に追加/削除/変更されたファイル数を表示
    changedFiles = [];
    if (pr.additions) changedFiles.push(`➕ ${pr.additions} additions`);
    if (pr.deletions) changedFiles.push(`➖ ${pr.deletions} deletions`);
    if (pr.changed_files) changedFiles.push(`📝 ${pr.changed_files} files changed`);
  }

  return {
    title: pr.title,
    author: pr.user.login,
    number: pr.number,
    url: pr.html_url,
    base: pr.base.ref,
    head: pr.head.ref,
    merged: isMerged,
    closed: isClosed,
    action,
    changedFiles,
    additions: pr.additions || 0,
    deletions: pr.deletions || 0,
    changedFilesCount: pr.changed_files || 0,
  };
}

async function sendNotification() {
  console.log('Processing notification for event:', eventName);
  let embed;

  if (eventName === 'push') {
    console.log('Processing push event...');
    const commit = getCommitInfo();
    if (!commit) {
      console.error('❌ Failed to get commit info');
      process.exit(1);
      return;
    }
    console.log('Commit info retrieved:', {
      message: commit.message.substring(0, 50) + '...',
      author: commit.author,
      branch: commit.branch,
      hash: commit.hash,
    });

    const fields = [
      { name: 'ブランチ', value: `\`${commit.branch}\``, inline: true },
      { name: '作成者', value: commit.author, inline: true },
      { name: 'コミット', value: `[\`${commit.hash}\`](${commit.url})`, inline: true },
    ];

    if (commit.commitCount > 1) {
      fields.push({ name: 'コミット数', value: `${commit.commitCount} commits`, inline: true });
    }

    if (commit.changedFiles.length > 0) {
      const filesText = commit.changedFiles
        .map(f => {
          const parts = f.split('\t');
          if (parts.length >= 2) {
            const status = parts[0];
            const filePath = parts.slice(1).join('\t');
            const icon = status.startsWith('A') ? '➕' : status.startsWith('D') ? '🗑️' : status.startsWith('M') ? '✏️' : status.startsWith('R') ? '🔄' : '📝';
            return `${icon} \`${filePath}\``;
          }
          return `📝 \`${f}\``;
        })
        .join('\n');
      fields.push({
        name: `変更されたファイル (${commit.changedFiles.length}件)`,
        value: filesText.length > 1024 ? filesText.substring(0, 1021) + '...' : filesText,
        inline: false,
      });
    }

    // ブランチに応じて色とタイトルを変更
    let title = '🚀 新しいコミット';
    let color = 0x57f287; // デフォルト: 緑
    
    if (commit.branch === 'main' || commit.branch === 'master') {
      title = '🚀 メインブランチにコミット';
      color = 0x57f287; // 緑（重要）
    } else if (commit.branch === 'develop') {
      title = '🚀 開発ブランチにコミット';
      color = 0x5865f2; // 青
    } else if (commit.branch.startsWith('feature/') || commit.branch.startsWith('feat/')) {
      title = '✨ フィーチャーブランチにコミット';
      color = 0xfee75c; // 黄
    } else if (commit.branch.startsWith('fix/') || commit.branch.startsWith('bugfix/')) {
      title = '🐛 バグ修正ブランチにコミット';
      color = 0xed4245; // 赤
    } else if (commit.branch.startsWith('hotfix/')) {
      title = '🔥 ホットフィックスにコミット';
      color = 0xed4245; // 赤（重要）
    }

    embed = createEmbed({
      title,
      description: commit.message.length > 2000 ? commit.message.substring(0, 1997) + '...' : commit.message,
      color,
      url: commit.url,
      fields,
      author: {
        name: commit.author,
        icon_url: `https://github.com/${commit.author}.png`,
      },
    });
  } else if (eventName === 'pull_request') {
    console.log('Processing pull request event...');
    const pr = getPRInfo();
    if (!pr) {
      console.error('❌ Failed to get PR info');
      process.exit(1);
      return;
    }
    console.log('PR info retrieved:', {
      number: pr.number,
      title: pr.title.substring(0, 50) + '...',
      author: pr.author,
      action: pr.action,
    });

    let title, color;
    switch (pr.action) {
      case 'opened':
        title = '🆕 新しいPR';
        color = 0x5865f2; // 青
        break;
      case 'closed':
        if (pr.merged) {
          title = '✅ PRマージ';
          color = 0x57f287; // 緑
        } else {
          title = '❌ PRクローズ';
          color = 0xed4245; // 赤
        }
        break;
      case 'synchronize':
        title = '🔄 PR更新';
        color = 0xfee75c; // 黄
        break;
      case 'reopened':
        title = '🔓 PR再オープン';
        color = 0x5865f2; // 青
        break;
      default:
        title = '📝 PR更新';
        color = 0x2f3136; // グレー
    }

    const fields = [
      { name: 'PR', value: `#${pr.number}`, inline: true },
      { name: '作成者', value: pr.author, inline: true },
      { name: 'ブランチ', value: `\`${pr.head}\` → \`${pr.base}\``, inline: false },
    ];

    if (pr.merged) {
      fields.push({ name: '状態', value: '✅ マージ済み', inline: true });
    } else if (pr.closed) {
      fields.push({ name: '状態', value: '❌ クローズ済み', inline: true });
    } else {
      fields.push({ name: '状態', value: '⏳ オープン', inline: true });
    }

    if (pr.changedFilesCount > 0) {
      fields.push({
        name: '変更内容',
        value: `➕ ${pr.additions} additions\n➖ ${pr.deletions} deletions\n📝 ${pr.changedFilesCount} files changed`,
        inline: false,
      });
    }

    embed = createEmbed({
      title,
      description: pr.title.length > 2000 ? pr.title.substring(0, 1997) + '...' : pr.title,
      color,
      url: pr.url,
      fields,
      author: {
        name: pr.author,
        icon_url: `https://github.com/${pr.author}.png`,
      },
    });
  } else {
    console.log(`⚠️ Event ${eventName} is not supported. Skipping notification.`);
    process.exit(0);
  }

  try {
    console.log('Sending notification to Discord...');
    const result = await sendToDiscord(embed);
    console.log('✅ Discord notification sent successfully.');
    console.log('Response:', result);
  } catch (error) {
    console.error('❌ Failed to send Discord notification:', error.message);
    console.error('Error details:', error);
    process.exit(1);
  }
}

sendNotification().catch((error) => {
  console.error('❌ Unhandled error:', error);
  process.exit(1);
});
