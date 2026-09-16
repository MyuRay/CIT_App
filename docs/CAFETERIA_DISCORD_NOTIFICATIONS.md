# 毎朝8時の学食画像更新とDiscord通知

## 送信先

`updateMenuImagesDailyAt8AM` は `DISCORD_WEBHOOK_URL_MENU_IMAGE` を使用する。
メニュー追加通知用の `DISCORD_WEBHOOK_URL_MENU` とは用途が異なる。
指定WebhookのIDは `1487867382859960572`、Webhook名は「学食画像更新」。
URLのトークンはドキュメントやソースへ記載しない。

ローカルの `functions/.env` に画像更新用の設定を保存済み。このファイルはGit管理対象外。
本番関数にも同じWebhookが設定されている。`discord.com` と `discordapp.com` のホスト表記は異なるが、Webhook ID・トークン・送信先は一致する。

## 2026-09-16の本番修正

本番には以前のソースが残っており、画像更新処理が `getWebhook('menu')` を呼んでいた。
本番の専用Webhook設定は正しかったが、その設定が参照されていなかった。
リポジトリ側はすでに `getWebhook('menu_image')` に対応済みだった。

本番から取得したソースに次の2点を適用し、毎朝8時の関数を更新した。

1. `getWebhook` の対応表に `menu_image: process.env.DISCORD_WEBHOOK_URL_MENU_IMAGE` を追加。
2. 画像更新通知の呼び出しを `getWebhook('menu_image')` に変更。

[Cloud FunctionsのPATCH API](https://cloud.google.com/functions/docs/reference/rest/v2/projects.locations.functions/patch)で `updateMask=buildConfig.source` を指定した。既存の本番ソースを基準にした差分だけを適用し、環境変数・スケジュール・他の関数は変更していない。

| 項目 | 確認値 |
| --- | --- |
| プロジェクト | `cit-app-2de1c` |
| 関数 | `updateMenuImagesDailyAt8AM` |
| リージョン | `us-central1` |
| 本番リビジョン | `updatemenuimagesdailyat8am-00008-ler` |
| 反映時刻 | 2026-09-16 22:45 JST |
| 実行時刻 | 毎日8:00、`Asia/Tokyo` |
| Scheduler | `ENABLED` |
| 関数・サービス | `ACTIVE` / `CONDITION_SUCCEEDED`、トラフィック100% |

## 検証

- Discord Webhookを読み取りAPIで確認し、有効な送信先であることを確認。
- 通信をモックした送信テストで旧コードの誤った通知先を再現し、修正版とリポジトリ版が指定Webhookを選ぶことを確認。その他9種類の通知先とメッセージ内容も維持。
- 修正版とリポジトリの `index.js` は `node --check` 成功。
- 本番反映後にソースを取得し直し、レビューした修正版と全ファイルの内容が一致することを確認。旧本番との差分は `index.js` の上記2点のみ。
- 環境変数の全項目、毎朝8時の設定、日本時間、Schedulerの有効状態を再確認。

実通知を伴う手動実行は行っていない。修正後の実際の配信は次回の定時実行で確認する。
