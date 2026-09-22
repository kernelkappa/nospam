import IdentityLookup

/// Filtro SMS/iMessage: il sistema interpella questa estensione solo per
/// messaggi da mittenti sconosciuti (non in rubrica), interamente offline,
/// prima ancora che il messaggio venga mostrato all'utente.
final class MessageFilterExtension: ILMessageFilterExtension {}

extension MessageFilterExtension: ILMessageFilterQueryHandling {
    func handle(
        _ queryRequest: ILMessageFilterQueryRequest,
        context: ILMessageFilterExtensionContext,
        completion: @escaping (ILMessageFilterQueryResponse) -> Void
    ) {
        let response = ILMessageFilterQueryResponse()
        if let sender = queryRequest.sender, SpamNumberStore.isSpamNumber(sender) {
            response.action = .filter
        } else {
            response.action = .allow
        }
        completion(response)
    }
}
