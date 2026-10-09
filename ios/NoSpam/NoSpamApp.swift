import SwiftUI

@main
struct NoSpamApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appearance = AppearancePreference.shared
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
            .preferredColorScheme(appearance.mode.colorScheme)
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
