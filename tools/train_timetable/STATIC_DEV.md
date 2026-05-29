# 静的時刻表をアプリで確認する手順

## なぜ「モック」のままになるか

| 設定 | 場所 | 役割 |
|------|------|------|
| `TRAIN_INFO_MODE=static` | `functions/.env` | **サーバー**が `tsudanuma.json` を返す |
| `TRAIN_INFO_USE_MOCK=false` | Flutter `--dart-define` | **アプリ**が HTTP を使う |
| `TRAIN_INFO_API_BASE_URL=...` | Flutter `--dart-define` | **どの URL** に GET するか |

`.env` だけ変更しても、アプリはデバッグ時 **端末内モック**（5分刻み）のままです。

## 手順（ローカル）

### 1. Functions エミュレータ

```bash
cd functions
# .env に TRAIN_INFO_MODE=static
npm run serve
```

確認:

```bash
curl -s "http://127.0.0.1:5001/cit-app-2de1c/us-central1/trainInfo?campus=tsudanuma" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('_meta',{}).get('mode'), d.get('source','')[:40])"
```

`static` と `JR東日本公式…` が出れば OK。

### 2. Flutter 起動

**VS Code / Cursor:** 実行構成  
`CIT App（電車: 静的時刻 · Android エミュ）` または `iOS / macOS`

**CLI（Android エミュレータ）:**

```bash
flutter run \
  --dart-define=TRAIN_INFO_USE_MOCK=false \
  --dart-define=TRAIN_INFO_API_BASE_URL=http://10.0.2.2:5001/cit-app-2de1c/us-central1/trainInfo
```

**CLI（iOS シミュレータ / macOS）:** `10.0.2.2` → `127.0.0.1`

### 3. 画面の見分け（デバッグ）

| メタ行 | 意味 |
|--------|------|
| `… · モック` | 端末内モック（本物ではない） |
| `… · 静的` | `trainInfo` + `static` モード（JSON 由来） |

## 反映元データ（時刻照合）

| 項目 | パス |
|------|------|
| アプリが読む JSON | `functions/data/train/tsudanuma.json` |
| 元 PDF（各停 上り） | `tools/train_timetable/raw/pdf/weekday/chuo_sobu_local_up.pdf` |
| 元 PDF（快速 上り） | `tools/train_timetable/raw/pdf/weekday/sobu_rapid_up.pdf` |

再生成:

```bash
python3 tools/train_timetable/build_tsudanuma_tokyo_weekday.py
```

## 実機（USB）の場合

`10.0.2.2` は使えません。Mac の LAN IP を使う:

`http://192.168.x.x:5001/cit-app-2de1c/us-central1/trainInfo`

## 本番（デプロイ後）

```bash
flutter build apk \
  --dart-define=TRAIN_INFO_USE_MOCK=false \
  --dart-define=TRAIN_INFO_API_BASE_URL=https://us-central1-cit-app-2de1c.cloudfunctions.net/trainInfo
```

Functions 側も `TRAIN_INFO_MODE=static` をデプロイ環境に設定すること。
