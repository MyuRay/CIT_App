# 電車時刻表（静的データ）ビルド用

JR東日本公式の時刻表 PDF / テキストから、CIT App 用 JSON を生成するための作業ディレクトリです。

## ディレクトリ構成

```
tools/train_timetable/
├── README.md                 # このファイル
├── raw/
│   ├── pdf/                  # 公式 PDF（手元保存・Git には載せない）
│   │   ├── weekday/          # 平日ダイヤ
│   │   └── weekend/          # 土日ダイヤ（JR表記どおり。祝日もこのダイヤを使用）
│   └── text/                 # PDF からコピーした生テキスト（任意）
├── build_tsudanuma_tokyo_weekday.py  # 津田沼・東京・平日 → tsudanuma.json
└── requirements.txt          # pdfplumber（PDF 補助抽出・任意）
```

生成物（アプリが読む JSON）は別途:

```
functions/data/train/
├── tsudanuma.json
└── narashino.json
```

## PDF の置き場所

**平日:**

`/Users/sora/develop/CIT_App/tools/train_timetable/raw/pdf/weekday/`

**土日（祝日も同ダイヤ）:**

`/Users/sora/develop/CIT_App/tools/train_timetable/raw/pdf/weekend/`

### 推奨ファイル名（英数字・スペースなし）

| 保存する PDF | 推奨名 |
|-------------|--------|
| 中央線・総武線（各駅停車）上り | `chuo_sobu_local_up.pdf` |
| 中央線・総武線（各駅停車）下り | `chuo_sobu_local_down.pdf` |
| 総武線快速・横須賀線 上り | `sobu_rapid_up.pdf` |
| 総武線快速・横須賀線 下り | `sobu_rapid_down.pdf` |
| 京葉線 上り | `keiyo_up.pdf` |
| 京葉線 下り | `keiyo_down.pdf` |
| 総武本線・成田線 下り | `sobu_hon_narita_down.pdf` |

土日分も **同じファイル名** で `weekend/` に置きます（`weekday/` と対になる）。

※ 元の日本語ファイル名のままでも構いません。ビルドスクリプトは後でパスを合わせます。

### 土日 PDF（津田沼向け・取得済み）

| ファイル | 内容 |
|---------|------|
| `chuo_sobu_local_up.pdf` | 中央・総武各停 上り |
| `chuo_sobu_local_down.pdf` | 中央・総武各停 下り |
| `sobu_rapid_up.pdf` | 総武快速 上り |
| `sobu_rapid_down.pdf` | 総武快速 下り |
| `sobu_hon_narita_down.pdf` | 総武本線・成田線 下り |

| `keiyo_up.pdf` | 京葉線 上り |
| `keiyo_down.pdf` | 京葉線 下り |

新習志野キャンパスは `keiyo_*`（土日は `weekend/`）を参照します。

### キャンパスとの対応

| キャンパス | 使う PDF |
|-----------|---------|
| 津田沼 | `chuo_sobu_local_*` + `sobu_rapid_*`（津田沼駅のページ） |
| 新習志野 | `keiyo_*`（新習志野駅のページ） |

## Git について

- **`raw/pdf/*.pdf` は `.gitignore` 対象**（容量・JR東の再配布条件のため）
- チーム共有は Google Drive 等でも可。リポジトリには **生成した JSON** と **更新手順** を載せる想定

## データの中身（方面・各停/快速）

**→ [DATA.md](./DATA.md)** に現状の JSON の意味（津田沼・東京上り・各停+快速マージ等）をまとめています。

## 照合メモ（`review`）

`functions/data/train/tsudanuma.json` の `directions.tokyo.review` に、手動照合の進捗を書きます（JSON は `//` や `/* */` コメント不可）。

```json
"review": {
  "weekdayVerifiedThrough": "08:48",
  "note": "この発車時刻まで公式時刻表と手動照合済み。以降の時刻は要確認。"
}
```

`weekdayVerifiedThrough` は `weekday` 配列内のいずれかの `"HH:mm"` と一致させてください。再生成スクリプト実行時もこのブロックは維持されます。

## JSON の再生成（津田沼・東京・平日）

```bash
cd /Users/sora/develop/CIT_App
# 手動コピペを使う場合: raw/text/weekday/tsudanuma_tokyo.txt を置く
# PDF のみの場合: pip install -r tools/train_timetable/requirements.txt
python3 tools/train_timetable/build_tsudanuma_tokyo_weekday.py
```

ローカル API:

```bash
cd functions
# .env に TRAIN_INFO_MODE=static
npm run serve
# curl "http://127.0.0.1:5001/.../trainInfo?campus=tsudanuma"
```

## 更新タイミング

- **3月ダイヤ改正** … 必須
- 8〜9月の副改正がある年 … 随時
- JSON の `dataVersion` を必ず更新すること
