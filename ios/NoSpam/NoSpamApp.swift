import SwiftUI

@main
struct NoSpamApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    ConsentManager.shared.start()
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                BGTaskManager.scheduleRefresh()
            }
        }
    }
}
