# 通報・ブロック機能実装ガイド

このドキュメントは、掲示板アプリにおける通報機能とユーザーブロック機能の実装手順をまとめた指示書です。既存の掲示板・コメント機能や管理者権限システムと連携し、Firebase セキュリティルールと整合する形で実装します。

## 目次
1. [前提条件と準備](#1-前提条件と準備)
2. [Firestore 構成](#2-firestore-構成)
3. [Flutter プロジェクト構成](#3-flutter-プロジェクト構成)
4. [UI/UX 要件](#4-uiux-要件)
5. [実装ステップ](#5-実装ステップ)
6. [バリデーションとエラーハンドリング](#6-バリデーションとエラーハンドリング)
7. [セキュリティルールとの整合](#7-セキュリティルールとの整合)
8. [テスト計画](#8-テスト計画)
9. [運用と将来的な拡張](#9-運用と将来的な拡張)

## 1. 前提条件と準備
- Firebase プロジェクトに Authentication・Firestore が有効化されていること。
- `firestore_rules_fixed.txt` に記載されている最新のセキュリティルールを使用すること。
- アプリは既に `AuthProvider` や掲示板関連のプロバイダを導入済みである前提とする。
- 通報／ブロックに共通で利用する定数・翻訳文字列を `lib/core/constants/` や `lib/l10n/` 配下に追加する。

## 2. Firestore 構成

### 2.1 コレクション概要
- `reports`: ユーザーによる投稿・コメント等の通報を記録。読み取り・更新は管理者のみ。
- `blocked_users`: ログインユーザーがブロックした相手の一覧。各自の UID 配下にレコードを保持。
- 補助コレクション（任意）: 運用で必要なら `hidden_posts` / `hidden_comments` を連動させ、ブロック時に自身の表示から除外できるようにする。

### 2.2 ドキュメントスキーマ

#### `reports/{reportId}`
```javascript
{
  "type": "post" | "comment" | "user", // 対象種別
  "targetId": "対象ドキュメントID または UID",
  "reporterId": "通報者UID",
  "reporterName": "通報者表示名",
  "reason": "enum: spam | abuse | inappropriate | other",
  "detail": "自由記述（任意）",
  "status": "pending" | "reviewing" | "resolved" | "rejected",
  "createdAt": Timestamp,
  "updatedAt": Timestamp（任意）
}
```

#### `blocked_users/{blockedId}`
```javascript
{
  "blockedUserId": "ブロック対象UID",
  "blockedUserName": "対象の表示名",
  "userId": "ブロック実施ユーザーUID",
  "reason": "enum: harassment | spam | personal | other",
  "notes": "自由記述（任意）",
  "blockedAt": Timestamp
}
```

### 2.3 インデックス
- `reports` の管理画面でステータス別に絞るため、`status` + `createdAt` の複合インデックスを作成。
- `blocked_users` は `userId` での取得頻度が高いため、`userId` 単体インデックスを確保（単純クエリの場合は自動生成で十分）。

## 3. Flutter プロジェクト構成

```
lib/
├── models/
│   ├── reports/
│   │   └── report_model.dart
│   └── users/
│       └── blocked_user_model.dart
├── services/
│   ├── reports/
│   │   └── report_service.dart
│   └── users/
│       └── user_block_service.dart
├── core/
│   ├── repositories/
│   │   ├── report_repository.dart
│   │   └── user_block_repository.dart
│   └── providers/
│       ├── report_provider.dart
│       └── user_block_provider.dart
└── screens/
    ├── reports/
    │   ├── report_form_dialog.dart
    │   └── report_management_screen.dart // 管理者向け
    └── user_block/
        ├── block_confirmation_dialog.dart
        └── blocked_user_list_screen.dart
```

## 4. UI/UX 要件
- **通報トリガー**: 投稿詳細画面・コメントメニューに「通報」アクションを配置。投稿・コメントそれぞれに対応する `targetId` を渡す。
- **通報フォーム**: 事前定義の理由（ラジオ／ドロップダウン）＋任意の詳細入力。送信前にプレビューや確認モーダルを出して誤送信を防ぐ。
- **送信後フィードバック**: 成功時にトースト／ダイアログで「通報を受け付けました」と表示し、重複通報を抑止。
- **ブロック操作**: ユーザープロフィールやコメントのアバタードロップダウンから「ブロック」を選択。確認ダイアログで対象名と影響範囲を明示。
- **ブロック結果**: ブロック後は自身のクライアントで対象ユーザーの投稿・コメントを非表示にする（プロバイダでフィルタリング）。解除操作も同画面から可能にする。
- **管理者画面**: `status` 別のタブ・検索、詳細ビューで対応履歴を記録できるようにする（更新は管理者のみ）。

## 5. 実装ステップ

### 5.1 モデル作成
- `Report`・`BlockedUser` クラスに `fromJson` / `toJson` を実装。
- `enum` を `extension` で文字列⇔列挙型に変換できるようにする。

### 5.2 リポジトリ層
- `ReportRepository`
  - `Future<void> submitReport(Report report)` で `reports` コレクションに追加。
  - 管理画面用に `Stream<List<Report>> watchReportsByStatus(ReportStatus status)` を提供。
  - `Future<void> updateStatus(String reportId, ReportStatus status)` を用意。
- `UserBlockRepository`
  - `Stream<List<BlockedUser>> watchBlockedUsers(String userId)`
  - `Future<void> addBlock(BlockedUser blocked)`
  - `Future<void> removeBlock(String userId, String blockedUserId)`

### 5.3 サービス層
- `ReportService` はリポジトリと `AuthProvider` を組み合わせ、フィールド自動補完（`reporterId` など）とバリデーションを担当。
- `UserBlockService` は自身の UID を注入し、既存のブロック状態チェック (`isBlocked(userId)`) と保存処理を提供。

### 5.4 プロバイダ設定
- Riverpod / Provider 等、既存の状態管理に合わせて `ChangeNotifier` もしくは `StateNotifier` を用意。
- 通報送信時は `AsyncValue` で状態を管理し、UI 側でローディング・エラー表示を切り替える。
- ブロック一覧はリスナーを用いてリアルタイム更新する。

### 5.5 UI 実装
- **通報フォーム**: `showDialog` で `ReportFormDialog` を表示し、送信ボタン押下でサービス経由の `submitReport` を呼ぶ。
- **ブロック確認**: `BlockConfirmationDialog` 内で理由選択と確認チェックボックスを提示。送信後はリスト画面に戻し、スナックバーで通知。
- **管理者画面**: `DataTable` または `PaginatedDataTable` を用いて一覧表示。詳細ダイアログでステータス変更ができるようにする。

### 5.6 コンテンツ除外ロジック
- ブロック済みユーザーの投稿／コメントは、一覧取得時に `where('authorId', isNotEqualTo: blockedUserId)` が使えないため、クライアント側でフィルタリングする。
- Firestore クエリは通常通り取得し、`UserBlockProvider` が保持する `blockedUserIds` セットで表示前に除外する。

### 5.7 Cloud Functions（任意）
- 管理者通知やスラック連携が必要な場合は、`reports` 作成トリガーの Cloud Functions を追加し、`status=pending` の通知を送る。

## 6. バリデーションとエラーハンドリング
- フロントエンドで入力必須チェック（理由の選択、任意詳細は 500 文字以内など）。
- サービス層で `AuthProvider.currentUser` が存在しない場合は処理を中断し、ログインを促す。
- Firestore 書き込みエラーは `FirebaseException` をキャッチしてユーザー向けメッセージに変換。
- 多重送信防止として送信完了まではボタンを disabled にする。

## 7. セキュリティルールとの整合
- `reports` 作成時には `reporterId == request.auth.uid` を満たすこと。`reporterName` や `status` など必須フィールドが揃っているかを `hasRequiredReportFields()` で検証。
- `blocked_users` では `userId == request.auth.uid` が必須。クライアント側で忘れずに設定し、`hasRequiredBlockedUserFields()` に対応する JSON を送る。
- 管理者によるステータス更新は `isAdmin()` の条件を満たす必要があるため、管理画面の操作には認証済み管理者のみアクセスさせる。

## 8. テスト計画
- **ユニットテスト**: モデルの `fromJson` / `toJson`、サービス層のバリデーション、プロバイダの状態遷移をテスト。
- **インテグレーションテスト**: 通報フォーム送信→Firestore 書き込み→管理者画面表示までのフローを `integration_test/` 配下に追加。
- **手動テストシナリオ**:
  - 通常ユーザーで投稿を通報し、管理者アカウントでステータス変更ができるか確認。
  - 同一対象の重複通報時に UI がどのように反応するか確認。
  - ブロック後に対象ユーザーの投稿・コメントが一覧から除外されるか確認。
  - ブロック解除後に再びコンテンツが表示されるか確認。

## 9. 運用と将来的な拡張
- 管理者が通報に対応した履歴（コメントや処理結果）を `reports` に `resolutionNote` フィールドとして追加する拡張を想定しておく。
- 多言語対応が必要な場合は、通報理由・ブロック理由のラベルをローカライズファイルに切り出す。
- ユーザーが自身の通報履歴を参照できるページを追加する場合は、ルールの変更（`reports` 読み取り権限）を検討する。
- ブロック機能をリアルタイム通知と連携し、ブロックされた側には通知しない設計を徹底する。
