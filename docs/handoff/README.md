# CIT_App 引き継ぎの入口

確認日: 2026-09-12
状態: 作業ツリーのコードとローカル検証結果に基づく。本番反映状況は未確認。

## 最初に読むもの

CIT_AppはFlutter製のAndroid・iOS・Webアプリ。Firebaseを認証、データ、画像、通知、Analyticsに使う。開発の入口は `lib/main.dart`、画面遷移は `lib/core/config/app_router.dart`、バックエンドは `functions/`。

- 開発環境・テスト: `docs/handoff/development.md`
- 機能と変更箇所: `docs/handoff/architecture.md`
- 障害対応: `docs/handoff/incidents.md`
- 公開・残っている確認: `docs/handoff/releases.md`
- アカウント・担当の引き継ぎ: `docs/handoff/ownership.md`
- Discord RAGの設定・更新・停止: `tools/discord-rag/README.md`

## 情報の扱い

この資料の「実装済み」は、配布済み・本番反映済みという意味ではない。実機確認、署名、ストア公開、Firebaseへのデプロイはそれぞれ別に記録する。

古いレビューやREADMEには現在のコードと異なる説明が残っている。2026-09-07の提案をそのまま未修正課題として扱わず、2026-09-12の対応記録とコードを照合する。分からないことを推測で補わず、未確認事項として残す。

## チームで更新するルール

機能や運用方法を変えるPRには、該当する引き継ぎ資料の更新を含める。「なぜ変更したか」「確認したこと」「まだ確認していないこと」「戻す方法」を記録する。

Discordの質問で資料不足が分かったら、担当者が内容を確認して資料へ追加する。Botの回答や会話の断片を自動で正しい知識として取り込まない。資料の更新後はRAGの検索データを再生成・検証し、Botへ反映する。

Botが停止したときも、このディレクトリを直接読めば作業を続けられるようにする。
