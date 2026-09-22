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
}
