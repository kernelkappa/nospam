import Foundation
import SwiftUI

/// Legge da remoto la versione minima richiesta e blocca l'app se quella
/// installata e' sotto quella soglia. Decidiamo noi, release per release,
/// se alzare la soglia (vedi docs/app_config.json) — non ogni pubblicazione
/// forza l'aggiornamento.
enum UpdateGate {
    static let configURL = URL(string: "https://kernelkappa.github.io/nospam/app_config.json")!
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6817815337")!

    private struct AppConfig: Decodable {
        let iosMinVersion: String

        enum CodingKeys: String, CodingKey {
            case iosMinVersion = "ios_min_version"
        }
    }

    /// Non blocca mai per un errore di rete: in dubbio, lascia usare l'app.
    static func isUpdateRequired() async -> Bool {
        guard let (data, _) = try? await URLSession.shared.data(from: configURL),
              let config = try? JSONDecoder().decode(AppConfig.self, from: data),
              let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        else {
            return false
        }
        return compare(currentVersion, config.iosMinVersion) == .orderedAscending
    }

    /// Confronta due versioni "dotted" numericamente per componente, non
    /// come stringhe (altrimenti "1.0.10" risulterebbe minore di "1.0.2").
    private static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lhsParts = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let rhsParts = rhs.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(lhsParts.count, rhsParts.count) {
            let l = i < lhsParts.count ? lhsParts[i] : 0
            let r = i < rhsParts.count ? rhsParts[i] : 0
            if l != r {
                return l < r ? .orderedAscending : .orderedDescending
            }
        }
        return .orderedSame
    }
}

struct UpdateRequiredView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text(LanguagePreference.shared.string("update.title"))
                .font(.title2.bold())
            Text(LanguagePreference.shared.string("update.message"))
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 32)
            Button(LanguagePreference.shared.string("update.button")) {
                UIApplication.shared.open(UpdateGate.appStoreURL)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
