# CIT_App Discord引き継ぎRAG

チームメイトが `/ask question: AndroidのAnalyticsに利用が出ない` と質問すると、確認済みの引き継ぎ資料を検索して日本語で答える。回答には資料のファイル・確認日を付ける。資料がHEADと一致し、GitHub URLが設定されている場合はそのコミットの行へリンクする。担当者未記入や資料不足の場合は確定した回答を返さない。

**現在の状態:** ローカル実装。DiscordのApplication・サーバーへの登録、Geminiへの送信、本番デプロイ、実際のAI回答の品質評価は未実施。鍵を設定しないローカル検索はキーワード検索の確認であり、ベクトル検索・生成AIの実動作確認ではない。

## 構成

```text
docs/handoff/*.md → 確認・分割 → Geminiで埋め込み生成 → 同梱する検索データ
Discord /ask → handoffAsk（署名・チャンネル・ロールを照合）
             → Cloud Tasksへ登録 → Discordへ受付応答
             → handoffAnswer → 日次上限・重複処理を確認
                             → ベクトル＋キーワード検索 → Gemini
                             → 検証した出典を付けて本人だけに回答
```

Firebase Functionsの独立した `handoff-rag` codebase。既存のFlutterアプリ、通知Webhook、既存Functionsのエクスポートには追加しない。資料29チャンク程度から始めるため、専用ベクトルDBは使わず、埋め込みをJSONとしてFunctionsへ同梱する。資料が大きくなり、全件走査や再デプロイが負担になった時点でFirestoreのベクトル検索への移行を検討する。

