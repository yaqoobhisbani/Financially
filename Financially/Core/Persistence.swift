import Foundation
import SwiftData

extension ModelContainer {
    static let financially: ModelContainer = {
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

        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
