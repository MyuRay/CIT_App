#!/usr/bin/env node

/**
 * ユーザー数推移を取得してCSVファイルにエクスポートするスクリプト
 * 
 * 使用方法:
 *   node scripts/user-growth-stats.js [オプション]
 * 
 * オプション:
 *   --output, -o   出力ファイル名（デフォルト: user-growth-stats.csv）
 *   --format, -f   出力形式: csv, json, both（デフォルト: both）
 *   --service-account  サービスアカウントキーのパス（環境変数GOOGLE_APPLICATION_CREDENTIALSでも指定可能）
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// コマンドライン引数の解析
const args = process.argv.slice(2);
let outputFile = 'user-growth-stats.csv';
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
ユーザー数推移エクスポートツール

使用方法:
  node scripts/user-growth-stats.js [オプション]

オプション:
  --output, -o <ファイル名>      出力ファイル名（デフォルト: user-growth-stats.csv）
  --format, -f <形式>           出力形式: csv, json, both（デフォルト: both）
  --service-account <パス>      サービスアカウントキーのパス
  --help, -h                     このヘルプを表示

環境変数:
  GOOGLE_APPLICATION_CREDENTIALS  サービスアカウントキーのパス

例:
  node scripts/user-growth-stats.js
  node scripts/user-growth-stats.js -o stats.csv -f csv
  node scripts/user-growth-stats.js --service-account ./service-account-key.json
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

// CSV形式に変換
function toCsv(stats) {
  const rows = [];
  
  // メタ情報
  rows.push('# ユーザー数推移統計データ');
  rows.push(`# 生成日時,${stats.generatedAt}`);
  rows.push(`# 総ユーザー数,${stats.totalUsers}`);
  rows.push('');
  
  // 月次データ
  rows.push('# 月次データ');
  rows.push('年月,新規登録数,累積ユーザー数');
  for (const monthly of stats.monthly) {
    rows.push(`${monthly.month},${monthly.count},${monthly.cumulative}`);
  }
  
  rows.push('');
  
  // 日次データ
  rows.push('# 日次データ');
  rows.push('日付,新規登録数,累積ユーザー数');
  for (const daily of stats.daily) {
    rows.push(`${daily.date},${daily.count},${daily.cumulative}`);
  }
  
  return rows.join('\n');
}

// CSV形式に変換（シンプル版、コメントなし）
function toCsvSimple(stats, type) {
  const rows = [];
  
  if (type === 'monthly' || type === 'both') {
    rows.push('年月,新規登録数,累積ユーザー数');
    for (const monthly of stats.monthly) {
      rows.push(`${monthly.month},${monthly.count},${monthly.cumulative}`);
    }
  }
  
  if (type === 'daily' || type === 'both') {
    if (rows.length > 0) rows.push('');
    rows.push('日付,新規登録数,累積ユーザー数');
    for (const daily of stats.daily) {
      rows.push(`${daily.date},${daily.count},${daily.cumulative}`);
    }
  }
  
  return rows.join('\n');
}

// ユーザー数推移を取得
async function getUserGrowthStats() {
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
    return result;
  } catch (error) {
    console.error('❌ ユーザー数推移の取得エラー:', error);
    throw error;
  }
}

// メイン処理
async function main() {
  try {
    // Firebase初期化
    initializeFirebase();

    // ユーザー数推移を取得
    const stats = await getUserGrowthStats();

    // 出力ディレクトリを確認
    const outputDir = path.dirname(outputFile) || '.';
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    // ファイル出力
    if (format === 'csv' || format === 'both') {
      const csvContent = toCsv(stats);
      const csvFile = format === 'both' ? outputFile.replace(/\.csv$/, '') + '.csv' : outputFile;
      fs.writeFileSync(csvFile, csvContent, 'utf8');
      console.log(`✅ CSVファイルを出力しました: ${csvFile}`);
    }

    if (format === 'json' || format === 'both') {
      const jsonContent = JSON.stringify(stats, null, 2);
      const jsonFile = format === 'both' ? outputFile.replace(/\.csv$/, '') + '.json' : outputFile.replace(/\.csv$/, '.json');
      fs.writeFileSync(jsonFile, jsonContent, 'utf8');
      console.log(`✅ JSONファイルを出力しました: ${jsonFile}`);
    }

    // 統計情報を表示
    console.log('\n📈 統計情報:');
    console.log(`  総ユーザー数: ${stats.totalUsers}人`);
    console.log(`  月次データ: ${stats.monthly.length}件`);
    console.log(`  日次データ: ${stats.daily.length}件`);
    console.log(`  最新の月: ${stats.monthly[stats.monthly.length - 1]?.month || 'N/A'}`);
    console.log(`  最新の日: ${stats.daily[stats.daily.length - 1]?.date || 'N/A'}`);

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

