# ホーム画面ウィジェットと講義詳細の改善（2026-09-12）

## 実装した変更

- 学食レビューの並べ替えに「レビューの多い順」を追加。メニューごとのレビュー総数で降順にし、同数ならおすすめ評価、新しさ、名前で順序を確定する。この並べ替えでは本日のレビューを別枠にせず、全メニューを件数順で比較できる。
- 講義詳細を、講義名・日時、教室と担当教員、メモ、出欠の順に整理。教室検索、メモのURL、編集・保存、出欠集計、従来の条件で表示するQR出席を維持した。メモ保存失敗時は入力を保持し、未保存で閉じる場合は破棄確認を出す。編集中は教室検索・QR画面への移動を無効にする。
- 講義詳細はスクロール可能な高さ制限付きダイアログ。文字倍率2倍、幅320、キーボード表示、Androidの3ボタン領域を含む条件で操作を検証した。
- 講義詳細の出欠集計は出欠管理と同じ色に統一し、「出欠を編集」から講義日ごとの記録を直接変更できる。詳細は [講義詳細からの出欠編集](LECTURE_ATTENDANCE.md)。

## Android / iOSの共通設計

| ウィジェット | 表示 | iOSのサイズ / kind |
| --- | --- | --- |
| 今日の時間割 | 終了済みを含む当日の全講義、開始・終了時刻、教室、連続時限 | small / medium / large・`TodayScheduleWidgetProvider` |
| 週間時間割 | 各時限の開始・終了時刻、月〜金、必要な場合は土曜日、連続講義を結合 | large・`FullScheduleWidgetProvider` |
| 学バス | 優先キャンパス順の路線と次の出発時刻、更新日時 | small / medium・`BusRealtimeWidgetProvider` |

Flutterの `HomeWidgetPayloads` が schemaVersion 2 のJSONを作り、`HomeWidgetsService` が書き込みと再描画要求を直列に実行する。Androidは既存の共有設定、iOSはApp GroupのUserDefaultsを読む。週間データの従来の曜日キーは維持した。共有データにアカウントID、講義メモ、出欠は含めない。

今日の授業は保存した週間データと日本時間から端末側で選ぶ。連続授業は1件にまとめ、終了した授業も含めて時限順に全件を表示する。表示件数に上限を設けず、「ほか○件」への省略はしない。Android・iOSとも小さいサイズを維持し、高さと授業数に応じて1列／2列に切り替える。2列では左を上から下、その後に右を上から下へ読む。授業数が多い小サイズでは文字も縮小し、長い講義名・教室名は行末を省略する。読み上げには完全な講義名・教室・時刻を残す。iOSは日付変更と授業の開始・終了に対応するTimelineを作る。

### 各時限の時刻表示（2026-09-16）

