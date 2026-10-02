import Foundation
import os

enum SpamDatabaseSync {
    static let remoteURL = URL(string: "https://kernelkappa.github.io/nospam/spam_db.json")!

    static func sync() async throws {
        let (data, response) = try await URLSession.shared.data(from: remoteURL)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        guard let destination = SpamNumberStore.localFileURL else {
            throw NSError(
                domain: "com.konrad.nospam",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "App Group container non disponibile"]
            )
        }
        try data.write(to: destination, options: .atomic)

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
