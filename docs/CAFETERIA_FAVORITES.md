# 学食のお気に入りとMy食堂

更新: 2026-09-17

## 利用者向けの変更

- メニュー一覧・メニュー詳細・My食堂で、ハートの下にお気に入り人数を表示する。同じ利用者が同じメニューを複数保存していても1人と数える。
- ハートと人数は同じボタン領域内に縦並びで収め、間隔は1px・中央揃え。通常文字サイズのコンパクト表示は高さ48pxで、人数のための追加行をカード下に確保しない。文字拡大時は内容に応じて高さを広げる。
- My食堂はお気に入りから開く。写真、メニュー名、価格、食堂をまとめ、メニュー検索・食堂フィルター・その場での解除を利用できる。
- 「自分のレビュー」では評価・コメント・投稿日を表示し、既存のレビュー編集画面に直接移動できる。
- 新習志野は緑、津田沼は青の食堂ラベル。ライト／ダーク表示、320px幅・文字200%・システム下部余白48pxでも縦にスクロールできる。
- 保存／解除中は連打を防ぐ。通信エラーでは再試行でき、未ログイン時は案内を表示する。下に引く操作で再読込できる。

## 確認して修正した問題

従来の人数取得はクライアントから全利用者の私有サブコレクションを集計していたため、Firestoreルールに拒否される構成だった。お気に入り明細を公開する代わりに、サーバーが人数だけを専用コレクションへ保存する。

従来の保存は自動採番で、解除は先頭1件だけ削除していた。重複が残ると再びお気に入り表示になるため、対象ごとの固定IDを使い、操作した対象の旧重複もすべて整理する。メニューIDがない旧データは「食堂ID＋正規化したメニュー名」で照合し、null同士の一致による他メニューの誤解除を防ぐ。

利用者IDは認証状態の変更を監視する。ログアウト・アカウント切り替え時に前の利用者の一覧を残さない。

## データと集計

保存先は従来どおり `users/{uid}/cafeteria_favorites/{targetKey}`。新しいtargetKeyは種別とSHA-256の組み合わせで、ハッシュ入力はUTF-8のJSON配列。

| 対象 | ハッシュ入力 |
| --- | --- |
| メニューIDあり | `["menu", menuItemId.trim()]` |
| メニューIDなし | `["menu-name", cafeteriaId, menuName.trim().toLowerCase()]` |
| 食堂 | `["cafeteria", cafeteriaId]` |

DartとNodeは `test/fixtures/cafeteria_favorite_keys.json` の共通値で互換性を検証する。

公開する集計は `cafeteria_favorite_stats/{targetKey}` の `count`, `updatedAt`, `schemaVersion` のみ。利用者ID・氏名・メール・保存した人の一覧は保存しない。読取は既存のCIT利用者判定、書込はAdmin SDKのみ。各人のお気に入り明細は本人だけがアクセスできる。

`syncCafeteriaFavoriteCounts` がお気に入りの作成・更新・削除を監視する。現在の明細をトランザクションで再集計し、UIDを重複排除するため、イベントの再配信・遅延で人数が増減し続けない。名前だけの旧データとメニューID付きデータを両方扱う。`syncCafeteriaMenuFavoriteCounts` はメニュー作成・削除・名前／食堂変更時に関連する集計を更新する。閲覧数や画像のみの変更では再集計しない。

人数はサーバー反映後に更新される。未初期化の集計は「集計待ち」、読取失敗は「取得失敗」と再試行操作を表示し、どちらも0人と誤表示しない。実際に集計済みで人数が0の場合だけ「0人」と表示する。

旧データ互換のため、再集計では該当食堂の明細も読む。利用者数が大きく増えた場合は、旧データを正規化した上で対象キーの索引を使う方式への移行を検討する。

## Firebaseへの反映

