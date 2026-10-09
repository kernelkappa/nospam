import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var labelKey: LocalizedStringKey {
        switch self {
        case .system: return "Sistema"
        case .light: return "Chiaro"
        case .dark: return "Scuro"
        }
    }
}

/// Preferenza persistita per il tema (Sistema/Chiaro/Scuro), indipendente
/// dall'impostazione di sistema.
final class AppearancePreference: ObservableObject {
    static let shared = AppearancePreference()

    @Published var mode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: Self.key)
        }
    }

    private static let key = "appearance_mode"

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.key)
        mode = stored.flatMap(AppearanceMode.init(rawValue:)) ?? .system
    }
}
