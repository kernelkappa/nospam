import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {
    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // L'MVP non traccia delta incrementali: se il sistema ci richiede un
        // aggiornamento incrementale rifiutiamo, cosi verra' ripetuto un
        // caricamento completo (isIncremental = false).
        if context.isIncremental {
            context.cancelRequest(withError: NSError(domain: "com.konrad.nospam.CallDirectory", code: 1))
            return
        }

        let numbers = SpamNumberStore.loadSortedPhoneNumbers()

        for number in numbers {
            context.addBlockingEntry(withNextSequentialPhoneNumber: CXCallDirectoryPhoneNumber(number))
        }
        for number in numbers {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: CXCallDirectoryPhoneNumber(number), label: "Spam probabile")
        }

        context.completeRequest()
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // Il sistema puo' ritentare piu' tardi; non c'e' altro da fare qui.
    }
}
