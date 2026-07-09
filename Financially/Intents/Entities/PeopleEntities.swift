import Foundation
import AppIntents
import SwiftData

// MARK: - Debtor

struct DebtorEntity: AppEntity {
    let id: UUID
    let name: String
    let outstanding: Decimal

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Debtor"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "Outstanding: Rs \(outstanding.formatted(.number.precision(.fractionLength(0...2))))")
    }

    static var defaultQuery = DebtorQuery()
}

struct DebtorQuery: EntityQuery {
    @MainActor
    func entities(for ids: [DebtorEntity.ID]) async throws -> [DebtorEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<Debtor>())) ?? []
        return all.filter { ids.contains($0.id) && !$0.isSettled }
            .map { $0.toDebtorEntity() }
    }

    @MainActor
    func suggestedEntities() async throws -> [DebtorEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<Debtor>())) ?? []
        return all.filter { !$0.isSettled }
            .map { $0.toDebtorEntity() }
    }

    @MainActor
    func entities(matching string: String) async throws -> [DebtorEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<Debtor>())) ?? []
        return all.filter { !$0.isSettled && $0.name.localizedCaseInsensitiveContains(string) }
            .map { $0.toDebtorEntity() }
    }
}

// MARK: - Creditor

struct CreditorEntity: AppEntity {
    let id: UUID
    let name: String
    let outstanding: Decimal

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Creditor"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "Outstanding: Rs \(outstanding.formatted(.number.precision(.fractionLength(0...2))))")
    }

    static var defaultQuery = CreditorQuery()
}

struct CreditorQuery: EntityQuery {
    @MainActor
    func entities(for ids: [CreditorEntity.ID]) async throws -> [CreditorEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<Creditor>())) ?? []
        return all.filter { ids.contains($0.id) && !$0.isSettled }
            .map { $0.toCreditorEntity() }
    }

    @MainActor
    func suggestedEntities() async throws -> [CreditorEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<Creditor>())) ?? []
        return all.filter { !$0.isSettled }
            .map { $0.toCreditorEntity() }
    }

    @MainActor
    func entities(matching string: String) async throws -> [CreditorEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<Creditor>())) ?? []
        return all.filter { !$0.isSettled && $0.name.localizedCaseInsensitiveContains(string) }
            .map { $0.toCreditorEntity() }
    }
}

extension Debtor {
    func toDebtorEntity() -> DebtorEntity {
        DebtorEntity(id: id, name: name, outstanding: outstandingBalance)
    }
}

extension Creditor {
    func toCreditorEntity() -> CreditorEntity {
        CreditorEntity(id: id, name: name, outstanding: outstandingBalance)
    }
}
