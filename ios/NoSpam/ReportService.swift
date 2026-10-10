import Foundation

enum ReportCategory: String, CaseIterable {
    case spam, scam, telemarketing, robocall, other

    var displayName: String {
        switch self {
        case .spam: return LanguagePreference.shared.string("category.spam")
        case .scam: return LanguagePreference.shared.string("category.scam")
        case .telemarketing: return LanguagePreference.shared.string("category.telemarketing")
        case .robocall: return LanguagePreference.shared.string("category.robocall")
        case .other: return LanguagePreference.shared.string("category.other")
        }
    }
}

enum ReportError: LocalizedError {
    case invalidResponse
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return LanguagePreference.shared.string("error.invalidResponse")
        case .server(let statusCode):
            return String(format: LanguagePreference.shared.string("error.serverUnavailable"), statusCode)
        }
    }
}

private struct ReportPayload: Encodable {
    let phone_number: String
    let category: String
    let device_hash: String
    let app_platform: String
}

enum ReportService {
    static func submit(phoneNumberE164: String, category: ReportCategory) async throws {
        var request = URLRequest(url: SupabaseConfig.url.appendingPathComponent("rest/v1/reports"))
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let payload = ReportPayload(
            phone_number: phoneNumberE164,
            category: category.rawValue,
            device_hash: DeviceIdentity.hashedDeviceId,
            app_platform: "ios"
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReportError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ReportError.server(statusCode: httpResponse.statusCode)
        }
    }
}
