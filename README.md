# CIT App - 千葉工業大学向け大学生活支援アプリ

千葉工業大学の学生向けに、時間割・課題・出欠、学内交流、掲示板、学食、学バス、キャンパスマップをまとめたアプリです。Android・iOS・Web向けにFlutterで開発しています。

**ソース版数: 2.5.0+86**（`pubspec.yaml`）。README更新日: 2026-11-19。

このREADMEはリポジトリ内の実装を説明しています。ストア公開版や本番Firebaseへの反映状況は、各機能の資料・リリース記録で確認してください。

- [公式サイト](https://cit-app.com/)
- [開発・運用の引き継ぎ資料](docs/handoff/README.md)
- [2.5.0のリリース記録](docs/releases/2.5.0.md)
- [利用規約](TERMS_OF_SERVICE.md)・[プライバシーポリシー](PRIVACY_POLICY.md)

## 主な機能

お問い合わせチャット、Cwitterの一部機能、学年別広告分析などはFirebase側の設定やデータ移行も必要です。各資料の反映条件を確認してください。

| 機能 | 内容 |
| --- | --- |
| 時間割・出欠 | 複数時間割の作成・編集、Excel取り込み、連続コマ、土曜日の表示切替、10限を超える時限の追加、画像共有、前期・後期別の出欠管理、講義通知 |
| 課題管理 | 講義に紐づく課題や単独の課題の登録、締切・メモ、完了／未完了の切替、ホーム表示、締切のリマインダー |
| 大学内SNS | Cwitterの投稿・画像・返信・いいね・リクイート・引用・投票・検索・フォロー・固定投稿、ちばちゃんねるのスレッド・返信、通報・ブロック |
| 掲示板 | カテゴリ別の投稿申請、画像・コメント、ピン留め、管理者による承認・掲載管理、スポンサー掲載 |
| 学食 | キャンパス別メニュー、写真・レビュー、お気に入り、並べ替え |
| 学バス | キャンパス間の時刻表、次の出発便、運行日・臨時ダイヤ、優先キャンパス設定 |
| キャンパス情報 | 教室・フロアマップ、津田沼／新習志野の3Dマップ、天気予報、学年暦、便利リンク |
| ホームウィジェット | Android・iOSの今日の時間割、週間時間割、学バス表示 |
| マイページ・サポート | プロフィール・アバター、ホーム表示のカスタマイズ、ライト／ダークテーマ、使い方ガイドの再表示、画像付きお問い合わせチャット、通知設定、アカウント削除 |
| 管理者機能 | 管理センター、投稿・通報・ユーザー・お問い合わせの管理、広告配信・学年別広告分析、講義期間・バス情報などの設定 |

2.5.0では学バスタイムアタックの入口を非表示にしています。3Dマップは津田沼・新習志野のモデルと表示に必要なデータを同梱しています。

### 認証・登録

- 新規登録は **`@chibatech.ac.jp` のみ**。メールリンクによる本人確認後に登録を完了し、パスワードを設定します。
- 既存の `@s.chibakoudai.jp`／`@p.chibakoudai.jp` アカウントは引き続きログインでき、新ドメインへの変更を案内します。
- 認証にはFirebase Authenticationを使用します。登録前のサーバーチェック、リンク設定、既存利用者の扱いは[メール登録の資料](docs/EMAIL_REGISTRATION.md)を参照してください。

## 技術構成

| 項目 | 使用技術・構成 |
| --- | --- |
| アプリ | Flutter / Dart、Material Design 3 |
| 状態管理・画面遷移 | Riverpod / Hooks Riverpod、Go Router |
| バックエンド | Firebase Authentication、Cloud Firestore、Cloud Storage、Cloud Functions |
| 通知・運用 | Firebase Cloud Messaging、ローカル通知、App Check、Analytics、Remote Config |
| モデル・コード生成 | Freezed、json_serializable、build_runner |
| ウィジェット・地図 | home_widget、WidgetKit、flutter_map、Three.js / WebViewによる3D表示 |

Cloud FirestoreのFlutterプラグインはローカル修正版を使用しています。`third_party/cloud_firestore` を含めて取得し、変更理由は[パッチ記録](third_party/cloud_firestore/PATCHES.md)を確認してください。

## セットアップ

### 必要な環境

- Flutter / Dart SDK。2.5.0+86の `pubspec.lock` はDart `>=3.13.0 <4.0.0`・Flutter `>=3.47.0` を要求します。Windowsでの検証にはFlutter 3.47.3を使用しています。
- Android開発: Android Studio、Android SDK、Gradleに対応するJDK。
- iOS開発: macOS、Xcode、CocoaPods、署名環境。
- バックエンド・ルールテスト: Node.js / npm、Firebase CLI。`functions/` の実行環境はNode.js 20、`security-functions/`・`game-functions/` はNode.js 22です。
- Firestore等のエミュレーター用Java。既存の検証ではJava 21を使用しています。

依存関係は `pubspec.lock` と各 `package-lock.json`、Functionsのランタイムは `firebase.json` と各 `package.json` を基準にしてください。

### 取得・依存関係

```bash
git clone https://github.com/MyuRay/CIT_App.git
cd CIT_App
flutter --version
flutter doctor
flutter pub get
```

バックエンドの開発・テストを行う場合は、対象の依存関係も取得します。

```bash
npm ci
npm ci --prefix functions
```

セキュリティ監視・キャンパスゲームのFunctionsを扱う場合は、それぞれ `npm ci --prefix security-functions`・`npm ci --prefix game-functions` も実行します。

Windows PowerShellで `npm.ps1` が実行ポリシーにより停止する場合は、`npm` を `npm.cmd` に置き換えて実行できます。

### Firebase設定

既存プロジェクトの設定を運営から受け取って使用してください。

| 対象 | 設定箇所 |
| --- | --- |
| Android | `android/app/google-services.json` |
| iOS | `ios/Runner/GoogleService-Info.plist` |
| Web | `lib/main.dart` の `FirebaseOptions`。`web/firebase-config.js` にも関連設定がありますが、Firebaseの初期化はDart側で行います |
| Web App Check | `--dart-define=FIREBASE_RECAPTCHA_SITE_KEY=...` で実際のサイトキーを指定 |

WebのApp Checkはサイトキー未設定時に初期化をスキップします。利用先のApp Check強制設定に合わせて構成してください。メール登録のApp Links／Universal Linksや認証用Hostingは[専用資料](docs/EMAIL_REGISTRATION.md)を参照してください。

### MacでiOSをビルドする

既にクローンしている場合は、`main` の最新コミットを取り込みます。既存のCIT App用 `GoogleService-Info.plist` を `ios/Runner/` に配置し、以下を実行してください。

```bash
flutter pub get --enforce-lockfile
(cd ios && pod install)
open ios/Runner.xcworkspace
```

`pod install` はFlutterの依存関係に合わせてネイティブプラグインを追加します。実機確認や配布では、XcodeでRunnerとCITWidgetsに既存のチーム・署名を設定し、ウィジェット用のApp Groupも揃えてください。Macではシミュレーター向けに `flutter build ios --simulator`、署名設定後の配信用には `flutter build ipa` を使えます。Firebase設定ファイルと署名情報は既存の管理先から取得してください。

### コード生成・起動

FreezedやJSONモデルを変更した場合は、生成コードを更新します。

```bash
dart run build_runner build --delete-conflicting-outputs
flutter devices
flutter run -d <device-id>
```

Webで起動する場合:

```bash
flutter run -d chrome
```

## プロジェクト構成

| パス | 役割 |
| --- | --- |
| `lib/main.dart` | 起動・Firebase初期化 |
| `lib/core/` | ルーティング、定数、Riverpodプロバイダー、テーマ、規約モデル |
| `lib/models/` | データモデル |
| `lib/screens/` | ホーム・時間割・交流・掲示板・管理などの画面 |
| `lib/services/` | 機能別のデータ取得・保存・通知処理 |
| `lib/widgets/` | 共通UI・機能別ウィジェット |
| `android/`・`ios/`・`web/` | プラットフォーム設定・ネイティブ実装 |
| `assets/` | 画像、3Dモデル、同梱データ・音声 |
| `functions/` | 通知、登録、プロフィール同期、アカウント削除等のFunctions |
| `security-functions/`・`game-functions/` | セキュリティ監視・キャンパスゲーム用Functions |
| `firestore.rules`・`storage.rules` | アクセス制御。インデックスは `firestore.indexes.json` |
| `legal/` | 利用規約・プライバシーポリシーの原稿 |
| `test/` | Flutter、認証、Firestore・Storageルールなどのテスト |
| `scripts/`・`tools/` | ビルド支援、運用、検証用プレビュー、Discord RAG等 |
| `docs/` | 機能仕様、検証記録、リリース・引き継ぎ資料 |

## 検証

Flutterのテスト・静的解析:

```bash
flutter test
dart analyze lib test
```

バックエンド・アクセス制御のテスト:

```bash
npm test --prefix functions
npm run test:rules
npm run test:auth
```

セキュリティ監視・キャンパスゲーム・お問い合わせを変更した場合は、`npm test --prefix security-functions`・`npm test --prefix game-functions`・`npm run test:contact-chat-rules` も実行します。

ルール・認証テストは各 `firebase.*test.json` と `demo-` で始まるテスト用プロジェクトを使用します。対象・前提条件は `package.json` のscriptsを確認してください。実機の通知、ウィジェット、メールリンク、iOS署名は別途端末で確認します。

規約の原稿を変更する場合は `legal/documents.json` を編集し、生成・整合性確認を行います。詳細は[規約管理の資料](legal/README.md)を参照してください。

```bash
node scripts/generate_legal_documents.cjs
node scripts/generate_legal_documents.cjs --check
```

## ビルド・配布

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS（macOS・Xcodeが必要）
flutter build ios --release

# Web
flutter build web --release
```

Androidの配信用ビルドには既存のPlayアップロードキーと `android/key.properties`、またはAndroid Studioの署名ウィザードによる設定が必要です。署名情報・キーストアはGitへ含めません。AABの通常の出力先は `build/app/outputs/bundle/release/app-release.aab` です。

生成したAABは `scripts/verify_android_bundle.ps1` で版数・署名・マニフェスト等を検査できます。必要な引数は `-BundlePath` と `-BundletoolPath` です。配布時の条件は[2.5.0の記録](docs/releases/2.5.0.md)、更新案内の設定は[アップデート案内](docs/APP_UPDATE_PROMPT.md)を参照してください。

Firebaseの反映対象・移行手順は機能ごとの資料で確認し、対象を指定してデプロイします。現在の作業ツリーには複数機能の変更が含まれるため、ルール全文やFunctions全体の一括反映前に本番との差分を確認してください。

### Windows / OneDriveのビルド復旧

`cleanMergeDebugAssets` で生成物を削除できない場合は、Android Studioの実行・デバッグを停止し、`android/gradlew.bat --stop` でGradleを停止します。[Windowsビルドの復旧記録](docs/WINDOWS_BUILD_RECOVERY_2026-09-12.md)と、使用するブランチの `scripts/prepare_windows_build.ps1` を確認してください。準備中の2.5.0には、対象の生成アセットを退避する `scripts/repair_android_assets.ps1` もあります。スクリプトの動作は版によって異なります。

## 機能・運用資料

| 分野 | 資料 |
| --- | --- |
| 時間割・課題・出欠 | [Excel取り込み](docs/EXCEL_TIMETABLE_IMPORT.md)、[課題管理](docs/ASSIGNMENTS.md)、[講義の出欠](docs/LECTURE_ATTENDANCE.md)、[ドラッグ操作](docs/SCHEDULE_DRAG.md) |
| ホーム・端末連携 | [ホームウィジェット](docs/HOME_WIDGETS.md)、[天気予報](docs/WEATHER_FORECAST.md)、[学年暦](docs/ACADEMIC_CALENDAR.md)、[使い方ガイド](docs/VISUAL_TUTORIAL.md) |
| 地図・バス | [3Dマップ](docs/CAMPUS_3D_MAP.md)、[バス時刻表管理](docs/BUS_TIMETABLE_MANAGEMENT.md) |
| 交流・プライバシー | [公開プロフィール](docs/PUBLIC_PROFILES_PRIVACY.md)、[ちばちゃんねるの投稿者情報](docs/CHIBA_PRIVATE_IDENTITIES.md) |
| 管理・サポート | [管理センター](docs/ADMIN_CENTER.md)、[お問い合わせ](docs/CONTACT_CHAT.md)、[広告配信・分析](docs/AD_TARGETING_AND_ANALYTICS.md)、[スポンサー掲載](docs/SPONSOR_PLACEMENTS.md) |
| 認証・規約・退会 | [メール登録](docs/EMAIL_REGISTRATION.md)、[規約管理](legal/README.md)、[アカウント削除](docs/ACCOUNT_DELETION.md)、[Storageの認可](docs/STORAGE_AUTHORIZATION.md) |
| 引き継ぎ | [資料の入口](docs/handoff/README.md)、[Discord RAG](tools/discord-rag/README.md) |

過去の変更履歴は [CHANGELOG.md](CHANGELOG.md)、最近の版別記録は [docs/releases/](docs/releases/) にあります。

## お問い合わせ

不具合報告・機能提案はアプリ内の「お問い合わせ」、[公式サイト](https://cit-app.com/)、または [citapp919@gmail.com](mailto:citapp919@gmail.com) へご連絡ください。
