import Foundation

/// Invia un log anonimo (solo tipo errore e contesto tecnico, mai input
/// dell'utente) al backend, archiviato su Supabase e inoltrato via email per
/// gli errori veri. Non deve mai interrompere il flusso che lo ha generato:
/// fallisce in silenzio.
enum ErrorReporter {
    enum Level: String {
        /// Stato noto/previsto, non un problema (es. estensione non ancora
        /// abilitata dall'utente): utile per capire la frequenza, non da
        /// trattare come un errore da investigare.
        case info
        case warning
        case error
    }

    private struct Payload: Encodable {
        let platform = "ios"
        let context: String
        let message: String
        let app_version: String?
        let os_version: String
        let level: String
    }

    static func report(_ error: Error, context: String, level: Level = .error) {
        Task {
            var request = URLRequest(url: SupabaseConfig.url.appendingPathComponent("rest/v1/error_reports"))
            request.httpMethod = "POST"
            request.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(SupabaseConfig.publishableKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

            var message = String(describing: error)
            let userInfo = (error as NSError).userInfo
            if !userInfo.isEmpty {
                message += " userInfo=\(userInfo)"
            }

            let payload = Payload(
                context: context,
                message: message,
                app_version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                os_version: ProcessInfo.processInfo.operatingSystemVersionString,
                level: level.rawValue
            )
            request.httpBody = try? JSONEncoder().encode(payload)
            _ = try? await URLSession.shared.data(for: request)
        }
    }
}
