# 開発環境とテスト

確認日: 2026-09-12
状態: リポジトリの設定を確認。新しいメンバーのPCでの再現は未確認。

## 開発環境を用意する

Flutter SDKとAndroid Studioを用意する。iOSのビルド・署名・実機確認にはMacとXcodeが必要。Dartの許容範囲は `pubspec.yaml` の `environment.sdk`、依存ライブラリの確定版は `pubspec.lock` を確認する。READMEに書かれたSDKの版だけを根拠にしない。

Flutterアプリは `flutter pub get`、既存Functionsは `npm ci --prefix functions`、Firestoreルールテストの依存はリポジトリ直下で `npm ci` を実行する。既存FunctionsのNode実行環境は `functions/package.json` と `firebase.json` に記載され、現在はNode 20。

FirebaseのAndroid設定は `android/app/google-services.json`、iOS設定は `ios/Runner/GoogleService-Info.plist`。これらや認証情報の受け渡しは管理者が承認した保管場所で行う。設定ファイルを揃えるために別の本番Firebaseプロジェクトを新規作成しない。

## テストの実行方法

Flutterのテストはリポジトリ直下で `flutter test`。Functionsは `npm test --prefix functions`。Firestoreルールは `npm run test:rules` で、`firebase.test.json` とテスト専用ID `demo-cit-review` を使う。ルールテストは本番Firebaseへ向けない。

Firestore Emulatorの確認ではJava 21を使用した。AndroidのGradle設定は `android/gradle/wrapper/gradle-wrapper.properties`、プラグイン設定は `android/settings.gradle.kts` が正。Javaの設定とAndroidアプリのコンパイル対象Javaバージョンを混同しない。

静的解析は `dart analyze lib test`。既存の警告が残っているため、終了コードだけで変更箇所の不具合と判断せず、変更で増えたエラー・警告を確認する。

## Android実機で確認する

端末の開発者オプションとUSBデバッグを有効にし、PCの接続を端末上で許可する。`flutter devices` で端末を確認し、`flutter run -d <device-id> --debug` でビルド・インストール・起動を確認する。端末一覧に表示されることだけでは実機テスト完了にならない。

3ボタンナビゲーション、文字拡大、横向き、キーボード表示も確認する。アプリ全体のシステム領域の扱いは `lib/widgets/common/app_system_safe_area.dart`。

## OneDrive内でビルドが止まる

この作業環境ではOneDrive配下の生成物がロックされ、`cleanMergeDebugAssets` や `build/unit_test_assets` の削除に失敗した。Gradle停止と `flutter clean` でも解消しなかったため、Windowsでは `scripts/prepare_windows_build.ps1` で生成物をユーザーのローカルキャッシュへ分離する。元のプロジェクトの `build`、`.dart_tool`、`android/.gradle` は同じ場所を指すジャンクションになり、Android StudioとFlutterは元のプロジェクトを開いたまま利用できる。

ビルド・デバッグを停止してから、PowerShellで次を実行する。

```powershell
.\android\gradlew.bat --stop
.\scripts\prepare_windows_build.ps1
flutter pub get
flutter run -d <device-id> --debug
```

スクリプトは生成物を削除せず、既存のフォルダーを `.build-cache-backups` へ退避する。この退避先はGitのローカル除外設定に追加される。生成物の実体は `%LOCALAPPDATA%\CIT_App\build-cache\<プロジェクト固有ID>`。他のチェックアウトとキャッシュが混ざらないように、プロジェクトのパスごとに分ける。既に正しいリンクがある場合は何も移動しない。

`flutter clean` がリンクを取り除いた場合は、**再びスクリプトを実行してから** `flutter pub get` と実機起動を行う。スクリプトの実行中にビルドやIDEのデバッグを同時に開始しない。これはWindowsのローカル開発設定であり、Mac・CIには適用しない。詳しい確認結果は [Windowsビルド復旧記録](../WINDOWS_BUILD_RECOVERY_2026-09-12.md) を参照。

他人の未コミット変更や退避フォルダーを一括削除しない。広範囲の自動整形と機能修正を同じ変更に混ぜない。
