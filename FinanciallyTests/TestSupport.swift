import Foundation
import SwiftData
@testable import Financially

@MainActor
enum TestSupport {
    static func makeContext() -> ModelContext {
        let schema = Schema([
            Account.self,
            Transaction.self,
            LedgerEntry.self,
            Debtor.self,
            Creditor.self,
            InvestmentEntry.self,
            Category.self,
            StockHolding.self,
            StockTrade.self,
            StockInfo.self,
            CommodityInfo.self,
            CommodityHolding.self,
            CommodityTrade.self,
            MutualFundScheme.self,
            MutualFundHolding.self,
            MutualFundTrade.self,
            Committee.self,
            CommitteeContribution.self,
            CommitteePayout.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @discardableResult
    static func makeAccount(
        in context: ModelContext,
        name: String = "Test Account",
        type: AccountType = .bank,
        initialBalance: Decimal = 0,
        isActive: Bool = true
    ) -> Account {
        let account = Account(name: name, accountType: type, initialBalance: initialBalance, isActive: isActive)
        context.insert(account)
        return account
    }
}
