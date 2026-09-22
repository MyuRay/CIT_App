# 起動時のアップデート案内

アプリ起動後、インストールされたアプリのバージョン・ビルド番号と Firebase Remote Config の公開済みリリースを比較する。
古い場合は「アップデートのお知らせ」を一度表示し、「更新する」でストアを開く。「あとで」や戻る操作でも閉じられる。
ストアから戻っただけでは再表示しない。アプリを終了して次回起動した際には再確認する。

- 通信失敗、6 秒の確認タイムアウト、不正・未設定のデータでは案内せず通常起動する。
- Remote Config の取得間隔は最短 1 時間。画面の表示は通信完了を待たない。
- チュートリアルやダイアログが開いている間、またバックグラウンド中は表示を待つ。
- 更新案内のある起動では、ストアのレビュー依頼を表示しない。
- 最新版や開発用の先行バージョンには表示しない。同じバージョン名でもビルド番号が新しければ対象。
- Web・デスクトップ版は対象外。Android と iOS の公開情報は別々に管理する。

## Firebase の設定

プロジェクト `cit-app-2de1c` の **Remote Config** に以下の JSON パラメータを設定する。
現時点で確認済みの公開済み Android 版を例にしている。未公開の版を入力しない。

`app_update_android`:

```json
{
  "enabled": true,
  "version": "2.3.1",
  "buildNumber": "82",
  "storeUrl": "https://play.google.com/store/apps/details?id=jp.ac.chibakoudai.citapp"
}
```

`app_update_ios` は iOS の公開済みバージョンと App Store URL を設定する。Android の公開番号を流用しない。
2026-09-22 に Apple の公開情報で、アプリ ID `6752514796`、Bundle ID `com.masatomurai.citapp`、公開バージョン `2.0.0` を照合済み。

```json
{
  "enabled": true,
  "version": "2.0.0",
  "storeUrl": "https://apps.apple.com/jp/app/cit-app/id6752514796"
}
```

iOS では公開情報からビルド番号を取得できないため、`buildNumber` を省略してバージョン名で判定できる。
省略時は同じバージョン名への案内をしない。App Store Connect で公開済みビルド番号が確認できる場合のみ設定してよい。
Android は公開済み `versionCode` による比較が必要なので `buildNumber` が必須。

`enabled: false` で案内を停止できる。パラメータは公開情報のみで、個人情報や秘密情報を含めない。
インストール済みの値は `package_info_plus` で OS から取得するため、表示用定数やビルド時の上書き値との差異に影響されない。

## 次回リリース時の手順

1. 機能を含むアプリをストアへ配信する。
2. **対象ユーザー全員が更新できる状態**になったことを確認する。審査中や段階配信中には公開番号を進めない。
3. Remote Config の `version`・`buildNumber` を更新して公開する。

PowerShell 7 用スクリプトでも同じ設定ができる。以下は **2.3.3 (84) が公開された後**の例。

```powershell
.\scripts\publish_app_update.ps1 -Platform android -Version 2.3.3 -BuildNumber 84
```

iOS は App Store での公開確認後に、独立したバージョンを設定する。現在の公開版を設定する例:

```powershell
.\scripts\publish_app_update.ps1 -Platform ios -Version 2.0.0
```

Android と iOS の URL はスクリプト内の既定値が別々になっている。必要に応じて `-StoreUrl` で明示できる。

`-ValidateOnly` を付けると設定の検証のみ。`-Disable` を付けると案内を停止する。
既存の他のパラメータを保持し、ETag により同時変更の上書きを防ぎ、公開前の検証と公開後の読戻しを行う。
必要な権限は Remote Config の読取り・更新。スクリプトは既存の `gcloud.cmd` 認証を使い、トークンを保存しない。

**この機能を持たない既存の配信済みアプリには、設定だけでポップアップを追加できない。**
まずこの機能入りの版へ更新してもらう必要がある。その後の更新から案内できる。

## 検証

```powershell
flutter test test/services/app_update_service_test.dart test/widgets/app_update_prompt_test.dart
```

バージョン比較、同名ビルド更新、誤ったストア URL、通信失敗、タイムアウト、重複表示、バックグラウンド、
既存ダイアログとの順序、ストア起動失敗、幅 320px・文字倍率 200% のライト／ダーク表示を確認する。
本番に架空の新バージョンを設定してテストしない。テストでは取得結果とストア操作を差し替える。
追加したネイティブプラグインはホットリロードでは読み込まれないため、端末テスト時はアプリを再ビルドする。
iOS は Mac で `pod install` とビルド・実機確認が必要。

参考: [Firebase Remote Config の Flutter 導入](https://firebase.google.com/docs/remote-config/flutter/get-started)、
[テンプレートの更新と ETag](https://firebase.google.com/docs/remote-config/automate-rc)。
