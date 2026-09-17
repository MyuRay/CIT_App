# メール認証後だけ登録する仕組み

更新: 2026-09-17。本番のメールリンク認証・登録前チェック・認証用Hostingを反映し、本番APIで登録とパスワードログインまで確認済み。実メールの受信・端末のリンク起動は別途確認が必要。

## 変更した登録手順

1. 新規登録画面で大学メールアドレスを入力し、確認メールを送る。この段階ではFirebase AuthenticationアカウントもFirestoreプロフィールも作らない。
2. 届いたリンクを開き、送信先と同じメールアドレス、表示名、パスワード、規約・プライバシー同意を入力する。
3. Firebaseの `signInWithEmailLink` が一度限りのメール所有確認に成功してから、認証済みアカウントを作成する。続けてパスワードとプロフィールを保存する。
4. 以後は従来どおりメールアドレス＋パスワードでログインできる。

旧処理の `createUserWithEmailAndPassword → sendEmailVerification` は削除した。メール認証判定はFirebase Authの結果を使い、Firestoreの自己申告値では代用しない。

メールの送信先だけを端末に保存する。パスワードや認証リンクを端末ストレージに保存したり、送信先アドレスをリンクのURLに埋め込んだりしない。別端末で開いた場合はメールアドレスを再入力する。Firebase HostingのこのプロジェクトのHTTPSリンクだけを受け付ける。

登録完了フォームのメール欄は送信先を表示する読み取り専用欄とし、キーボード・貼り付けで変更できない。認証済みの登録再開時は現在の認証ユーザーのメールを優先する。送信先が端末にない場合だけ、先にメールを入力して「このメールアドレスで続ける」で固定してから表示名・パスワード設定へ進む。固定はUI上の制限であり、所有確認は従来どおりFirebaseが行う。アドレスを変える場合は「新しい確認メールを送る」へ戻る。

新規登録後にホームを開くと、規約同意の確認後にチュートリアルを表示する。表示済み状態は `tab_tutorial_seen_version:{uid}` でアカウント別に保存し、完了・スキップ後は同じ端末・アカウントで繰り返さない。旧端末共通キーは別アカウントの閲覧済み状態か判別できないため引き継がない（既存アカウントにも移行後一度表示される）。設定からの再表示は維持する。登録画面・登録サービス・表示済み管理のテスト19件と対象ファイルの静的解析が成功。

期限切れ・使用済み・アドレス不一致の場合は新しいメールで再試行する。送信後60秒間はUIの再送を止め、Firebaseの制限エラーも案内する。端末をまたぐ制限の根拠はFirebase側の制限で、UIのタイマーだけをセキュリティ対策とはしない。

## 途中失敗と既存利用者

### 登録時の同意と交流サービスの更新案内

新規登録画面で利用規約・プライバシーポリシーに同意した場合、登録完了時のプロフィール保存と一緒に `users/{uid}.legalConsentVersion` と `legalConsentRecordedAt` を保存する。Cwitter・ちばちゃんねるの規約更新ポップアップは、現在の規約への同意が確認できない既存利用者に表示する。新規登録後に同じ規約への同意をもう一度求めない。

端末のキャッシュは `legal_consent_accepted_version:{uid}` でアカウント別に保持する。別端末・再インストール時はプロフィールから復元し、別アカウントの同意を流用しない。登録失敗時には端末を同意済みにしない。通常のプロフィール初回作成・ログインだけでは規約同意を付けず、プロフィール更新でも同意記録を消さない。

旧実装のUIDがない端末共通の同意記録は、誰の同意か特定できないため自動移行しない。アカウント側にも記録がない旧利用者には一度確認が必要。作成日時だけから同意済みと推定しない。今後規約バージョンが変わった場合も、旧バージョンの同意では更新案内を省略しない。

同意の読込中は更新案内を先に表示しない。通信失敗時は再試行を案内し、同意保存に失敗した場合はチェック状態を保ったまま再試行できる。ローカルの同意状態はUI用で、Firestore・Cwitterのアクセス権限を与える根拠には使わない。

検証: 登録・プロフィール・同意保存のテストと登録画面25件、更新同意ゲート5件が成功。新規登録直後、別端末、既存未同意、旧規約、アカウント切替、保存失敗、文字200%・下部システム余白48pxを確認。

### 登録の再開

