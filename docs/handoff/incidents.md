# 障害対応の入口

確認日: 2026-09-12
状態: コードと既存の調査記録に基づく。実際の障害時には現在の状態を再確認する。

## Androidの利用がAnalyticsに出ない

まずFirebase/Analyticsで見ているアプリ登録・データストリームを確認する。現行Androidのパッケージは `jp.ac.chibakoudai.citapp`。旧登録 `jp.ac.example.cit.cit_app` と表示名が同じ「CIT App」のため混同しやすい。

2026-09-12の調査では、現行ストリームは受信していた一方、Firebase概要には旧Android登録が表示されていた。概要の表示アプリは最大3件だった。概要の「4 アプリ」から旧登録と現行登録の表示を切り替える方法がある。アプリ登録を削除する必要はない。

調査時の現行Androidストリームは `14974290384`、GA4プロパティは `499656302`、Firebaseプロジェクトは `cit-app-2de1c`。これは調査時の記録で、現在の受信状況を保証しない。詳細と確認範囲は `docs/ANDROID_ANALYTICS_INVESTIGATION_2026-09-12.md`。

現行ストリームでも届かない場合は、配布中アプリのパッケージ、組み込まれたFirebase設定、Analytics収集設定、対象端末の通信を確認する。修正済みのローカルAPKとストア配布版を混同しない。

## ログイン・アクセス権限で失敗する

Firebase Authのメール認証とトークン更新を確認する。Firestore上の認証フラグだけを書き換えて解消しようとしない。最近のルール・Functionsとアプリが対応した版か確認する。管理用APIは管理者のIDトークン検証が必要。

匿名・一般利用者へ権限を広げて障害回避しない。まず再現条件、該当ルール、直前の変更を調べ、テスト環境で修正を確認する。

## 通知が別のアカウントへ届く・届かない

アカウント、端末、アプリの版、起動状態を切り分ける。端末別登録、ログアウト時の解除、旧トークンからの移行、Functionsの送信先を確認する。FCMトークンや利用者の情報をDiscordの質問へ貼らない。再現には匿名化した手順を使う。

## 学年暦のbottom overflow

`lib/widgets/home/academic_month_calendar.dart` と `lib/screens/home/home_screen.dart` を確認する。月表示は固定高さではなく、6週ある月・文字拡大でも収まる高さにする。再現テストは `test/widgets/home/academic_month_calendar_test.dart`。システムナビゲーションの余白は `lib/widgets/common/app_system_safe_area.dart`。

## WindowsのAndroidビルドがcleanMergeDebugAssetsで失敗する

OneDrive配下の生成物ロックが原因となることがある。Gradle停止と通常のクリーンでも直らない場合は、[開発環境のOneDrive対策](development.md#onedrive内でビルドが止まる)に従って `scripts/prepare_windows_build.ps1` を実行し、生成物をローカルキャッシュへ分離する。2026-09-12には、元のプロジェクトからSamsung実機への起動・デバッグ接続と、失敗していた削除タスクを含む再ビルドまで確認した。詳細は `docs/WINDOWS_BUILD_RECOVERY_2026-09-12.md`。

## Webだけ起動に失敗する

`lib/main.dart` のWeb用Firebase初期化とApp Checkを確認する。WebのApp Check用ビルド設定名は `FIREBASE_RECAPTCHA_SITE_KEY`。モバイル専用APIをWebで呼んでいないか確認する。本番のキー設定・App Checkの強制適用状況は別途管理画面で確認する。

## 事故の記録

発生日時、影響範囲、配布版、直前の変更、再現手順、確認した根拠、復旧操作、再発防止を記録する。利用者データ・秘密情報の原文ではなく、必要最小限の匿名化情報を残す。
