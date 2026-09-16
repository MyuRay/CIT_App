# Windows / OneDrive配下のAndroidビルド復旧

確認日: 2026-09-12

## 発生した問題

Android Studioからの起動が `:app:cleanMergeDebugAssets` で失敗した。`build/app/intermediates/assets/debug/mergeDebugAssets` 以下の生成物を削除できなかった。

Gradleデーモンを停止して `flutter clean` を実行しても、`build` と `.dart_tool` の削除は失敗した。どちらもOneDrive配下の再解析ポイントを含むフォルダーだった。ロックを保持していた個別のプロセスは特定していない。

## 実施した復旧

ソースの場所を維持し、`scripts/prepare_windows_build.ps1` で次の生成フォルダーをOneDrive外へ分離した。

| プロジェクト内のパス | 実体の保存先 |
| --- | --- |
| `build` | `%LOCALAPPDATA%\CIT_App\build-cache\<ID>\build` |
| `.dart_tool` | `%LOCALAPPDATA%\CIT_App\build-cache\<ID>\.dart_tool` |
| `android/.gradle` | `%LOCALAPPDATA%\CIT_App\build-cache\<ID>\android-.gradle` |

プロジェクト内のパスはWindowsのジャンクションとして同じ実体を参照するため、Android Studioで開くプロジェクトやFlutterの通常の出力パスを変更する必要はない。IDはプロジェクトパスから算出し、別チェックアウトのキャッシュと分ける。

元の生成フォルダーは `.build-cache-backups` に日時付きで退避した。スクリプトは既存ファイルを削除しない。退避先はGitのローカル除外設定に登録し、共有するソースには含めない。

MicrosoftはOneDriveの同期でシンボリックリンク／ジャンクションをサポートしていない。この設定では、リンク先を**同期しないローカル生成物**として扱う。生成物のバックアップ用途には使わない。[Microsoftの制限事項](https://support.microsoft.com/en-us/onedrive/restrictions-and-limitations-in-onedrive-and-sharepoint)

## 確認結果

- 元のプロジェクト直下から `flutter pub get` が成功。
- 同じセットアップを再実行しても、既存リンクを維持し、新しい退避を作らないことを確認。
- 元のプロジェクト直下から `flutter run --debug` によるSamsung SM-S928Q向けビルドが成功。
- APKのインストール、MainActivityの前面表示、Flutter VM Serviceへの接続を確認。
- ホットリロードが成功。
- 続けて `:app:cleanMergeDebugAssets :app:assembleDebug` を明示的に実行し、**問題だった削除タスクを含めて再ビルドが成功**（41秒）。
- スクリプトの構文チェックと差分の空白チェックが成功。

検証後はFlutter CLIのデバッグ接続だけを切り離し、実機上のアプリは起動したままにした。Android Studioから次回の実行を開始できる状態。

## 次回の使い方

### 2026-09-16: Android Studioだけで `.dart_tool` の作成に失敗した場合

Android Studioからの実行で、`Got dependencies!` の直後に `Creation failed, path = '.dart_tool' (OS Error: 指定されたパスが見つかりません。, errno = 3)` が発生した。

このとき、`.dart_tool` のジャンクション、リンク先の実体、`package_config.json` は存在し、プロジェクト直下からの `flutter pub get --verbose` は終了コード0で成功した。一方、Android Studioは生成フォルダーを正しく認識せず、ログに `Unable to delete dill or write params` が出ていた。

編集中の内容を保存し、Android Studioを通常終了して開き直すと、依存パッケージの参照エラーが消えた。実行先にSamsung SM-S928Qを選び、Android Studioの実行操作でAPKのビルド・インストールとFlutter VM Serviceへの接続を確認した。`pubspec.lock` は作業前後で同じSHA-256だった。

この事例ではリンク先の消失は確認できず、IDEの再起動で復旧した。再発時も、生成フォルダーを削除する前にリンク先の存在とIDE外でのパッケージ取得を確認する。`132 packages have newer versions incompatible with dependency constraints` は更新案内であり、このパス作成エラーを解消するために依存バージョンを一括更新する必要はない。

### リンク先が消失した場合・セットアップをやり直す場合

通常はAndroid Studioの実行ボタンを使う。`flutter clean` 後や、別のWindows PCで同じ状況が起きた場合は、ビルド・デバッグを停止して次を実行する。

```powershell
.\android\gradlew.bat --stop
.\scripts\prepare_windows_build.ps1
flutter pub get
flutter run -d <device-id> --debug
```

`flutter clean` がジャンクションを取り除いた場合も、セットアップスクリプトで再設定できる。現在の端末での復旧は確認済みだが、別のWindows PC・OneDrive設定・長期間の同期動作は別途確認が必要。

共有のGradle設定、Flutter全体の出力設定、OneDrive全体の設定は変更していない。
