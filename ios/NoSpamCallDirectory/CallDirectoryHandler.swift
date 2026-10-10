import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {
    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        CallDirectoryDebugLog.reset()
        CallDirectoryDebugLog.log("beginRequest start, isIncremental=\(context.isIncremental)")
        context.delegate = self

        // L'MVP non traccia delta incrementali: quando il sistema chiede un
        // aggiornamento incrementale, azzeriamo tutto e poi ri-aggiungiamo
        // l'intero set corrente, cosi' il risultato e' sempre corretto.
        if context.isIncremental {
            context.removeAllBlockingEntries()
            context.removeAllIdentificationEntries()
        }
        CallDirectoryDebugLog.log("after isIncremental handling")

        let (blocking, identification) = SpamNumberStore.loadCallDirectoryNumbers()
        CallDirectoryDebugLog.log("data loaded: blocking=\(blocking.count) identification=\(identification.count)")

        for (index, number) in blocking.enumerated() {
            context.addBlockingEntry(withNextSequentialPhoneNumber: CXCallDirectoryPhoneNumber(number))
            if index % 5000 == 0 {
                CallDirectoryDebugLog.log("blocking progress: \(index)/\(blocking.count)")
            }
        }
        CallDirectoryDebugLog.log("blocking loop done: \(blocking.count) entries")

        for (index, number) in identification.enumerated() {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: CXCallDirectoryPhoneNumber(number), label: "Spam probabile")
            if index % 5000 == 0 {
                CallDirectoryDebugLog.log("identification progress: \(index)/\(identification.count)")
            }
        }
        CallDirectoryDebugLog.log("identification loop done: \(identification.count) entries")

        CallDirectoryDebugLog.log("calling completeRequest")
        context.completeRequest()
        CallDirectoryDebugLog.log("completeRequest returned")
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // Il sistema puo' ritentare piu' tardi; non c'e' altro da fare qui.
    }
}
