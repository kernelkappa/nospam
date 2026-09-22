"""
Fonti esterne gratuite da unire alle segnalazioni crowdsourced.

ShopSicuro (progetto MIMIT "Squadra Antifrode" / Federazione iConsumatori)
pubblica una lista statica, senza protezioni anti-bot e consentita da
robots.txt, di numeri segnalati dalla loro community: la trattiamo come
fonte pre-verificata e la includiamo sempre, indipendentemente dalla
soglia MIN_REPORTS che applichiamo alle nostre segnalazioni dirette.
"""

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
