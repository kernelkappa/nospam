import GoogleMobileAds
import SwiftUI

/// Banner pubblicitario AdMob, mostrato solo dopo che ConsentManager ha
/// concluso la raccolta del consenso GDPR e la richiesta ATT (altrimenti
/// l'SDK non è nemmeno avviato). Riserva comunque lo spazio prima di allora
/// per evitare che il layout "salti" quando il consenso si risolve.
struct AdBannerView: View {
    @ObservedObject private var consentManager = ConsentManager.shared

    var body: some View {
        Group {
            if consentManager.canRequestAds {
                AdBannerRepresentable()
            } else {
                Color.clear
            }
        }
    }
}

/// Il refresh automatico configurabile da dashboard ha un minimo di 30
/// secondi imposto da Google (refresh più aggressivi rischiano la
/// sospensione dell'account per "invalid traffic"), quindi qui il banner si
/// ricarica manualmente ogni 30 secondi con lo stesso intervallo minimo.
private struct AdBannerRepresentable: UIViewRepresentable {
    /// ID di TEST ufficiale Google (banner formato fisso 320x50), sicuro da
    /// usare in sviluppo. Sostituire con l'ID reale AdMob prima di pubblicare.
    var adUnitID: String = "ca-app-pub-3940256099942544/2934735716"

    private static let refreshInterval: TimeInterval = 30

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = Self.currentRootViewController()
        banner.load(Request())
        context.coordinator.startRefreshTimer(for: banner)
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        private var timer: Timer?

        func startRefreshTimer(for banner: BannerView) {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: AdBannerRepresentable.refreshInterval, repeats: true) { [weak banner] _ in
                banner?.load(Request())
            }
        }

        deinit {
            timer?.invalidate()
        }
    }

    private static func currentRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?.rootViewController
    }
}
