# Androidクラッシュ調査（2026-09-17）

## 結論

実機でFirestoreトランザクションのネイティブクラッシュを確認した。使用中の `cloud_firestore 5.6.12` のAndroid実装には、コールバックのタイムアウト時に処理を正常終了扱いしてしまい、遅れて続行した読み込みが終了済みトランザクションへアクセスする問題がある。公式報告 #18666 とエラー・呼び出し経路が一致し、公式修正 #18668 がある。

今回のアプリ内の発火点は通知端末の再登録が最有力。エラー直前のログと、そこで行う2回の逐次読み込みが一致する。ただし、アプリのログには失敗した読み込みのパス・エラーコードがないため、どちらの読み込みが何秒遅れたかまでは直接記録されていない。

## 実機で確認した事実

対象は接続中のSamsung SM-S928Q、アプリは `jp.ac.chibakoudai.citapp`、2.3.0 / versionCode 81。

| 時刻（JST） | 記録 |
| --- | --- |
| 9/17 23:41〜23:47 | 認証保持の実機テスト開始・終了、APK更新、明示的なforce-stopによる終了が複数。Androidの終了理由は `USER REQUESTED / FORCE STOP` または `PACKAGE UPDATED`。 |
| 9/17 23:48:52.869 | アプリ復帰。コード上、ログイン中の復帰時には通知端末を再登録する。 |
| 9/17 23:49:23.967 | `通知端末の登録に失敗しました`。 |
| 9/17 23:49:23.968 | 同じアプリプロセスでFirestoreの `AssertionError`。 |
| 9/17 23:49:23.972 | Androidの終了理由 `APP CRASH(EXCEPTION)`。 |
| 9/16 03:30:11.397 | 同じFirestoreの例外が過去ログにも存在。9/17の課題カードの表示調整より前から発生している。 |

致命的エラーの要点:

```text
java.lang.AssertionError: INTERNAL ASSERTION FAILED:
A transaction object cannot be used after its update callback has been invoked.
com.google.firebase.firestore.core.Transaction.ensureCommitNotCalled
com.google.firebase.firestore.Transaction.get
io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestorePlugin.transactionGet
```

直近の終了をすべてテストによる停止と扱うのは誤り。上記の実際のクラッシュと、テストによる停止が混在している。今回捕捉した実クラッシュの終了理由はメモリ不足やANRではない。

## コードとの対応

- `lib/main.dart` の `_checkAuthenticationOnResume` は復帰のたびに `NotificationService.refreshTokenRegistration()` を呼ぶ。表示中の画面に依存しない。
- `lib/services/notification/device_token_store.dart` の `register` / `unregister` は、同一トランザクションで親の旧トークン文書と端末文書を順番に `await transaction.get(...)` する。
- `cloud_firestore_platform_interface 6.6.12` の既定タイムアウトは30秒。
- ローカルに解決された `cloud_firestore 5.6.12` の `TransactionStreamHandler.java` は、時間切れに例外を投げず、失敗を表すオブジェクトをコールバックから返す。Android SDKには正常なコールバック終了として見え、後続の読み込みが終了済みトランザクションへ到達する。
- 同バージョンの `FlutterFirebaseFirestorePlugin.java` の `transactionGet` は `Exception` のみ捕捉する。`AssertionError` はその対象外なので、Dart側の `catchError` があってもAndroidプロセスが終了する。

起動ログにはApp Checkの403もあったが、今回の読み込み遅延との因果関係は未確認。これをクラッシュの直接原因とは断定しない。

## 修正方針と検証条件

1. 公式修正を含むFirestore連携ライブラリへ更新するか、互換性を維持した形で公式修正を取り込む。公式CHANGELOGでは6.10.0の修正項目に記載がある。更新時はFirebase Core/Auth等の依存関係とiOSの要件も確認する。
2. 通知登録の失敗ログには、トークン・ユーザーID・文書内容を記録せず、エラーコードと処理時間を残す。復帰のたびの重複した登録要求もまとめる余地があるが、回数削減やタイムアウト延長だけでは根本修正にならない。
3. 修正後、隔離したテスト用データで「1回目の読み込みがタイムアウト後に戻り、2回目に進む」ケースをAndroidで確認する。通常の通知登録、ログアウト時の端末解除、複数端末の保持も確認する。

原因調査の段階では端末のログを読み取り、実際に発生したクラッシュを捕捉した。既存のDart単体テストでは、このAndroidプラグインの挙動は検証できない。

## 修正（2026-09-18）

`cloud_firestore 5.6.12` の公式配布アーカイブをSHA-256で検証し、ランタイムソースを `third_party/cloud_firestore` に収録した。現在のFirebase依存関係とApple対応範囲を保つため、Androidの2ファイルへ公式修正 `168172a8` を移植した。Pubキャッシュは編集していない。

