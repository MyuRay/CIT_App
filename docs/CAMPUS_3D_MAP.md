# 3Dキャンパス探索 — 2026-10-04

## 最新の入口・番号ラベル

キャンパス名直下の「3Dマップ」は正確なモデル表示へ入り、「教室を探す」直下の「学バスタイムアタック」は別のゲーム専用シーンへ入る。以下のスティック・GLB衝突説明は地図探索モードの仕様。ゲームの方向ボタン・ペダル・4コースは [CAMPUS_BUS_GAME.md](CAMPUS_BUS_GAME.md) を参照する。

津田沼1〜9号館、新習志野1〜13号館の番号を、GLBの明示IDと公式図を照合して表示する。重なり・画面外・操作部付近のラベルは抑制し、タップで詳細、戻る操作で詳細を閉じる。無番号の寮・別館から番号を推測しない。[公式図の確認記録](campus_3d/building-label-sources.json)。既存GLBは改変していない。

以下の件数は初期マップ版の検証記録。最新のFlutter対象テスト36件、解析エラー・警告0（既存Matrix4非推奨情報2件）が通過。最新ブラウザー・ビルド結果は後続の検証記録で区別する。

実装先: `C:\Users\mmura\OneDrive\Desktop\CIT_App`（MasatoMythos）

既存の教室マップのAppBarとホームのキャンパス画像から3D探索へ入り、津田沼・新習志野を切り替えられる。Webはiframe、Android/iOSはlocalhostのWebViewで、同梱GLBとオフラインのThree.jsエンジンを表示する。Firebaseのユーザーデータは3D描画に使わない。

## 操作

- 自由視点: ドラッグで回転、ピンチで拡大、2本指で平行移動。
- 車: 左スティックの上下で加速・減速・後退、右スティックの左右で操舵。
- 飛行機: 左スティックの上下で加減速、右スティックの上下で上昇・下降、左右で旋回。
- 車・飛行機でも、操作部以外の画面をスワイプすると追従カメラの方位・仰角が変わる。左右スティックと3本目の指による視点操作を併用できる。
- キーボード: 矢印/WASD、上昇R・下降F、停止Space。
- 停止は現在位置で入力と速度を解除。リセット・モード切替は出発位置へ戻す。

スティックには中央の遊びと入力強度があり、右の斜め入力は正規化する。1つのスティックは1本の指だけが所有し、余分な指で奪えない。指がスティックの枠外に出ても、元のpointerIdが所有したまま入力を上限で保持する。枠内へ戻せば位置に応じた強度へ戻り、同じ指のリリースまたは真のキャンセルまで操作が続く。離す・キャンセル・キャプチャ喪失、画面サイズ変更、切替・リセット、フォーカス離脱・バックグラウンドで入力を解除する。画面サイズ変更とバックグラウンドでは速度も停止する。

横画面ではFlutterの説明欄を省略して描画面を広げる。スティックは左右下部、モードと停止・リセットは上部に配置し、WebView内部ではsafe-area insetを考慮する。向きの固定は追加していない。

## 地面・建物判定

GLBのSite_Base/Campus_Ground等に下向きraycastし、車体の高さを地面に合わせる。地面なし、65cm以上の急な段差、地面の範囲外では停止する。

建物ID付きルート（津田沼11、新習志野18）の実際の三角形をワールド座標に統合してBVHを構築する。津田沼53,114、新習志野108,584三角形。建物全体の外接直方体を塗りつぶす従来の判定を、建物表面と向き付き車体ボックス、飛行機の胴体・翼・尾翼の3ボックスの交差判定に置き換えた。L字の空間や低い部分の上空を外接ボックスだけで塞がない。カメラの遮蔽も建物表面へのraycastを使う。

運動は最大10msごとに分割し、接触時は移動・旋回を確定せず停止する。車の出発位置は保守的な建物外接ボックスの外から選ぶ。この判定は表面交差を扱い、完全に建物内部へ任意に置かれた物体を「内部」と判定する体積判定ではない。操作による小刻みな移動で壁・屋根の通過を防ぐ方式で、厳密な連続衝突判定や衝突反応ではない。

