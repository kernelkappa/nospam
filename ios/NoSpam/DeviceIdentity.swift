import Foundation
import CryptoKit

/// Per-install random identifier, sent only as an irreversible hash — never
/// IDFA/device serials — so reports can be rate-limited without tracking users.
enum DeviceIdentity {
    private static let storageKey = "nospam.device_identifier"

    static var hashedDeviceId: String {
        let digest = SHA256.hash(data: Data(rawDeviceId().utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func rawDeviceId() -> String {
        if let existing = UserDefaults.standard.string(forKey: storageKey) {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: storageKey)
        return newId
    }
}
