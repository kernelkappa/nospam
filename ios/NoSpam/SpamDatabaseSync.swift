import Foundation
import os

enum SpamDatabaseSync {
    static let remoteURL = URL(string: "https://kernelkappa.github.io/nospam/spam_db.json")!
    static let liteRemoteURL = URL(string: "https://kernelkappa.github.io/nospam/spam_numbers_lite.txt")!
    private static let lastSyncDateKey = "last_spam_db_sync_date"

    /// Ultimo sync riuscito, sia manuale che in background (BGTaskManager):
    /// usato per avvisare l'utente se il database locale non si aggiorna da
    /// troppo tempo, visto che il refresh in background su iOS e'
    /// opportunistico e non garantito ogni 24h.
    static var lastSyncDate: Date? {
        UserDefaults.standard.object(forKey: lastSyncDateKey) as? Date
    }

    static func isStale(afterHours hours: Double = 12) -> Bool {
        guard let lastSyncDate else { return true }
        return Date().timeIntervalSince(lastSyncDate) > hours * 3600
    }

    static func sync() async throws {
        let (data, response) = try await URLSession.shared.data(from: remoteURL)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        guard let destination = SpamNumberStore.localFileURL, let liteDestination = SpamNumberStore.liteFileURL else {
            throw NSError(
                domain: "com.konrad.nospam",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "App Group container non disponibile"]
            )
        }
        try data.write(to: destination, options: .atomic)

        // File leggero dedicato all'estensione CXCallDirectoryProvider (vedi
        // SpamNumberStore.liteFileName): se questa seconda richiesta fallisce
        // non blocchiamo il sync del file principale, l'estensione terra'
        // semplicemente la copia precedente finche' non riprova.
        if let (liteData, liteResponse) = try? await URLSession.shared.data(from: liteRemoteURL),
           let liteHttpResponse = liteResponse as? HTTPURLResponse,
           (200..<300).contains(liteHttpResponse.statusCode) {
            try? liteData.write(to: liteDestination, options: .atomic)
        }

        // Il dato locale e' aggiornato da qui in poi: segnamo il sync come
        // fresco anche se il reload dell'estensione sotto fallisse perche'
        // disabilitata, altrimenti chi ha il blocco disattivato vedrebbe
        // sempre l'avviso di database "vecchio" a prescindere dalla realta'.
        UserDefaults.standard.set(Date(), forKey: lastSyncDateKey)

        // CXCallDirectoryManager puo' invocare il completion handler piu' di una
        // volta in alcuni casi limite (es. l'estensione viene interrotta dal
        // sistema mentre elabora un elenco molto grande e poi richiamata): una
        // CheckedContinuation risolta due volte genera un fatal error, quindi
        // ignoriamo qualsiasi chiamata successiva alla prima.
        let hasResumed = OSAllocatedUnfairLock(initialState: false)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            CallDirectoryManager.reloadExtension { error in
                let alreadyResumed = hasResumed.withLock { resumed -> Bool in
                    let wasResumed = resumed
                    resumed = true
                    return wasResumed
                }
                guard !alreadyResumed else { return }
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
