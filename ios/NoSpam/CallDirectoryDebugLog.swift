import Foundation

/// Log diagnostico temporaneo per capire a che punto esatto
/// CXCallDirectoryProvider viene interrotto (errore
/// com.apple.CallKit.error.calldirectorymanager code 2). Scrive su un file
/// nell'App Group cosi' sopravvive anche se l'estensione viene uccisa a
/// meta' esecuzione; leggibile da Mac via:
/// xcrun devicectl device copy from --domain-type appGroupDataContainer
/// --domain-identifier group.com.konrad.nospam --source calldirectory_debug.log
enum CallDirectoryDebugLog {
    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.konrad.nospam")?
            .appendingPathComponent("calldirectory_debug.log")
    }

    static func reset() {
        guard let fileURL else { return }
        try? "".write(to: fileURL, atomically: true, encoding: .utf8)
    }

    static func log(_ message: String) {
        guard let fileURL else { return }
        let line = "\(Date()) \(message)\n"
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile()
            handle.write(line.data(using: .utf8)!)
            try? handle.close()
        } else {
            try? line.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
}
