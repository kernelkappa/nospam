import SwiftUI

/// Lingue supportate dall'app, stessi codici/nomi nativi usati lato Android
/// (`SupportedLanguage` in SettingsScreen.kt) per coerenza tra le due
/// piattaforme. I nomi nativi non cambiano al variare della lingua corrente
/// dell'app, quindi sono stringhe letterali qui, non chiavi nel catalogo.
enum AppLanguage: String, CaseIterable, Identifiable, Hashable {
    case it, en, es, fr, de, pt
    case ptBR = "pt-BR"
    case ar, bn, ca
    case zhHans = "zh-Hans"
    case zhHant = "zh-Hant"
    case hr, cs, da, nl, fi, el, gu, he, hi, hu, id, ja, kn, ko, ms, ml, mr, nb, or, pl, pa, ro, ru, sk, sl, sv, ta, te, th, tr, uk, ur, vi

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .it: return "Italiano"
        case .en: return "English"
        case .es: return "Español"
        case .fr: return "Français"
        case .de: return "Deutsch"
        case .pt: return "Português"
        case .ptBR: return "Português (Brasil)"
        case .ar: return "العربية"
        case .bn: return "বাংলা"
        case .ca: return "Català"
        case .zhHans: return "中文(简体)"
        case .zhHant: return "中文(繁體)"
        case .hr: return "Hrvatski"
        case .cs: return "Čeština"
        case .da: return "Dansk"
        case .nl: return "Nederlands"
        case .fi: return "Suomi"
        case .el: return "Ελληνικά"
        case .gu: return "ગુજરાતી"
        case .he: return "עברית"
        case .hi: return "हिन्दी"
        case .hu: return "Magyar"
        case .id: return "Bahasa Indonesia"
        case .ja: return "日本語"
        case .kn: return "ಕನ್ನಡ"
        case .ko: return "한국어"
        case .ms: return "Bahasa Melayu"
        case .ml: return "മലയാളം"
        case .mr: return "मराठी"
        case .nb: return "Norsk bokmål"
        case .or: return "ଓଡ଼ିଆ"
        case .pl: return "Polski"
        case .pa: return "ਪੰਜਾਬੀ"
        case .ro: return "Română"
        case .ru: return "Русский"
        case .sk: return "Slovenčina"
        case .sl: return "Slovenščina"
        case .sv: return "Svenska"
        case .ta: return "தமிழ்"
        case .te: return "తెలుగు"
        case .th: return "ไทย"
        case .tr: return "Türkçe"
        case .uk: return "Українська"
        case .ur: return "اردو"
        case .vi: return "Tiếng Việt"
        }
    }
}

/// Preferenza persistita per la lingua dell'app, indipendente da quella di
/// sistema. `nil` = automatica (segue la lingua del telefono). A differenza
/// di Android (`AppCompatDelegate.setApplicationLocales`), iOS non offre
/// un'API di sistema equivalente per le app di terze parti: l'override si fa
/// via `.environment(\.locale, ...)` sulla vista radice, che SwiftUI
/// propaga automaticamente a tutti i `Text("letterale")` che risolvono dal
/// String Catalog.
final class LanguagePreference: ObservableObject {
    static let shared = LanguagePreference()

    @Published var language: AppLanguage? {
        didSet {
            UserDefaults.standard.set(language?.rawValue, forKey: Self.key)
        }
    }

    /// Da usare per le chiamate `String(localized:locale:)` fuori dal
    /// contesto SwiftUI (es. UserFacingError, ReportService), che non
    /// ereditano l'environment della view.
    var locale: Locale {
        Locale(identifier: language?.rawValue ?? Locale.current.identifier)
    }

    private static let key = "app_language"

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.key)
        language = stored.flatMap(AppLanguage.init(rawValue:))
    }

    /// `String(localized:locale:)` non sceglie davvero la risorsa tradotta in
    /// base al parametro locale: lo ignora per quello scopo, influenzando
    /// solo la formattazione delle interpolazioni (bug/limite documentato:
    /// https://developer.apple.com/forums/thread/745217). Carichiamo a mano
    /// il bundle .lproj corretto, l'unico modo verificato che funziona per
    /// le stringhe lette fuori dall'environment SwiftUI (Text/LocalizedStringKey
    /// invece rispettano correttamente .environment(\.locale, ...)).
    func string(_ key: String) -> String {
        guard let identifier = language?.rawValue,
              let path = Bundle.main.path(forResource: identifier, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else {
            return NSLocalizedString(key, comment: "")
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