認証後にパスワードやプロフィール保存が失敗した場合、認証済みUIDだけを再開用に保持する。同じ認証済みセッションで再試行し、使い終えたメールリンクを消費し直さない。GoRouterを認証トークン更新のたびに作り直さず、保存中は登録画面を維持する。必要ならいったんログアウトできる。

既存アカウントと同じメールの場合も、メール所有確認を通過した本人だけがパスワードを設定できる。画面にパスワードが更新されることを明記する。UIDと既存の表示名・レビュー・Cwitter IDなどを引き継ぐ。Firebaseは、以前メール未認証のまま作られたアカウントのパスワードをメールリンク認証時に除去するため、新しいパスワードを設定する必要がある。

プロフィールの取得と初回作成はトランザクションにした。取得失敗を「プロフィールなし」と見なして初期値で上書きしない。未認証の旧アカウントではプロフィールを新規作成しない。既存の旧ドメイン利用者のログイン・従来の認証待ち画面は残す。

既存の未認証アカウントを一括削除する処理は含めていない。

## Firebase側の作成前チェック

`requireVerifiedEmailBeforeCreate` はIdentity Platformの `beforeUserCreated` を使い、保存前に次を確認する。

- Firebaseの `emailVerified` が厳密に `true`。
- 新規登録ドメインが正確に `chibatech.ac.jp`。ローカル部の許可文字は既存のAppConstantsと同じ。

不一致は拒否し、関数から認証済みフラグを付けることはしない。旧アプリやREST APIからの未認証パスワード登録も、Authenticationに保存される前に拒否する。作成後に削除する方式ではない。既存ユーザーの通常ログインを止めるbeforeSignInフックは追加しない。

この制限はクライアントからの新規登録が対象。管理者のConsole操作・Admin SDKによる作成には別途運用上の管理が必要。

## 本番の確認結果と反映手順

対象は `cit-app-2de1c`。2026-09-17に依頼を受けて本番反映した。変更前は `subtype: FIREBASE_AUTH`、メールリンク無効、beforeCreateフックなし、認証用Hostingは404だった。変更後は `IDENTITY_PLATFORM`、メール／パスワードとメールリンクの両方が有効、`requireVerifiedEmailBeforeCreate` がACTIVEでbeforeCreateに登録済み。既存利用者のアカウントは削除していない。

Identity Platformへの切り替え、作成前チェックのデプロイ、認証用Hostingの関連付けと案内ページの公開、確認済みdebug証明書の登録を行った後、メールリンク方式を有効化した。Identity Platformへの切り替え後の料金は末尾の公式資料を参照する。

本番検証でFirebase CLI 15.30.0がbeforeCreateに `cloudfunctions.net` のURLを登録し、firebase-functions 6系が要求する `run.app` のaudienceと不一致になる問題を確認した。関数の `serviceConfig.uri` を読み、同じ関数のCloud Run URLへフックを修正した。トークン検証は無効化していない。関数を再デプロイしたら、下記の修復と本番テストを必ず再実行する。

設定APIはfalseのbooleanを省略するため、`passwordRequired` の省略もfalseとして判定するよう確認スクリプトを修正した。

本番APIテストではランダムな専用アドレスの確認リンクを管理者APIで生成し、メールを送らず公開クライアントAPIを検証した。未認証パスワード登録の拒否、リンク生成段階でアカウントがないこと、認証済み登録、パスワード設定とログイン、リンク再利用の拒否、外部ドメインの拒否を確認。テスト用Authアカウントはfinallyで削除し、残っていないことも確認した。プロフィールは作成せず、Firestore作成通知を発生させていない。これは実メールの到着・実機のリンク起動の検証とは別。

`/signup/complete`、Androidのassetlinks、iOSのapple-app-site-associationはいずれも本番HTTP 200と公開内容の一致を確認。Flutter登録関連40件、Node登録ポリシー24件、Authエミュレーター5件が成功。

接続中のAndroid実機 `R5CX51A651D` では、公開前のApp Links認証失敗（1024）が残っていたためOSに再検証を要求し、`cit-app-2de1c.firebaseapp.com: verified` を確認した。アプリの再インストールやデータ削除は行っていない。実メールからのタップ操作自体は未確認。

反映は更新版アプリの配布と調整する。作成前チェックを有効にすると旧版アプリの未認証登録は拒否される。

