"""
Backfill una tantum: archivia su Supabase i numeri spagnoli di
lista-telefonos-spam (github.com/mv12star, cancellato il 13/10/2026) che
vivono solo in docs/spam_db.json grazie al carry-forward incrementale di
aggregate.py, ma non sono mai stati scritti su Supabase perche' la fonte e'
morta e non viene piu' interrogata.

Esclude i numeri +34 che appartengono in realta' ad altre fonti ancora vive
(ShopSicuro, bundesnetzagentur-de possono contenere qualche numero spagnolo
per coincidenza) controllando cosa e' gia' archiviato sotto il loro
device_hash: cosi' non attribuiamo per errore un numero alla fonte sbagliata.

Da eseguire una tantum via GitHub Actions (unico posto con le credenziali
Supabase), poi da cancellare insieme al workflow temporaneo che lo lancia.
"""

import json
import sys
from pathlib import Path

import aggregate

SPAM_DB_PATH = Path("docs/spam_db.json")
SOURCE_NAME = "lista-telefonos-spam"


def main() -> None:
    entries = json.loads(SPAM_DB_PATH.read_text(encoding="utf-8"))
    spain_entries = [e for e in entries if e["number"].startswith("+34")]
    print(f"Numeri +34 in spam_db.json: {len(spain_entries)}", file=sys.stderr)

    already_other_sources: set[str] = set()
    for other_source in ("ShopSicuro", "bundesnetzagentur-de", "blocklist-telefonica-italia", "callavert-spam-list"):
        device_hash = f"{aggregate.EXTERNAL_SOURCE_DEVICE_HASH_PREFIX}{other_source}"
        numbers = aggregate.fetch_archived_external_numbers(device_hash)
        overlap = {n for n in numbers if n.startswith("+34")}
        if overlap:
            print(f"Esclusi {len(overlap)} numeri +34 gia' attribuiti a {other_source}: {sorted(overlap)}", file=sys.stderr)
        already_other_sources |= overlap

    to_backfill = [e for e in spain_entries if e["number"] not in already_other_sources]
    print(f"Numeri da archiviare sotto {SOURCE_NAME}: {len(to_backfill)}", file=sys.stderr)

    aggregate.archive_external_entries(SOURCE_NAME, to_backfill)
    print("Backfill completato.", file=sys.stderr)


if __name__ == "__main__":
    main()
