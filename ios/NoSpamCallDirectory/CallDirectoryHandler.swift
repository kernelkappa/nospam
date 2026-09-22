import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {
    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // L'MVP non traccia delta incrementali: quando il sistema chiede un
        // aggiornamento incrementale, azzeriamo tutto e poi ri-aggiungiamo
        // l'intero set corrente, cosi' il risultato e' sempre corretto.
        if context.isIncremental {
            context.removeAllBlockingEntries()
            context.removeAllIdentificationEntries()
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
