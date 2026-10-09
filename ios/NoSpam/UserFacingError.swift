import Foundation

/// Traduce un errore gestito in un messaggio comprensibile per l'utente:
/// se la causa è qualcosa che può risolvere lui (un'impostazione da
/// abilitare, la connessione da controllare), lo dice esplicitamente invece
/// di mostrare la descrizione tecnica grezza.
enum UserFacingError {
    static func message(for error: Error) -> String {
        if CallDirectoryManager.isExtensionDisabledError(error) {
            return String(localized: "error.extensionDisabled")
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return String(localized: "error.noInternet")
            case .timedOut:
                return String(localized: "error.timeout")
            default:
                break
            }
        }
        return error.localizedDescription
    }
}
