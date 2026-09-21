# Storage の大学メール認証と学年暦画像

## 2026-09-18 の修正

年間画像 (`year_calender/`) の取得で、`s.chibakoudai.jp` は成功する一方、
`p.chibakoudai.jp` と `chibatech.ac.jp` は 403 になることを本番で再現した。

`isCITUser()` がアカウント削除状態を確認した後、ドメイン判定の各
`authEmailLower()` でも同じ `firestore.exists()` を実行していた。
照会回数はドメイン順に 2 / 3 / 4 回になっていた。
Storage のクロスサービス照会上限をモックのルール検証だけでは再現できなかった。

`authEmailLower()` を認証情報からのメール取得だけにし、削除状態の照会を
`isCITUser()` の 1 回に集約した。大学メールの対象と削除中アカウントの拒否は維持する。

公式仕様: https://firebase.google.com/docs/storage/security/rules-conditions#enhance_with_cloud_firestore

## 検証

- 本番の一時アカウントで、修正前は s ドメインのみ list/get が 200、p と新ドメインは 403。
- 修正後は 3 ドメインすべて list/get が 200、一覧に年間画像 2 枚。
- 学外メールは修正後も list/get ともに 403。
- 検証用 Auth アカウントは各検証の finally で削除済み。
- 実機は接続されていなかったため、修正後の端末表示は未確認。

読み取り専用の回帰チェック:

```powershell
node scripts/test-storage-account-rules.cjs
```

Firebase CLI の既存認証を使う。合成ユーザーと Firestore モックによる 28 ケース
（3 大学ドメイン、大文字メール、学外・類似ドメイン、未認証、削除状態、get/list）を確認し、
アカウント状態照会が 1 回以下であることも検証する。実アカウント・データは作成しない。

本番反映した ruleset: `e3202d17-b2c5-4ebf-9c5d-1b0e7d062ed8`。
本番の最新ルールを取得し、この関数だけ変更して反映した。
