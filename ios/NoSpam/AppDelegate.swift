import GoogleMobileAds
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // La registrazione deve avvenire prima che il launch termini, per
        // questo vive qui e non in una view SwiftUI.
        BGTaskManager.registerTasks()

        // Ads non personalizzate: evita il prompt di App Tracking Transparency
        // e la richiesta di consenso GDPR per le ads personalizzate in UE.
        MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState = .disabled
        MobileAds.shared.start(completionHandler: nil)

        return true
    }
}
