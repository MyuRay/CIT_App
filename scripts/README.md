# ユーザー数推移エクスポートツール

Windows上でユーザー数推移データを取得・エクスポートするためのNode.jsスクリプトです。

## セットアップ

### 1. Node.jsのインストール

Node.js 20以上がインストールされていることを確認してください。

```bash
node --version
```

### 2. 依存関係のインストール

プロジェクトのルートディレクトリで実行：

```bash
cd functions
npm install
cd ..
```

### 3. サービスアカウントキーの取得

1. [Firebase Console](https://console.firebase.google.com/)にアクセス
2. プロジェクト「cit-app-2de1c」を選択
3. プロジェクト設定（⚙️）→ サービスアカウント
4. 「新しい秘密鍵の生成」をクリック
5. ダウンロードしたJSONファイルを保存（例: `service-account-key.json`）

## 使用方法

### 基本的な使用方法

```bash
# デフォルト設定で実行（user-growth-stats.csvとuser-growth-stats.jsonを出力）
node scripts/user-growth-stats.js
```

### オプション指定

```bash
# CSVのみ出力
node scripts/user-growth-stats.js --format csv --output stats.csv

# JSONのみ出力
node scripts/user-growth-stats.js --format json --output stats.json

# サービスアカウントキーを指定
node scripts/user-growth-stats.js --service-account ./service-account-key.json

# 出力ファイル名を指定
node scripts/user-growth-stats.js --output ./exports/user-stats-2025.csv
```

### 環境変数を使用

```bash
# Windows (PowerShell)
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account-key.json"
node scripts/user-growth-stats.js

# Windows (CMD)
set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\service-account-key.json
node scripts/user-growth-stats.js
```

### functionsディレクトリから実行

```bash
cd functions
npm run export-stats
```

## 出力形式

### CSV形式

```csv
# ユーザー数推移統計データ
# 生成日時,2025-01-15T12:00:00.000Z
# 総ユーザー数,1234

# 月次データ
年月,新規登録数,累積ユーザー数
2024-01,50,50
2024-02,100,150
...

# 日次データ
日付,新規登録数,累積ユーザー数
2025-01-15,5,1234
...
```

### JSON形式

```json
{
  "totalUsers": 1234,
  "daily": [
    {
      "date": "2025-01-15",
      "count": 5,
      "cumulative": 1234
    }
  ],
  "monthly": [
    {
      "month": "2025-01",
      "count": 150,
      "cumulative": 1234
    }
  ],
  "generatedAt": "2025-01-15T12:00:00.000Z"
}
```

## トラブルシューティング

### エラー: Firebase Admin SDKの初期化に失敗

サービスアカウントキーが正しく設定されているか確認してください。

```bash
# 環境変数を確認
echo %GOOGLE_APPLICATION_CREDENTIALS%

# ファイルが存在するか確認
dir service-account-key.json
```

### エラー: 権限が不足しています

サービスアカウントに以下の権限が必要です：
- Firebase Authentication Admin
- Cloud Functions Admin（オプション）

Firebase Consoleでサービスアカウントの権限を確認してください。

## ヘルプ

```bash
node scripts/user-growth-stats.js --help
```


