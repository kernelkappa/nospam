import BackgroundTasks
import Foundation

enum BGTaskManager {
    static let refreshTaskIdentifier = "com.konrad.nospam.refresh"

    static func registerTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            handleRefresh(task: refreshTask)
        }
    }

    static func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handleRefresh(task: BGAppRefreshTask) {
        // Incateniamo subito la prossima esecuzione, cosi' il ciclo continua
        // anche se questa fallisce o scade.
        scheduleRefresh()

        let syncTask = Task {
            do {
                try await SpamDatabaseSync.sync()
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            syncTask.cancel()
        }
    }
}
