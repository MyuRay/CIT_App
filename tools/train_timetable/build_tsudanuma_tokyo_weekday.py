#!/usr/bin/env python3
"""津田沼・東京方面・平日の発車時刻リストを JSON 化する。

データ源（優先順）:
1. raw/text/weekday/tsudanuma_tokyo_*.txt … 公式サイトからの手動コピペ（方式A）
2. raw/pdf/weekday/chuo_sobu_local_up.pdf … pdfplumber 抽出（中央・総武各駅停車のみ）

出力: functions/data/train/tsudanuma.json
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RAW_TEXT_DIR = Path(__file__).resolve().parent / "raw" / "text" / "weekday"
PDF_DIR = Path(__file__).resolve().parent / "raw" / "pdf" / "weekday"
OUT_PATH = ROOT / "functions" / "data" / "train" / "tsudanuma.json"

TOKYO_LINE_LABEL = "中央・総武線各駅停車"
TOKYO_DIRECTION_LABEL = "西船橋・両国方面 (西行)"

TOKYO_TIMETABLE_COMPOSITION = {
    "station": "津田沼",
    "travelDirection": "up",
    "destinationArea": TOKYO_DIRECTION_LABEL,
    "calendar": "weekday",
    "trainTypes": [
        {
            "serviceType": "local",
            "lineName": TOKYO_LINE_LABEL,
            "sourcePdf": "tools/train_timetable/raw/pdf/weekday/chuo_sobu_local_up.pdf",
        },
    ],
    "mergeRule": "JR津田沼駅発・中央・総武線各駅停車（西船橋・両国方面 西行）の平日時刻のみ。",
}

CHIBA_TIMETABLE_COMPOSITION = {
    "station": "津田沼",
    "travelDirection": "down",
    "destinationArea": "千葉方面",
    "calendar": "weekday",
    "trainTypes": [],
    "mergeRule": "未投入（下り・千葉方面の PDF 未取り込み）",
}


def normalize_station_label(label: str) -> str:
    return (
        label.replace("⽥", "田")
        .replace("⻄", "西")
        .replace("⾞", "車")
    )


def is_tsudanuma_station(label: str) -> bool:
    n = normalize_station_label(label)
    return "津田沼" in n or (n.startswith("津") and "沼" in n)


def parse_hhmm_token(token: str) -> str | None:
    m = re.match(r"^(\d{1,2}):(\d{2})$", token.strip())
    if not m:
        return None
    h, mi = int(m.group(1)), int(m.group(2))
    if h >= 24:
        h -= 24
    if h > 23 or mi > 59:
        return None
    return f"{h:02d}:{mi:02d}"


def parse_raw_jr_text(raw: str) -> list[str]:
    """JR 公式コピペ形式: 「6 02三 09中 ...」"""
    out: list[str] = []
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.split(maxsplit=1)
        if len(parts) < 2:
            continue
        hour = parts[0].zfill(2)
        for train in parts[1].split():
            m = re.match(r"^(\d+)", train)
            if not m:
                continue
            minute = m.group(1).zfill(2)
            hhmm = parse_hhmm_token(f"{hour}:{minute}")
            if hhmm:
                out.append(hhmm)
    return sorted(set(out), key=lambda t: int(t[:2]) * 60 + int(t[3:]))


def parse_pdf_cell(cell: str) -> str | None:
    c = str(cell).strip()
    if c in ("", "・", "┐", "┘"):
        return None
    m = re.match(r"^(\d{3,4})$", c)
    if not m:
        return None
    t = m.group(1).zfill(4)
    return parse_hhmm_token(f"{int(t[:2])}:{t[2:]}")


def extract_from_pdf(pdf_path: Path, station_match) -> list[str]:
    try:
        import pdfplumber
    except ImportError:
        print("pdfplumber not installed; skip PDF", pdf_path.name, file=sys.stderr)
        return []

    times: list[str] = []
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            for table in page.extract_tables() or []:
                for row in table:
                    if not row or len(row) < 3:
                        continue
                    label = str(row[0] or "")
                    if not station_match(label):
                        continue
                    if row[1] and "発" not in str(row[1]):
                        continue
                    for cell in row[2:]:
                        hhmm = parse_pdf_cell(cell)
                        if hhmm:
                            times.append(hhmm)
    return sorted(set(times), key=lambda t: int(t[:2]) * 60 + int(t[3:]))


def merge_times(*lists: list[str]) -> list[str]:
    return sorted(set().union(*lists), key=lambda t: int(t[:2]) * 60 + int(t[3:]))


def load_times() -> list[str]:
    local_text = RAW_TEXT_DIR / "tsudanuma_tokyo_local.txt"
    if local_text.exists():
        return parse_raw_jr_text(local_text.read_text(encoding="utf-8"))

    local = extract_from_pdf(PDF_DIR / "chuo_sobu_local_up.pdf", is_tsudanuma_station)
    if not local:
        raise SystemExit(
            "No timetable data. Add raw/text/weekday/tsudanuma_tokyo_local.txt "
            "or install pdfplumber and keep chuo_sobu_local_up.pdf in raw/pdf/weekday/",
        )
    return local


def _preserve_tokyo_review(payload: dict) -> None:
    """既存 JSON の手動照合メモ (review) を再生成後も残す。"""
    if not OUT_PATH.exists():
        return
    try:
        existing = json.loads(OUT_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return
    review = (existing.get("directions") or {}).get("tokyo", {}).get("review")
    if review:
        payload["directions"]["tokyo"]["review"] = review


def main() -> None:
    times = load_times()
    payload = {
        "stationName": "津田沼",
        "dataVersion": "2026-03",
        "source": "JR東日本公式時刻表（中央・総武線各駅停車 上り・平日）",
        "directions": {
            "tokyo": {
                "directionKey": "tokyo",
                "lineLabel": TOKYO_LINE_LABEL,
                "directionLabel": TOKYO_DIRECTION_LABEL,
                "timetableComposition": TOKYO_TIMETABLE_COMPOSITION,
                "weekday": times,
                "weekend": [],
            },
            "chiba": {
                "directionKey": "chiba",
                "directionLabel": "千葉方面",
                "timetableComposition": CHIBA_TIMETABLE_COMPOSITION,
                "weekday": [],
                "weekend": [],
            },
        },
    }
    _preserve_tokyo_review(payload)
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(times)} departures -> {OUT_PATH}")


if __name__ == "__main__":
    main()
