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

callavert-spam-list (github.com/Call-Avert) e' un CSV gzippato, licenza CC0
1.0 dichiarata esplicitamente nel README del repository (nessun file LICENSE
separato, ma la dichiarazione e' inequivocabile: "This compilation is
published under CC0 1.0 - use it freely"), compilato quotidianamente dai dati
pubblici "Do Not Call" della FTC statunitense (opera del governo USA, di
dominio pubblico). I dati FTC sono segnalazioni non verificate quindi li
trattiamo come le nostre segnalazioni crowdsourced: li uniamo solo se il
report_count supera MIN_REPORTS, non come fonte pre-verificata.

Le liste per India e Brasile non sono numeri esatti ma prefissi imposti per
norma dai rispettivi regolatori delle telecomunicazioni a tutte le chiamate di
telemarketing (non solo quelle illecite): finiscono quindi in
spam_prefixes.json in modalita' "identify" (etichetta informativa, la
chiamata continua a squillare) invece di "block", perche' bloccare
includerebbe anche telemarketing legittimo e conforme.

bundesnetzagentur-de (bundesnetzagentur.de, l'autorita' federale tedesca delle
telecomunicazioni) pubblica in PDF la "Maßnahmenliste": i numeri su cui ha
gia' preso un provvedimento per abuso (spam SMS/fax/e-mail, dialer truffaldini,
hacking/manipolazione del numero, ecc.), aggiornata continuamente per l'anno
in corso. E' un atto amministrativo pubblico, non uno scraping di terzi: la
trattiamo come fonte pre-verificata, anzi piu' solida delle altre perche' i
numeri hanno gia' un provvedimento formale alle spalle, non solo segnalazioni.
Il PDF usa due formati diversi (una tabella per la parte corrente, blocchi di
testo "Bescheid/Kategorie/Maßnahme/Rufnummern" per l'archivio a fine lista):
il parsing li gestisce entrambi pagina per pagina. Alcuni numeri sono scritti
in formato internazionale con il prefisso di selezione "00" (equivalente al
"+") invece che in formato nazionale tedesco: sono numeri esteri abusati
tramite instradamento/operatori tedeschi, non un errore di estrazione.
"""

import csv
import gzip
import io
import re
import time

import phonenumbers
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


CALLAVERT_US_URL = "https://raw.githubusercontent.com/Call-Avert/callavert-spam-list/main/spam/current.csv.gz"

# Sottoinsieme delle "subject" esatte usate dal feed (vedi README del
# repository), mappate sulle nostre categorie. Tutto cio' che non compare qui
# (incluso "Other" e "No Subject Provided") ricade su "other".
CALLAVERT_US_CATEGORY_MAP = {
    "Calls pretending to be government, businesses, or family and friends": "scam",
    "Lotteries, prizes  & sweepstakes": "scam",
    "Computer  & technical support": "scam",
    "Work from home  & other ways to make money": "scam",
    "Warranties  & protection plans": "scam",
    "Dropped call or no message": "robocall",
    "Reducing your debt (credit cards, mortgage, student loans)": "telemarketing",
    "Medical  & prescriptions": "telemarketing",
    "Home improvement  & cleaning": "telemarketing",
    "Vacation  & timeshares": "telemarketing",
    "Energy, solar,  & utilities": "telemarketing",
    "Home security  & alarms": "telemarketing",
    "Charities": "other",
}


def fetch_callavert_us() -> list[dict]:
    resp = requests.get(CALLAVERT_US_URL, timeout=30)
    resp.raise_for_status()
    text = gzip.decompress(resp.content).decode("utf-8")

    entries = []
    for line in text.splitlines():
        if not line or line.startswith("#"):
            continue
        # Il "subject" puo' contenere virgole: si divide solo sulle prime due
        # (vedi README del repository).
        parts = line.split(",", 2)
        if len(parts) != 3:
            continue
        number, report_count, subject = parts
        entries.append(
            {
                "number": number.strip(),
                "report_count": int(report_count),
                "category": CALLAVERT_US_CATEGORY_MAP.get(subject.strip(), "other"),
            }
        )
    return entries


# Prefissi imposti per norma, non liste di numeri segnalati: ogni
# telemarketer conforme li usa, non solo quelli abusivi. Vedi il modulo
# docstring per il motivo per cui sono in modalita' "identify".
REGULATORY_TELEMARKETING_PREFIXES = [
    {
        "prefix": "+91140",
        "label": "Telemarketing (TRAI 140xx)",
        "mode": "identify",
        "source": "trai-telemarketing-prefix",
    },
    {
        "prefix": "+911600",
        "label": "Telemarketing (TRAI 1600)",
        "mode": "identify",
        "source": "trai-telemarketing-prefix",
    },
    {
        "prefix": "+55303",
        "label": "Telemarketing (Anatel +55303)",
        "mode": "identify",
        "source": "anatel-telemarketing-prefix",
    },
]


def fetch_regulatory_telemarketing_prefixes() -> list[dict]:
    """Prefissi di telemarketing imposti per norma da TRAI (India) e Anatel
    (Brasile), non una lista scaricata: nessuna richiesta HTTP necessaria."""
    return list(REGULATORY_TELEMARKETING_PREFIXES)


# Lista "corrente" (anno in corso), continuamente aggiornata: non usiamo gli
# archivi storici per anno (2016-2024) perche' un numero disattivato anni fa
# e' probabilmente stato riassegnato a un nuovo intestatario innocente nel
# frattempo (riciclo delle numerazioni).
BUNDESNETZAGENTUR_DE_URL = (
    "https://www.bundesnetzagentur.de/SharedDocs/Downloads/DE/Sachgebiete/Telekommunikation/"
    "Verbraucher/Rufnummernmissbrauch/Massnahmenlisten/Ma%C3%9Fnahmenliste2025.pdf?__blob=publicationFile"
)

# Le etichette di categoria usate nel PDF non corrispondono 1:1 alle nostre:
# le raggruppiamo nelle stesse 5 usate da tutte le altre fonti.
BUNDESNETZAGENTUR_DE_CATEGORY_MAP = {
    "spam-sms": "spam",
    "spam sms": "spam",
    "sms": "spam",
    "spam-fax": "spam",
    "spam-e-mail": "spam",
    "spam-messenger": "spam",
    "sms messenger mit zahlungsaufforderung": "scam",
    "internet popup": "scam",
    "telefonie-dialer": "scam",
    "rufnummernmanipulation": "scam",
    "hacking": "scam",
    "fake hotlines": "scam",
    "bandansage": "robocall",
    "sonstiges": "other",
    "spezifische missbrauchsformen": "other",
    "umgehungstatbestand": "other",
}


def _bundesnetzagentur_category(label: str) -> str:
    normalized = " ".join(label.split()).strip().lower()
    return BUNDESNETZAGENTUR_DE_CATEGORY_MAP.get(normalized, "other")


def _bundesnetzagentur_normalize_number(raw: str) -> str | None:
    digits = raw.strip()
    if not digits:
        return None
    try:
        # "00" e' il prefisso di selezione internazionale tedesco, equivalente
        # al "+": alcuni numeri nell'archivio (soprattutto categoria Hacking)
        # sono esteri scritti in questo formato, non nazionali tedeschi.
        parsed = phonenumbers.parse("+" + digits[2:], None) if digits.startswith("00") else phonenumbers.parse(digits, "DE")
    except phonenumbers.NumberParseException:
        return None
    if not phonenumbers.is_valid_number(parsed):
        return None
    return phonenumbers.format_number(parsed, phonenumbers.PhoneNumberFormat.E164)


def fetch_bundesnetzagentur_de() -> list[dict]:
    """Legge la Maßnahmenliste della Bundesnetzagentur (PDF): import di
    pdfplumber fatto qui dentro, non in cima al modulo, perche' e' una
    dipendenza pesante usata solo da questa fonte."""
    import pdfplumber

    resp = requests.get(BUNDESNETZAGENTUR_DE_URL, timeout=60)
    resp.raise_for_status()

    entries_by_number: dict[str, dict] = {}

    def add_entries(raw_numbers: str, category_label: str) -> None:
        category = _bundesnetzagentur_category(category_label)
        for raw_number in re.split(r"[,\s]+", raw_numbers.strip()):
            if not raw_number:
                continue
            number = _bundesnetzagentur_normalize_number(raw_number)
            if number:
                entries_by_number[number] = {"number": number, "report_count": 1, "category": category}

    with pdfplumber.open(io.BytesIO(resp.content)) as pdf:
        for page in pdf.pages:
            # Parte corrente della lista: tabella con colonne
            # Bescheid vom | Rufnummer(e) | Kategorie | Maßnahme.
            tables = page.extract_tables()
            if tables:
                for table in tables:
                    for row in table:
                        if not row or len(row) < 3 or not row[0] or not re.match(r"\d{2}\.\d{2}\.\d{4}", row[0]):
                            continue
                        add_entries(row[1] or "", row[2] or "")
                continue

            # Archivio a fine lista: blocchi di testo libero, non tabellari,
            # uno per Bescheid (puo' usare "Rufnummer:" o "Rufnummern:").
            text = page.extract_text() or ""
            category_match = re.search(r"Kategorie:\s*(.+?)\s*Maßnahme:", text, re.DOTALL)
            numbers_match = re.search(r"Rufnummern?:\s*(.+)", text, re.DOTALL)
            if category_match and numbers_match:
                add_entries(numbers_match.group(1), category_match.group(1))

    return list(entries_by_number.values())
