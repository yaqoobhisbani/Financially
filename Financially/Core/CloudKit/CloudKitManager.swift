import Foundation
import CloudKit
import SwiftData

@Observable
final class CloudKitManager {
    private let container: CKContainer
    private let database: CKDatabase
    private let zoneID: CKRecordZone.ID

    var syncStatus: SyncStatus = .unknown

    enum SyncStatus {
        case unknown
        case syncing
        case synced
        case error(Error)
    }

    init(containerIdentifier: String = "iCloud.com.financially.app") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
        self.zoneID = CKRecordZone.ID(zoneName: "FinanciallyZone", ownerName: CKCurrentUserDefaultName)
    }

    func setupZone() async throws {
        let zone = CKRecordZone(zoneID: zoneID)
        do {
            _ = try await database.modifyRecordZones(saving: [zone], deleting: [])
        } catch {
            return
        }
    }

    func subscribe() async throws {
        let subscription = CKDatabaseSubscription(subscriptionID: "financially-sync")
        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification
        _ = try await database.save(subscription)
    }
}