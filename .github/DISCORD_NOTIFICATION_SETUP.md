# Discord通知ボットのセットアップ

GitHubのPRやコミットをDiscordに通知するためのセットアップガイドです。

## 機能

- **コミット通知**: 全てのブランチへのプッシュ時に通知
  - メインブランチ（main/master）: 🚀 緑色で強調表示
  - 開発ブランチ（develop）: 🚀 青色で表示
  - フィーチャーブランチ（feature/*）: ✨ 黄色で表示
  - バグ修正ブランチ（fix/*）: 🐛 赤色で表示
  - ホットフィックス（hotfix/*）: 🔥 赤色で強調表示
- **PR通知**: PRの作成、更新、マージ、クローズ時に通知
- **詳細情報**: コミットメッセージ、作成者、変更されたファイルなどを表示

## セットアップ手順

### 1. Discord Webhookの作成

1. Discordサーバーで、通知を送信したいチャンネルを開く
2. チャンネル設定（⚙️）を開く
3. 「連携サービス」→「Webhook」を選択
4. 「新しいWebhook」をクリック
5. Webhook名を設定（例: `GitHub Notifications`）
6. 「Webhook URLをコピー」をクリック

### 2. GitHub Secretsの設定

1. GitHubリポジトリの「Settings」→「Secrets and variables」→「Actions」を開く
2. 「New repository secret」をクリック
3. 以下のいずれかの名前でWebhook URLを設定:
   - `DISCORD_WEBHOOK_URL_GITHUB`（推奨：GitHub専用）
   - `DISCORD_WEBHOOK_URL`（既存のWebhook URLがある場合）

### 3. ワークフローの動作確認

1. リポジトリにコミットをプッシュ
2. GitHub Actionsでワークフローが実行されることを確認
3. Discordチャンネルに通知が表示されることを確認

## 通知内容

### コミット通知

- 🚀 新しいコミット
- ブランチ名
- コミットハッシュ（クリック可能なリンク）
- 作成者
- コミットメッセージ
- 変更されたファイル一覧（最大15ファイル）

### PR通知

- 🆕 新しいPR: PR作成時
- ✅ PRマージ: PRがマージされた時
- ❌ PRクローズ: PRがクローズされた時（マージなし）
- 🔄 PR更新: PRに新しいコミットが追加された時
- 🔓 PR再オープン: クローズされたPRが再オープンされた時

## カスタマイズ

### 通知するブランチを変更

現在は全てのブランチ（`**`）へのpushを通知します。特定のブランチのみを通知したい場合は、`.github/workflows/discord-notify.yml`の`on.push.branches`を編集:

```yaml
on:
  push:
    branches:
      - main
      - develop
      - feature/*  # フィーチャーブランチのみ通知
```

全てのブランチを通知する場合（デフォルト）:
```yaml
on:
  push:
    branches:
      - '**'  # 全てのブランチを対象
```

### 通知するPRイベントを変更

`.github/workflows/discord-notify.yml`の`on.pull_request.types`を編集:

```yaml
on:
  pull_request:
    types: [opened, closed, synchronize, reopened, ready_for_review]
```

## トラブルシューティング

### 通知が届かない

1. GitHub SecretsにWebhook URLが正しく設定されているか確認
2. GitHub Actionsのワークフローが実行されているか確認
3. Discord Webhookが有効か確認
4. ワークフローのログを確認（エラーメッセージをチェック）

### エラーログの確認

1. GitHubリポジトリの「Actions」タブを開く
2. 失敗したワークフローを選択
3. 「Send Discord notification」ステップのログを確認

## 既存のDiscord通知との統合

既に`DISCORD_WEBHOOK_URL`が設定されている場合、GitHub通知専用のWebhook URLとして`DISCORD_WEBHOOK_URL_GITHUB`を設定することを推奨します。

これにより、GitHub通知とその他の通知（ユーザー登録、お問い合わせなど）を別のチャンネルで受け取ることができます。

