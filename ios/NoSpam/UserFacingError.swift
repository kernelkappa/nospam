import Foundation

/// Traduce un errore gestito in un messaggio comprensibile per l'utente:
/// se la causa è qualcosa che può risolvere lui (un'impostazione da
/// abilitare, la connessione da controllare), lo dice esplicitamente invece
/// di mostrare la descrizione tecnica grezza.
enum UserFacingError {
    static func message(for error: Error) -> String {
        if CallDirectoryManager.isExtensionDisabledError(error) {
            return "Tocca «Apri Impostazioni» nella schermata principale: ti guidiamo passo passo per attivarlo."
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return "Nessuna connessione Internet: controlla la connessione e riprova."
            case .timedOut:
                return "La richiesta ha impiegato troppo tempo: riprova più tardi."
            default:
                break
            }
        }
        return error.localizedDescription
    }
}
