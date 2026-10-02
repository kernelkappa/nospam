import Foundation

/// Invia un log di errore anonimo (solo tipo errore e contesto tecnico, mai
/// input dell'utente) al backend, che lo inoltra via email. Non deve mai
/// interrompere il flusso che lo ha generato: fallisce in silenzio.
enum ErrorReporter {
    private struct Payload: Encodable {
        let platform = "ios"
        let context: String
        let message: String
        let app_version: String?
        let os_version: String
    }

    static func report(_ error: Error, context: String) {
        Task {
            var request = URLRequest(url: SupabaseConfig.url.appendingPathComponent("rest/v1/error_reports"))
            request.httpMethod = "POST"
            request.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(SupabaseConfig.publishableKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

            let payload = Payload(
                context: context,
                message: String(describing: error),
                app_version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                os_version: ProcessInfo.processInfo.operatingSystemVersionString
            )
            request.httpBody = try? JSONEncoder().encode(payload)
            _ = try? await URLSession.shared.data(for: request)
        }
    }
}
