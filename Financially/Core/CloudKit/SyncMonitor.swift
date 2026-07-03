import CloudKit
import SwiftData

@Observable
final class SyncMonitor {
    private let cloudKitManager: CloudKitManager

    init(cloudKitManager: CloudKitManager) {
        self.cloudKitManager = cloudKitManager
    }

    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async {
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        guard notification?.subscriptionID == "financially-sync" else { return }
        await sync()
    }

    func sync() async {
        cloudKitManager.syncStatus = .synced
    }
}