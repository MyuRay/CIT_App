# 機能と変更箇所

確認日: 2026-09-12
状態: 現在の作業ツリーに基づく。

## 起動・画面遷移・データ

`lib/main.dart` が初期化の入口。WebとモバイルでFirebaseの初期化や利用できるAPIが異なるため、`kIsWeb` の分岐を確認する。GoRouterの画面遷移は `lib/core/config/app_router.dart`、Riverpodの状態管理は `lib/core/providers/`。

画面は `lib/screens/`、再利用UIは `lib/widgets/`、サービスは `lib/services/`、データモデルは `lib/models/`。画面に大きな処理が残る箇所もあるため、新規変更では責務ごとに切り出す。

## 使い方ガイド

初回案内とマイページからの再表示は lib/screens/main/widgets/visual_tab_tutorial.dart。5つのタブの操作見本は tab_tutorial_demo.dart に分離する。キャンパスは現在の設定を初期表示し、「使い始める」で選択内容を保存してからホームへ進む。それ以外の見本は実データを変更しない。利用規約同意後に開始し、メール移行案内との重なりを防ぐ。既存の完了判定を維持する。操作内容と検証は [使い方ガイドの説明](../VISUAL_TUTORIAL.md)。

## 認証・権限・通知

Firebase Authの検証結果を認証判定に使う。Firestoreプロフィールの認証済みフラグを自己申告でtrueにしても、メール認証の代わりにはならない。ルールは `firestore.rules`、管理HTTP APIの認可は `functions/admin_http.js`。

新規登録はメールリンクの所有確認後にAuthアカウントを作る方式。メール送信だけではアカウントもプロフィールも作らない。旧版・REST APIからの未認証登録も防ぐにはIdentity Platformの作成前チェックを本番に反映する必要がある。実装、切り替え、既存利用者、Android／iOSリンク設定と検証は [メール認証後の登録](../EMAIL_REGISTRATION.md)。

通知先の端末別登録は `lib/services/notification/device_token_store.dart`、Functions側は `functions/device_tokens.js`。ログアウトではこの端末の登録解除、予約通知・ウィジェット・キャッシュの消去を伴う。別端末の登録を消さないこと、AからBへのアカウント切替でAのデータを残さないことが重要。

通知からの遷移は `lib/services/notification/notification_target.dart` と `notification_navigation.dart`。起動中・背景・アプリ終了時の挙動はOSを含む実機テストが必要。

## 利用状況の分析

Analyticsの属性・イベントは `lib/core/services/analytics_service.dart`、Authと設定の同期は `lib/core/providers/analytics_provider.dart`。GA4プロパティ499656302にユーザー範囲の7項目を登録済み。キャンパス、ログイン状態、登録月、テーマ、文字サイズ、講義通知設定、実行環境を比較できる。メイン5タブの閲覧も計測する。分析をオフにする設定はマイページにあり、再起動後も維持する。

氏名・メール・学籍番号・Firebase UID・自由入力は追加イベントへ送らず、Firestoreのユーザー一覧は読み出さない。利用者数はSDKのインストール識別子に基づき、端末をまたいだ人数ではない。属性を増やすときはコードとGA4定義を合わせ、個人情報を含まない有限の分類を使う。詳細は [分析の運用ガイド](../ANALYTICS_GUIDE.md)。

## 時間割・講義詳細・学年暦

時間割の保存は `lib/services/schedule/schedule_service.dart`、編集内容の検証は `schedule_class_edit.dart`。連続コマや重複を検証してからトランザクションで保存する。先に元の授業を削除してから検証する形へ戻さない。

Excelの講義名・担当教員・教室の抽出は `excel_lecture_fields.dart`。提供資料424件を用いた修正内容と再検証方法は [Excel抽出の運用メモ](../EXCEL_IMPORT_EXTRACTION.md)。元資料はGitとアプリ配布の対象外で、通常のテストには匿名化した小さな例を使う。

講義詳細UIは `lib/widgets/schedule/schedule_class_detail_dialog.dart`。教室への移動、メモのURL・編集・保存、出欠集計、条件に応じたQR出席を残している。

講義詳細の「出欠を編集」から、同じポップアップ内で講義日を選んで保存できる。出席は緑、遅刻はオレンジ、欠席は赤で、出欠管理画面と `attendance_status_chip.dart` の色・ラベルを共用する。休講・未記録も編集できる。日程は `attendance_session.dart`、取得・保存は `AttendanceService`。旧記録の置き換えは一括更新し、成功後は削除済みIDを再利用しない。CIT App内の参考記録を変更する機能で、大学側の登録には影響しない。仕様・検証は [講義詳細からの出欠編集](../LECTURE_ATTENDANCE.md)。

学年暦のカードは `lib/widgets/home/academic_calendar_card.dart`、月表示は `lib/widgets/home/academic_month_calendar.dart`、ホームへの配置と年間画像は `lib/screens/home/home_screen.dart`。月の全予定をコンパクトな行で表示し、日付選択では該当行を強調する。当月への復帰と右上の年間画像ボタンを備える。高さは表示月の週数に合わせ、6週ある月・文字拡大でのbottom overflowを防ぐ。年度は現在日付から求め、同年度内の操作では購読を作り直さない。操作と検証は `docs/ACADEMIC_CALENDAR.md` を参照。

## ホームの天気予報