- 週間表示の左端に「時限 / 開始時刻 / 終了時刻」を追加。講義がない時限や連続講義の途中の時限にも時刻を表示する。
- 今日の表示は、AndroidとiOSの全対応サイズで開始・終了時刻を表示する。授業中も時刻を省略しない。連続講義は最初の時限の開始から最後の時限の終了までを表示する。
- 共有JSONに `timeSlots` を追加し、1〜10限を時限順に保存する。設定された時刻を優先し、定義がない時限はアプリ本体と同じ `DefaultTimeSlots` を使う。Android・iOSの今日／週間表示とも、開始 `09:00` と終了 `10:00` をハイフンなしで上下2行に並べる。schemaVersion 2の既存の曜日・講義フィールドは維持する。
- 以前のキャッシュに `timeSlots` がない場合は、保存済み講義の開始・終了から分かる境界だけを表示する。不明な時刻や不正な時刻は `--:--` とし、独自設定を推測しない。更新版アプリで時間割を開くと全時限の時刻が保存される。
- Android週間表示は講義セル・空きセル・時刻欄の高さを統一。10限分の時刻を読めるよう、標準高さ340dp・縮小下限320dp、幅の下限250dpとした。旧サイズで高さが足りない場合は拡大案内を表示する。
- 時刻はライト／ダーク用の文字色を使用し、読み上げにも時限と時刻を含める。iOS 14を維持するため、等幅数字は [FontのAPI](https://developer.apple.com/documentation/swiftui/font/monospaceddigit()) を使用する。

今回の確認: 時刻共有データと連携のテスト10件・対象Dart静的解析に成功。Android debug APKビルド成功。iOSはSwift構文とXcodeプロジェクト構成の検査まで実施した（構文検査器の対象外である既存の `#available` 条件を除外）。Android実機は未接続、iOSのSDK型検査・ビルド・実機表示は未検証。

Androidの差分ビルドで一度 `WidgetSnapshot` のinternal参照エラーが発生したため、`--android-project-arg=kotlin.incremental=false` を付けた再コンパイルを実行した。その後、通常の `flutter build apk --debug --no-pub` も成功（27.7秒）。Gradleの恒久設定は変更していない。

端末確認時は、1限・10限、空きコマ、連続講義、独自時刻、旧キャッシュからの更新、各サイズと文字サイズ、ライト／ダークで、開始・終了時刻が講義行と揃うことを確認する。

ハイフンなしの縦並びへの変更後も、Samsung実機に更新版を上書きし、既存のネイティブテスト4件（描画70条件を含む）が成功した。Androidの今日表示は時刻2行分の高さを考慮し、iOSの小サイズでは2行の時刻と教室を横に並べて高さを抑えた。Swift構文・プロジェクト構成の検査も成功したが、iOS実機は未確認。今回も差分ビルドのinternal参照エラーが再発し、一時的な `--android-project-arg=kotlin.incremental=false` でAPKを生成した（49.1秒）。

学バスは当日分の絶対時刻を保存し、日本時間の翌日0時に期限切れとする。古い「あと○分」を表示し続けないよう、表示は「HH:mm 発」に統一した。iOSは各出発時刻にTimelineを切り替え、Androidは更新時点の次発であることを明示する。同じ内容の再描画要求は1分以内ではまとめる。ウィジェットから学バス画面を直接開いてもデータを書き直し、ホームへ戻れる。

OSがホーム画面ウィジェットの再描画タイミングを制御するため、秒単位の更新は保証しない。iOSの更新方針は[WidgetKitのTimeline](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)に従う。バスの翌日分取得、サーバー側の変更取得にはアプリを開く必要がある。

ログアウト時は週間・今日の両方を空にして再描画する。進行中の旧セッションの読み込みが、その後に時間割を復元しないようセッションの世代と所有者を確認する。

## Androidの追加失敗と日替わり更新の修正（2026-09-16）

- 実機の `Couldn't add widget` は、文字サイズ0.8倍の環境で自動縮小の最小値 `8dp` と最大値 `10sp` が同じ28pxとなり、RemoteViewsの展開に失敗していた。週間の時刻・講義・教室、今日の時刻の最小値を `sp` に統一し、端末の文字サイズと一緒に変化するよう修正した。
- Androidの今日の時間割は、日本時間の翌日0時に更新を予約する。保存した週間データから当日の講義を選ぶため、アプリを開く必要はない。端末再起動、アプリ更新、日時・タイムゾーン変更でも再描画と予約の復元を行い、最後の今日ウィジェットを削除すると予約を解除する。既存の30分周期の更新も維持する。
- 更新には `setAndAllowWhileIdle` を使用する。正確なアラームの特別な権限は要求しないため、0時ちょうどの表示切り替えは保証しない。省電力などによりOSが配信を遅らせる場合がある。[Androidのアラーム仕様](https://developer.android.com/develop/background-work/services/alarms)
- iOSも日本時間の日付変更と講義の開始・終了を1週間先までTimelineに用意し、翌日0時以降に再取得を要求する。保存済み時間割の日替わり表示を継続し、時間割そのものの変更取得には引き続きアプリの更新処理が必要。

### 今回の確認結果

- Samsung実機（Android API 36、文字倍率0.8）に修正版debug APKを上書きインストールした。アプリデータや端末の日時・文字サイズは変更していない。
- Androidネイティブテスト4件成功。7レイアウト × 5文字倍率（0.8 / 0.85 / 1 / 1.3 / 2）× ライト／ダークの70条件で、AndroidフレームワークによるRemoteViewsの展開と測定に成功した。
- 日本時間の0時前後で同じ週間データから別曜日の講義を選ぶこと、休日・月末・年末・うるう日、更新時に保存済み週間データを変更しないことを検証した。端末の実際の日付変更を待った試験は未実施。
- 実機のAlarmManagerに2026-09-17 00:00の更新予約が存在することを確認した。修正版インストール後の取得可能なログに、新しいRemoteViewsの展開エラーはなかった。
- 共有データのDartテスト10件と通常のAndroid debug APKビルドが成功。iOSはSwift構文とXcodeプロジェクト構成の検査までで、SDKビルド・実機は未検証。
- ホーム画面で修正後のウィジェットを目視する最終確認は、端末がほかの操作に使われていたため未完了。上記70条件の試験は描画処理の確認であり、ホーム画面の見た目の確認とは区別する。

### 今日の全授業を常時表示する変更（2026-09-16）

- Android・iOSの終了時刻による絞り込みと表示件数の制限を除去した。夜も当日の全授業を時限順に残し、日本時間の日付変更で翌日の一覧に切り替える。「本日の授業は終了」への置き換えは行わない。
- 小さいサイズも維持するという指定に合わせて、行当たりの高さが足りない場合は2列にする。時限・講義名を上段、教室を下段に置き、開始／終了の時刻は左にハイフンなしの2行で表示する。長い名称は行末を省略するが、授業そのものは省略しない。連続講義は1行にまとめ、授業中の表示と各行のタップ遷移を維持する。
- Androidの最小サイズ180×140dp、標準250×180dp、大きめ320×340dpについて、朝／深夜、文字倍率0.8／1／2、ライト／ダークの36条件で、10件すべての存在・時限順・行の収まり・時刻2行・タップ可能な状態を実機で検証した。連続講義と休講日のテストも追加し、既存分と合わせてネイティブテスト6件が成功した。
- Android debug APKを作成し、Samsung実機へアプリデータを保って上書きインストールした。全10件の架空データを実機で描画した画像について、最小サイズのライト／ダークと大きめサイズのライトを目視確認した。ユーザーの時間割データはテスト用データに置き換えていない。画像は `build/widget-recovery/today-all-*.png`、実行結果は `build/widget-recovery/all-day-tests.txt` に保存する。
- iOSは全対応サイズの表示を改修し、Swift構文・プロジェクト構成の検査に成功した。XcodeのSDKビルドとiPhoneでの表示確認は未実施。サイズごとの構成は[WidgetKitのサイズ対応](https://developer.apple.com/documentation/widgetkit/supporting-additional-widget-sizes)に従う。

実機テストは次の手順で実行できる。利用中のアプリデータを保つため、APKを上書きインストールして計測テストを直接実行する。Android StudioのJDKが利用できる環境で実施する。

```powershell
flutter build apk --debug --no-pub
Push-Location android
.\gradlew.bat :app:assembleDebugAndroidTest --console=plain
Pop-Location
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb install -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
adb shell am instrument -w -r -e class jp.ac.chibakoudai.citapp.widget.ScheduleWidgetRuntimeTest jp.ac.chibakoudai.citapp.test/androidx.test.runner.AndroidJUnitRunner
# 自分で追加したテスト用パッケージだけを削除する。
adb uninstall jp.ac.chibakoudai.citapp.test
```

## iOSの組み込みとMacでの確認

`ios/CITWidgets` にSwiftUI / WidgetKitの拡張を追加し、Runnerの依存ターゲットと埋め込み対象に設定済み。拡張はiOS 14以降を対象とし、iOS 17以降のウィジェット背景指定とダークモードに対応する。バージョン番号はFlutterの生成設定を共用する。

| 設定 | 値 |
| --- | --- |
| アプリのBundle ID | `com.masatomurai.citapp` |
| 拡張のBundle ID | `com.masatomurai.citapp.CITWidgets` |
| 共通App Group | `group.com.masatomurai.citapp` |
| 時間割のURL | `citapp://schedule?homeWidget=true` |
| 学バスのURL | `citapp://bus?homeWidget=true` |

RunnerとCITWidgetsのentitlements、UserDefaults、Flutterの `setAppGroupId` は同じApp Groupを使用する。iOSの初期化は必ず保存より先に行う。[home_widgetのiOS設定](https://docs.page/abausg/home_widget/setup/ios)に基づき、`iOSName` とWidgetKitのkindも一致させた。両ターゲットにUserDefaults利用のPrivacyInfoを含める。

**WindowsではiOSのSDKビルド・署名・実機表示は確認できていない。** Macで次を実行する。

1. `flutter pub get` の後、`ios` で `pod install` を実行し、`Runner.xcworkspace` をXcodeで開く。
2. Apple Developerで上記App Groupを登録し、アプリと拡張の両IDに割り当てる。XcodeのSigning & Capabilitiesでも両ターゲットに同じApp Groupが選択されていることを確認する。[AppleのApp Groups設定](https://developer.apple.com/documentation/Xcode/configuring-app-groups)
3. Runnerには既存の手動署名設定があるため、App Groupsを含むプロビジョニングプロファイルを再生成する。CITWidgetsは既存チームを指定した自動署名設定。実機デバッグには用途に合った開発用署名を選ぶ。
4. シミュレーターでSDK型検査・ビルドを確認する。リポジトリ直下から実行する例：

```sh
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

5. iPhoneで起動・ログインし、時間割を選び、学バス画面を開いて共有データを保存する。ホーム画面のウィジェット追加から3種類を配置する。
6. 各サイズ、ライト／ダーク、連続講義、講義終了と日付変更、ログアウト後の表示、アプリ終了中／起動中のタップ遷移を確認する。学バスは翌日になると更新案内を表示する。

## 初回実装時の検証（2026-09-12）

| 確認 | 結果 |
| --- | --- |
| `flutter test` | 74件成功。件数順、共有データ、iOS連携順序、学バスの直接起動、講義詳細の操作を含む |
| `dart analyze lib test` | エラー0。既存の警告46・情報430は残る |
| `flutter build apk --debug` | 成功 |
| Android実機 | 最終確認時点で接続端末なし。今回の変更の実機表示は未検証 |
| iOS | コードと構成の静的確認まで。Xcodeビルド・署名・実機表示は未検証 |

OneDriveの生成物ロックを避けるため、最終テストとAndroidビルドは同期対象外の同一ソースの作業コピーを使った。

Xcodeプロジェクトをパーサーで読み、拡張ターゲットの3構成、Runnerの依存と埋め込み、共有entitlements、PrivacyInfoのリソース組み込みを確認した。Swiftの構文検査も実施したが、検査器が解釈しない標準の `#available` 条件は除外している。この検査はXcodeによるSDK型検査・ビルドの代替にはならない。