- タイムアウト／割込み時には失敗オブジェクトを返さず、例外を投げてネイティブトランザクションを中断する。
- `transactionGet` のネイティブ例外をFlutterへ返し、Androidプロセスを終了させない。
- ルートの `pubspec.yaml` は相対パスのoverrideで修正版を参照する。通常の `flutter pub get` とAndroid Studioのビルドにも適用される。
- アーカイブとの比較で、2つのJavaソースと追加の `PATCHES.md` 以外の配布ファイルに差分がないことを確認。Firebase Auth 24.0.1の既存修正も保持する。

通知の登録回数抑制やログ項目追加は、この根本修正に含めていない。

### Android回帰テスト

`FirestoreTransactionTimeoutTest.kt` は実際にAPKへ組み込まれた `TransactionStreamHandler` とAndroid Firestore SDKを使う。1回目の読み込み後、実際のコールバックタイムアウトを待ってから2回目を読み、致命的assertionの有無を調べる。修正前モードではassertionをテスト内で捕捉して既知の不具合を確認するため、意図的なプロセスクラッシュは不要。終了後に正常なトランザクションで更新できることも確認する。

本番とは別の名前付きFirebase app、`demo-cit-transaction-regression`、ローカル8091番ポートのみを使う。実機のアプリデータ・本番Firestoreを削除しない。テスト自体の開始・終了時にはAndroidが対象アプリを停止する。

```powershell
# 1. プロジェクト直下でローカルFirestoreエミュレーターを起動する。
.\node_modules\.bin\firebase.cmd emulators:start --only firestore --project demo-cit-transaction-regression --config firebase.transaction.test.json

# 2. 別のターミナルでビルドする（Android用JDKをJAVA_HOMEに設定しておく）。
flutter pub get
Push-Location android
.\gradlew.bat :app:assembleDebug :app:assembleDebugAndroidTest
Pop-Location

# 3. 接続端末のserialを指定する。-rはデータを保持して上書きする。
$deviceSerial = 'R5CX51A651D'
adb -s $deviceSerial reverse tcp:8091 tcp:8091
adb -s $deviceSerial install -r build/app/outputs/apk/debug/app-debug.apk
adb -s $deviceSerial install -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
adb -s $deviceSerial shell am instrument -w -r -e class jp.ac.chibakoudai.citapp.firestore.FirestoreTransactionTimeoutTest -e firestoreRegression true jp.ac.chibakoudai.citapp.test/androidx.test.runner.AndroidJUnitRunner

# 4. 結果がOK (1 test)であることを確認後、テスト用転送を解除してアプリを開く。
adb -s $deviceSerial reverse --remove tcp:8091
adb -s $deviceSerial shell am start -W -n jp.ac.chibakoudai.citapp/.MainActivity
```

修正前のAPKで比較するときだけ `-e expectUnpatched true` を指定する。比較後は必ず修正版APKへ戻す。エミュレーターは終了する。将来Firebase全体を更新する際は `third_party/cloud_firestore/PATCHES.md` の削除条件に従う。

### 確認結果

- アプリ全体のFlutterテスト: 562件成功、既存の2件スキップ。
- Android debug APK / androidTest APK: ビルド成功。
- 同じSamsung実機で修正前APKを検証し、遅延した2回目の読み込みで既知の `AssertionError` が発生することを確認（テスト内で捕捉、`expectUnpatched=true` で成功）。
- 修正版APKでは同じ条件で `deadline-exceeded` が通知され、2回目の読み込みによる致命的assertionは発生せず。その後の通常トランザクションも保存成功。回帰テスト `OK (1 test)`。
- 2026-09-18 00:03:27 JSTに修正版APKを実機へ上書き。通常アプリのコールドスタート、ログイン状態の復元、プッシュ通知初期化を確認。新しいアプリプロセス（PID 9222）のクラッシュバッファは空。
- テスト用ADB転送とローカルFirestoreエミュレーターを停止。アプリデータ消去・本番ルールのデプロイは実施していない。
- iOSネイティブ実行は未実施。iOS・Dartソースは公式5.6.12と同一であることをファイル比較で確認。

証跡は `build/firestore-crash-baseline-test.log`、`build/firestore-crash-fixed-test.log`、`build/firestore-crash-fixed-launch.log`、`build/firestore-crash-build.log`、`build/firestore-crash-flutter-tests.log`（Git対象外）。

## 根拠

- [公式の不具合報告 #18666](https://github.com/firebase/flutterfire/issues/18666)
- [公式修正コミット 168172a8](https://github.com/firebase/flutterfire/commit/168172a889c0d08c0b618d7ef68d9c5ce503dc40)
- [Firestore CHANGELOG](https://github.com/firebase/flutterfire/blob/main/packages/cloud_firestore/cloud_firestore/CHANGELOG.md)
- ローカル調査ログ: `build/cit-crash-exit-info.txt`、`build/cit-crash-buffer.txt`（Git対象外）。