天気カードは `lib/widgets/home/campus_weather_card.dart`、Open-Meteoの取得は `lib/services/weather/campus_weather_service.dart`、雨の開始・終了・再開の判定は `lib/models/weather/campus_weather.dart`。初期表示はメインキャンパスに合わせ、10分おきと復帰時・手動操作で更新する。天気だけの選択は保存せず、旧 `home_weather_campus_v1` も参照しない。通信失敗時は同じ場所の前回予報と取得時刻を残し、古い情報は「いま」と表示しない。

初期表示は天気・気温・次の雨の変化に絞り、「詳細」で時間別予報や湿度・レーダーなどを展開する。上端の左右分割ボタンはメインキャンパスが左、もう一方が右。ホームで `preferredBusCampusProvider` を監視し、設定変更時はカードの並び順と表示する天気を更新する。新習志野は緑、津田沼は青のキャンパステーマ色を使い、選択欄は淡い背景にする。学バスの路線色には連動させず、選択に応じてボタンとカードの配色を変える。天気だけを切り替える操作では並び順を保ち、フリップは行わない。

現在の天気は推定値、雨の変化は1時間単位の目安。APIの降水量は時刻の直前1時間を表すため、表示時間帯を1時間ずらさないこと。欠損を雨量ゼロにせず、日付をまたぐ24時間の予報も扱う。仕様・表示画像・検証手順は [天気予報の説明](../WEATHER_FORECAST.md)。

## スポンサー枠と掲示板管理

管理者の入口はマイページの「管理センター」。lib/screens/admin/admin_dashboard_screen.dart に対応待ち件数、機能検索、ユーザーごとのお気に入りを集約し、admin_destination_page.dart が既存の管理画面に接続する。問い合わせ・ユーザー・通報の一覧は検索と絞り込みを同じスクロール領域に置く。権限確認前に管理データを取得しない。詳しくは [管理センター](../ADMIN_CENTER.md)。

掲示板とアプリ内広告の isSponsored / sponsorName は管理者が設定する。既存データは通常枠として扱い、スポンサー枠では金色の背景・枠線と「広告」ラベルを表示する。掲示板管理は検索、状態・カテゴリの絞り込み、並べ替え、複数選択、掲載設定、CSVコピーに対応する。管理者プレビューでは閲覧数や広告計測を増やさない。

保存処理は lib/services/bulletin/bulletin_admin_service.dart、検索・CSVは lib/models/bulletin/bulletin_management_query.dart。操作・権限・反映手順は [スポンサー枠の説明](../SPONSOR_PLACEMENTS.md)。本番利用にはFirestoreルールの反映とアプリ配布が必要。

広告管理は `in_app_ad_management_screen.dart` に状態別件数、検索、掲載場所・スポンサーの絞り込み、並べ替えをまとめる。`ad_management_query.dart` が配信設定と期間から掲載中・予約中・停止中・終了を判定し、`ad_management_card.dart` が一覧を表示する。編集は `in_app_ad_editor_dialog.dart` の3区分と実表示プレビューを使う。複製は初期状態を配信停止とし、保存後に別広告として作成する。未保存の変更は破棄確認、保存失敗は入力保持と再試行に対応する。プレビューで広告計測を増やさないこと。

## 学バスのダイヤ管理

管理センターの学バス管理は `lib/screens/admin/bus_admin_screen.dart`。路線の「ダイヤを編集」から `bus_timetable_editor_screen.dart` を開き、曜日別に時刻の貼り付け・等間隔作成・別曜日や路線からのコピーができる。下書きを確認して最後に保存する。保存は `bus_timetable_admin_service.dart` が担当し、元の配列との競合検知と親ドキュメントの更新通知を同じトランザクションで行う。既存の備考・運休状態・路線情報を保持する。旧 `bus_management_screen.dart` とは別画面のため、現行の管理センターから動作を確認する。操作・入力例・検証は [ダイヤ登録の説明](../BUS_TIMETABLE_MANAGEMENT.md)。

## ホーム画面ウィジェット

Flutterの `lib/services/widget/home_widget_payloads.dart` が共通JSONを作成し、`home_widgets_service.dart` が保存・更新要求を行う。Androidは `android/app/src/main/kotlin/jp/ac/chibakoudai/citapp/widget/`、iOSは `ios/CITWidgets/`。

詳細は `docs/HOME_WIDGETS.md`。iOSのApp Groupは `group.com.masatomurai.citapp`。Runnerと拡張の両方に権限・署名設定が必要で、Windows上の静的確認だけではiOS対応の検証は完了しない。

## 学食とDiscord通知

学食レビューの表示は `lib/screens/cafeteria/cafeteria_menu_reviews_screen.dart`。レビューの多い順はメニューごとのレビュー総数で降順にする。

お気に入りは利用者配下に保存し、人数だけをCloud Functionsが `cafeteria_favorite_stats` に集計する。My食堂では検索・食堂切替・直接解除・自分のレビュー編集ができる。旧データ対応、権限、初回反映手順は `docs/CAFETERIA_FAVORITES.md`。2026-09-16に本番の2つの集計Function・索引・読取ルールを確認し、90メニュー・67明細から180件の集計を初期作成した。全対象の欠落・人数不一致は0件。実機での追加／解除確認は未実施。

既存のDiscord連携は `functions/index.js` の通知Webhookと `.github/workflows/discord-notify.yml` のGitHub通知。これらはRAGの質問受付とは別の機能。Bot用の新しい設定を通知用Webhookへ流用しない。
