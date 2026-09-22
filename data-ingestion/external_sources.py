"""
Fonti esterne gratuite da unire alle segnalazioni crowdsourced.

ShopSicuro (progetto MIMIT "Squadra Antifrode" / Federazione iConsumatori)
pubblica una lista statica, senza protezioni anti-bot e consentita da
robots.txt, di numeri segnalati dalla loro community: la trattiamo come
fonte pre-verificata e la includiamo sempre, indipendentemente dalla
soglia MIN_REPORTS che applichiamo alle nostre segnalazioni dirette.

blocklist-telefonica-italia (github.com/thesqual87) e' un CSV statico,
licenza CC BY-SA 4.0 (uso commerciale esplicitamente consentito citando la
fonte), con criteri di inclusione propri (>=2 segnalazioni indipendenti o
riscontri pubblici verificabili) e un canale di contestazione dedicato:
anche questa e' trattata come fonte pre-verificata.

lista-telefonos-spam (github.com/mv12star) e' un TXT statico di numeri
spagnoli in formato nazionale (senza prefisso), licenza Unlicense (dominio
pubblico): la trattiamo come fonte pre-verificata.

nophonespam-fr (github.com/jeromerobert) e' un TXT statico di intervalli di
prefissi telemarketing francesi (numeri con cifre finali sostituite da "_"),
senza un file LICENSE esplicito: inclusa comunque perche' pubblicata
apertamente proprio per essere consumata da app di blocco chiamate come la
nostra (e' gia' la fonte dati della app open source NoPhoneSpam). Il formato
a intervalli non si presta alla lista di numeri esatti (spam_db.json):
finisce invece in spam_prefixes.json, confrontata per prefisso.
"""

import csv
import io
import re
import time

import requests

SHOPSICURO_BASE_URL = "https://www.shopsicuro.it/numeri-spam"
SHOPSICURO_MAX_PAGES = 30  # margine di sicurezza oltre le ~11 pagine attuali
REQUEST_DELAY_SECONDS = 1.0

CATEGORY_MAP = {
    "spam": "spam",
    "telemarketing": "telemarketing",
    "possibile frode": "scam",
    "phishing": "scam",
    "altro": "other",
}

ROW_PATTERN = re.compile(
    r'href="https://www\.shopsicuro\.it/numero/\d+"[^>]*>(?P<number>\+\d+)</a>.*?'
    r'font-weight:600;margin:1px 4px 1px 0">(?P<category>[^<]+)<.*?'
    r'text-align:center;font-weight:700;color:#c0392b;font-size:15px">(?P<count>\d+)<',
    re.DOTALL,
)


def fetch_shopsicuro() -> list[dict]:
    session = requests.Session()
    session.headers["User-Agent"] = "NoSpamApp-DataIngestion/1.0 (+https://github.com/kernelkappa/nospam)"

    entries_by_number: dict[str, dict] = {}

    for page in range(1, SHOPSICURO_MAX_PAGES + 1):
        resp = session.get(SHOPSICURO_BASE_URL, params={"q": "", "page": page}, timeout=30)
        resp.raise_for_status()

        rows = ROW_PATTERN.findall(resp.text)
        if not rows:
            break

        for number, category_label, count in rows:
            category = CATEGORY_MAP.get(category_label.strip().lower(), "other")
            report_count = int(count)
            existing = entries_by_number.get(number)
            if existing is None or report_count > existing["report_count"]:
                entries_by_number[number] = {
                    "number": number,
                    "report_count": report_count,
                    "category": category,
                }

        time.sleep(REQUEST_DELAY_SECONDS)

    return list(entries_by_number.values())


BLOCKLIST_TELEFONICA_ITALIA_URL = (
    "https://raw.githubusercontent.com/thesqual87/blocklist-telefonica-italia/main/data/blocklist.csv"
)

BLOCKLIST_TELEFONICA_ITALIA_CATEGORY_MAP = {
    "truffa": "scam",
    "finanza": "scam",
    "energia": "telemarketing",
    "telefonia": "telemarketing",
    "sondaggi": "other",
    "pubblicita": "telemarketing",
    "ping": "robocall",
    "altro": "other",
}


def fetch_blocklist_telefonica_italia() -> list[dict]:
    resp = requests.get(BLOCKLIST_TELEFONICA_ITALIA_URL, timeout=30)
    resp.raise_for_status()

    reader = csv.DictReader(io.StringIO(resp.text))
    entries = []
    for row in reader:
        category = BLOCKLIST_TELEFONICA_ITALIA_CATEGORY_MAP.get(row["categoria"].strip().lower(), "other")
        entries.append(
            {
                "number": row["numero"].strip(),
                "report_count": int(row["segnalazioni"]),
                "category": category,
            }
        )
    return entries


LISTA_TELEFONOS_SPAM_ES_URL = (
    "https://raw.githubusercontent.com/mv12star/lista-telefonos-spam/main/lista_numeros_spam.txt"
)


def fetch_lista_telefonos_spam_es() -> list[dict]:
    resp = requests.get(LISTA_TELEFONOS_SPAM_ES_URL, timeout=30)
    resp.raise_for_status()

    entries = []
    for line in resp.text.splitlines():
        national_number = line.strip()
        if not national_number.isdigit():
            continue
        entries.append(
            {
                "number": f"+34{national_number}",
                "report_count": 1,
                "category": "spam",
            }
        )
    return entries


NOPHONESPAM_FR_URL = "https://raw.githubusercontent.com/jeromerobert/nophonespam-fr/main/NoPhoneSpam_blacklist.txt"

NOPHONESPAM_FR_LINE_PATTERN = re.compile(r"^(?P<prefix>\+33[\d_]+):\s*(?P<label>.+?)\s+\d+$")


def fetch_nophonespam_fr() -> list[dict]:
    """Ritorna intervalli di prefisso (non numeri esatti): {prefix, label, mode, source}."""
    resp = requests.get(NOPHONESPAM_FR_URL, timeout=30)
    resp.raise_for_status()

    entries = []
    for line in resp.text.splitlines():
        match = NOPHONESPAM_FR_LINE_PATTERN.match(line.strip())
        if match is None:
            continue
        digit_prefix = match.group("prefix").rstrip("_")
        entries.append(
            {
                "prefix": digit_prefix,
                "label": match.group("label").strip(),
                "mode": "block",
                "source": "nophonespam-fr",
            }
        )
    return entries
