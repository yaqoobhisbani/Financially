import Foundation
import AppIntents
import SwiftData

struct CommitteeEntity: AppEntity {
    let id: UUID
    let name: String
    let monthlyAmount: Decimal
    let totalMembers: Int
    let monthsCompleted: Int

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Committee"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "Rs \(monthlyAmount.formatted(.number.precision(.fractionLength(0))))/mo - \(monthsCompleted)/\(totalMembers) months")
    }

    static var defaultQuery = CommitteeQuery()
}

struct CommitteeQuery: EntityQuery {
    @MainActor
    func entities(for ids: [CommitteeEntity.ID]) async throws -> [CommitteeEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<Committee>())) ?? []
        return all.filter { ids.contains($0.id) && $0.isActive && !$0.isComplete }
            .map { $0.toCommitteeEntity() }
    }

    @MainActor
    func suggestedEntities() async throws -> [CommitteeEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<Committee>())) ?? []
        return all.filter { $0.isActive && !$0.isComplete }
            .map { $0.toCommitteeEntity() }
    }

    @MainActor
    func entities(matching string: String) async throws -> [CommitteeEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<Committee>())) ?? []
        return all.filter { $0.isActive && !$0.isComplete && $0.name.localizedCaseInsensitiveContains(string) }
            .map { $0.toCommitteeEntity() }
    }
}

extension Committee {
    func toCommitteeEntity() -> CommitteeEntity {
        CommitteeEntity(id: id, name: name, monthlyAmount: monthlyAmount, totalMembers: totalMembers, monthsCompleted: monthsCompleted)
    }
}
