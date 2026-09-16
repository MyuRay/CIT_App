# Android Analyticsの調査（2026-09-12）

## 結論

現行AndroidアプリからのデータはGoogle Analyticsに届いている。Firebaseのプロジェクト概要では、別のAndroidアプリ登録が表示対象になっており、現行のアプリ登録は非表示になっていた。2つとも表示名が「CIT App」のため区別しにくい。

## 管理画面で確認した事実

プロジェクト: `cit-app-2de1c`、GA4プロパティ: `499656302`。

| Androidのパッケージ | Firebase概要の表示 | Analyticsストリーム | 受信状態 |
| --- | --- | --- | --- |
| `jp.ac.example.cit.cit_app` | 表示中 | `11858107829` | 過去48時間の受信なし |
| `jp.ac.chibakoudai.citapp` | 非表示 | `14974290384` | 過去48時間にトラフィックデータを受信 |

Firebase概要の「4 アプリ」を開くと「表示可能なアプリ 3 個（最大 3 個）」と表示された。旧Android登録・iOS・Webが表示中で、現行Android登録には「データを表示」の操作が出ている。

現行ストリームの詳細には、プラットフォーム `Android`、パッケージ `jp.ac.chibakoudai.citapp`、FirebaseアプリID `1:196876028875:android:a57b785c4a4213fca1444e` が表示された。

- [Firebaseプロジェクト概要](https://console.firebase.google.com/u/1/project/cit-app-2de1c/overview?hl=ja)
- [現行Androidアプリの登録](https://console.firebase.google.com/u/1/project/cit-app-2de1c/settings/general/android:jp.ac.chibakoudai.citapp?hl=ja)
- [Analyticsのデータストリーム一覧](https://analytics.google.com/analytics/web/?authuser=1&hl=ja#/a346066863p499656302/admin/streams/table)
- [現行Androidストリームの詳細](https://analytics.google.com/analytics/web/?authuser=1&hl=ja#/a346066863p499656302/admin/streams/table/14974290384)

## アプリ・ビルド側の確認

- `android/app/build.gradle.kts` の applicationId は `jp.ac.chibakoudai.citapp`。Google Servicesプラグインも適用されている。
- `android/app/google-services.json` の現行パッケージに対応するアプリIDは、管理画面と一致する。
- 直前に成功したAndroid debugビルドの生成リソース `google_app_id` も同じID。統合済みManifestにはAnalyticsとFirebaseの初期化コンポーネント、および通信権限が存在する。
- `lib/main.dart` はモバイルでネイティブのFirebase設定を使用し、Analytics収集を有効にして `app_open` を記録する。Androidの収集を停止する設定は見つからなかった。

## 表示を直す方法

Firebase概要 →「4 アプリ」で、`jp.ac.example.cit.cit_app` を非表示にし、`jp.ac.chibakoudai.citapp` を表示する。表示上限が3個なので、旧登録と現行登録を入れ替える。

これは概要画面に出すアプリの選択であり、アプリ登録の削除やSDK設定の変更は必要ない。管理画面にも、プロジェクト単位の指標にはすべてのアプリが含まれ、詳細は選択したアプリだけに表示される旨の説明がある。

今回の依頼は調査のため、アプリコードと管理画面の表示設定は変更していない。

## 確認範囲

管理画面で現行Androidストリームへの直近48時間の受信を確認した。調査時点ではADB接続端末がないため、特定のテスト端末・最新APKからの送信は個別に検証していない。

端末単位の確認が必要な場合は、対象端末のAnalyticsログと[DebugView](https://firebase.google.com/docs/analytics/debugview)を照合する。通常のレポートには[24〜48時間の処理時間がかかる場合がある](https://support.google.com/analytics/answer/9333790)。
