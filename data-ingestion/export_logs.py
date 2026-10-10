"""
Esporta i log di errore del giorno precedente da Supabase (error_reports) in
un file nel repo (logs/) e applica la retention sulla tabella live.

Eseguito quotidianamente da GitHub Actions, poco dopo la mezzanotte UTC:
cosi' l'archivio su GitHub resta leggibile anche senza bisogno di aprire le
email o interrogare Supabase a mano. La tabella live resta piccola (solo gli
ultimi RETENTION_DAYS giorni); l'archivio su GitHub ha una retention propria
(GITHUB_RETENTION_DAYS), piu' lunga perche' e' solo testo e costa pochissimo
tenerlo piu' a lungo della tabella live.
"""

import datetime
import json
import os
import sys
from pathlib import Path

import requests

SUPABASE_URL = os.environ["SUPABASE_URL"].rstrip("/")
SUPABASE_SERVICE_KEY = os.environ["SUPABASE_SERVICE_KEY"]
RETENTION_DAYS = int(os.environ.get("RETENTION_DAYS", "30"))
GITHUB_RETENTION_DAYS = int(os.environ.get("GITHUB_RETENTION_DAYS", "60"))
LOGS_DIR = Path(os.environ.get("LOGS_DIR", "logs"))
PAGE_SIZE = 1000

HEADERS = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
}


def fetch_rows(start: datetime.datetime, end: datetime.datetime) -> list[dict]:
    rows = []
    offset = 0
    while True:
        resp = requests.get(
            f"{SUPABASE_URL}/rest/v1/error_reports",
            headers=HEADERS,
            params={
                "select": "*",
                "reported_at": [f"gte.{start.isoformat()}", f"lt.{end.isoformat()}"],
                "order": "reported_at.asc",
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


def delete_old_rows(before: datetime.datetime) -> int:
    resp = requests.delete(
        f"{SUPABASE_URL}/rest/v1/error_reports",
        headers={**HEADERS, "Prefer": "return=representation"},
        params={"reported_at": f"lt.{before.isoformat()}"},
        timeout=30,
    )
    resp.raise_for_status()
    return len(resp.json())


def prune_old_log_files(before: datetime.date) -> list[str]:
    """Cancella i file di log giornalieri (nome "YYYY-MM-DD.jsonl") piu'
    vecchi della soglia. Ignora qualsiasi file che non segue quel formato,
    cosi' non rischia di toccare altro nella cartella."""
    removed = []
    if not LOGS_DIR.is_dir():
        return removed
    for path in LOGS_DIR.glob("*.jsonl"):
        try:
            file_date = datetime.date.fromisoformat(path.stem)
        except ValueError:
            continue
        if file_date < before:
            path.unlink()
            removed.append(path.name)
    return removed


def main() -> None:
    today = datetime.datetime.now(datetime.timezone.utc).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    yesterday = today - datetime.timedelta(days=1)

    rows = fetch_rows(yesterday, today)

    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    output_path = LOGS_DIR / f"{yesterday.date().isoformat()}.jsonl"
    with output_path.open("w", encoding="utf-8") as f:
        for row in rows:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")

    retention_cutoff = today - datetime.timedelta(days=RETENTION_DAYS)
    deleted_count = delete_old_rows(retention_cutoff)

    github_retention_cutoff = today.date() - datetime.timedelta(days=GITHUB_RETENTION_DAYS)
    removed_files = prune_old_log_files(github_retention_cutoff)

    print(f"Log esportati per {yesterday.date().isoformat()}: {len(rows)}", file=sys.stderr)
    print(f"Output: {output_path}", file=sys.stderr)
    print(f"Righe cancellate da Supabase (precedenti a {retention_cutoff.date().isoformat()}): {deleted_count}", file=sys.stderr)
    print(f"File di log rimossi da GitHub (precedenti a {github_retention_cutoff.isoformat()}): {len(removed_files)}", file=sys.stderr)


if __name__ == "__main__":
    main()
