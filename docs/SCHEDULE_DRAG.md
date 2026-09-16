# 時間割のドラッグ移動

時間割タブを編集モードにし、講義を長押ししたまま移動先へドラッグして指を離す。通常のタップは従来どおり講義編集を開く。閲覧モードでは移動しない。

- 指の位置にある曜日・時限が移動先の開始セル。枠で連続講義の全範囲を示す。
- 別の講義と1コマでも重なる場合は、赤枠と「重複」を表示する。そのまま離すと保存せず元の位置に戻り、重複する講義・時限をメッセージで案内する。
- 同じ講義の元の範囲と重なる移動は可能。例：月曜1〜2限から月曜2〜3限への移動。
- 連続講義が10限を越える場合は「移動不可」。範囲外へのドロップ、移動せずに指を離す操作、キャンセルでも保存しない。
- 画面の上下端で自動スクロールし、画面外の時限へ移動できる。ドロップまたはキャンセルで自動スクロールを停止する。
- 保存中はグリッドの再操作を防止。通信失敗時は元の位置に残し、再試行できる。
- スクリーンリーダーのカスタム操作「曜日と時限を選んで移動」から従来の選択ダイアログも使える。

移動は既存の `ScheduleService.moveClass` を通じてFirestoreトランザクションで保存する。画面での重複判定に加え、保存時の最新データでも移動元・連続講義の構成・移動先の空きを検証する。講義ID、色、教室、担当教員、メモ、連続コマ数を保持する。成功時はホーム表示、通知、ホーム画面ウィジェットを更新する。

## 検証

```powershell
C:\flutter\bin\flutter.bat test --no-pub test/widgets/schedule_drag_drop_test.dart test/widgets/schedule_class_move_test.dart test/services/schedule/schedule_move_test.dart
```

ドラッグ成功、開始セル／連続講義の後半での重複、同じ曜日での移動、10限超過、保存中の同時更新、通信失敗・再試行、キャンセル、通常タップ、閲覧モード、内側／外側のスクロール領域での自動スクロール、幅320px・文字200%・48pxのシステムナビ領域、ライト／ダークを検証する。

表示確認用画像は `docs/qa/schedule-drag/`。再生成する場合は上記テストに `--dart-define=THEME_PREVIEW_DIR=docs/qa/schedule-drag` を追加する。WindowsのMeiryoを用いたウィジェット描画であり、実機のスクリーンショットではない。Android実機・iOS実機での指操作とTalkBack／VoiceOverの実操作は未検証。

2026-09-16の結果：移動関連24テスト成功。全体では378テスト成功、任意のローカルExcelサンプルを必要とする1テストは未指定のためスキップ。対象ファイルの解析エラー0、既存の未使用宣言などの警告5・info35。`flutter build apk --debug --no-pub` 成功（Gradle 143.5秒）。

ログ：`build/schedule-drag-tests.log`、`build/schedule-drag-full-tests.log`、`build/schedule-drag-analysis.log`、`build/schedule-drag-build.log`。APK：`build/app/outputs/flutter-apk/app-debug.apk`。既存の未署名リリースAABはこの変更前のため、配布用には別途再ビルドが必要。
