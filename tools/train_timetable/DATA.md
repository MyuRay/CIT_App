# 静的時刻表 JSON の中身（現状）

アプリが読むファイル: `functions/data/train/tsudanuma.json`

## いま入っているデータ（津田沼キャンパス）

| 項目 | 内容 |
|------|------|
| **駅** | 津田沼 |
| **路線** | 中央・総武線各駅停車 |
| **方面** | 西船橋・両国方面 (西行) のみ時刻あり |
| **曜日** | 平日（`weekday`）のみ。土日（`weekend`）は空 |
| **列車種別** | **中央・総武各駅停車** のみ |

### データ源 PDF（平日・上り）

| serviceType | 路線名 | PDF |
|-------------|--------|-----|
| `local` | 中央・総武線各駅停車 | `raw/pdf/weekday/chuo_sobu_local_up.pdf` |

ビルド時は PDF から **津田沼駅・発** 行の各駅停車時刻のみを抜きます。総武快速は含めません。

### 未投入

| directionKey | 方面 | 備考 |
|--------------|------|------|
| `chiba` | 千葉方面（下り） | `weekday` / `weekend` とも空 |
| `tokyo` | 東京方面 | 土日ダイヤ未投入（`weekend: []`） |

新習志野キャンパス用は別ファイル `functions/data/train/narashino.json`（現状スタブ）。

## JSON の見方（例）

```json
{
  "stationName": "津田沼",
  "directions": {
    "tokyo": {
      "directionKey": "tokyo",
      "lineLabel": "中央・総武線各駅停車",
      "directionLabel": "西船橋・両国方面 (西行)",
      "timetableComposition": {
        "station": "津田沼",
        "travelDirection": "up",
        "destinationArea": "西船橋・両国方面 (西行)",
        "calendar": "weekday",
        "trainTypes": [
          { "serviceType": "local", "lineName": "中央・総武各駅停車", ... }
        ],
        "mergeRule": "..."
      },
      "review": {
        "weekdayVerifiedThrough": "08:48",
        "note": "手動照合の進捗"
      },
      "weekday": ["06:04", "06:06", ...],
      "weekend": []
    }
  }
}
```

- **`weekday`**: 実際にアプリ／Functions が次発計算に使う時刻リスト（`HH:mm`）
- **`timetableComposition`**: 人間向け・保守向けのメタデータ（表示には使わない）
- **`review`**: 手動照合の進捗（表示には使わない）

## アプリ内アセット

`assets/train/tsudanuma_tokyo_weekday.json` は上記 `tokyo.weekday` のコピー（オフライン用）。  
メタデータは Functions 側 JSON を参照してください。
