# Risposta a "Guideline 2.1 - Information Needed" (App Review)

Da incollare in App Store Connect: sia come risposta al messaggio di revisione, sia nel campo "Note" di App Review Information (per le sottomissioni future).

---

**2. App purpose and target audience**

NoSpam is a free call-blocking and caller-identification utility for iPhone, targeted primarily at users in Italy (with growing coverage for Spain and France). It solves a common problem: unwanted spam, scam, telemarketing, and robocall phone calls, including "wangiri" (one-ring-and-hangup) fraud calls. The app automatically blocks and identifies incoming calls from numbers already reported as spam, and lets users report new numbers to a shared, community-maintained blocklist. It also filters spam SMS/iMessage using the same data. The app contains no account system, no user-generated free-text content, and no paid features — it is entirely free, supported by non-intrusive banner ads.

**3. Instructions for setting up and accessing main features**

No login, account, or credentials are required — the app has no account system whatsoever.

1. Launch the app. On first launch, an onboarding alert explains that to enable automatic call blocking, the user must set NoSpam as the system's default Call Screening app (Settings > Phone > Call Blocking & Identification, or via the in-app "Diventa app predefinita" / "Become default app" button, which opens the system role-request dialog).
2. On the main screen, enter a phone number in the text field and choose a category (Spam/Scam/Telemarketing/Robocall/Other).
3. "Blocca" ("Block") adds the number to the local on-device blocklist only. "Blocca e segnala" ("Block and report") does the same and additionally submits an anonymous report (phone number + category + a random, non-identifying device hash) to our backend, contributing to the shared community blocklist.
4. "Numeri bloccati" ("Blocked Numbers") shows all blocked numbers (community + personal), with search and an "Unblock" action for personally-blocked numbers.
5. "Aggiorna database spam" ("Update spam database") manually refreshes the locally cached community blocklist (it also refreshes automatically once every 24 hours in the background).
6. A banner ad is shown at the bottom of the two main screens, gated behind a real GDPR consent flow (Google User Messaging Platform) and, on iOS, the App Tracking Transparency prompt — both run automatically shortly after first launch.

**4. External services/tools used for core functionality**

- **Supabase** (hosted Postgres + REST API): stores community-submitted spam reports.
- **GitHub Pages**: hosts the publicly aggregated, anonymized spam-number list (`spam_db.json`) that the app downloads and caches locally.
- **Google AdMob** and **Google User Messaging Platform (UMP)**: banner ad serving and GDPR/consent management. No other analytics or crash-reporting SDKs are integrated.
- A small number of free, openly-licensed third-party phone-number blocklists are merged into the same aggregated list (credited with name/license/link in the in-app "Crediti"/"Credits" screen): ShopSicuro (Italy), blocklist-telefonica-italia (Italy, CC BY-SA 4.0), lista-telefonos-spam (Spain, Unlicense/public domain).

**5. Regional differences**

The app functions consistently across all regions — call blocking, identification, and SMS filtering work identically everywhere using the same shared dataset and the same code path. The only region-related nuance is data *coverage*, not functional behavior: the underlying crowdsourced + open-data blocklist currently has denser coverage for Italian, Spanish, and French phone numbers (reflecting where our data sources and user base are concentrated today), so users outside those countries may simply encounter fewer pre-identified numbers. No feature is hidden, disabled, or changed by region.

**6. Regulated industry / third-party material**

NoSpam does not operate in a regulated industry (it is not a financial, medical, legal, or similarly licensed service) and does not include any protected or proprietary third-party material. The phone-number data it uses is either (a) submitted directly and voluntarily by our own users through the app's own reporting feature, or (b) drawn from openly licensed/public-domain third-party sources, each explicitly credited with name, license, and source link in the app's own "Crediti"/"Credits" screen (ShopSicuro, blocklist-telefonica-italia under CC BY-SA 4.0, lista-telefonos-spam under the Unlicense). No authorization documentation is applicable since no licensed/proprietary material is used.

---

## Cosa deve contenere la registrazione video (punto 1, da fare tu su iPhone fisico)

Registra lo schermo (Centro di Controllo > Registrazione schermo) con questo percorso, partendo dal lancio dell'app:

1. Avvio dell'app (dalla home screen)
2. Se appare l'alert di onboarding, mostralo e chiudilo ("Più tardi" va bene)
3. Digita un numero di telefono nel campo principale, scegli una categoria
4. Tocca **"Blocca"** → mostra il messaggio di conferma
5. Vai su **"Numeri bloccati"** (in alto) → mostra la lista, il filtro Tutti/Personali, la ricerca, il numero appena aggiunto con il pulsante "Sblocca"
6. Torna alla schermata principale, digita un altro numero, tocca **"Blocca e segnala"** → mostra il messaggio di conferma
7. Mostra **"Crediti"** (in alto) → le fonti dati con licenze
8. Torna alla principale, tocca **"Aggiorna database spam"** → mostra "Database aggiornato"

Non serve mostrare login/account (non esistono) né acquisti (non ce ne sono). Carica il video direttamente nella risposta ad Apple in App Store Connect.
