# ユーザー管理機能 - Firestoreセキュリティルール設定

## 必要なFirestoreセキュリティルール

Firebase Console → Firestore Database → Rules で以下を追加・更新してください：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // 既存のルール...
    
    // ユーザーコレクション（管理者のみ読み書き可能）
    match /users/{userId} {
      // 管理者のみ読み取り可能
      allow read: if request.auth != null &&
        exists(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)).data.isAdmin == true;
      
      // 管理者のみ書き込み・更新可能
      allow write, update: if request.auth != null &&
        exists(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)).data.isAdmin == true &&
        get(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)).data.canManageUsers == true;
      
      // 自分の情報は読み取り可能
      allow read: if request.auth != null && request.auth.uid == userId;
    }
    
    // 管理者権限コレクション
    match /admin_permissions/{userId} {
      // 自分の権限は読み取り可能
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // 管理者は全ての権限情報を読み取り可能
      allow read: if request.auth != null &&
        exists(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)).data.isAdmin == true;
      
      // ユーザー管理権限を持つ管理者のみ書き込み・更新・削除可能
      allow write, update, delete: if request.auth != null &&
        exists(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)).data.isAdmin == true &&
        get(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)).data.canManageUsers == true;
    }
    
    // ユーザーアクティビティログコレクション（管理者のみアクセス）
    match /user_activities/{activityId} {
      // 管理者のみ読み取り可能
      allow read: if request.auth != null &&
        exists(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)).data.isAdmin == true;
      
      // システムまたは管理者のみ書き込み可能
      allow write: if request.auth != null &&
        (
          // システムによる自動記録
          request.auth.uid == resource.data.uid ||
          // 管理者による記録
          (
            exists(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)) &&
            get(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)).data.isAdmin == true
          )
        );
    }
    
    // 全体通知コレクション（管理者のみ書き込み、全員読み取り可能）
    match /global_notifications/{document} {
      // 読み取りは全員に許可（ログインユーザーのみ）
      allow read: if request.auth != null;
      
      // 書き込み・更新・削除は管理者のみ
      allow write, update, delete: if request.auth != null &&
        exists(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // 問い合わせフォームコレクション
    match /contact_forms/{contactId} {
      // 作成者本人は読み取り可能
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      
      // 問い合わせ閲覧権限を持つ管理者は読み取り可能
      allow read: if request.auth != null &&
        exists(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)).data.isAdmin == true &&
        get(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)).data.canViewContacts == true;
      
      // ログインユーザーは作成可能
      allow create: if request.auth != null;
      
      // 管理者のみ更新可能（返信など）
      allow update: if request.auth != null &&
        exists(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)).data.isAdmin == true &&
        get(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)).data.canViewContacts == true;
    }
    
    // 掲示板投稿コレクション
    match /bulletin_posts/{postId} {
      // 全ログインユーザーが読み取り可能
      allow read: if request.auth != null;
      
      // 作成者本人は書き込み・更新可能
      allow create, update: if request.auth != null && request.auth.uid == resource.data.authorId;
      
      // 投稿管理権限を持つ管理者は削除・更新可能
      allow update, delete: if request.auth != null &&
        exists(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)).data.isAdmin == true &&
        get(/databases/$(database)/documents/admin_permissions/$(request.auth.uid)).data.canManagePosts == true;
    }
    
    // その他の既存コレクションルール...
  }
}
```

## 設定手順

1. **Firebase Console** にアクセス
2. プロジェクトを選択
3. **Firestore Database** → **Rules**
4. 上記のルールを追加・更新
5. **「公開」ボタン** をクリック

## 重要な権限設定

### 管理者権限の階層

1. **基本管理者権限** (`isAdmin: true`)
   - 管理者機能へのアクセス
   - 他の詳細権限の前提条件

2. **ユーザー管理権限** (`canManageUsers: true`)
   - ユーザー情報の読み書き
   - 管理者権限の付与・取り消し
   - ユーザーの有効化・無効化

3. **投稿管理権限** (`canManagePosts: true`)
   - 掲示板投稿の管理・削除

4. **問い合わせ閲覧権限** (`canViewContacts: true`)
   - ユーザーからの問い合わせ確認・返信

5. **カテゴリ管理権限** (`canManageCategories: true`)
   - 投稿カテゴリの管理

## 確認事項

- `admin_permissions`コレクションに管理者ユーザーのドキュメントが存在するか
- 必要な権限フィールドが適切に設定されているか：
  - `isAdmin: true`
  - `canManageUsers: true` (ユーザー管理機能を使用する場合)
  - `canManagePosts: true` (投稿管理機能を使用する場合)
  - `canViewContacts: true` (問い合わせ管理機能を使用する場合)
  - `canManageCategories: true` (カテゴリ管理機能を使用する場合)

## インデックス設定

以下のインデックスも作成してください：

1. **global_notifications**
   - Fields: `isActive (Ascending)`, `createdAt (Descending)`

2. **users**
   - Fields: `isActive (Ascending)`, `createdAt (Descending)`

3. **user_activities**
   - Fields: `uid (Ascending)`, `timestamp (Descending)`
   - Fields: `timestamp (Descending)` (全体の履歴用)

## トラブルシューティング

- **Permission denied エラー**: ルールの設定と管理者権限の確認
- **インデックスエラー**: 上記インデックスの作成
- **認証エラー**: Firebase Authenticationの設定確認