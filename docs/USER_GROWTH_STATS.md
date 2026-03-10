# ユーザー数推移の確認方法

Firebase Admin SDKを使用したユーザー数推移機能の確認方法を説明します。

## デプロイ方法

まず、Firebase Functionsをデプロイします：

```bash
cd functions
npm install
cd ..
firebase deploy --only functions:getUserGrowthStats
```

## 確認方法

### 1. ブラウザで直接確認

デプロイ後、以下のURLにアクセスするとJSON形式でデータが表示されます：

```
https://us-central1-cit-app-2de1c.cloudfunctions.net/getUserGrowthStats
```

### 2. curlコマンドで確認

ターミナルで以下のコマンドを実行：

```bash
curl https://us-central1-cit-app-2de1c.cloudfunctions.net/getUserGrowthStats
```

### 3. Flutterアプリ内で確認

1. アプリを起動
2. 管理者権限でログイン
3. **管理者ダッシュボード** → **ダッシュボード**タブ
4. 「ユーザー数推移」カードを確認

### 4. Firebase Consoleで確認

1. [Firebase Console](https://console.firebase.google.com/)にアクセス
2. プロジェクト「cit-app-2de1c」を選択
3. **Functions** → **getUserGrowthStats** を確認
4. ログや実行履歴を確認できます

## レスポンス形式

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

## Windows上での使用方法

### Node.jsスクリプトを使用（推奨）

Windows上で直接ユーザー数推移データを取得・エクスポートできます。

#### セットアップ

1. **サービスアカウントキーの取得**
   - Firebase Console > プロジェクト設定 > サービスアカウント
   - 「新しい秘密鍵の生成」をクリック
   - ダウンロードしたJSONファイルを保存（例: `service-account-key.json`）

2. **環境変数の設定**
   ```cmd
   set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\service-account-key.json
   ```

#### 実行方法

**方法1: バッチファイルを使用（最も簡単）**
```cmd
scripts\export-stats.bat
```

**方法2: PowerShellスクリプトを使用**
```powershell
.\scripts\export-stats.ps1
```

**方法3: Node.jsスクリプトを直接実行**
```cmd
node scripts\user-growth-stats.js
```

**方法4: functionsディレクトリから実行**
```cmd
cd functions
npm run export-stats
```

#### オプション

```cmd
# CSVのみ出力
node scripts\user-growth-stats.js --format csv --output stats.csv

# JSONのみ出力
node scripts\user-growth-stats.js --format json --output stats.json

# サービスアカウントキーを指定
node scripts\user-growth-stats.js --service-account .\service-account-key.json
```

詳細は `scripts/README.md` を参照してください。

## トラブルシューティング

### エラー: Function not found

- Functionsがデプロイされているか確認
- デプロイコマンドを再実行

### エラー: Permission denied

- Firebase Admin SDKの権限を確認
- サービスアカウントの権限を確認

### エラー: Firebase Admin SDKの初期化に失敗

- サービスアカウントキーが正しく設定されているか確認
- 環境変数 `GOOGLE_APPLICATION_CREDENTIALS` が正しく設定されているか確認
- サービスアカウントキーファイルのパスが正しいか確認

### データが表示されない

- ブラウザのコンソールでエラーを確認
- Firebase Functionsのログを確認

