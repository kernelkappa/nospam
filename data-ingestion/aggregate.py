"""
Aggrega le segnalazioni crowdsourced salvate su Supabase, unite alle fonti
esterne gratuite disponibili, in spam_db.json.

Eseguito quotidianamente da GitHub Actions. Legge la tabella `reports` con la
service role key (bypassa RLS), normalizza i numeri in E.164, scarta i numeri
segnalati da meno di MIN_REPORTS dispositivi distinti (non basta che un solo
utente segnali piu' volte in giorni diversi), li unisce alle fonti esterne
(sempre incluse, gia' pre-verificate) e scrive il JSON finale.
"""

import collections
import json
import os
import sys
from pathlib import Path

import phonenumbers
import requests

from external_sources import (
    fetch_blocklist_telefonica_italia,
    fetch_lista_telefonos_spam_es,
    fetch_nophonespam_fr,
    fetch_shopsicuro,
)

EXTERNAL_SOURCES = {
    "ShopSicuro": fetch_shopsicuro,
    "blocklist-telefonica-italia": fetch_blocklist_telefonica_italia,
    "lista-telefonos-spam": fetch_lista_telefonos_spam_es,
}

# Fonti a intervalli di prefisso (non numeri esatti): finiscono in
# spam_prefixes.json, non in spam_db.json. Usate solo da Android, che ha
# logica di confronto custom (CXCallDirectoryProvider su iOS richiede numeri
# singoli espliciti e non supporta intervalli/prefissi).
PREFIX_SOURCES = {
    "nophonespam-fr": fetch_nophonespam_fr,
}

# Prefissi internazionali spesso citati in segnalazioni di truffe "wangiri"
# (chiamata di un solo squillo per indurre a richiamare un numero a
# tariffazione speciale). I truffatori ruotano continuamente paese di
# provenienza (Europol/Commsrisk: 176 paesi diversi osservati in totale), per
# cui una lista fissa non e' un blocco affidabile: la usiamo solo in
# modalita' "identify" (etichetta di avviso, la chiamata continua a
# squillare normalmente) per non rischiare di silenziare chiamate legittime
# da questi paesi.
WANGIRI_WATCHLIST_PREFIXES = [
    {"prefix": "+216", "label": "Tunisia", "mode": "identify", "source": "wangiri-watchlist"},
    {"prefix": "+213", "label": "Algeria", "mode": "identify", "source": "wangiri-watchlist"},
    {"prefix": "+373", "label": "Moldova", "mode": "identify", "source": "wangiri-watchlist"},
    {"prefix": "+93", "label": "Afghanistan", "mode": "identify", "source": "wangiri-watchlist"},
    {"prefix": "+53", "label": "Cuba", "mode": "identify", "source": "wangiri-watchlist"},
]

SUPABASE_URL = os.environ["SUPABASE_URL"].rstrip("/")
SUPABASE_SERVICE_KEY = os.environ["SUPABASE_SERVICE_KEY"]
MIN_REPORTS = int(os.environ.get("MIN_REPORTS", "5"))
DEFAULT_REGION = os.environ.get("DEFAULT_REGION", "IT")
OUTPUT_PATH = Path(os.environ.get("OUTPUT_PATH", "docs/spam_db.json"))
PREFIX_OUTPUT_PATH = Path(os.environ.get("PREFIX_OUTPUT_PATH", "docs/spam_prefixes.json"))
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
                "select": "phone_number,category,device_hash",
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
    by_number = collections.defaultdict(lambda: {"device_hashes": set(), "categories": collections.Counter()})

    for row in rows:
        e164 = normalize_e164(row["phone_number"])
        if e164 is None:
            continue
        entry = by_number[e164]
        # Contiamo dispositivi distinti, non righe: un singolo utente non deve
        # poter far entrare un numero nella lista condivisa segnalandolo piu'
        # volte in giorni diversi (il vincolo unico in DB blocca solo i
        # duplicati nello stesso giorno).
        entry["device_hashes"].add(row["device_hash"])
        entry["categories"][row["category"]] += 1

    spam_db = {
        number: {
            "number": number,
            "report_count": len(data["device_hashes"]),
            "category": data["categories"].most_common(1)[0][0],
        }
        for number, data in by_number.items()
        if len(data["device_hashes"]) >= MIN_REPORTS
    }
    return spam_db


def merge_external_entries(spam_db: dict[str, dict], external_entries: list[dict]) -> None:
    for entry in external_entries:
        existing = spam_db.get(entry["number"])
        if existing is None or entry["report_count"] > existing["report_count"]:
            spam_db[entry["number"]] = entry


def build_prefix_db() -> list[dict]:
    prefix_db: dict[str, dict] = {}

    for name, fetch_fn in PREFIX_SOURCES.items():
        try:
            entries = fetch_fn()
        except requests.RequestException as error:
            print(f"Avviso: fonte prefissi {name} non raggiungibile ({error}), la salto", file=sys.stderr)
            continue
        for entry in entries:
            prefix_db[entry["prefix"]] = entry
        print(f"Prefissi da {name}: {len(entries)}", file=sys.stderr)

    for entry in WANGIRI_WATCHLIST_PREFIXES:
        prefix_db[entry["prefix"]] = entry

    return sorted(prefix_db.values(), key=lambda entry: entry["prefix"])


def main() -> None:
    rows = fetch_reports()
    spam_db = build_spam_db(rows)
    crowdsourced_count = len(spam_db)

    external_total = 0
    for name, fetch_fn in EXTERNAL_SOURCES.items():
        try:
            entries = fetch_fn()
        except requests.RequestException as error:
            print(f"Avviso: fonte esterna {name} non raggiungibile ({error}), la salto", file=sys.stderr)
            continue
        merge_external_entries(spam_db, entries)
        external_total += len(entries)
        print(f"Numeri da {name}: {len(entries)}", file=sys.stderr)

    sorted_entries = sorted(spam_db.values(), key=lambda entry: entry["number"])

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(json.dumps(sorted_entries, ensure_ascii=False, indent=2), encoding="utf-8")

    prefix_entries = build_prefix_db()
    PREFIX_OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    PREFIX_OUTPUT_PATH.write_text(json.dumps(prefix_entries, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"Segnalazioni lette: {len(rows)}", file=sys.stderr)
    print(f"Numeri da crowdsourcing (>= {MIN_REPORTS} segnalazioni): {crowdsourced_count}", file=sys.stderr)
    print(f"Numeri da fonti esterne (totale grezzo): {external_total}", file=sys.stderr)
    print(f"Numeri pubblicati totali (uniti, deduplicati): {len(sorted_entries)}", file=sys.stderr)
    print(f"Output numeri: {OUTPUT_PATH}", file=sys.stderr)
    print(f"Prefissi pubblicati totali: {len(prefix_entries)}", file=sys.stderr)
    print(f"Output prefissi: {PREFIX_OUTPUT_PATH}", file=sys.stderr)


if __name__ == "__main__":
    main()
