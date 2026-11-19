# ローカルUI更新

- 時間割の末尾に追加した11〜15限を削除可能。確認後、その時限にかかる連続講義全体も削除する。1〜10限は残す。最新データと確認時の時限数をトランザクションで照合する。
- 時間割名は `name`、年度・学期は既存の `semester` に保存する。選択時は `2026年度前期` の形式。未設定で作成した時間割にも、出欠管理のカレンダーアイコンから設定できる。名前の変更は学期に影響しない。
- 管理者の講義期間は `app_settings/lecture_period.periods.{year}_{spring|fall}` に追加する。各項目は `year/isFall/startDate/endDate/isActive`。年度は4月〜翌3月。重複追加は拒否し、登録済みの項目は一覧から編集する。
- 同じ年度・学期の新しい設定を従来の春／秋フィールドより優先する。無効化した期間には従来フィールドを適用しない。出欠管理、ホームの週表示・期間判定、通知に共通の期間判定を使う。
- お問い合わせは余分な説明ヘッダーを置かず、指定の運営メッセージを先頭に表示する。
- マイページは「便利な機能・カスタマイズ」。全機能を表示し、編集操作は置かない。
- Cwitterは時刻を左、アクション群を右に配置する。
- ホームの課題カードは未登録でも初期表示。ユーザーによる明示的な非表示設定は維持する。
- 吹き出しはライトで白地・黒枠・黒文字、ダークで黒地・白枠・白文字。4種類のTipsを既存のランダム表示に加える。ホームカスタマイズのTipsはメニューアイコンを文中に表示する。
- 掲示板の画像未設定時は、保存済みカテゴリのアイコン・名前・色から共通カバーを描画する。投稿／編集フォーム、一覧、詳細、管理者プレビューで同じカバーを使う。写真が設定されていれば写真を優先する。

## 確認

```powershell
flutter run -d chrome -t tools/contact_chat_preview.dart
flutter test test/services/schedule/academic_terms_test.dart test/widgets/customization_update_test.dart test/widgets/attendance_semester_dates_test.dart test/services/schedule/extended_periods_test.dart test/widgets/schedule_extra_periods_test.dart test/services/schedule/schedule_notifications_test.dart
```

確認用画面の保存先はメモリーのみ。本番データは更新しない。