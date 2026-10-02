import CallKit
import Foundation

enum CallDirectoryManager {
    static let extensionIdentifier = "com.konrad.nospam.CallDirectory"

    static func reloadExtension(completion: ((Error?) -> Void)? = nil) {
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: extensionIdentifier) { error in
            completion?(error)
        }
    }

    static func checkEnabled(completion: @escaping (CXCallDirectoryManager.EnabledStatus) -> Void) {
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extensionIdentifier) { status, _ in
            completion(status)
        }
    }

    /// `reloadExtension` restituisce questo errore quando l'utente non ha
    /// ancora abilitato l'estensione da Impostazioni: non e' un bug, va
    /// mostrato come stato informativo e non come errore tecnico.
    static func isExtensionDisabledError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == "com.apple.CallKit.error.calldirectorymanager" && nsError.code == 6
    }
}
