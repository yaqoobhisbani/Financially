import Foundation
import CloudKit

@Observable
final class CloudKitManager {
    private let container: CKContainer
    private let database: CKDatabase

    var syncStatus: SyncStatus = .unknown
    var isAvailable = false

    enum SyncStatus: Equatable {
        case unknown
        case syncing
        case synced
        case failed(String)
    }

    init(containerIdentifier: String = "iCloud.com.yaqoobdev.Financially") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
    }

    func setup() async {
        syncStatus = .syncing
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                isAvailable = true
                try await setupZone()
                try await subscribe()
                syncStatus = .synced
            case .noAccount, .restricted, .couldNotDetermine, .temporarilyUnavailable:
                isAvailable = false
                syncStatus = .failed("iCloud account not available")
            @unknown default:
                isAvailable = false
                syncStatus = .failed("Unknown iCloud status")
            }
        } catch {
            isAvailable = false
            syncStatus = .failed(error.localizedDescription)
        }
    }

    private func setupZone() async throws {
        let zoneID = CKRecordZone.ID(zoneName: "FinanciallyZone")
        let zone = CKRecordZone(zoneID: zoneID)
        do {
            _ = try await database.modifyRecordZones(saving: [zone], deleting: [])
        } catch {
            return
        }
    }

    private func subscribe() async throws {
        let subscription = CKDatabaseSubscription(subscriptionID: "financially-sync")
        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification
        do {
            _ = try await database.save(subscription)
        } catch {
            // Subscription may already exist — that's fine
        }
    }
}