# My食堂機能 - Firebase関連設定ガイド

My食堂のお気に入り機能を動作させるために必要なFirebase設定をまとめています。

---

## 1. 必要なFirebase設定一覧

| 項目 | 状態 | 説明 |
|------|------|------|
| Firestore ルール | デプロイ必要 | `cafeteria_favorites` 用のセキュリティルール |
| Firebase Auth | 既存 | ログイン必須（CITメールアドレス） |
| Firestore データベース | 既存 | 有効化済み |
| google-services.json (Android) | 既存 | `android/app/` に配置 |
| GoogleService-Info.plist (iOS) | 既存 | Xcodeで設定 |

---

## 2. Firestore ルールのデプロイ（必須）

お気に入り機能は `users/{uid}/cafeteria_favorites/{favoriteId}` にデータを保存します。このコレクションへのアクセスには、`firestore.rules` に定義されたルールのデプロイが必要です。

### 2.1 必要な権限

- Firebase プロジェクトの **編集者（Editor）** または **所有者（Owner）** 権限
- 閲覧者（Viewer）のみの場合はデプロイできません

### 2.2 デプロイ手順

```bash
# 1. Firebase CLI にログイン（未ログインの場合）
firebase login

# 2. プロジェクトを指定
firebase use cit-app-2de1c

# 3. Firestore ルールのみデプロイ
firebase deploy --only firestore:rules
```

### 2.3 デプロイ前の確認（任意）

```bash
# 構文チェック（実際にはデプロイしない）
firebase deploy --only firestore:rules --dry-run
```

### 2.4 デプロイ後の確認

1. [Firebase Console](https://console.firebase.google.com/project/cit-app-2de1c/firestore/rules) でルールが更新されているか確認
2. アプリで以下を確認：
   - 学食レビュー画面のメニューカードでお気に入りボタンをタップ → 追加できる
   - My食堂の「お気に入り」タブで一覧が表示される
   - お気に入りをタップしてメニュー詳細・食堂一覧に遷移できる

---

## 3. cafeteria_favorites のルール内容

`firestore.rules` に含まれるルール（抜粋）：

```
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

  // 更新・削除: 自分のお気に入りのみ
  allow update, delete: if isCITUser()
    && request.auth != null
    && request.auth.uid == userId
    && resource.data.userId == request.auth.uid;
}
```

- **isCITUser()**: `@s.chibakoudai.jp`, `@p.chibakoudai.jp`, `@chibatech.ac.jp` のメールアドレスでログインしたユーザーのみ
- **hasRequiredCafeteriaFavoriteFields()**: `type` が `cafeteria` または `menu` で、必須フィールドが揃っていること

---

## 4. ルール未デプロイ時の動作

| 機能 | 動作 |
|------|------|
| My食堂「自分のレビュー」タブ | ✅ 動作（`cafeteria_reviews` は別ルール） |
| お気に入りボタンで追加 | ❌ `permission-denied` エラー |
| お気に入りタブの表示 | ❌ `permission-denied` エラー |
| お気に入りからの詳細遷移 | お気に入り一覧が表示されないため利用不可 |

---

## 5. その他のFirebase設定（参考）

### 5.1 firebase.json

```json
{
  "firestore": {
    "rules": "firestore.rules"
  },
  "functions": [...]
}
```

Firestore ルールのファイルパスは `firestore.rules` で指定されています。

### 5.2 トラブルシューティング

| エラー | 対処 |
|--------|------|
| `Permission denied` | ルールがデプロイされていない、または権限不足 |
| `Firebase CLI not found` | `npm install -g firebase-tools` でインストール |
| `Project not found` | `firebase use cit-app-2de1c` でプロジェクトを指定 |

---

## 6. まとめ

1. **Firestore ルールをデプロイ**すれば、My食堂のお気に入り機能が動作します
2. デプロイには Firebase プロジェクトの **編集者以上の権限** が必要です
3. 権限がない場合は、プロジェクト管理者にデプロイを依頼してください
