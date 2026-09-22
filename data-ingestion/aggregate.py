"""
Aggrega le segnalazioni crowdsourced salvate su Supabase, unite alle fonti
esterne gratuite disponibili, in spam_db.json.

Eseguito quotidianamente da GitHub Actions. Legge la tabella `reports` con la
service role key (bypassa RLS), normalizza i numeri in E.164, scarta i numeri
sotto la soglia minima di segnalazioni indipendenti, li unisce alle fonti
esterne (sempre incluse, gia' pre-verificate) e scrive il JSON finale.
"""

import collections
import json
import os
import sys
from pathlib import Path

import phonenumbers
import requests

from external_sources import fetch_shopsicuro

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

    spam_db = {
        number: {
            "number": number,
            "report_count": data["report_count"],
            "category": data["categories"].most_common(1)[0][0],
        }
        for number, data in by_number.items()
        if data["report_count"] >= MIN_REPORTS
    }
    return spam_db


def merge_external_entries(spam_db: dict[str, dict], external_entries: list[dict]) -> None:
    for entry in external_entries:
        existing = spam_db.get(entry["number"])
        if existing is None or entry["report_count"] > existing["report_count"]:
            spam_db[entry["number"]] = entry


def main() -> None:
    rows = fetch_reports()
    spam_db = build_spam_db(rows)
    crowdsourced_count = len(spam_db)

    try:
        external_entries = fetch_shopsicuro()
    except requests.RequestException as error:
        print(f"Avviso: fonte esterna ShopSicuro non raggiungibile ({error}), la salto", file=sys.stderr)
        external_entries = []
    merge_external_entries(spam_db, external_entries)

    sorted_entries = sorted(spam_db.values(), key=lambda entry: entry["number"])

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(json.dumps(sorted_entries, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"Segnalazioni lette: {len(rows)}", file=sys.stderr)
    print(f"Numeri da crowdsourcing (>= {MIN_REPORTS} segnalazioni): {crowdsourced_count}", file=sys.stderr)
    print(f"Numeri da fonti esterne: {len(external_entries)}", file=sys.stderr)
    print(f"Numeri pubblicati totali: {len(sorted_entries)}", file=sys.stderr)
    print(f"Output: {OUTPUT_PATH}", file=sys.stderr)


if __name__ == "__main__":
    main()
