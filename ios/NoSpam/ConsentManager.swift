import AppTrackingTransparency
import GoogleMobileAds
import SwiftUI
import UserMessagingPlatform

/// Raccoglie il consenso GDPR tramite Google UMP (mostra il form solo se
/// l'utente è geolocalizzato in SEE/UK/Svizzera, altrimenti prosegue subito),
/// poi richiede l'autorizzazione App Tracking Transparency (obbligatoria su
/// iOS per l'accesso all'IDFA, indipendente dalla geografia). L'SDK AdMob
/// viene avviato e le ads caricate solo dopo che entrambi i passaggi sono
/// conclusi, così la personalizzazione riflette la scelta reale dell'utente
/// invece di essere disattivata a priori.
@MainActor
final class ConsentManager: ObservableObject {
    static let shared = ConsentManager()

    @Published private(set) var canRequestAds = false

    private var didStart = false

    private init() {}

    func start() {
        guard !didStart else { return }
        didStart = true

        let parameters = RequestParameters()
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            if let error {
                print("ConsentManager: errore aggiornamento consenso: \(error.localizedDescription)")
            }
            Task { @MainActor in
                await self?.presentFormIfNeeded()
            }
        }
    }

    private func presentFormIfNeeded() async {
        if let rootViewController = Self.currentRootViewController() {
            do {
                try await ConsentForm.loadAndPresentIfRequired(from: rootViewController)
            } catch {
                print("ConsentManager: errore form di consenso: \(error.localizedDescription)")
            }
        }
        await requestTrackingAuthorization()
    }

    private func requestTrackingAuthorization() async {
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
        finish()
    }

    private func finish() {
        guard ConsentInformation.shared.canRequestAds else { return }
        MobileAds.shared.start(completionHandler: nil)
        canRequestAds = true
    }

    private static func currentRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?.rootViewController
    }
}
