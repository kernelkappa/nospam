import Foundation

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

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            CallDirectoryManager.reloadExtension { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
