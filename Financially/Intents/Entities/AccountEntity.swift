import Foundation
import AppIntents
import SwiftData

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

extension Account {
    func toAccountEntity() -> AccountEntity {
        AccountEntity(id: id, name: name, displayType: accountType == .bank ? (bankName ?? "Bank") : accountType == .cash ? "Cash" : accountType.rawValue)
    }
}
