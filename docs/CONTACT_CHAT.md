# お問い合わせ

ユーザーごとに1つの運営との会話を持つ。名称は「お問い合わせ」に統一する。
最初の運営メッセージとして、次の固定文を表示する（未読件数には含めない）。

> こちらの画面ではCIT Appに関するお問い合わせや不具合報告、新機能提案などをすることができます。お気軽にメッセージをお送りください。

件名・カテゴリは不要。本文なしの画像送信にも対応し、画像は1回4枚まで。
送信前に添付を確認・削除でき、受信画像はタップで拡大できる。
画像はJPEGに変換・縮小し、撮影時のEXIFを除去する。Storageは本人とお問い合わせ担当者のみが読める。
公開ダウンロードURLを保存・共有せず、認証付きSDKで画像を取得する。

## 保存先と互換性

- `contact_chats/{uid}`: 最新メッセージ・対応状況・双方の未読/既読位置。
- `contact_chats/{uid}/messages/{id}`: 追記専用メッセージ。画像は `imagePaths` に保存先のキーだけを持つ。
- `contact_chat_images/{uid}/{senderUid}/{messageId}/{0..3}.jpg`: お問い合わせの添付画像。
- 画像なしの旧メッセージもそのまま表示できる。従来のフォームは「過去のお問い合わせ」に残す。
- 本文・サマリーは同一トランザクションで保存し、再送時は同じメッセージID・画像キーを再利用する。
- 運営返信は既存の「お問い合わせへの返信」通知設定に従う。ロック画面には本文・画像を載せない。
- ユーザーのアカウント削除時は、運営の返信・添付も含めてそのお問い合わせを削除する。

## ローカルで確認

```powershell
flutter run -d chrome -t tools/contact_chat_preview.dart
```

確認用画面は本番に接続せず、メモリー内にのみデータを持つ。
上部の選択欄で「お問い合わせ」を選び、「ユーザー画面」「運営画面」を切り替えて本文・画像の送受信を試せる。時間割・出欠管理・講義期間設定・Tips／カテゴリ画像も確認できる。リロードでリセットされる。

## 本番更新

```powershell
node scripts/deploy_contact_chat.cjs --deploy
```

反映先は `cit-app-2de1c`。準備だけ行う場合は `--prepare-only` を使う。
スクリプトは現在の本番ルールを取得し、お問い合わせ用のマーカーで囲んだ部分だけを追加・更新する。
ローカルの他機能のルール変更は本番に反映しない。元のルールとリリースIDは `build/contact-chat-deploy/` に退避する。

本番から取得して組み合わせたルールは、エミュレーターで他人の閲覧拒否・運営なりすまし・画像のアクセス制限を検証し、成功した場合のみ更新する。

Functionsは `notifyContactChatMessage`、`sendPushNotification`、`processAccountDeletion`、
`retryAccountDeletions` の4つに限定する。その後、本番ルールを再取得してFirestoreとStorageのルールを反映し、結果を照合する。
アプリのストア配信はこのスクリプトには含まれない。

この実行環境からはGoogle APIへの接続が制限されており、本番への反映は未完了。

## 検証

- Flutter: `flutter test test/services/contact/contact_chat_test.dart test/widgets/contact_chat_test.dart test/services/notification/notification_navigation_test.dart test/services/admin/admin_dashboard_test.dart test/widgets/admin_management_test.dart`
- Functions: `npm test --prefix functions`
- 更新スクリプト: `npm run test:contact-chat-deploy`
- Firestore/Storageの権限: `npm run test:contact-chat-rules`

この環境では通常のFlutterテストのローカル通信が制限されるため、テストエンジンで直接検証した。
Firestore/Storageルールはコンパイル確認済み。エミュレーターの権限テストと、実機からのStorage/FCM連携確認は未実施。