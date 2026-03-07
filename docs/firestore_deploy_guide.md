# Firestoreルールのデプロイ方法

## 前提条件

- Firebase CLIがインストールされていること（`firebase --version`で確認）
- Firebaseプロジェクトにログインしていること

## デプロイ手順

### 1. Firebase CLIにログイン（初回のみ）

```bash
firebase login
```

ブラウザが開くので、Firebaseアカウントでログインしてください。

### 2. Firestoreルールをデプロイ

プロジェクトのルートディレクトリで以下のコマンドを実行：

```bash
firebase deploy --only firestore:rules
```

### 3. デプロイの確認

デプロイが成功すると、以下のようなメッセージが表示されます：

```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/cit-app-2de1c/overview
```

## その他の便利なコマンド

### Firestoreルールのみをデプロイ（推奨）

```bash
firebase deploy --only firestore:rules
```

### すべてのFirebaseリソースをデプロイ

```bash
firebase deploy
```

### Firestoreルールの構文チェック（デプロイ前に確認）

```bash
firebase deploy --only firestore:rules --dry-run
```

## トラブルシューティング

### エラー: "Firebase CLI not found"

Firebase CLIがインストールされていない場合：

```bash
npm install -g firebase-tools
```

### エラー: "Permission denied"

Firebaseプロジェクトへのアクセス権限がない場合、プロジェクトの管理者に権限を依頼してください。

### エラー: "Rules file not found"

`firestore.rules`ファイルがプロジェクトのルートディレクトリに存在することを確認してください。

## 注意事項

- Firestoreルールをデプロイすると、**即座に本番環境に反映**されます
- デプロイ前にルールの内容を十分に確認してください
- テスト環境で動作確認してからデプロイすることを推奨します

## 参考リンク

- [Firebase CLI リファレンス](https://firebase.google.com/docs/cli)
- [Firestore セキュリティルール](https://firebase.google.com/docs/firestore/security/get-started)
