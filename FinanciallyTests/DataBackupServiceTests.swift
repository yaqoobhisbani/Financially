import Testing
import Foundation
import SwiftData
@testable import Financially

@MainActor
@Suite("DataBackupService.factoryReset")
struct DataBackupServiceResetTests {

    @Test func factoryResetWipesUserDataAndReseedsDefaults() throws {
        let context = TestSupport.makeContext()

        // Some user data across a few tables, including a ledger entry and a custom category.
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let service = LedgerService(modelContext: context)
        _ = try service.execute(TransactionRequest(type: .expense, amount: 100, date: Date(), sourceAccountId: account.id))
        context.insert(Financially.Category(name: "Custom", icon: "star", categoryType: .expense, sortOrder: 99, isDefault: false))
        try context.save()

        #expect(try !context.fetch(FetchDescriptor<Account>()).isEmpty)
        #expect(try !context.fetch(FetchDescriptor<LedgerEntry>()).isEmpty)

        try DataBackupService(modelContext: context).factoryReset()

        // All user data gone.
        #expect(try context.fetch(FetchDescriptor<Account>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Transaction>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<LedgerEntry>()).isEmpty)

        // Default categories restored (custom one dropped), and Gold/Silver commodity infos re-seeded.
        let categories = try context.fetch(FetchDescriptor<Financially.Category>())
        #expect(categories.count == SeedCategories.expenseCategories.count + SeedCategories.incomeCategories.count)
        #expect(categories.allSatisfy { $0.isDefault })
        #expect(try context.fetch(FetchDescriptor<CommodityInfo>()).count == 2)
    }
}
