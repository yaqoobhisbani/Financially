import Foundation
import SwiftData

@Observable
final class MFPortfolioViewModel {
    private let modelContext: ModelContext
    let account: Account

    private var allLedgerEntries: [LedgerEntry] { (try? modelContext.fetch(FetchDescriptor<LedgerEntry>())) ?? [] }
    private var allTransactions: [Transaction] { (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? [] }
    private var allHoldings: [MutualFundHolding] { (try? modelContext.fetch(FetchDescriptor<MutualFundHolding>())) ?? [] }

    init(modelContext: ModelContext, account: Account) {
        self.modelContext = modelContext
        self.account = account
    }

    var accountHoldings: [MutualFundHolding] {
        allHoldings.filter { $0.accountId == account.id && $0.totalUnits > 0 }
    }

    var totalHoldingValue: Decimal {
        accountHoldings.reduce(0) { $0 + $1.currentValue }
    }

    var totalCostBasis: Decimal {
        accountHoldings.reduce(0) { $0 + $1.totalCost }
    }

    var totalUnrealizedPAndL: Decimal {
        accountHoldings.reduce(0) { $0 + $1.unrealizedPAndL }
    }

    var totalPAndLPercentage: Decimal {
        guard totalCostBasis > 0 else { return 0 }
        return (totalUnrealizedPAndL / totalCostBasis) * 100
    }

    var mfTransactions: [Transaction] {
        allTransactions.filter { $0.relatedEntityId == account.id && ($0.type == .mutualFundBuy || $0.type == .mutualFundSell) }
            .sorted { $0.date > $1.date }
    }

    var mfLedgerEntries: [LedgerEntry] {
        allLedgerEntries.filter { entry in
            mfTransactions.contains { $0.id == entry.transactionId }
        }
    }

    func transaction(for entry: LedgerEntry) -> Transaction? {
        allTransactions.first { $0.id == entry.transactionId }
    }

    func toggleActive() {
        account.isActive.toggle()
        account.updatedAt = Date()
    }
}
