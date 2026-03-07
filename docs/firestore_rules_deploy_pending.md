# Firestoreルールデプロイ待ち状態

## 現在の状況

- **権限**: 閲覧者（Viewer）
- **デプロイ状態**: 未デプロイ（権限不足のため）
- **必要な権限**: 編集者（Editor）または所有者（Owner）

## 権限が付与された後のデプロイ手順

### 方法1: Firebase CLIでデプロイ（推奨）

```bash
# 1. Firebase CLIにログイン（必要に応じて）
firebase login

# 2. プロジェクトを確認
firebase use cit-app-2de1c

# 3. Firestoreルールをデプロイ
firebase deploy --only firestore:rules
```

### 方法2: Firebase Consoleから直接デプロイ

1. Firebase Consoleにアクセス：
   ```
   https://console.firebase.google.com/project/cit-app-2de1c/firestore/rules
   ```

2. `firestore.rules`ファイルの内容をコピー＆ペースト

3. 「公開」ボタンをクリック

## デプロイが必要な理由

`firestore.rules`に以下のルールが追加されています：

```javascript
// 学食お気に入りのルール（サブコレクション）
match /users/{userId}/cafeteria_favorites/{favoriteId} {
  // 読み取り: 自分のお気に入りのみ
  allow read: if isCITUser()
    && request.auth != null
    && request.auth.uid == userId;

  // 作成: 自分のお気に入りのみ、必須フィールドを満たすこと
  allow create: if isCITUser()
    && request.auth != null
    && request.auth.uid == userId
    && hasRequiredCafeteriaFavoriteFields();

  // 更新: 自分のお気に入りのみ
  allow update: if isCITUser()
    && request.auth != null
    && request.auth.uid == userId
    && resource.data.userId == request.auth.uid;

  // 削除: 自分のお気に入りのみ
  allow delete: if isCITUser()
    && request.auth != null
    && request.auth.uid == userId
    && resource.data.userId == request.auth.uid;
}
```

このルールがデプロイされていない場合、お気に入り機能で以下のエラーが発生します：
- `[cloud_firestore/permission-denied]` エラー
- お気に入りの追加・削除ができない
- 「My食堂」画面のお気に入りタブでエラーが表示される

## デプロイ前の動作確認

権限が付与されるまでの間、お気に入り機能は動作しませんが、以下の機能は正常に動作します：

- ✅ 学食レビューの表示
- ✅ レビューの投稿・編集
- ✅ いいね機能
- ✅ My食堂画面の「自分のレビュー」タブ

## デプロイ後の確認事項

デプロイが完了したら、以下を確認してください：

1. **お気に入り機能の動作確認**
   - メニューカードのお気に入りボタンをタップ
   - お気に入りに追加できるか確認
   - 「My食堂」画面の「お気に入り」タブで表示されるか確認

2. **エラーの確認**
   - アプリのログで`permission-denied`エラーが発生していないか確認
   - 「My食堂」画面でエラーが表示されていないか確認

## 注意事項

- Firestoreルールをデプロイすると、**即座に本番環境に反映**されます
- デプロイ前にルールの内容を十分に確認してください
- デプロイ後は、お気に入り機能が正常に動作するかテストしてください
