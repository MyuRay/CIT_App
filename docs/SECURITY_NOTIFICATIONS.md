# セキュリティ通知

指定されたDiscord Webhookへ、不審な操作・異常なアクセス量を通知する。
検知結果は不正アクセスの断定ではない。許可された操作による情報閲覧、少数の試行、アカウント乗っ取りによる通常と同じ操作など、検知できないケースがある。
アクセス制御の修正・App Check必須化とは別の機能であり、通知自体が操作を阻止したり変更を戻したりするものではない。

## 検知対象

### データ変更時

- Cwitter投稿・返信、ちばちゃんねるのスレッド・コメント、掲示板投稿の `authorId`・`authorEmail`・`cwitterId` の追加・変更・削除。
- 上記文書で、元から存在する本文・タイトル・説明の削除または文字列以外への変更、作成日時の変更・削除。
- `admin_permissions` の追加・変更・削除。正規の管理操作も確認対象として通知する。
- いいね、返信数の更新、通常の本文編集、空文字列を使う正規の論理削除は通知しない。
- 文書全体の削除は件数監視の対象。個別の削除が不正かどうかは自動断定しない。

### 5分ごとの集計

| 種類 | 初期しきい値 |
| --- | --- |
| Firestoreルール拒否・評価エラー | 10分間に50件以上 |
| Storageルール拒否・評価エラー | 10分間に50件以上 |
| ログイン失敗 | 10分間に20件以上 |
| 管理用HTTP APIの401・403 | 10分間に10件以上 |
| Firestore文書削除 | 10分間に100件以上 |
| Firestore文書読み取り | 10分間に50,000件以上 |
| Firestore文書書き込み | 10分間に5,000件以上 |
| Firebaseルール・IAM変更 | 10分間に1件以上 |

管理APIの対象は `updateMenuImagesNow`、`syncClubOrganizationsNow`、`getUserGrowthStats`。
しきい値は導入時の初期値で、攻撃を統計的に判定する学習済み基準ではない。通常利用・退会処理・管理作業による通知もあり得る。
Cloud Monitoringの取り込み遅延を考慮し、メトリクスは実行時刻の5分前を終点とする10分間を確認する。取り込み遅延と実行周期によって通知が遅れる。
ログは直近10分を確認し、しきい値分を取得したら打ち切るため、ログ由来の件数は下限値。

## 通知と情報保護

- WebhookはSecret Managerの `DISCORD_SECURITY_WEBHOOK` に保存。アプリ、Git管理ファイル、通常ログには埋め込まない。
- Discordへの送信項目は、検知種類・時刻・対象コレクションまたは監視元・件数・確認番号・文書パスのハッシュ。
- 投稿本文、メール、IP、認証トークン、Webhook URL、利用者の生のUIDは送らない。
- 通知文は「要確認」とし、メンションは無効にする。
- 確認番号から、クラウド管理権限でFirestoreの `security_alerts/{確認番号}` を調査できる。
- 文書の照合番号は文書パスのSHA-256先頭16文字。原文の文書パスをDiscordに含めない。
- 同種の通知はプロジェクト全体で10分間に最大1回。抑制数は `security_monitor_state/throttle_{種類}` に残す。
- Discordの `wait=true` でメッセージ作成結果を確認してから送信済みとする。送信失敗は再試行し、同一イベント・並行実行の重複送信を抑える。
- Discord受理直後、送信済み保存前にプロセスが終了した場合など、外部サービスをまたぐ完全な一度だけの配信は保証できない。
- 送信済み記録は30日後から定期削除する。未送信記録は調査用に保持する。

## 本番構成

- Firebase Functionsの独立した `security` コードベース。ソースは `security-functions/`、Node.js 22、us-central1。
- 実行アカウントは `cit-security-monitor@cit-app-2de1c.iam.gserviceaccount.com`。
- 付与するプロジェクト権限はFirestoreデータ操作、Monitoring閲覧、非公開ログ閲覧、Eventarc受信。WebhookのSecret参照権限は当該Secretに限定。
- 認証の操作ログと、Firestore／StorageのDATA_WRITE監査ログを有効にする。DATA_READ監査ログの全量保存はこの構成では追加しない。
- Cloud Loggingの追加記録、Functions・Scheduler・Firestoreの実行には利用量に応じた料金がかかる。
- クライアントから `security_alerts`、`security_monitor_state`、`security_monitor_probes` への読み書きは許可しない。既存ルールのデフォルト拒否を利用し、アプリ内管理者も直接操作できない。
- `security_monitor_state/health` に最後の監視時刻、8種類のチェック結果、失敗数を記録する。部分的な取得失敗も通知対象。
- Discord全体の停止、秘密情報の失効、監視基盤全体の停止時は、この通知経路から届かないことがある。Functions/Schedulerの実行状態も確認する。

