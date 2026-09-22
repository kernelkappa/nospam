import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // La registrazione deve avvenire prima che il launch termini, per
        // questo vive qui e non in una view SwiftUI.
        BGTaskManager.registerTasks()
        return true
    }
}
