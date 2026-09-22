# Progetto: App Antispam (iOS & Android) - Specifiche e Roadmap

## 1. Obiettivo del Progetto
Creare un'applicazione mobile per **iOS** e **Android** di blocco e identificazione delle chiamate spam.
L'app utilizzerà una combinazione di:
* Database remoto sincronizzato quotidianamente.
* Lista locale di numeri personalizzata dall'utente.
* Sistema di segnalazione in-app da parte degli utenti (Crowdsourcing).

---

## 2. Architettura Tecnico-Infrastrutturale (Modello Gratis)

Per ridurre i costi al minimo nella fase di avvio e test (MVP), l'infrastruttura si baserà su un modello statico con aggiornamento automatizzato a costo zero.

### A. Data Ingestion & CDN (Gratuito)
* **Script quotidiano (GitHub Actions):** Un task programmato (cron job) gira ogni 24 ore su GitHub Actions, esegue il parsing/scraping da sorgenti e API pubbliche gratuite (es. *Notruffa.it*, registri pubblici, feed open source).
* **Elaborazione dati:** Lo script rimuove duplicati, pulisce la numerazione nel formato standard **E.164** (es. `390612345678`) e ordina numericamente i record.
* **Hosting file (CDN):** Generazione di un file statico `spam_db.json` (o `.sqlite` / `.gz`) pubblicato su **Cloudflare Pages** o **GitHub Pages**.

### B. Sync Client e Storage Locale
* **Frequenza Sync:** L'app programma un job in background ogni 24 ore (`BGTaskScheduler` per iOS, `WorkManager` per Android) inviando una richiesta HTTP con header `If-Modified-Since` per scaricare solo se ci sono aggiornamenti.
* **Gestione File Locali:**
  1. `remote_spam.json`: File sincronizzato dalla CDN.
  2. `local_user_list.json`: Numeri bloccati o aggiunti manualmente dall'utente.
  3. **Merge:** L'app unisce i due file e aggiorna i registri di sistema.

---

## 3. Gestione Nativa dei Sistemi Operativi

### iOS (CallKit / Call Directory)
* **Funzionamento:** Utilizza l'estensione `CXCallDirectoryProvider`. Per motivi di privacy, iOS non condivide il numero del chiamante in tempo reale con l'app, ma confronta il chiamante con un database caricato nativamente dall'app nel sistema operativo.
* **Requisiti Stringenti:** I numeri inviati a `addIdentificationEntry` o `addBlockingEntry` devono essere convertiti in **interi a 64 bit (`Int64`)** e **debitamente ordinati in modo crescente**.

### Android (CallScreeningService)
* **Funzionamento:** Usa `CallScreeningService` / `RoleManager`. L'app intercetta la chiamata in ingresso e consulta istantaneamente il database locale (es. **Room** / **SQLite**).
* **Flessibilità:** Permette il blocco diretto, la chiusura della chiamata o la notifica visiva prima dello squillo.

---

## 4. Ambiente di Sviluppo e Testing
* **Sviluppo iOS su iPhone Fisico:** **Non** è necessario acquistare subito l'account *Apple Developer Program* ($99/anno). È possibile testare l'app e l'estensione CallKit nativamente sul proprio iPhone tramite Xcode usando un **Personal Team** (ID Apple gratuito).
* **Pubblicazione:** L'abbonamento Developer servirà unicamente per la pubblicazione finale su App Store e Google Play.

---

## 5. Prossimi Passi
1. Creazione del repository GitHub del progetto.
2. Scrittura dello script (Python o Node.js) per l'aggregazione iniziale dei dati e la pubblicazione su Cloudflare Pages.
3. Sviluppo dell'applicazione mobile (gestione background sync + estensioni native CallKit e CallScreeningService).