## 運用コマンド（プロジェクト直下）

```powershell
# 初期権限・操作ログ設定（既存設定を保持して追加）
node scripts/security-monitor-admin.cjs configure
# Secret保存後のアクセス権限
node scripts/security-monitor-admin.cjs grant-secret
# 監視コードのみ配置
node node_modules/firebase-tools/lib/bin/firebase.js deploy --only functions:security --project cit-app-2de1c --non-interactive
# 監視専用の各サービスに呼び出し権限を付与
node scripts/security-monitor-admin.cjs grant-invocation
# 本番状態・定期監視の手動実行
node scripts/security-monitor-admin.cjs status
node scripts/security-monitor-admin.cjs run-poll
# 利用者データに触れない、検知からDiscordまでの接続テスト
node scripts/security-monitor-admin.cjs probe
node scripts/security-monitor-admin.cjs verify-delivery
```

接続テストは管理専用の架空文書を作り、投稿者情報変更と同じ検査を通す。「テスト」と明示した通知を送り、Discord上のメッセージを取得して確認後に架空文書を削除する。
未完了なら `verify-delivery` を再実行する。初期設定のバックアップと検証結果はGit管理外の `.firebase/security-deploy/` に保存する。
再試行ポリシーを新規導入する初回配置では、対象が `security` のみであることを確認して `--force` を追加する。これは失敗時の再試行を有効にするためのCLI確認。

## 検証

```powershell
npm.cmd --prefix security-functions test
node node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --only firestore --project demo-cit-security-notify --config firebase.security-test.json "node --test security-functions/test/firestore.integration.cjs"
```

通常操作、既知の本文削除、投稿者情報変更、通知抑制、個人情報の除外、Discord失敗時の再試行、しきい値判定、部分監視失敗を単体テストする。
エミュレーターでは監視記録へのアクセス拒否と、実際のFirestoreトランザクションでの並行処理を確認する。

### 2026-09-29 導入時の確認

- 独立した `security` コードベースの9関数を本番配置し、すべて `ACTIVE` を確認。
- 定期ジョブは `every 5 minutes`、`ENABLED`。本番サービスアカウントによる8種類のチェックが失敗0件で完了。
- 単体テスト18件と、エミュレーター統合テスト2件が成功。監視記録の読み書き拒否と同時送信も検証。
- 架空アカウントで1回のログイン失敗を発生させ、認証操作ログと集計で検出できることを確認。実在利用者のアカウントには操作していない。
- 管理専用テスト文書の投稿者情報変更 → 検知 → 通知記録 → Discord送信 → Discord上のメッセージ取得、の経路を確認。
- Discordの確認済みテストメッセージID: `1554173157630419018`。作成日時: `2026-09-29 01:49:15 JST`。確認番号: `222ea909ddbfb13a7befdf1b671d31fb`。
- テスト文書は確認後に削除。監視記録は保持。
- 初期配置後のEventarc呼び出しは権限不足で拒否されたが、監視専用サービスに限定した呼び出し権限を付与し、反映後の実配信を確認した。未認証の公開呼び出しは許可していない。
- 今回は通知を実装・配置した。先のセキュリティ確認で指摘した投稿・画像・個人情報のアクセス制御は、この変更では修正していない。

## 公式仕様

- [Firestoreの変更トリガーと認証情報](https://firebase.google.com/docs/functions/firestore-events)
- [FunctionsとSecret Manager](https://firebase.google.com/docs/functions/config-env)
- [Firestoreルール・操作回数の監視](https://firebase.google.com/docs/firestore/monitor-usage)
- [認証の操作ログ](https://docs.cloud.google.com/identity-platform/docs/activity-logging)
- [Firestore監査ログ](https://docs.cloud.google.com/firestore/native/docs/audit-logging)
- [Discord Webhook](https://docs.discord.com/developers/resources/webhook)
