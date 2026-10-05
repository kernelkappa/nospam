import SwiftUI

@main
struct NoSpamApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var updateRequired = false

    var body: some Scene {
        WindowGroup {
            Group {
                if updateRequired {
                    UpdateRequiredView()
                } else {
                    ContentView()
                }
            }
            .task {
                ConsentManager.shared.start()
                updateRequired = await UpdateGate.isUpdateRequired()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                BGTaskManager.scheduleRefresh()
            }
        }
    }
}