飛行機はモデル最高点+25mから開始。高度は地面+3m〜モデル最高点+250m、飛行範囲は地面外接矩形から最大幅の40%ずつ広げた範囲。速度0で空中停止できる簡易飛行で、揚力・失速・離着陸、路面に合わせた車体姿勢・サスペンションは再現しない。木・家具は衝突対象外。外観・高さは一部推定で、測量精度や実際の通行可否を示さない。

## 検証

- 対象Dart解析: 指摘なし。
- Flutterテスト6件: 読込失敗、切替・再試行・戻る、320px/文字200%、844×390横画面、既存マップrefresh。
- JavaScriptテスト10件: 車・飛行機の運動と制限、停止・リセット、独立スティック、L字空間・低い屋根の上空、薄い壁・拒否された旋回。
- 両GLBの建物三角形生成・接触確認: [mesh-collision-validation.json](campus_3d/mesh-collision-validation.json)。表面と交差しないサンプルには建物の内部も含まれるため、記録の件数を中庭や走行可能な空間の件数とは扱わない。
- ブラウザー: 同じCampus3dScreenを使うプレビューを390×844、844×390、headless Chrome/SwiftShader、合成タッチで確認。両キャンパス×車/飛行機×縦/横の8組の実描画、同時スティック、3本目の指のカメラ、領域外・キャンセル・余分な指・リセットを確認。
- 詳細: [stick-render-validation.json](campus_3d/stick-render-validation.json)。スクリーンショットは同じフォルダの`*-portrait-*.png`と`*-landscape-*.png`。
- 通常Web・Android debug APKをビルドし、ソース/Web/APKの2モデル・エンジン・HTML・ライセンス通知を照合: [bundle-validation.json](campus_3d/bundle-validation.json)。

GLBはKhronos Validatorで両方errors 0 / warnings 0。津田沼4,139,212 bytes、新習志野10,311,688 bytes。モデルのSHA-256等は[model-validation.json](campus_3d/model-validation.json)を参照。

## 未検証・制約

Android/iOS実機での表示・操作・GPU性能とiOSビルドは未検証（実機接続なし、Windows環境）。ブラウザーの合成タッチを実機確認とは扱わない。通常アプリのログイン後導線の実機E2Eは未実施。隔離プレビューではオフラインのFlutter日本語フォントfallbackが取得できず、Flutter側の日本語が一部欠字になる。HTML操作ラベルと3D描画は確認できる。

Library upload helperは以前`library upload failed: Library prepare_uploads is not available`で失敗しており、確認済みLibrary IDはない。今回の成果物はPC内に保存した。既存変更を維持し、commit・push・本番公開は行っていない。

## 再生成

`npm ci --prefix tools/campus_3d`

`npm run build --prefix tools/campus_3d`

`npm test --prefix tools/campus_3d`

ソースはtools/campus_3d/。固定バージョン: Three.js 0.186.1、three-mesh-bvh 0.9.15、esbuild 0.28.2。生成先はassets/models/campus/campus_engine.jsとviewer.html、第三者ライセンスはcampus_engine.js.LEGAL.txt。

ブラウザー検証の再実行: `flutter build web --no-pub --no-wasm-dry-run --no-web-resources-cdn --target tools/campus_3d_preview.dart --output build/campus_3d_qa` の後に `node tools/campus_3d/browser_qa.cjs`。Chromeパスは`CHROME_PATH`、プレビュー保存先は`CAMPUS_3D_QA_WEB`で指定できる。合成タッチを使用し、スクリーンショットとJSONをdocs/campus_3d/に保存する。

2026-10-04 操作仕様更新: 枠外での解放を廃止しました。[枠外保持の検証](campus_3d/stick-hold-validation.json)は、車・飛行機・バスの縦横表示で両指の枠外保持、枠内復帰、片方だけの解放、真のキャンセル、回転・モード変更・背景化・ビュー破棄を確認します。以前の検証JSONにある枠外解放の結果は旧仕様です。
