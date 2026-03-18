#!/usr/bin/env node

/**
 * Firebase Authenticationのメールアドレスから最初の3文字を抽出するスクリプト
 * 
 * 使用方法:
 *   node scripts/extract-user-id-prefix.js [オプション]
 * 
 * オプション:
 *   --output, -o   出力ファイル名（デフォルト: email-prefixes.csv）
 *   --format, -f   出力形式: csv, json, both（デフォルト: both）
 *   --service-account  サービスアカウントキーのパス（環境変数GOOGLE_APPLICATION_CREDENTIALSでも指定可能）
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// コマンドライン引数の解析
const args = process.argv.slice(2);
let outputFile = 'email-prefixes.csv';
let format = 'both';
let serviceAccountPath = null;

for (let i = 0; i < args.length; i++) {
  const arg = args[i];
  if ((arg === '--output' || arg === '-o') && args[i + 1]) {
    outputFile = args[i + 1];
    i++;
  } else if ((arg === '--format' || arg === '-f') && args[i + 1]) {
    format = args[i + 1];
    i++;
  } else if (arg === '--service-account' && args[i + 1]) {
    serviceAccountPath = args[i + 1];
    i++;
  } else if (arg === '--help' || arg === '-h') {
    console.log(`
メールアドレスプレフィックス抽出ツール

使用方法:
  node scripts/extract-user-id-prefix.js [オプション]

オプション:
  --output, -o <ファイル名>      出力ファイル名（デフォルト: email-prefixes.csv）
  --format, -f <形式>           出力形式: csv, json, both（デフォルト: both）
  --service-account <パス>      サービスアカウントキーのパス
  --help, -h                     このヘルプを表示

環境変数:
  GOOGLE_APPLICATION_CREDENTIALS  サービスアカウントキーのパス

例:
  node scripts/extract-user-id-prefix.js
  node scripts/extract-user-id-prefix.js -o prefixes.csv -f csv
  node scripts/extract-user-id-prefix.js --service-account ./service-account-key.json
`);
    process.exit(0);
  }
}

// Firebase Admin SDKの初期化
function initializeFirebase() {
  try {
    // サービスアカウントキーのパスを取得
    const serviceAccount = serviceAccountPath || process.env.GOOGLE_APPLICATION_CREDENTIALS;
    
    if (serviceAccount && fs.existsSync(serviceAccount)) {
      const serviceAccountKey = require(path.resolve(serviceAccount));
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccountKey),
        projectId: serviceAccountKey.project_id || 'cit-app-2de1c',
      });
      console.log('✅ Firebase Admin SDKを初期化しました（サービスアカウントキーから）');
    } else if (process.env.FIREBASE_PROJECT_ID) {
      // 環境変数から初期化（GCP環境など）
      admin.initializeApp({
        projectId: process.env.FIREBASE_PROJECT_ID,
      });
      console.log('✅ Firebase Admin SDKを初期化しました（環境変数から）');
    } else {
      // デフォルトのプロジェクトIDを使用
      admin.initializeApp({
        projectId: 'cit-app-2de1c',
      });
      console.log('✅ Firebase Admin SDKを初期化しました（デフォルトプロジェクトID）');
      console.log('⚠️  注意: サービスアカウントキーを設定することを推奨します');
    }
  } catch (error) {
    console.error('❌ Firebase Admin SDKの初期化に失敗しました:', error.message);
    console.error('\nサービスアカウントキーを設定してください:');
    console.error('  1. Firebase Console > プロジェクト設定 > サービスアカウント');
    console.error('  2. 「新しい秘密鍵の生成」をクリック');
    console.error('  3. ダウンロードしたJSONファイルを保存');
    console.error('  4. 環境変数を設定: set GOOGLE_APPLICATION_CREDENTIALS=パス\\to\\key.json');
    console.error('     または --service-account オプションで指定');
    process.exit(1);
  }
}

// メールアドレスから最初の3文字を抽出（@より前の部分から）
function extractPrefix(email) {
  if (!email || typeof email !== 'string') {
    return '';
  }
  // @より前の部分を取得
  const localPart = email.split('@')[0];
  if (!localPart || localPart.length < 3) {
    return localPart || '';
  }
  return localPart.substring(0, 3);
}

// CSV形式に変換
function toCsv(userData) {
  const rows = [];
  
  // ヘッダー
  rows.push('ユーザーID,メールアドレス,プレフィックス（メールの最初の3文字）,作成日時');
  
  // データ行
  for (const user of userData) {
    const email = user.email || '';
    const createdAt = user.createdAt || '';
    rows.push(`"${user.uid}","${email}","${user.prefix}","${createdAt}"`);
  }
  
  return rows.join('\n');
}

// プレフィックス別の集計をCSV形式に変換
function toCsvSummary(prefixSummary) {
  const rows = [];
  
  // ヘッダー
  rows.push('プレフィックス,ユーザー数');
  
  // プレフィックスでソート
  const sortedPrefixes = Object.entries(prefixSummary)
    .sort((a, b) => b[1] - a[1]); // ユーザー数の降順
  
  // データ行
  for (const [prefix, count] of sortedPrefixes) {
    rows.push(`${prefix},${count}`);
  }
  
  return rows.join('\n');
}

// メールアドレスプレフィックスを抽出
async function extractEmailPrefixes() {
  try {
    console.log('📊 メールアドレスプレフィックスの抽出を開始...');

    // 全ユーザーを取得
    let allUsers = [];
    let nextPageToken;
    
    do {
      const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
      allUsers = allUsers.concat(listUsersResult.users);
      nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);

    console.log(`✅ 合計 ${allUsers.length} 人のユーザーを取得しました`);

    // メールアドレスから最初の3文字を抽出
    const userData = [];
    const prefixSummary = {};
    let usersWithoutEmail = 0;

    for (const user of allUsers) {
      const email = user.email || '';
      const prefix = extractPrefix(email);
      const createdAt = user.metadata.creationTime 
        ? new Date(user.metadata.creationTime).toISOString()
        : '';

      if (!email) {
        usersWithoutEmail++;
      }

      userData.push({
        uid: user.uid,
        prefix: prefix,
        email: email,
        createdAt: createdAt,
      });

      // プレフィックス別の集計（メールアドレスがある場合のみ）
      if (prefix) {
        prefixSummary[prefix] = (prefixSummary[prefix] || 0) + 1;
      }
    }

    console.log(`✅ メールアドレスプレフィックスの抽出が完了しました`);
    console.log(`   プレフィックスの種類: ${Object.keys(prefixSummary).length}種類`);
    if (usersWithoutEmail > 0) {
      console.log(`   メールアドレスなしのユーザー: ${usersWithoutEmail}人`);
    }

    return {
      users: userData,
      prefixSummary: prefixSummary,
      totalUsers: allUsers.length,
      usersWithoutEmail: usersWithoutEmail,
      generatedAt: new Date().toISOString(),
    };
  } catch (error) {
    console.error('❌ メールアドレスプレフィックスの抽出エラー:', error);
    throw error;
  }
}

// メイン処理
async function main() {
  try {
    // Firebase初期化
    initializeFirebase();

    // メールアドレスプレフィックスを抽出
    const result = await extractEmailPrefixes();

    // 出力ディレクトリを確認
    const outputDir = path.dirname(outputFile) || '.';
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    // ファイル出力
    if (format === 'csv' || format === 'both') {
      // ユーザー詳細データ
      const csvContent = toCsv(result.users);
      const csvFile = format === 'both' 
        ? outputFile.replace(/\.csv$/, '') + '.csv' 
        : outputFile;
      fs.writeFileSync(csvFile, csvContent, 'utf8');
      console.log(`✅ CSVファイルを出力しました: ${csvFile}`);

      // プレフィックス集計データ
      const summaryCsv = toCsvSummary(result.prefixSummary);
      const summaryFile = format === 'both'
        ? outputFile.replace(/\.csv$/, '') + '-summary.csv'
        : outputFile.replace(/\.csv$/, '') + '-summary.csv';
      fs.writeFileSync(summaryFile, summaryCsv, 'utf8');
      console.log(`✅ プレフィックス集計CSVファイルを出力しました: ${summaryFile}`);
    }

    if (format === 'json' || format === 'both') {
      const jsonContent = JSON.stringify(result, null, 2);
      const jsonFile = format === 'both' 
        ? outputFile.replace(/\.csv$/, '') + '.json' 
        : outputFile.replace(/\.csv$/, '.json');
      fs.writeFileSync(jsonFile, jsonContent, 'utf8');
      console.log(`✅ JSONファイルを出力しました: ${jsonFile}`);
    }

    // 統計情報を表示
    console.log('\n📈 統計情報:');
    console.log(`  総ユーザー数: ${result.totalUsers}人`);
    if (result.usersWithoutEmail > 0) {
      console.log(`  メールアドレスなし: ${result.usersWithoutEmail}人`);
    }
    console.log(`  プレフィックスの種類: ${Object.keys(result.prefixSummary).length}種類`);
    
    // 上位10個のプレフィックスを表示
    const topPrefixes = Object.entries(result.prefixSummary)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10);
    
    const usersWithEmail = result.totalUsers - (result.usersWithoutEmail || 0);
    console.log('\n  上位10個のプレフィックス:');
    for (const [prefix, count] of topPrefixes) {
      const percentage = usersWithEmail > 0 
        ? ((count / usersWithEmail) * 100).toFixed(2)
        : '0.00';
      console.log(`    ${prefix}: ${count}人 (${percentage}%)`);
    }

  } catch (error) {
    console.error('❌ エラーが発生しました:', error);
    process.exit(1);
  } finally {
    // Firebase Admin SDKをクリーンアップ
    if (admin.apps.length > 0) {
      await admin.app().delete();
    }
  }
}

// スクリプト実行
main();

