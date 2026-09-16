# CIT App の利用状況分析

更新日: 2026-09-12

## 設定済みの内容

Firebase `cit-app-2de1c` に接続された GA4 プロパティ `499656302` に、下記7項目を**ユーザー範囲のカスタムディメンション**として登録済み。登録時の一覧は7件。アプリ側も同じ名前を使用する。

[Google Analytics 管理画面](https://analytics.google.com/analytics/web/?authuser=1&hl=ja#/a346066863p499656302/admin) → データの表示 → カスタム定義。

| 管理画面の表示名 | ユーザープロパティ | 値・意味 |
| --- | --- | --- |
| メインキャンパス | `main_campus` | `tsudanuma` / `narashino` / `unknown`。アプリで選択したキャンパス。GPS位置ではなく、所属や学年も推測しない |
| ログイン状態 | `account_state` | `verified` / `unverified` / `signed_out` / `unknown`。Firebase Authによる判定 |
| アカウント登録月 | `signup_month` | 日本時間の `YYYY_MM`。Authのアカウント作成日時を月単位に丸める。未ログイン・日時不明では解除 |
| テーマ設定 | `theme_preference` | `light` / `dark` / `system`。選択した設定であり実際の明暗とは限らない |
| 文字サイズ設定 | `font_size` | `small` / `medium` / `large`。アプリの文字サイズ設定。OSの拡大率とは別 |
| 講義通知設定 | `lecture_reminders` | `enabled` / `disabled`。アプリの通知設定であり、OSの許可や実際の配信成功とは別 |
| アプリ実行環境 | `app_environment` | `production`=release、`development`=debug/profile |

OS、端末モデル、アプリのバージョンなど、Analyticsが標準で扱う項目は重複定義しない。

## 何を比較するか

GA4「探索」で自由形式を作成し、上記のディメンションと「プラットフォーム」「画面名」「アクティブユーザー」「表示回数」「イベント数」などを選ぶ。画面関連項目の日本語ラベルはGA4の表示によって異なるため、`screen_view` の画面名に対応する標準ディメンションを使う。

1. **キャンパス別の利用機能**: 行にメインキャンパス、列に画面名、値にアクティブユーザーまたは表示回数。時間割・ホーム・交流などの利用を比較する。
2. **登録月ごとの継続利用**: アカウント登録月で比較を作り、週ごとのアクティブユーザーを見る。これは更新版で活動したインストールの比較であり、登録者全員を分母にした継続率ではない。
3. **表示設定の優先順位**: テーマ設定・文字サイズ設定別のアクティブユーザーを見る。アクセシビリティ改善の判断材料にする。
4. **通知設定と利用の関係**: 講義通知設定別に時間割画面の利用を見る。通知の効果を因果関係として断定しない。

通常の利用分析では `app_environment = production` に絞る。開発版だけで動作確認する場合は `development` を選ぶ。古い版にはこの属性がないため、このフィルタを適用すると旧版のデータは対象外になる。

Androidは現行ストリーム **`jp.ac.chibakoudai.citapp` / `14974290384`** を使う。旧 `jp.ac.example.cit.cit_app` を選ばない。iOSは **`com.masatomurai.citapp` / `12142784783`**。両方とも管理画面で過去48時間の受信を確認済み。

## イベント

| イベント | タイミング | 送信内容 |
| --- | --- | --- |
| `app_open` | 認証状態が判明し、属性を同期した後。プロセス起動ごとに最大1回 | SDKの標準イベント |
| `screen_view` | メインタブの初期表示・切替・ディープリンクと、対応する名前付き画面への遷移 | 固定の画面名と `screen_class = Flutter` |
| `in_app_ad_impression` | 既存の広告カード表示処理 | 広告ID、定義済みの掲載場所 |
| `in_app_ad_click` | 既存の広告カードタップ処理 | 広告ID、掲載場所、`external` / `bulletin` |

メインタブの画面名は `home` / `schedule` / `community` / `bulletin` / `profile`。同じタブの連続選択は重複送信しない。時間割への直接起動をホームの閲覧として数えない。

名前付きの対象画面はバス、ログイン、登録、メール認証・変更、利用規約、プライバシーポリシー、ブロック一覧、教室マップ。無名の画面・ダイアログを一律に `unknown` として数えることはしない。個別の講義詳細・投稿・レビュー完了などは今回の独立したイベントには含めていない。SDKが自動送信するネイティブ画面イベントとは区別し、タブ分析では上記5つの画面名を対象にする。

## データの扱い

- Firestoreのユーザー一覧をエクスポートしたり、一括アップロードしたりしない。既存のAuthセッションとアプリ設定だけを使用する。追加のFirestore読み取りは不要。
- 氏名、メール、学籍番号、プロフィール本文、投稿内容、検索語、Firebase UIDを追加の属性・操作イベントへ送らない。自由入力の学科・学部欄からも取得しない。
- カスタムUser-IDは設定しない。SDKが生成するインストール／ブラウザの識別子による計測であり、同じ人の別端末・AndroidとiOSを統合した人数ではない。匿名性を保証するものではない。
- 既存ユーザーも更新版を使えば登録月等が設定される。過去の閲覧や属性をGA4へさかのぼって追加する実装ではない。
- オフ設定は「マイページ → 設定 → 利用状況の分析」。この端末の収集を停止して保持属性を解除し、再起動後も設定を維持する。過去に送信したデータの削除とは別。
- ログアウト時は登録月を解除する。設定変更とイベント送信は順序を保つ。オフ時は待機中の操作イベントも破棄し、再度オンにしても復活させない。

## 実装と検証

- 属性の定義・送信・画面名の許可リスト: `lib/core/services/analytics_service.dart`
- Authと設定の同期・分析設定の保存: `lib/core/providers/analytics_provider.dart`
- 起動処理: `lib/main.dart`
- タブ閲覧: `lib/screens/main/main_screen.dart`
- ユーザーへの説明: マイページの設定と `lib/screens/legal/privacy_policy_screen.dart`
- テスト: `test/services/analytics/analytics_service_test.dart`

Analytics対象の11テストを含む全体138テストが成功。属性の限定、登録月の精度、ログアウト・アカウント切替、送信前の属性同期、オフ設定の永続化、待機イベント破棄、SDK障害、5タブの計測、ルートの許可リスト、Auth/設定の連携を検証。AndroidデバッグAPKのビルド成功。

Android実機（SM-S928Q）に更新APKを上書きインストールし、起動を確認。GA4のDebugViewで、7属性すべてと `app_open` / `screen_view` / `in_app_ad_impression` の受信を確認した。画面イベントの `firebase_screen = home` と `firebase_previous_screen = schedule` も確認。実機の一時的なAnalyticsデバッグ指定・詳細ログ指定は作業前の空値へ戻した。iOSの実機送信はこのWindows環境では未検証。

新しい属性の通常レポートへの反映は、データを送り始めてから24〜48時間が目安。管理画面への定義登録だけでは、配布済みの古いアプリに計測コードは追加されない。更新版を配布して利用される必要がある。

公式資料: [ユーザープロパティ](https://firebase.google.com/docs/analytics/user-properties)、[カスタムディメンションと反映時間](https://support.google.com/analytics/answer/14240153)、[ユーザー識別子](https://firebase.google.com/docs/analytics/userid)。
