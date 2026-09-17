# Android 再インストール後のログイン保持

更新: 2026-09-17

## 原因

再インストール後、一度ログインしてもコールドスタートごとに未ログインになる症状。Android設定からアプリのデータを削除すると解消する。

- FlutterFireが解決していたAndroidの `firebase-auth:23.2.1` には暗号化セッション保存の回帰がある。Auto Backupなどで暗号化された `StorageCryptoKeyset` が戻っても、対応するAndroid Keystoreの端末固有鍵は戻らない。この状態では認証はメモリ上で成功しても、新しいセッションの暗号化・保存にも失敗する。
- 既存のバックアップ除外指定 `com.google.firebase.auth.api.Store.` は前方一致ではない。実ファイルは `Store.<Firebase app persistence key>.xml` であり、指定が一致していなかった。`crypto.<key>.xml` の除外もなかった。クラウド復元・端末間転送の両方が対象。
- Dartの `AuthStorageReconciler` は旧アプリ独自の表示用キャッシュを消すだけで、SDKの鍵セットを復旧できない。起動待ち時間や `remember_me` の設定では直らない。

根拠: [Firebase公式リリースノート](https://firebase.google.com/support/release-notes/android)、[同じ復元不具合の報告](https://github.com/firebase/firebase-android-sdk/issues/8392)、[Androidバックアップのパス仕様](https://developer.android.com/identity/data/autobackup)。使用中の23.2.1と修正版24.0.1の配布SDKも調べ、後者に鍵セットを再生成して再試行する処理があることを確認した。

## 修正

- `android/app/build.gradle.kts` でAndroidのAuth SDKを `24.0.1` に更新。復元できない暗号鍵データはSDKが復旧し、次のログインを保存できるようにする。FlutterFire全体の更新は行わない。
- Android 11以前の `backup_rules.xml`、Android 12以降の `data_extraction_rules.xml` のクラウド・端末転送の全3箇所で `sharedpref` の `path="."` を除外。Firebase appごとに変わるセッション・暗号鍵のファイル名と、アプリの表示用ログインキャッシュをまとめて復元対象から外す。従来から除外していたFlutter設定に加え、通知・ウィジェット等のSharedPreferencesもバックアップされなくなる。通常の再起動・上書き更新では設定やセッションを削除しない。
- 全アプリデータの消去、正常なログイン状態の強制解除、パスワードやトークンの独自保存は行わない。

アンインストール後の初回に再ログインが必要なのは正常。既に鍵を失ったセッションを復元することはできないため、修正版で一度ログインし直した後の保持を保証する方針。

## 実機検証

2026-09-17、接続したSamsung SM-S928Qで確認した。

- 修正前23.2.1: ローカルAuth Emulatorで作成した隔離テスト用Firebase appの鍵を失わせて復元を再現。ログイン自体は成功するが、新しい暗号化セッションの保存の検証に失敗。次プロセスでも未ログイン。
- 修正後24.0.1: 同じ条件で再ログイン・保存に成功。別プロセスでの復元を2回続けて確認。正常な鍵での通常再起動も成功。
- テストのSDKはSharedPreferencesへ非同期で書くため、書込フェーズの末尾でcommitを待ってからinstrumentationを終了する。コールドスタート確認フェーズではログイン・再読込・トークン取得・保存を行わない。
- Android debug APKとandroidTest APKのビルド成功。依存解決結果も24.0.1。実機へ上書きインストール済み。
- 上書き後の本番アプリも `force-stop` → `am start -W` で `LaunchState: COLD` を確認し、既存ユーザーセッションが復元された。該当起動の致命的エラー・暗号化保存エラーはなし。セッション内容は出力していない。
- 本番アカウントの認証情報とアプリデータは消去していない。テストは名前付きFirebase appとローカルエミュレーターだけを使う。Googleクラウドからのバックアップ復元操作そのものは未実施。バックアップXMLは3経路とも確認済み。

## 再現テストの実行

対象: `android/app/src/androidTest/kotlin/jp/ac/chibakoudai/citapp/auth/AuthPersistenceRuntimeTest.kt`。

1. `firebase emulators:start --only auth --project demo-cit-auth-storage --config firebase.auth.test.json` でローカルAuth Emulatorを9098番に起動する。
2. `android` ディレクトリで `gradlew.bat :app:assembleDebug :app:assembleDebugAndroidTest` を実行する。
3. 接続端末にdebug APKとandroidTest APKを上書きインストールする。
4. `adb -s <serial> reverse tcp:9098 tcp:9098` を設定する。
5. 下記コマンドを、各フェーズごとに別々に実行する。フェーズ順は `seed` → `verify-cold-start` → `seed-restored` → `sign-in-after-restore` → `verify-cold-start` → `verify-cold-start` → `cleanup`。

```text
adb -s <serial> shell am instrument -w -r -e class jp.ac.chibakoudai.citapp.auth.AuthPersistenceRuntimeTest -e authStoragePhase <phase> jp.ac.chibakoudai.citapp.test/androidx.test.runner.AndroidJUnitRunner
```

各結果の `OK (1 test)` を確認する。adb自体の終了コードだけではテスト失敗を検出できない。終了後は追加した9098番のreverseとローカルエミュレーターを停止する。テスト用の `cleanup` は隔離appのデータだけを消す。

将来FlutterFireを更新する際は、解決されるAndroid Auth SDKが24.0.1以降であることと、この実機テストの成功を確認してから明示依存を整理する。
