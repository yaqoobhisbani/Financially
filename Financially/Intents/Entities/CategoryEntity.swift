import Foundation
import AppIntents
import SwiftData

// MARK: - Expense Category

struct ExpenseCategoryEntity: AppEntity {
    let id: UUID
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Expense Category"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery = ExpenseCategoryQuery()
}

struct ExpenseCategoryQuery: EntityQuery {
    @MainActor
    func entities(for ids: [ExpenseCategoryEntity.ID]) async throws -> [ExpenseCategoryEntity] {
        let context = ModelContainer.financially.mainContext
        try seedIfNeeded(context: context)
        let all = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        return all.filter { ids.contains($0.id) && $0.categoryType == .expense }
            .map { $0.toExpenseCategoryEntity() }
    }

    @MainActor
    func suggestedEntities() async throws -> [ExpenseCategoryEntity] {
        let context = ModelContainer.financially.mainContext
        try seedIfNeeded(context: context)
        let all = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        return all.filter { $0.categoryType == .expense }
            .map { $0.toExpenseCategoryEntity() }
    }

    @MainActor
    func entities(matching string: String) async throws -> [ExpenseCategoryEntity] {
        let context = ModelContainer.financially.mainContext
        try seedIfNeeded(context: context)
        let all = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        return all.filter { $0.categoryType == .expense && $0.name.localizedCaseInsensitiveContains(string) }
            .map { $0.toExpenseCategoryEntity() }
    }

    @MainActor
    private func seedIfNeeded(context: ModelContext) throws {
        let descriptor = FetchDescriptor<Category>()
        guard try context.fetchCount(descriptor) == 0 else { return }

        for (index, cat) in SeedCategories.expenseCategories.enumerated() {
            let category = Category(
                name: cat.name,
                icon: cat.icon,
                categoryType: .expense,
                sortOrder: index,
                isDefault: true
            )
            context.insert(category)
        }

        for (index, cat) in SeedCategories.incomeCategories.enumerated() {
            let category = Category(
                name: cat.name,
                icon: cat.icon,
                categoryType: .income,
                sortOrder: index,
                isDefault: true
            )
            context.insert(category)
        }

        try context.save()
    }
}

// MARK: - Income Category

struct IncomeCategoryEntity: AppEntity {
    let id: UUID
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Income Category"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery = IncomeCategoryQuery()
}

struct IncomeCategoryQuery: EntityQuery {
    @MainActor
    func entities(for ids: [IncomeCategoryEntity.ID]) async throws -> [IncomeCategoryEntity] {
        let context = ModelContainer.financially.mainContext
        try seedIfNeeded(context: context)
        let all = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        return all.filter { ids.contains($0.id) && $0.categoryType == .income }
            .map { $0.toIncomeCategoryEntity() }
    }

    @MainActor
    func suggestedEntities() async throws -> [IncomeCategoryEntity] {
        let context = ModelContainer.financially.mainContext
        try seedIfNeeded(context: context)
        let all = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        return all.filter { $0.categoryType == .income }
            .map { $0.toIncomeCategoryEntity() }
    }

    @MainActor
    func entities(matching string: String) async throws -> [IncomeCategoryEntity] {
        let context = ModelContainer.financially.mainContext
        try seedIfNeeded(context: context)
        let all = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        return all.filter { $0.categoryType == .income && $0.name.localizedCaseInsensitiveContains(string) }
            .map { $0.toIncomeCategoryEntity() }
    }

    @MainActor
    private func seedIfNeeded(context: ModelContext) throws {
        let descriptor = FetchDescriptor<Category>()
        guard try context.fetchCount(descriptor) == 0 else { return }

        for (index, cat) in SeedCategories.expenseCategories.enumerated() {
            let category = Category(
                name: cat.name,
                icon: cat.icon,
                categoryType: .expense,
                sortOrder: index,
                isDefault: true
            )
            context.insert(category)
        }

        for (index, cat) in SeedCategories.incomeCategories.enumerated() {
            let category = Category(
                name: cat.name,
                icon: cat.icon,
                categoryType: .income,
                sortOrder: index,
                isDefault: true
            )
            context.insert(category)
        }

        try context.save()
    }
}

extension Category {
    func toExpenseCategoryEntity() -> ExpenseCategoryEntity {
        ExpenseCategoryEntity(id: id, name: name)
    }

    func toIncomeCategoryEntity() -> IncomeCategoryEntity {
        IncomeCategoryEntity(id: id, name: name)
    }
}
