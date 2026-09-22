"""
Aggrega le segnalazioni crowdsourced salvate su Supabase in spam_db.json.

Eseguito quotidianamente da GitHub Actions. Legge la tabella `reports` con la
service role key (bypassa RLS), normalizza i numeri in E.164, scarta i numeri
sotto la soglia minima di segnalazioni indipendenti e scrive il JSON finale.
"""

import collections
import json
import os
import sys
from pathlib import Path

import phonenumbers
import requests

SUPABASE_URL = os.environ["SUPABASE_URL"].rstrip("/")
SUPABASE_SERVICE_KEY = os.environ["SUPABASE_SERVICE_KEY"]
MIN_REPORTS = int(os.environ.get("MIN_REPORTS", "3"))
DEFAULT_REGION = os.environ.get("DEFAULT_REGION", "IT")
OUTPUT_PATH = Path(os.environ.get("OUTPUT_PATH", "docs/spam_db.json"))
PAGE_SIZE = 1000


def fetch_reports() -> list[dict]:
    headers = {
        "apikey": SUPABASE_SERVICE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    }
    rows = []
    offset = 0
    while True:
        resp = requests.get(
            f"{SUPABASE_URL}/rest/v1/reports",
            headers=headers,
            params={
                "select": "phone_number,category",
                "limit": PAGE_SIZE,
                "offset": offset,
            },
            timeout=30,
        )
        resp.raise_for_status()
        page = resp.json()
        rows.extend(page)
        if len(page) < PAGE_SIZE:
            break
        offset += PAGE_SIZE
    return rows


def normalize_e164(raw_number: str) -> str | None:
    try:
        parsed = phonenumbers.parse(raw_number, DEFAULT_REGION)
    except phonenumbers.NumberParseException:
        return None
    if not phonenumbers.is_valid_number(parsed):
        return None
    return phonenumbers.format_number(parsed, phonenumbers.PhoneNumberFormat.E164)


def build_spam_db(rows: list[dict]) -> list[dict]:
    by_number = collections.defaultdict(lambda: {"report_count": 0, "categories": collections.Counter()})

    for row in rows:
        e164 = normalize_e164(row["phone_number"])
        if e164 is None:
            continue
        entry = by_number[e164]
        entry["report_count"] += 1
        entry["categories"][row["category"]] += 1

    spam_db = [
        {
            "number": number,
            "report_count": data["report_count"],
            "category": data["categories"].most_common(1)[0][0],
        }
        for number, data in by_number.items()
        if data["report_count"] >= MIN_REPORTS
    ]
    spam_db.sort(key=lambda entry: entry["number"])
    return spam_db


def main() -> None:
    rows = fetch_reports()
    spam_db = build_spam_db(rows)

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(json.dumps(spam_db, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"Segnalazioni lette: {len(rows)}", file=sys.stderr)
    print(f"Numeri pubblicati (>= {MIN_REPORTS} segnalazioni): {len(spam_db)}", file=sys.stderr)
    print(f"Output: {OUTPUT_PATH}", file=sys.stderr)


if __name__ == "__main__":
    main()