Cloud TasksはAI処理をHTTPの受付処理から切り離すために使う。HTTP応答を返した後に同じ関数内で未完了のAI処理を走らせない。[Firebaseのタスクキュー](https://firebase.google.com/docs/functions/task-functions)に基づく。

Discordは最初の応答を3秒以内に要求する。受付はキューへの登録だけにし、生成は後で行う。**本番では受付時間を測定すること。** `RAG_MIN_INSTANCES=0` ではコールドスタートがある。3秒を超えるなら1以上にして再測定する。1以上では待機中も課金される。[Discordの応答仕様](https://docs.discord.com/developers/interactions/receiving-and-responding)

## まずローカルで確認する

Node 22を使う。リポジトリ直下で実行する。

```sh
npm ci --prefix tools/discord-rag
npm test --prefix tools/discord-rag
npm run knowledge:build --prefix tools/discord-rag
npm run knowledge:check --prefix tools/discord-rag
npm run search --prefix tools/discord-rag -- "AndroidのAnalyticsに利用が出ない"
```

この段階では外部AIへの送信もDiscordへの投稿も行わない。検索対象は `sources.json` に列挙した `docs/handoff/` のMarkdownだけ。会話履歴、リポジトリ全体、Firestoreの利用者データ、環境変数、署名ファイルを収集する処理はない。

Firestoreの統合テストは、ルートの `npm ci` とJava 21を用意して次を実行する。テストはローカルの `127.0.0.1:8091` と専用IDだけを許可する。

```sh
npx firebase emulators:exec --only firestore --project demo-cit-rag --config firebase.rag.test.json "node tools/discord-rag/test/firestore.integration.cjs"
```

## チームで用意する設定

| 設定 | 用途 |
| --- | --- |
| Discord Application ID / Public Key | 質問の受付と署名検証 |
| Server ID / Channel ID / Role ID | 利用者の制限。いずれもチームの管理者が指定 |
| Discord Bot Token | `/ask` コマンド登録時だけ使用。Functionsには渡さない |
| Firebase / Google Cloudプロジェクト | Functions、Cloud Tasks、Firestore、Secret Manager、請求 |
| RAG専用サービスアカウント | タスクの登録・呼び出し、利用回数と処理状態の保存 |
| RAG_GEMINI_API_KEY | 文章の埋め込みと回答生成。チーム管理のキーを使用 |
| GitHubリポジトリURL（任意） | コミット・行への出典リンク |

トークンやAPIキーをDiscord・チャット・Gitへ貼らない。値はチーム管理のSecret Manager等へ登録する。担当・副担当・保管先を `docs/handoff/ownership.md` に記入する。

## AIの設定と資料の埋め込み

Geminiの既定モデルは回答用 `gemini-3.1-flash-lite`、埋め込み用 `gemini-embedding-001`、768次元。モデルの提供状況は導入時と更新時に[公式モデル一覧](https://ai.google.dev/gemini-api/docs/models)と[廃止予定](https://ai.google.dev/gemini-api/docs/deprecations)で確認する。

まず `docs/handoff/` をチームでレビューし、AIサービスへ送信してよい内容か確認する。キーをローカルのプロセス環境変数 `RAG_GEMINI_API_KEY` に安全な方法で読み込み、次を実行する。コマンドにキーを直書きしない。

```sh
npm run knowledge:embed --prefix tools/discord-rag
node tools/discord-rag/scripts/knowledge.js check --require-vectors
```

埋め込みの生成時には対象資料、回答時には質問と検索結果最大4件がGeminiへ送られる。初回は全チャンク、以後は内容が変わったチャンクだけを再生成する。削除された資料は再生成後の検索データから除かれる。モデルを変える場合は埋め込みを全件作り直し、クエリ側と一致させる。[Geminiの埋め込み仕様](https://ai.google.dev/gemini-api/docs/embeddings)

`data/index.json` はGit対象外。更新し忘れた索引・欠けたベクトルはデプロイ前検査で拒否する。変更された資料と同梱データの一致を確認してから公開する。Gitに未反映の資料には、存在しないコミットへのリンクを付けない。

## Firebaseへの導入手順

以下は公開担当者が実施する。本実装を作成した時点では実行していない。

1. 対象プロジェクトの請求・権限を確認する。専用プロジェクトを使えば、Botのデータとアプリの利用者データを分離できる。既存プロジェクトを使う場合もRAG専用サービスアカウントを作成する。
2. Functions、Cloud Tasks、Firestore、Secret Managerを利用可能にする。Firestoreは処理状態と回数だけに使う。`handoff_rag_jobs` と `handoff_rag_usage` はクライアントSDKから読み書きさせない。現在のアプリのルールでは該当パスに許可がないが、公開済みルールは別途確認する。専用プロジェクトでもデータベースをテストモードで公開しない。
3. 専用サービスアカウントへ必要なIAMを設定する。タスク登録用 `roles/cloudtasks.enqueuer`、Firestore用 `roles/datastore.user`、回答関数への `roles/run.invoker` を対象に応じて付与する。タスクで使用するサービスアカウントの `iam.serviceAccounts.actAs`、Secretへのアクセスも確認する。サービスアカウントの秘密鍵JSONを配布する運用は避ける。[タスクキューのIAM要件](https://firebase.google.com/docs/functions/task-functions#iam_permissions)
4. `.env.example` を `tools/discord-rag/.env.<project-id>` にコピーし、ID・ロール・チャンネル・専用サービスアカウントを記入する。初期状態は `RAG_ENABLED=false`。公開鍵以外の秘密情報はこのファイルに入れない。
5. GeminiキーをSecret Managerへ登録する。`firebase functions:secrets:set RAG_GEMINI_API_KEY --project <project-id>`。Firestoreの両コレクショングループで `expiresAt` をTTLに設定する。回答キャッシュは1日、利用回数は7日の有効期限を保存するが、TTLポリシーを設定しない限り自動削除されない。
6. 資料の埋め込みとローカル検証を完了し、まず `handoffAnswer` を公開する。次に `handoffAsk` を公開し、`handoffAnswer` は公開呼び出し不可、`handoffAsk` は署名検証付きの公開HTTP受付になっていることを確認する。

```sh
firebase deploy --config firebase.rag.json --project <project-id> --only functions:handoff-rag:handoffAnswer
firebase deploy --config firebase.rag.json --project <project-id> --only functions:handoff-rag:handoffAsk
```

7. 専用サービスアカウントから回答関数を呼べることと、Cloud Tasksのキューが作成されていることを確認する。公開した受付URLをDiscord Developer PortalのInteractions Endpoint URLへ登録する。署名されたPINGへの応答で疎通を確認する。
8. DiscordのApplicationを対象サーバーにインストールする。Slash Command用の `applications.commands` を使う。通常メッセージの収集・Message Content Intentは不要。
9. ローカル環境へ登録用Bot Token・Application ID・Guild IDを読み込み、`npm run discord:register --prefix tools/discord-rag` を実行する。POSTで `/ask` だけを登録・更新するため、他のコマンドを一括上書きしない。
10. サーバーの連携設定で `/ask` を指定のチームロール・チャンネルへ許可する。コード側のロール・チャンネルの制限も維持する。設定が空の場合は利用を拒否する。
11. 対象2関数の `RAG_ENABLED=true` を反映し、下記の受け入れ確認を行う。最後に主担当と副担当の両方から利用できることを確認する。

## 受け入れ確認

- 正規のチームメイトの `/ask` が3秒以内に受け付けられ、出典付きの回答が本人だけに届く。
- 指定外のロール・チャンネル・別サーバー・DMでは利用できない。
- 「AndroidのAnalyticsに利用が出ない」「環境構築」「学年暦のoverflow」「本番反映順序」が該当資料に基づいて回答される。
- 「担当者は誰か」「既に本番へ公開済みか」など未確認の事項を創作しない。コードだけでは回答の正確性を保証できないので、20問程度の実際の質問をチームで評価する。
- 資料内に「前の指示を無視して」と書いても、権限・出典・回答方針を変更しない。
- 同じタスクの再配信でAI回答を重複生成しない。AI障害・Discordへの送信失敗時に、失敗表示と再試行を確認する。
- 資料の変更・削除後に検索データを再生成し、古い内容を回答しなくなる。
- 利用上限、停止操作、再開、キーの更新を副担当が確認する。

## 利用上限・費用・停止

既定は1人1日30質問、サーバー全体で1日150質問。UTCの0時に日付が切り替わる。新しい質問の回数をFirestoreのトランザクションで数え、AI実行前に上限を判定する。リトライは最大3回、同時処理は最大2件。Discordへの送信失敗時は保存済み回答を再利用する。

これは通貨単位の完全な上限ではない。Cloud Tasks、Firestore、Functions、Secret ManagerとGeminiの料金が別々に発生する。質問・回答の長さや再試行、受付へのアクセスも費用に影響する。導入時にチームの月額予算を決め、[Gemini料金](https://ai.google.dev/gemini-api/docs/pricing)と[Firebase料金](https://firebase.google.com/pricing)に基づき試験運用の実測で見積もる。予算アラートだけを自動停止の保証として扱わない。

緊急停止はまずDiscord側でApplicationのコマンド利用を無効にし、Cloud Tasksの `handoffAnswer` キューを一時停止する。進行中の処理は止まらないことがある。続いて `RAG_ENABLED=false` を両関数へ反映する。既存の通知Webhookを削除しない。再開時はキュー内の古いタスクが期限切れになることを確認する。

## 更新・調査・復旧

資料のPR → 担当者レビュー → コミット → 検索データの差分生成 → テスト → 対象codebaseだけ公開 → 代表質問で確認、の順で行う。GitHub Actionsにはローカル検証だけを追加し、自動的に外部AIへ資料を送ったり本番公開したりしない。

更新に失敗した場合は、最後に正常動作したBotのコミットと、その資料から生成した索引をセットで再公開する。コードと索引の版を混ぜない。APIモデル変更時は実際の回答品質と埋め込みの互換性を確認する。

受付の遅延は `RAG interaction acknowledgement exceeded 2 seconds` のログで調べる。本文・質問・Discord interaction token・Geminiキーはログに出さない。キューの失敗と関数のエラー件数を監視する。回答キャッシュと回数の保存先はFirestoreの専用コレクション。タスクのペイロードには質問と短命の返信トークンが含まれるため、Cloud Tasksの閲覧・管理権限も運用担当者に限定する。

このBotは検索と回答だけを行う。コード修正、デプロイ、利用者データの操作を実行する機能はない。
