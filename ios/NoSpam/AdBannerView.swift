import GoogleMobileAds
import SwiftUI

/// Banner pubblicitario AdMob, mostrato solo dopo che ConsentManager ha
/// concluso la raccolta del consenso GDPR e la richiesta ATT (altrimenti
/// l'SDK non è nemmeno avviato). Riserva comunque lo spazio prima di allora
/// per evitare che il layout "salti" quando il consenso si risolve.
struct AdBannerView: View {
    @ObservedObject private var consentManager = ConsentManager.shared

    /// L'altezza del banner adattivo dipende solo dalla larghezza del
    /// dispositivo (non dal contenuto), quindi si puo' calcolare una sola
    /// volta dalla larghezza dello schermo invece che misurare il layout.
    private var adSize: AdSize {
        largeAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width)
    }

    var body: some View {
        Group {
            if consentManager.canRequestAds {
                AdBannerRepresentable(adSize: adSize)
            } else {
                Color.clear
            }
        }
        .frame(height: adSize.size.height)
    }
}

/// Il refresh automatico configurabile da dashboard ha un minimo di 30
/// secondi imposto da Google (refresh più aggressivi rischiano la
/// sospensione dell'account per "invalid traffic"), quindi qui il banner si
/// ricarica manualmente ogni 30 secondi con lo stesso intervallo minimo.
private struct AdBannerRepresentable: UIViewRepresentable {
    var adSize: AdSize
    var adUnitID: String = "ca-app-pub-3640143071817482/3121414906"

    private static let refreshInterval: TimeInterval = 30

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = Self.currentRootViewController()
        banner.delegate = context.coordinator
        banner.load(Request())
        context.coordinator.startRefreshTimer(for: banner)
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        private var timer: Timer?

        func startRefreshTimer(for banner: BannerView) {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: AdBannerRepresentable.refreshInterval, repeats: true) { [weak banner] _ in
                banner?.load(Request())
            }
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("AdBannerView: errore caricamento annuncio: \(error.localizedDescription)")
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