```powershell
# 現在の設定だけを確認（読取専用）
node scripts/email-registration-config.cjs --project cit-app-2de1c

# 本番反映・再反映（登録方式の変更を依頼された場合）
node scripts/email-registration-config.cjs --project cit-app-2de1c --apply --upgrade-identity-platform --register-debug-certificate
npx firebase deploy --project cit-app-2de1c --config firebase.registration.json --only hosting
npx firebase deploy --project cit-app-2de1c --only functions:requireVerifiedEmailBeforeCreate
node scripts/email-registration-config.cjs --project cit-app-2de1c --apply --repair-before-create-url --enable-email-links

# 再確認
node scripts/email-registration-config.cjs --project cit-app-2de1c
# 一時Authアカウントを作成・削除する本番検証。メール送信なし。
node scripts/test-registration-production.cjs --project cit-app-2de1c --run
```

スクリプトは既存のFirebase CLIログインを使い、トークンを表示・保存しない。既存のメール設定を保ってメールリンクを有効にする。登録アカウントの一覧は取得しない。汎用の `firebase deploy` では他機能の変更も含むため、上記の対象を限定した反映を使う。

## Android／iOSとリンク

新しいFirebase Hosting方式を使う。Dynamic Linksは使わない。固定ドメインは `cit-app-2de1c.firebaseapp.com`。

- Android: `jp.ac.chibakoudai.citapp`、Manifestで `/__/auth/links` を受け取る。`assetlinks.json` はFirebaseに登録されていた2つのSHA-256と、この端末のdebug証明書を含む。2026-09-17にdebug証明書の実値を確認してFirebaseにもSHA-1／SHA-256を追加済み。キーストアを変更した場合はファイルとスクリプトの公開フィンガープリントも更新する。
- iOS: `com.masatomurai.citapp`、Team ID `7D772NSCDY` をFirebaseから確認済み。Associated DomainsをRunnerのentitlementsに追加。Xcodeで対応する署名・Provisioning Profileを用意し、実機でUniversal Linksを確認する。
- アプリが開かない場合は、元のメールの登録リンクをコピーして登録画面に貼り付けられる。Hostingの案内ページは登録を実行せず、その操作を説明する。リンクやメールを外部サイトへ転送しない。
- `firebase.registration.json` は認証用Hostingだけの設定で、`.well-known` を除外しない。既存サイトが別途公開された場合は、上書き前に内容を統合する。

確認したSDKはFirebase Android BoM 33.16.0／Apple SDK 11.15.0で、新しいHosting方式に対応する世代。

## 検証とファイル

- `npm run test:auth`: 実際のAuthエミュレーター＋本番用blockingハンドラーで5件成功。メール送信時の0アカウント、誤アドレス、リンク再利用、未認証REST登録の拒否、外部ドメイン拒否、通常パスワードログイン、旧未認証アカウントのUID維持を確認。
- `npm --prefix functions test`: 52件成功（他機能のテストを含む）。
- Flutter全体: 359件成功、既存の1件はスキップ。登録サービス、プロフィール、画面、実ルーターの状態維持を含む。
- 認証関連のDart静的解析: 指摘なし。画面の最終再確認7件も成功。
- Android: `flutter build apk --debug --target-platform android-arm64 --no-pub` 成功。共有作業中の生成APK破損と時間割インポートの一時的な引数不整合で失敗した試行の後、最新ソースで再ビルドして確認。全体の `flutter clean` は実施していない。
- 画面: ライト／ダーク、320px幅・文字200%・下部システム余白48pxで確認。プレビューは `docs/qa/email-registration/` のテストデータ。
- 実機・本番でのメール到着とリンク起動は、設定反映後に確認する。iOS署名ビルドはWindowsでは未実施。

主要コードは `lib/services/auth/email_registration.dart`, `verified_profile.dart`, `lib/core/providers/email_registration_provider.dart`, `lib/screens/auth/signup_screen.dart`, `lib/core/config/app_router.dart`, `functions/verified_registration.js`。

公式資料: [Flutterのメールリンク認証](https://firebase.google.com/docs/auth/flutter/email-link-auth)、[作成前に拒否するBlocking Functions](https://firebase.google.com/docs/auth/extend-with-blocking-functions)、[Android設定](https://firebase.google.com/docs/auth/android/email-link-auth)、[iOS設定](https://firebase.google.com/docs/auth/ios/email-link-auth)、[Identity Platform料金](https://cloud.google.com/identity-platform/pricing)、[Identity Platform有効化API](https://cloud.google.com/identity-platform/docs/reference/rest/v2/projects.identityPlatform/initializeAuth)。
