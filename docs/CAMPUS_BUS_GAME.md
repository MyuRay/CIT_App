# キャンパス3Dマップと学バスタイムアタック

作業先は MasatoMythos の `C:\Users\mmura\OneDrive\Desktop\CIT_App`。既存変更を保持し、commit・push・本番公開は行っていない。

## 画面と操作

キャンパスカードのキャンパス名直下に「3Dマップ」、既存の「教室を探す」直下に「学バスタイムアタック」を置く。教室検索を保持する。3Dマップは津田沼・新習志野の既存GLB、ゲームは別入口の専用シーンを使用する。ゲームでキャンパスGLBの読み込みを待たせない。

地上のバス・車は左側の左右方向ボタンと、右側のアクセル・ブレーキを使用する。両ペダル同時押しはブレーキ優先。ブレーキから自動後退しない。押した指を保持し、ボタン境界外で継続し、実際の離指・キャンセル・画面非表示で解除する。カメラ操作とは指の所有権を分ける。

ゲームの道路と路肩は操作しやすい幅に変更し、道路外では減速する。正確なキャンパスモデルやDEMは変更しない。復帰は最後の検証済みチェックポイントへ戻し、5秒を加算する。サーバーは呼び出し側から指定されたチェックポイントを受け付けず、連続復帰には待機時間を設ける。

| コースID | 内容 | 距離 | 版キー |
|---|---|---:|---|
| outward | キャンパス間の往路 | 1,067.63m | 2edfca69 |
| return | キャンパス間の復路 | 1,067.63m | d2de1edd |
| s_bay | S字と高さ12mの立体交差 | 1,876.83m | 5dbf1dfb |
| neon_city | 長い直線と夜景・球体ランドマーク | 2,683.11m | a48f537d |

追加の２コースは公式資料から特徴を参考にした独自の形状・名称で、実寸複製ではない。公式ロゴ・画像・映像は配布しない。球体の位置関係は公式ラスベガス案内のTurn 5〜7–9付近を参考にする。光は穏やかにし、点滅させない。資料URLは `assets/models/campus/pop_courses.json` の `courseSources` に記録する。

旧記録は新しいコース群のベスト・ランキングに混ぜない。ローカルのキー、サーバーのチャレンジ、ルーム、公開順位に同じコースIDと版を使用する。立体交差では高さと進行順を検証し、上下の道路を取り違えない。

## 建物番号

マップ内の番号はGLBの明示的な建物IDと公式キャンパス図を照合した津田沼1〜9号館、新習志野1〜13号館だけに表示する。無番号の寮・別館から番号を推測しない。ラベルの重なりと画面操作部への重なりを避け、タップで詳細を開く。外観・高さは推定を含む。[出典と照合記録](campus_3d/building-label-sources.json)。公式地図画像・PDFはアプリに同梱しない。

## オンラインと名前

表示名はマイページと共通の `users/{認証UID}.displayName` を読み取る。ゲーム専用の名前入力・保存を設けない。メール・Auth表示名・実名・学籍番号へフォールバックしない。別人のUID・参照・名前を指定する要求はサーバーで拒否する。名前変更はルームとランキング・相手表示に反映する。正規プロフィールへのゲーム側の書き込みや、実ユーザーのデータ移行は行わない。

ランキング公開は別の明示的な同意を必要とする。ローカル完走記録をそのまま公開記録として受け取らず、認証済みCallable `campusGame` のチャレンジ・開始時刻・位置列・チェックポイント・速度・高さを検証する。2〜4人のルームは12文字の参加コード、ready、共通開始時刻を使用する。相手車両は表示用で、通信遅延を物理衝突に使用しない。

Functionsは本番未デプロイ。ローカルエミュレーターの確認が本番利用可能を意味しない。サーバー検証は申告位置を検査する方式で、サーバーによる完全な物理シミュレーションではない。

## Latest local verification

The recovery clock bug is fixed: retain the original shared-start clock,
reset only the server-selected checkpoint trace baseline, and record the real
restored pose at response receipt. No synthetic or backdated samples are added.
A response delayed over5s fails closed and allows explicit retry. Server speed,
checkpoint, height, sample-gap, finish-freshness and score rules are unchanged.

Node48 tests passed, including coupled real-server-core regressions for2.2s
and3s delayed recovery plus over5s fail-closed behavior. Flutter38 scoped tests
and the portable visual fixture recheck passed; backend25 unit tests and9
sequential emulator integrations remain valid (backend source unchanged).
Normal main.dart JavaScript Web and Android debug APK builds passed;67
source/Web/APK assets match; the QA driver is absent from the shipped engine.
The optional Wasm dry-run still fails in the existing image4.3.0 dependency.
Broader home/map analysis retains existing5 warnings/10 infos,0 errors.

The two independent real Flutter UI contexts passed all12 continuous checks,
with one driver having0 recoveries and the other exactly1 recovery whose real
HTTP response was delayed3000ms (3212ms round trip). Both verified server
finishes, published times/ranks, disconnect/reconnect, finished-room reload/code
rejoin and blank-name guide passed. Public times were59.365s and75.764s;
the latter includes exactly5s server penalty. No unexpected API/JS errors.
See [final record](campus_3d/final-validation.json) and
[UI evidence](campus_3d/flutter-two-client-validation.json).

The UI completion driver uses QA-only centreline motion and disables3D draws
after true first rendering; it proves UI/Auth/Callable/Firestore integration,
not physical steering/GPU performance. Eight real Flutter map/navigation checks
and6 genuine WebGL vehicle/orientation input checks are separate evidence.
Physical Android/iOS GPU/touch, iOS build, production online and scheduler
delivery remain unverified. Cleanup exported-handler expiry/preservation/
idempotence passed. Local demo emulators were stopped. No commit/push/deploy.
Library was previously unavailable; no new upload attempt was made.
