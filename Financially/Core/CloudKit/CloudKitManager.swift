import Foundation
import CloudKit

@Observable
final class CloudKitManager {
    private let container = CKContainer.default()
    private var database: CKDatabase?

    var syncStatus: SyncStatus = .unknown
    var isAvailable = false

    enum SyncStatus: Equatable {
        case unknown
        case syncing
        case synced
        case failed(String)
    }

    func setup() async {
        syncStatus = .syncing
        database = container.privateCloudDatabase

        do {
            _ = try await container.userRecordID()
        } catch {
            isAvailable = false
            syncStatus = .failed("CloudKit not available (no entitlements)")
            return
        }

        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                isAvailable = true
                try await setupZone()
                try await subscribe()
                syncStatus = .synced
            case .noAccount, .restricted, .couldNotDetermine:
                isAvailable = false
                syncStatus = .failed("iCloud account not available")
            case .temporarilyUnavailable:
                isAvailable = false
                syncStatus = .failed("iCloud temporarily unavailable")
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
        guard let database = database else { return }
        let zoneID = CKRecordZone.ID(zoneName: "FinanciallyZone")
        let zone = CKRecordZone(zoneID: zoneID)
        do {
            _ = try await database.modifyRecordZones(saving: [zone], deleting: [])
        } catch {
            return
        }
    }

    private func subscribe() async throws {
        guard let database = database else { return }
        let subscription = CKDatabaseSubscription(subscriptionID: "financially-sync")
        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification
        do {
            _ = try await database.save(subscription)
        } catch {
            // fine
        }
    }
}