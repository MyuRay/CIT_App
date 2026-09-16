# Play Console 2.3.0 入力原稿

この原稿は未送信。担当者が実際の公開状態・送信先と照合して登録する。アカウントやパスワードはリポジトリへ書かない。

## 最新情報（日本語）

・ホームの天気予報をコンパクトに表示し、展開して詳しい予報を確認できるようにしました。
・時間割の講義詳細と出欠編集を改善しました。編集モードでは講義を長押しして曜日・時限を移動できます。
・学食レビューの並び替えと画像の読み込みを改善しました。
・管理センターを刷新し、スポンサー掲載に対応しました。
・文字サイズ、ライト／ダークモード、画面下部の表示を調整しました。
・アカウントと関連データの削除申請を分かりやすくしました。

## 短い説明

千葉工大生の時間割・出欠・学食・学バス・キャンパス情報をひとつに。

## 詳しい説明

CIT Appは、千葉工業大学の学生が開発・運営する大学生活支援アプリです。大学の公式・公認アプリではありません。

時間割の作成、講義ごとのメモや出欠の管理、キャンパスの天気予報、学バス情報、学食メニュー・レビュー、掲示板などを確認できます。Cwitterやちばちゃんねるでは、学生同士の情報交換ができます。

時間割は学期ごとに切り替えられ、編集モードの長押しで講義の曜日・時限を変更できます。メインキャンパスや文字サイズ、ライト／ダークモードを設定でき、講義通知やホーム画面ウィジェットにも対応しています。

新規登録には @chibatech.ac.jp のメールアドレスとメール認証が必要です。既存ユーザーは対応する旧学内ドメインでもログインできます。大学ポータル等の外部サービスは、それぞれの利用条件・認証に従います。

アプリ内にはスポンサーの広告が表示される場合があります。利用状況の分析はマイページの設定から停止できます。データの取り扱いはプライバシーポリシーをご確認ください。

## App access: review instructions (English)

Use the preconfigured, email-verified review account entered in the separate credentials fields. New self-registration requires a university email address; reviewers should use the provided existing account. Do not register a new university account.

1. Open CIT App and select ログイン (Log in). Enter the supplied email and password.
2. If the terms/privacy update screen appears, read it and proceed. Follow or dismiss the introduction.
3. The five main tabs are ホーム (Home), 時間割 (Timetable), 交流 (Community), 掲示板 (Bulletin), and マイページ (Profile).
4. In Timetable, enter edit mode with the pencil button. Tap a cell to edit it, or long-press a lecture and choose its destination weekday and period. A consecutive lecture moves as one unit.
5. Open a lecture in normal mode to view details and attendance. University QR attendance and external university services may require their own valid university resources; supply any necessary review resources separately.
6. Reporting and blocking are available from user/content menus. To request account and associated-data deletion, open Profile → 設定 (Settings) → アカウント削除 (Account deletion). This submits a support request; the operator processes deletion and emails the outcome. Merely submitting the request does not immediately delete the account.

Before using these instructions, verify that the supplied account can access every feature to be reviewed, without expiring passwords, location restrictions, or extra verification. Supply separate restricted-feature access instructions if required. Do not claim that inaccessible functionality has been reviewed.

## データ セーフティ照合メモ

現在の公開ストアには主に「個人情報、写真と動画」と表示されていた。最新版の実装に対して次を再確認する。

| 対象 | 実装から分かる内容・目的 | 申告前の確認 |
| --- | --- | --- |
| メール・ユーザーID・表示名 | Firebase Auth / Firestoreによる認証、アカウント管理、問い合わせ | 必須／任意を登録・各機能別に区別 |
| ユーザー作成コンテンツ | 投稿、返信、レビュー、プロフィール、時間割、出欠等 | フォーム上の各データ種別への対応と公開範囲を確認 |
| 写真 | 利用者が選択・撮影した画像をStorageへ保存 | 写真機能は任意。動画対応は現在の実機能に合わせる |
| アプリ操作・端末識別子 | Firebase Analyticsの画面表示、広告表示／タップ、アプリインスタンス識別子、端末・OS情報。FCMの端末トークン | 「アプリのアクティビティ」「デバイスまたはその他のID」等との対応を確認 |
| おおよその位置・診断情報 | SDK、IPアドレス、外部API等の取り扱いも対象 | 位置権限がないだけで「一切収集しない」と判断しない。SDKの公式開示と照合 |
| 広告 | スポンサー掲示・インアプリ広告がある | 広告あり。Android 2.3.0では広告ID権限・取得を無効化。旧版・別プラットフォームとは区別 |
| 共有 | クラウド処理、他ユーザーに公開する投稿、管理通知やモデレーション連携 | Firebase以外の送信先（Functions等）も調査し、サービスプロバイダー等の例外を含め公式定義と照合 |
| 削除 | アプリ内で申請し、運営が関連データとアカウントを削除する方式 | 公開Web窓口、対応担当、完了までの運用を確認して登録 |

分析オフは将来のAnalytics計測を停止する設定であり、アカウント管理や投稿の保存、過去に送信したデータの削除とは異なる。公開ポリシーにもAnalytics、Storage、FCM、コミュニティ機能、申請方式を反映する。

対象年齢・コンテンツレーティングは実際の対象者、UGCと広告、現在の機能に合わせて回答する。「大学生向け」だけを理由に既存申告を自動変更しない。
