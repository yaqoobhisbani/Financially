import Foundation
import AppIntents
import SwiftData

// MARK: - Bank / Cash Account

struct AccountEntity: AppEntity {
    let id: UUID
    let name: String
    let displayType: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Account"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(displayType)")
    }

    static var defaultQuery = AccountQuery()
}

struct AccountQuery: EntityQuery {
    @MainActor
    func entities(for ids: [AccountEntity.ID]) async throws -> [AccountEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        return all.filter { ids.contains($0.id) && $0.isActive && ($0.accountType == .bank || $0.accountType == .cash) }
            .map { $0.toAccountEntity() }
    }

    @MainActor
    func suggestedEntities() async throws -> [AccountEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        return all.filter { $0.isActive && ($0.accountType == .bank || $0.accountType == .cash) }
            .map { $0.toAccountEntity() }
    }
}

// MARK: - PSX Account

struct PSXAccountEntity: AppEntity {
    let id: UUID
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "PSX Account"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery = PSXAccountQuery()
}

struct PSXAccountQuery: EntityQuery {
    @MainActor
    func entities(for ids: [PSXAccountEntity.ID]) async throws -> [PSXAccountEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        return all.filter { ids.contains($0.id) && $0.isActive && $0.accountType == .psx }
            .map { $0.toPSXAccountEntity() }
    }

    @MainActor
    func suggestedEntities() async throws -> [PSXAccountEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        return all.filter { $0.isActive && $0.accountType == .psx }
            .map { $0.toPSXAccountEntity() }
    }
}

// MARK: - MF Account

struct MFAccountEntity: AppEntity {
    let id: UUID
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Mutual Fund Account"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery = MFAccountQuery()
}

struct MFAccountQuery: EntityQuery {
    @MainActor
    func entities(for ids: [MFAccountEntity.ID]) async throws -> [MFAccountEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        return all.filter { ids.contains($0.id) && $0.isActive && $0.accountType == .mutualFund }
            .map { $0.toMFAccountEntity() }
    }

    @MainActor
    func suggestedEntities() async throws -> [MFAccountEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        return all.filter { $0.isActive && $0.accountType == .mutualFund }
            .map { $0.toMFAccountEntity() }
    }
}

extension Account {
    func toAccountEntity() -> AccountEntity {
        AccountEntity(id: id, name: name, displayType: accountType == .bank ? (bankName ?? "Bank") : accountType == .cash ? "Cash" : accountType.rawValue)
    }

    func toPSXAccountEntity() -> PSXAccountEntity {
        PSXAccountEntity(id: id, name: name)
    }

    func toMFAccountEntity() -> MFAccountEntity {
        MFAccountEntity(id: id, name: name)
    }
}
