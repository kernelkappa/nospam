"""
Smoke test manuale per il setup Supabase: da lanciare a mano dopo aver creato
il progetto ed eseguito supabase_schema.sql, per verificare che l'inserimento
pubblico (come farebbe l'app con la anon key) e la lettura privilegiata (come
fa aggregate.py con la service key) funzionino entrambi.

Uso:
    SUPABASE_URL=... SUPABASE_ANON_KEY=... SUPABASE_SERVICE_KEY=... \
        .venv/bin/python verify_supabase.py
"""

import os
import uuid

import requests

SUPABASE_URL = os.environ["SUPABASE_URL"].rstrip("/")
ANON_KEY = os.environ["SUPABASE_ANON_KEY"]
SERVICE_KEY = os.environ["SUPABASE_SERVICE_KEY"]

test_number = "+393330000000"
test_device_hash = f"verify-{uuid.uuid4()}"

print("1) Inserimento come farebbe l'app (anon key)...")
insert_resp = requests.post(
    f"{SUPABASE_URL}/rest/v1/reports",
    headers={
        "apikey": ANON_KEY,
        "Authorization": f"Bearer {ANON_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
    },
    json={
        "phone_number": test_number,
        "category": "spam",
        "device_hash": test_device_hash,
        "app_platform": "ios",
    },
    timeout=15,
)
insert_resp.raise_for_status()
print(f"   OK ({insert_resp.status_code})")

print("2) L'anon key non deve poter leggere la tabella (RLS)...")
read_as_anon = requests.get(
    f"{SUPABASE_URL}/rest/v1/reports",
    headers={"apikey": ANON_KEY, "Authorization": f"Bearer {ANON_KEY}"},
    params={"phone_number": f"eq.{test_number}"},
    timeout=15,
)
if read_as_anon.status_code == 200 and read_as_anon.json():
    print("   ATTENZIONE: la anon key riesce a leggere righe, controlla la policy RLS!")
else:
    print(f"   OK, lettura bloccata (status {read_as_anon.status_code}, body {read_as_anon.text[:100]})")

print("3) Lettura come fa lo script di aggregazione (service key)...")
read_as_service = requests.get(
    f"{SUPABASE_URL}/rest/v1/reports",
    headers={"apikey": SERVICE_KEY, "Authorization": f"Bearer {SERVICE_KEY}"},
    params={"phone_number": f"eq.{test_number}"},
    timeout=15,
)
read_as_service.raise_for_status()
rows = read_as_service.json()
assert rows and rows[0]["phone_number"] == test_number, "Riga di test non trovata con la service key"
print(f"   OK, trovata la riga di test: {rows[0]}")

print("\nSetup Supabase verificato correttamente.")
