import Foundation

/// Traduce un errore gestito in un messaggio comprensibile per l'utente:
/// se la causa è qualcosa che può risolvere lui (un'impostazione da
/// abilitare, la connessione da controllare), lo dice esplicitamente invece
/// di mostrare la descrizione tecnica grezza.
enum UserFacingError {
    static func message(for error: Error) -> String {
        if CallDirectoryManager.isExtensionDisabledError(error) {
            return LanguagePreference.shared.string("error.extensionDisabled")
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return LanguagePreference.shared.string("error.noInternet")
            case .timedOut:
                return LanguagePreference.shared.string("error.timeout")
            default:
                break
            }
        }
        return error.localizedDescription
    }
}
