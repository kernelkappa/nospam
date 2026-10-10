import Foundation

/// Shared between the main app and the Call Directory extension via an App Group.
struct SpamEntry: Codable {
    let number: String
    let reportCount: Int
    let category: String

    enum CodingKeys: String, CodingKey {
        case number
        case reportCount = "report_count"
        case category
    }
}

enum BlockedNumberSource {
    case community
    case personal
}

struct BlockedNumberDisplay: Identifiable {
    let number: String
    let source: BlockedNumberSource
    let category: String?

    var id: String { number }
}

enum SpamNumberStore {
    static let appGroupId = "group.com.konrad.nospam"
    static let fileName = "spam_db.json"
    /// Formato leggero (CSV minimale "numero,segnalazioni", non JSON) usato
    /// solo dall'estensione CXCallDirectoryProvider: decodificare l'intero
    /// spam_db.json con JSONDecoder dentro l'estensione supera il budget di
    /// memoria che il sistema le concede (osservato a ~33k voci), causando
    /// com.apple.CallKit.error.calldirectorymanager code 2
    /// ("loadingInterrupted"). Un parsing a riga di testo grezzo evita del
    /// tutto l'albero JSON intermedio.
    static let liteFileName = "spam_numbers_lite.txt"
    private static let personalListKey = "personal_blocklist"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }

    static var localFileURL: URL? {
        sharedContainerURL?.appendingPathComponent(fileName)
    }

    static var liteFileURL: URL? {
        sharedContainerURL?.appendingPathComponent(liteFileName)
    }

    private static func communityEntries() -> [SpamEntry] {
        guard let url = localFileURL,
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([SpamEntry].self, from: data)
        else {
            return []
        }
        return entries
    }

    /// Numero -> categoria.
    private static func personalEntriesDict() -> [String: String] {
        sharedDefaults?.dictionary(forKey: personalListKey) as? [String: String] ?? [:]
    }

    static func personalNumbers() -> [String] {
        personalEntriesDict().keys.sorted()
    }

    /// Rimuove spazi e altri separatori (es. copiati dal registro chiamate),
    /// mantenendo solo le cifre e un eventuale "+" iniziale.
    static func normalizedNumber(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = trimmed.filter(\.isNumber)
        return trimmed.hasPrefix("+") ? "+\(digits)" : digits
    }

    static func addPersonalNumber(_ number: String, category: String = "personale") {
        var entries = personalEntriesDict()
        entries[normalizedNumber(number)] = category
        sharedDefaults?.set(entries, forKey: personalListKey)
    }

    static func removePersonalNumber(_ number: String) {
        var entries = personalEntriesDict()
        entries.removeValue(forKey: normalizedNumber(number))
        sharedDefaults?.set(entries, forKey: personalListKey)
    }

    /// Elenco unificato per la schermata "Numeri bloccati": community + personali.
    static func allEntries() -> [BlockedNumberDisplay] {
        let community = communityEntries().map {
            BlockedNumberDisplay(number: $0.number, source: .community, category: $0.category)
        }
        let personal = personalEntriesDict().map {
            BlockedNumberDisplay(number: $0.key, source: .personal, category: $0.value)
        }
        return (community + personal).sorted { $0.number < $1.number }
    }

    private static func toCallDirectoryNumber(_ number: Substring) -> Int64? {
        Int64(number.filter(\.isNumber))
    }

    /// Legge il file lite riga per riga ("numero,segnalazioni") senza mai
    /// passare da JSONDecoder: vedi il commento su `liteFileName` per il
    /// motivo. Niente categoria qui, non serve all'estensione.
    private static func liteEntries() -> [(number: Int64, reportCount: Int)] {
        CallDirectoryDebugLog.log("liteEntries: start")
        guard let url = liteFileURL, let text = try? String(contentsOf: url, encoding: .utf8) else {
            CallDirectoryDebugLog.log("liteEntries: file read failed")
            return []
        }
        CallDirectoryDebugLog.log("liteEntries: file read, chars=\(text.count)")
        var result: [(number: Int64, reportCount: Int)] = []
        result.reserveCapacity(40_000)
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: ",")
            guard parts.count == 2, let number = toCallDirectoryNumber(parts[0]), let count = Int(parts[1]) else {
                continue
            }
            result.append((number, count))
        }
        CallDirectoryDebugLog.log("liteEntries: parsed, count=\(result.count)")
        return result
    }

    /// CXCallDirectory requires phone numbers as Int64 without the leading '+',
    /// with no duplicates, strictly sorted in ascending order.
    ///
    /// Numeri per il blocco (lista completa, nessun tetto) e numeri per
    /// l'etichetta "Spam probabile" nel registro chiamate (solo i piu'
    /// segnalati + quelli personali, sempre pochi): mandare SIA il blocco SIA
    /// l'etichetta per ogni singolo numero raddoppia il totale di voci da
    /// elaborare. Il blocco non ha un tetto perche' e' la protezione vera;
    /// l'etichetta si limita ai numeri che hanno piu' probabilita' di
    /// richiamare (report_count piu' alto), dove serve di piu'.
    static func loadCallDirectoryNumbers(identificationLimit: Int = 5_000) -> (blocking: [Int64], identification: [Int64]) {
        let lite = liteEntries()
        let personalCallDirectoryNumbers = personalNumbers().compactMap { toCallDirectoryNumber(Substring($0)) }

        let blocking = Array(Set(lite.map(\.number) + personalCallDirectoryNumbers)).sorted()

        let topReported = lite
            .sorted { $0.reportCount > $1.reportCount }
            .prefix(identificationLimit)
            .map(\.number)
        let identification = Array(Set(topReported + personalCallDirectoryNumbers)).sorted()

        return (blocking, identification)
    }

    /// Usato dall'estensione di filtro SMS/iMessage: confronta solo le cifre,
    /// dato che il mittente riportato dal sistema potrebbe non includere il
    /// prefisso "+".
    static func isSpamNumber(_ rawNumber: String) -> Bool {
        let digits = rawNumber.filter(\.isNumber)
        guard !digits.isEmpty else { return false }
        let allNumbers = communityEntries().map(\.number) + personalNumbers()
        return allNumbers.contains { $0.filter(\.isNumber) == digits }
    }
}