2026-09-16、本番 `cit-app-2de1c` に2つの集計Functionを限定デプロイし、両方のACTIVE状態を確認した。必要なCOLLECTION_GROUP索引2件を追加し、既存の集計読取ルールも確認済み。お気に入り原本は変更せず、90件のメニュー・67件の明細から180件の集計データ（メニューIDと旧名称キー）を初期作成した。全対象を原本からの重複排除集計と照合し、欠落0件・人数不一致0件を確認した。

以下は新しい環境へ反映する場合の手順。

1. 対象プロジェクトを確認する。現在の `.firebaserc` の既定値は `cit-app-2de1c`。
2. `firestore.rules` のお気に入り・集計ルールと `firestore.indexes.json` のCOLLECTION_GROUP索引（type＋menuItemId、type＋cafeteriaId）を反映する。これらのファイルには別機能の未反映変更もあるため、統合した差分を確認してからデプロイする。
3. 2つの集計Functionをデプロイする。
4. 索引の準備完了後、既存データをdry runで確認してから初期集計する。初期集計スクリプトはお気に入り原本を変更しない。
5. CITアカウント2つで同一メニューを追加／解除し、全表示箇所で0→1→2→1人になること、再起動後も保存状態が続くことを確認する。

リポジトリ直下からのコマンド例:

```powershell
npx firebase deploy --project cit-app-2de1c --only "firestore:rules,firestore:indexes"
npx firebase deploy --project cit-app-2de1c --only "functions:syncCafeteriaFavoriteCounts,functions:syncCafeteriaMenuFavoriteCounts"
node functions/scripts/rebuild-cafeteria-favorite-counts.js --project cit-app-2de1c
node functions/scripts/rebuild-cafeteria-favorite-counts.js --project cit-app-2de1c --write
```

初期集計には対象プロジェクトの読取・集計書込権限を持つApplication Default Credentialsが必要。既存の運用環境を使い、認証情報をリポジトリへ保存しない。dry runはメニュー数・元の明細数・生成予定の集計数だけを出力し、利用者情報を出力しない。

## 実装と検証先

- `lib/models/cafeteria/cafeteria_favorite_target.dart`: 対象ID・旧データ照合・重複排除
- `lib/services/cafeteria/cafeteria_favorite_service.dart`: 保存／解除・人数読取
- `lib/core/providers/cafeteria_favorite_provider.dart`: 認証連動・共有保存状態
- `lib/widgets/cafeteria/cafeteria_favorite_button.dart`: 全画面で共通のハートと人数
- `lib/screens/cafeteria/cafeteria_my_screen.dart`: My食堂
- `functions/cafeteria_favorites.js`: 集計本体
- `test/services/cafeteria/cafeteria_favorite_service_test.dart`: 保存・重複・認証切替・人数・キー互換
- `test/widgets/my_cafeteria_test.dart`: 表示・検索・解除反映・エラー・両テーマ・小画面
- `test/firestore/cafeteria_favorites.rules.test.cjs`: 権限・再集計・旧データ・初期化・名称変更
- `functions/test/cafeteria_favorites.test.js`: キー互換・所有者とパスの検証
- `docs/qa/my-cafeteria/`: テストデータの表示プレビュー。本番利用者の情報は使用していない。

確認結果: お気に入りのサービス／UIテスト16件、Functionsの単体テスト28件、Firestoreルール／集計テスト23件が成功。お気に入りとMy食堂の新規・変更部分の静的解析は指摘なし。全Flutterテストは確認時点で254件成功、別機能の `account_deletion_test.dart` に2件の失敗が残る。今回の本番反映時には集計単体テスト2件を再実行して成功し、本番の全180集計も原本と一致した。実機画面と実利用者による追加／解除イベントの確認は未実施。

Android arm64のdebug APKビルドも成功。初回は同時に更新中だった時間割画面のメソッド未定義で失敗したが、その実装が追加された後の再ビルドで成功した。ログは `build/favorites-android-build-recheck.log`。
