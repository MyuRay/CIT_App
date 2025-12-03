# Firebase Analytics Debug View 設定ガイド

Firebase AnalyticsのDebug Viewを有効にするには、プラットフォームごとに設定が必要です。

## Android での設定

### 方法1: ADBコマンドを使用（推奨）

1. AndroidデバイスをUSBで接続するか、エミュレーターを起動
2. ターミナルで以下のコマンドを実行：

```bash
adb shell setprop debug.firebase.analytics.app jp.ac.chibakoudai.citapp
```

**注意**: `setprop`コマンドは成功時に何も出力しません。これは正常な動作です。

3. 設定が正しく適用されているか確認（オプション）：
```bash
adb shell getprop debug.firebase.analytics.app
```
出力が `jp.ac.chibakoudai.citapp` と表示されれば成功です。

4. アプリを起動（既に起動している場合は再起動）

### 方法2: アプリ起動時に自動設定（開発用）

デバッグビルド時に自動的に設定する場合は、`MainActivity.kt`に以下を追加：

```kotlin
if (BuildConfig.DEBUG) {
    System.setProperty("debug.firebase.analytics.app", "jp.ac.chibakoudai.citapp")
}
```

**注意**: この方法は開発ビルドでのみ動作します。

## iOS での設定

### Xcodeのスキーム設定で環境変数を追加

1. Xcodeでプロジェクトを開く
2. メニューバーから「Product」→「Scheme」→「Edit Scheme...」を選択
3. 「Run」を選択し、「Arguments」タブを開く
4. 「Environment Variables」セクションで「+」をクリック
5. 以下の環境変数を追加：
   - **Name**: `-FIRDebugEnabled`
   - **Value**: `1`
6. 「Close」をクリック
7. アプリを再起動

### または、コマンドラインで実行

```bash
flutter run --dart-define=FIRDebugEnabled=1
```

## Debug Viewの確認方法

1. Firebase Consoleにログイン
2. プロジェクトを選択
3. 「Analytics」→「DebugView」を開く
4. アプリを操作すると、リアルタイムでイベントが表示されます

## トラブルシューティング

### AndroidでDebug Viewが表示されない場合

1. ADBコマンドが正しく実行されているか確認：
   ```bash
   adb shell getprop debug.firebase.analytics.app
   ```
   出力が `jp.ac.chibakoudai.citapp` であることを確認

2. アプリを完全に終了して再起動

3. Firebase Consoleで正しいプロジェクトを選択しているか確認

### iOSでDebug Viewが表示されない場合

1. Xcodeのスキーム設定で環境変数が正しく設定されているか確認
2. アプリを完全に終了して再起動
3. TestFlight経由では動作しません（実機またはシミュレーターでテスト）

## 注意事項

- Debug Viewは開発・テスト環境でのみ使用してください
- 本番環境では自動的に無効になります
- Debug Viewのデータは最大24時間保持されます

